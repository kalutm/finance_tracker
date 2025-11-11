from sqlmodel import Session
from app.transactions import repo
from app.models.transaction import Transaction
from typing import List, Optional, Tuple
from sqlalchemy.exc import SQLAlchemyError
from uuid import uuid4
from sqlmodel import Session
from app.models.transaction import Transaction, TransactionType
from app.transactions import repo
from app.transactions.schemas import TransferTransactionCreate, TransactionPatch
from app.accounts.repo import get_account_for_user
from app.transactions.exceptions import (
    TransactionNotFound,
    InsufficientBalance,
    InvalidAmount,
    TransactionError,
    CanNotUpdateTransaction,
)


class TransactionsService:
    def __init__(self, session: Session):
        self.session = session

    def create_income_expense_transaction(self, data, user_id: str) -> Transaction:
        transaction = Transaction(**data, user_id=user_id)
        account_id = transaction.account_id
        amount = transaction.amount
        account = get_account_for_user(self.session, account_id, user_id)

        if amount <= 0:
            raise InvalidAmount("amount must be a postive integer")
        if transaction.type == TransactionType.EXPENSE:
            if account.balance < amount:
                raise InsufficientBalance("account balance insufficient")
            account.balance -= amount
        elif transaction.type == TransactionType.INCOME:
            account.balance += amount

        txn = repo.save_transaction(self.session, transaction)
        self.session.commit()
        return txn

    def create_transfer_transaction(
        self, transfer_txn: TransferTransactionCreate, user_id: str
    ) -> Tuple[Transaction, Transaction]:
        try:
            transfer_group_id = uuid4()
            amount = transfer_txn.amount
            occured_at = transfer_txn.occurred_at

            # validate amount before continuing
            if amount <= 0:
                raise InvalidAmount("amount must be a postive integer")

            # 1. Decrease balance on sender account
            from_account = get_account_for_user(
                self.session, transfer_txn.account_id, user_id
            )
            if from_account.balance < amount:
                raise InsufficientBalance("account balance insufficient")
            from_account.balance -= amount

            # 2. Increase balance on receiver account
            to_account = get_account_for_user(
                self.session, transfer_txn.to_account_id, user_id
            )
            to_account.balance += amount

            # 3. Add two linked transaction rows
            outgoing_txn = Transaction(
                account_id=from_account.id,
                user_id=user_id,
                amount=amount,
                currency=transfer_txn.currency,
                type=TransactionType.TRANSFER,
                transfer_group_id=transfer_group_id,
                description=transfer_txn.description,
                is_outgoing=True,
            )
            if occured_at:
                outgoing_txn.occurred_at = occured_at
            incoming_txn = Transaction(
                account_id=to_account.id,
                user_id=user_id,
                amount=amount,
                currency=transfer_txn.currency,
                type=TransactionType.TRANSFER,
                transfer_group_id=transfer_group_id,
                description=transfer_txn.description,
                is_outgoing=False,
            )
            if occured_at:
                incoming_txn.occurred_at = occured_at

            outgoing_txn = repo.save_transaction(self.session, outgoing_txn)
            incoming_txn = repo.save_transaction(self.session, incoming_txn)

            self.session.commit()
            return outgoing_txn, incoming_txn
        except SQLAlchemyError as e:
            self.session.rollback()
            raise e

    def get_user_transactions(
        self, user_id, limit, offset, account_id, category_id, start, end
    ) -> Tuple[List[Transaction], int]:
        return repo.list_user_transactions(
            self.session, user_id, limit, offset, account_id, category_id, start, end
        )

    def get_transaction(self, id, user_id) -> Transaction:
        transaction = repo.get_transaction_for_user(self.session, id, user_id)
        if not transaction:
            raise TransactionNotFound("Transaction not found")
        return transaction

    def update_transaction(
        self, transaction_data: TransactionPatch, id, user_id
    ) -> Transaction:
        transaction = repo.get_transaction_for_user(self.session, id, user_id)
        if not transaction:
            raise TransactionNotFound("Transaction not found")

        account = get_account_for_user(self.session, transaction.account_id, user_id)
        amount = transaction_data.amount

        if transaction.type == TransactionType.TRANSFER:
            raise CanNotUpdateTransaction("cannot update transfer transctions")

        # validate amount before continuing
        if amount is not None and amount <= 0:
            raise InvalidAmount("amount must be a postive integer")

        # update account balance only if the user updated the amount
        if amount is not None:
            offset = amount - transaction.amount

            if transaction.type == TransactionType.EXPENSE:
                # validate account balance before updating
                if offset > account.balance:
                    raise InsufficientBalance("account balance insufficient")
                account.balance -= offset
            else:
                if offset < 0 and account.balance < abs(offset):
                    raise InsufficientBalance("account balance insufficient")
                account.balance += offset

        update_data = transaction_data.model_dump(exclude_unset=True)
        for field, value in update_data.items():
            setattr(transaction, field, value)

        updated_transaction = repo.save_transaction(self.session, transaction)
        self.session.commit()
        return updated_transaction

    def delete_transaction(self, id, user_id):
        transaction = repo.get_transaction_for_user(self.session, id, user_id)
        if not transaction:
            raise TransactionNotFound("Transaction not found")
        amount = transaction.amount
        account = get_account_for_user(self.session, transaction.account_id, user_id)
        if transaction.type == TransactionType.INCOME:
            if amount > account.balance:
                raise InsufficientBalance("account balance insufficient")
            account.balance -= amount
        elif transaction.type == TransactionType.EXPENSE:
            account.balance += amount
        else:
            transfer_group_id = transaction.transfer_group_id
            group_transactions = repo.get_transfer_transactions(
                self.session,
                transfer_group_id,
                user_id
            )
            if len(group_transactions) != 2:
                raise TransactionError("Invalid transfer transaction")
            outgoing_transaction = [
                txn for txn in group_transactions if txn.is_outgoing
            ].pop()
            incoming_transaction = [
                txn for txn in group_transactions if not txn.is_outgoing
            ].pop()

            from_account = get_account_for_user(
                self.session, outgoing_transaction.account_id, user_id
            )
            to_account = get_account_for_user(
                self.session, incoming_transaction.account_id, user_id
            )

            from_account.balance += outgoing_transaction.amount
            if to_account.balance < incoming_transaction.amount:
                raise InsufficientBalance("account balance insufficient")
            to_account.balance -= incoming_transaction.amount

            repo.delete_transaction(self.session, outgoing_transaction)
            repo.delete_transaction(self.session, incoming_transaction)
            self.session.commit()
            return
        repo.delete_transaction(self.session, transaction)
        self.session.commit()

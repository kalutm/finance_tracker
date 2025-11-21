from sqlmodel import Session
from fastapi import Depends
from app.models.transaction import Transaction
from typing import List, Optional, Tuple, Dict
from decimal import Decimal, ROUND_HALF_UP
from sqlalchemy.exc import SQLAlchemyError
from uuid import uuid4
from datetime import datetime
from calendar import monthrange
from sqlmodel import Session
from app.models.transaction import Transaction, TransactionType
from app.models.account import Account
from app.models.category import Category
from app.transactions.schemas import TransferTransactionCreate, TransactionPatch
from app.accounts.repo import AccountRepository, get_account_repo
from app.transactions.repo import TransactionRepo, get_transaction_repo
from app.transactions.exceptions import (
    TransactionNotFound,
    InsufficientBalance,
    InvalidAmount,
    TransactionError,
    CanNotUpdateTransaction,
    InvalidTransferTransaction
)


class TransactionsService:
    def __init__(
        self, transaction_repo: TransactionRepo, account_repo: AccountRepository
    ):
        self.transaction_repo = transaction_repo
        self.account_repo = account_repo

    def create_income_expense_transaction(
        self, session: Session, data, user_id: str
    ) -> Transaction:
        transaction = Transaction(**data, user_id=user_id)
        account_id = transaction.account_id
        amount = transaction.amount
        account = self.account_repo.get_account_for_user(session, account_id, user_id)

        if amount <= 0:
            raise InvalidAmount("amount must be a postive integer")
        if transaction.type == TransactionType.EXPENSE:
            if account.balance < amount:
                raise InsufficientBalance("account balance insufficient")
            account.balance -= amount
        elif transaction.type == TransactionType.INCOME:
            account.balance += amount

        txn = self.transaction_repo.save_transaction(session, transaction)
        session.commit()
        return txn

    def create_transfer_transaction(
        self, session: Session, transfer_txn: TransferTransactionCreate, user_id: str
    ) -> Tuple[Transaction, Transaction]:
        try:
            transfer_group_id = uuid4()
            amount = transfer_txn.amount
            occured_at = transfer_txn.occurred_at

            # validate amount before continuing
            if amount <= 0:
                raise InvalidAmount("amount must be a postive integer")

            # 1. Decrease balance on sender account
            from_account = self.account_repo.get_account_for_user(
                session, transfer_txn.account_id, user_id
            )
            if from_account.balance < amount:
                raise InsufficientBalance("account balance insufficient")
            from_account.balance -= amount

            # 2. Increase balance on receiver account
            to_account = self.account_repo.get_account_for_user(
                session, transfer_txn.to_account_id, user_id
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

            outgoing_txn = self.transaction_repo.save_transaction(session, outgoing_txn)
            incoming_txn = self.transaction_repo.save_transaction(session, incoming_txn)

            session.commit()
            return outgoing_txn, incoming_txn
        except SQLAlchemyError as e:
            session.rollback()
            raise e

    def get_user_transactions(
        self,
        session: Session,
        user_id,
        limit,
        offset,
        account_id,
        category_id,
        type,
        start,
        end,
    ) -> Tuple[List[Transaction], int]:
        return self.transaction_repo.list_user_transactions(
            session,
            user_id,
            limit,
            offset,
            account_id,
            category_id,
            type,
            start,
            end,
        )

    def get_transaction(self, session: Session, id, user_id) -> Transaction:
        transaction = self.transaction_repo.get_transaction_for_user(
            session, id, user_id
        )
        if not transaction:
            raise TransactionNotFound("Transaction not found")
        return transaction

    def update_transaction(
        self, session: Session, transaction_data: TransactionPatch, id, user_id
    ) -> Transaction:
        transaction = self.transaction_repo.get_transaction_for_user(
            session, id, user_id
        )
        if not transaction:
            raise TransactionNotFound("Transaction not found")

        account = self.account_repo.get_account_for_user(
            session, transaction.account_id, user_id
        )
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

        updated_transaction = self.transaction_repo.save_transaction(
            session, transaction
        )
        session.commit()
        return updated_transaction

    def delete_transaction(self, session: Session, id, user_id):
        transaction = self.transaction_repo.get_transaction_for_user(
            session, id, user_id
        )
        if not transaction:
            raise TransactionNotFound("Transaction not found")
        amount = transaction.amount
        account = self.account_repo.get_account_for_user(
            session, transaction.account_id, user_id
        )
        if transaction.type == TransactionType.INCOME:
            if amount > account.balance:
                raise InsufficientBalance("account balance insufficient")
            account.balance -= amount
        elif transaction.type == TransactionType.EXPENSE:
            account.balance += amount
        self.transaction_repo.delete_transaction(session, transaction)
        session.commit()

    def delete_transfer_transaction(self, session: Session, transfer_group_id, user_id):
        try:
            group_transactions = self.transaction_repo.get_transfer_transactions(
                session, transfer_group_id, user_id
            )
            if len(group_transactions) != 2:
                raise InvalidTransferTransaction("Invalid transfer transaction")
            outgoing_transaction = [
                txn for txn in group_transactions if txn.is_outgoing
            ].pop()
            incoming_transaction = [
                txn for txn in group_transactions if not txn.is_outgoing
            ].pop()

            from_account = self.account_repo.get_account_for_user(
                session, outgoing_transaction.account_id, user_id
            )
            to_account = self.account_repo.get_account_for_user(
                session, incoming_transaction.account_id, user_id
            )

            from_account.balance += outgoing_transaction.amount
            if to_account.balance < incoming_transaction.amount:
                raise InsufficientBalance("account balance insufficient")
            to_account.balance -= incoming_transaction.amount

            self.transaction_repo.delete_transaction(session, outgoing_transaction)
            self.transaction_repo.delete_transaction(session, incoming_transaction)
            session.commit()
        except SQLAlchemyError as e:
            session.rollback()
            raise e

    def get_transaction_summary(
        self, session: Session, month: str, user_id: str
    ) -> Dict[str, object]:
        year, month_num = map(int, month.split("-"))
        start_date = datetime(year, month_num, 1)
        end_date = datetime(year, month_num, monthrange(year, month_num)[1], 23, 59, 59)

        income = self.transaction_repo.get_transaction_summary_for_type(
            session, TransactionType.INCOME, start_date, end_date, user_id
        )
        expense = self.transaction_repo.get_transaction_summary_for_type(
            session, TransactionType.EXPENSE, start_date, end_date, user_id
        )

        net = income - expense
        return {
            "month": month,
            "total_income": income,
            "total_expense": expense,
            "net_savings": net,
        }

    def get_transaction_stats(
        self, session: Session, by: str, user_id: str
    ) -> List[Dict[str, object]]:
        group_field = {
            "category": Transaction.category_id,
            "account": Transaction.account_id,
            "type": Transaction.type,
        }[by]

        results = self.transaction_repo.get_grouped_transaction_totals(
            session, user_id, group_field
        )
        if not results:
            return []

        # total_sum might be Decimal or float
        total_sum = sum(Decimal(str(row.total)) for row in results)

        enriched = []
        for group_value, total in results:
            name = None
            if by == "category":
                category = session.get(Category, group_value)
                name = category.name if category else "Uncategorized"
            elif by == "account":
                account = session.get(Account, group_value)
                name = account.name if account else "Unknown Account"
            elif by == "type":
                name = group_value.value

            percentage = (
                (Decimal(total) / total_sum * 100).quantize(
                    Decimal("0.01"), rounding=ROUND_HALF_UP
                )
                if total_sum > 0
                else Decimal("0.00")
            )

            enriched.append(
                {"name": name, "total": Decimal(total), "percentage": percentage}
            )

        return enriched


# FastApi dependency provider
def get_transaction_service(
    transaction_repo: TransactionRepo = Depends(get_transaction_repo),
    account_repo: AccountRepository = Depends(get_account_repo),
) -> TransactionsService:
    return TransactionsService(transaction_repo, account_repo)

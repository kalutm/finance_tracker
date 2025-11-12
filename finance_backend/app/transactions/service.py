from sqlmodel import Session
from app.transactions import repo
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
        self, user_id, limit, offset, account_id, category_id, type, start, end
    ) -> Tuple[List[Transaction], int]:
        return repo.list_user_transactions(
            self.session,
            user_id,
            limit,
            offset,
            account_id,
            category_id,
            type,
            start,
            end,
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
        repo.delete_transaction(self.session, transaction)
        self.session.commit()

    def delete_transfer_transaction(self, transfer_group_id, user_id):
        try:
            group_transactions = repo.get_transfer_transactions(
                self.session, transfer_group_id, user_id
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
        except SQLAlchemyError as e:
            self.session.rollback()
            raise e

    def get_transaction_summary(self, month: str, user_id: str) -> Dict[str, object]:
        year, month_num = map(int, month.split("-"))
        start_date = datetime(year, month_num, 1)
        end_date = datetime(year, month_num, monthrange(year, month_num)[1], 23, 59, 59)

        income = repo.get_transaction_summary_for_type(
            self.session, TransactionType.INCOME, start_date, end_date, user_id
        )
        expense = repo.get_transaction_summary_for_type(
            self.session, TransactionType.EXPENSE, start_date, end_date, user_id
        )

        net = income - expense
        return {
            "month": month,
            "total_income": income,
            "total_expense": expense,
            "net_savings": net,
        }

    def get_transaction_stats(self, by: str, user_id: str) -> List[Dict[str, object]]:
        group_field = {
            "category": Transaction.category_id,
            "account": Transaction.account_id,
            "type": Transaction.type,
        }[by]

        results = repo.get_grouped_transaction_totals(
            self.session, user_id, group_field
        )
        if not results:
            return []

        # total_sum might be Decimal or float
        total_sum = sum(Decimal(str(row.total)) for row in results)

        enriched = []
        for group_value, total in results:
            name = None
            if by == "category":
                category = self.session.get(Category, group_value)
                name = category.name if category else "Uncategorized"
            elif by == "account":
                account = self.session.get(Account, group_value)
                name = account.name if account else "Unknown Account"
            elif by == "type":
                name = group_value.value  # assuming Enum

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

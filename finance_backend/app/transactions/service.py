from collections import defaultdict
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
    InvalidTransferTransaction,
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

    def create_transactions_bulk(
        self,
        session: Session,
        transactions,
        user_id: int,
        chunk_size: int = 500,
    ):
        # Validate incoming payload quickly
        incoming_mids = {t.message_id for t in transactions if t.message_id}
        if not incoming_mids:
            return {
                "inserted": 0,
                "skipped": len(transactions),
                "skipped_reasons": {"no_message_id": len(transactions)},
            }

        # Query DB for *only* message_ids that are in incoming_mids
        existing_mids = self.transaction_repo.get_transaction_with_message_id(
            session, incoming_mids, user_id
        )

        to_insert = []
        skipped_reasons = defaultdict(int)

        for t in transactions:
            # basic validation
            if not t.message_id:
                skipped_reasons["no_message_id"] += 1
                continue
            if t.message_id in existing_mids:
                skipped_reasons["duplicate"] += 1
                continue
            if t.amount <= 0:
                skipped_reasons["invalid_amount"] += 1
                continue

            account = self.account_repo.get_account_for_user(
                session, t.account_id, user_id
            )
            if not account:
                skipped_reasons["invalid_account"] += 1
                continue

            if t.type == TransactionType.EXPENSE:
                if account.balance < t.amount:
                    skipped_reasons["insufficient_funds"] += 1
                    continue
                account.balance -= t.amount
            else:
                account.balance += t.amount

            entity = Transaction(
                user_id=user_id, 
                account_id=t.account_id,
                amount=t.amount,
                merchant=t.merchant,
                currency=t.currency,
                type=t.type,
                description=t.description,
                occurred_at=t.occurred_at,
                message_id=t.message_id,
            )
            to_insert.append(entity)

            inserted = 0
            for i in range(0, len(to_insert), chunk_size):
                try:

                    chunk = to_insert[i : i + chunk_size]
                    self.transaction_repo.bulk_insert(session, chunk)
                except SQLAlchemyError:
                    # ignore duplicate transaciton's
                    continue
            session.commit()

        return {
            "inserted": len(to_insert),
            "skipped": sum(skipped_reasons.values()),
            "skipped_reasons": dict(skipped_reasons),
        }

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
        self, session: Session, month: str, date_from, date_to, user_id: str
    ) -> Dict[str, object]:
        if month:
            year, m = map(int, month.split("-"))
            date_from = datetime(year, m, 1)
            date_to = datetime(year, m + 1, 1) if m < 12 else datetime(year + 1, 1, 1)

        income, i_count = self.transaction_repo.get_transaction_summary_for_type(
            session, TransactionType.INCOME, date_from, date_to, user_id
        )
        expense, e_count = self.transaction_repo.get_transaction_summary_for_type(
            session, TransactionType.EXPENSE, date_from, date_to, user_id
        )

        net = income - expense
        count = i_count + e_count
        return {
            "total_income": income,
            "total_expense": expense,
            "net_savings": net,
            "transactions_count": count 
        }
    
    def get_timeseries(self, session: Session, granularity, date_from, date_to, user_id: str) -> List[Dict]:
        rows = self.transaction_repo.get_time_series_rows(session, granularity, date_from, date_to, user_id)
        return [
            {
            "date": period,
            "income": income,
            "expense": expense,
            "net": income - expense,
            }
            for period, income, expense in rows
        ]


    def get_transaction_stats(
        self, session: Session, by: str, date_from, date_to, limit, user_id: str
    ) -> List[Dict[str, object]]:
        group_field = {
            "category": Transaction.category_id,
            "account": Transaction.account_id,
            "type": Transaction.type,
        }[by]

        results = self.transaction_repo.get_grouped_transaction_totals_expense(
            session, date_from, date_to, limit, user_id, group_field
        )
        if not results:
            return []

        total_sum = sum(Decimal(str(total)) for label, total, count in results)

        enriched = []
        for group_value, total, count in results:
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
                {"name": name, "total": Decimal(total), "percentage": percentage, "transaction_count": count}
            )

        return enriched


# FastApi dependency provider
def get_transaction_service(
    transaction_repo: TransactionRepo = Depends(get_transaction_repo),
    account_repo: AccountRepository = Depends(get_account_repo),
) -> TransactionsService:
    return TransactionsService(transaction_repo, account_repo)

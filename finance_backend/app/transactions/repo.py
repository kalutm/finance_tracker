from sqlmodel import Session, select
from app.models.transaction import Transaction
from sqlalchemy import func, case
from typing import List, Tuple
from decimal import Decimal
from datetime import datetime

from app.models.enums import TransactionType


class TransactionRepo:
    def list_user_transactions(
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
        conditions = [Transaction.user_id == user_id]
        if account_id:
            conditions.append(Transaction.account_id == account_id)
        if category_id:
            conditions.append(Transaction.category_id == category_id)
        if type:
            conditions.append(Transaction.type == type)
        if start and end:
            conditions.append(Transaction.occurred_at.between(start, end))
        elif start:
            conditions.append(Transaction.occurred_at >= start)
        elif end:
            conditions.append(Transaction.occurred_at <= end)

        totalstmt = select(func.count()).select_from(Transaction).where(*conditions)
        total = session.exec(totalstmt).one()

        stmt = (
            select(Transaction)
            .where(*conditions)
            .limit(limit)
            .offset(offset)
            .order_by(Transaction.occurred_at.desc())
        )

        transactions = session.exec(stmt).all()
        return transactions, total

    def get_transaction_for_user(self, session: Session, id, user_id) -> Transaction:
        return session.exec(
            select(Transaction).where(
                Transaction.id == id, Transaction.user_id == user_id
            )
        ).first()

    def get_transfer_transactions(
        self, session: Session, transfer_group_id, user_id
    ) -> List[Transaction]:
        return session.exec(
            select(Transaction).where(
                Transaction.transfer_group_id == transfer_group_id,
                Transaction.user_id == user_id,
            )
        ).all()

    def get_transaction_with_message_id(
        self, session: Session, incoming_mids, user_id
    ) -> List[str]:
        return session.exec(
            select(Transaction.message_id).where(
                Transaction.user_id == user_id,
                Transaction.message_id.in_(list(incoming_mids)),
            )
        ).all()

    def save_transaction(
        self, session: Session, transaction: Transaction
    ) -> Transaction:
        session.add(transaction)
        session.flush()
        session.refresh(transaction)

        return transaction

    def bulk_insert(self, session: Session, transactions: List[Transaction]):
        session.add_all(transactions)

    def delete_transaction(self, session: Session, transaction: Transaction):
        session.delete(transaction)
        session.flush()

    def get_transaction_summary_for_type(
        self, session: Session, type, start_date, end_date, user_id
    ) -> Tuple[Decimal, int]:
        return session.exec(
            select(
                func.coalesce(func.sum(Transaction.amount), 0),
                func.count(Transaction.id),
            )
            .where(Transaction.user_id == user_id)
            .where(Transaction.type == type)
            .where(Transaction.occurred_at.between(start_date, end_date))
        ).one()

    def get_time_series_rows(
        self, session: Session, granularity, date_from, date_to, user_id
    ) -> List[Tuple[datetime, Decimal, Decimal]]:
        trunc = {
            "day": func.date(Transaction.occurred_at),
            "week": func.date_trunc("week", Transaction.occurred_at),
            "month": func.date_trunc("month", Transaction.occurred_at),
        }[granularity]

        stmt = (
            select(
                trunc.label("period"),
                func.sum(
                    case(
                        (
                            Transaction.type == TransactionType.INCOME,
                            Transaction.amount,
                        ),
                        else_=0,
                    )
                ).label("income"),
                func.sum(
                    case(
                        (
                            Transaction.type == TransactionType.EXPENSE,
                            Transaction.amount,
                        ),
                        else_=0,
                    )
                ).label("expense"),
            )
            .where(
                Transaction.user_id == user_id,
                Transaction.occurred_at >= date_from,
                Transaction.occurred_at <= date_to,
            )
            .group_by("period")
            .order_by("period")
        )
        return session.exec(stmt).all()

    def get_grouped_transaction_totals(
        self,
        session: Session,
        date_from,
        date_to,
        limit,
        is_expense,
        user_id: str,
        group_field,
    ) -> List[Tuple]:
        stmt = (
            select(
                group_field, func.sum(Transaction.amount), func.count(Transaction.id)
            )
            .where(
                Transaction.user_id == user_id,
                (
                    True
                    if not is_expense
                    else (
                        Transaction.type == TransactionType.EXPENSE
                        if is_expense
                        else Transaction.type == TransactionType.INCOME
                    )
                ),
            )
            .group_by(group_field)
            .order_by(func.sum(Transaction.amount).desc())
            .limit(limit)
        )
        if date_from:
            stmt = stmt.where(Transaction.occurred_at >= date_from)
        if date_to:
            stmt = stmt.where(Transaction.occurred_at <= date_to)
        return session.exec(stmt).all()


# FastApi dependency provider
def get_transaction_repo() -> TransactionRepo:
    return TransactionRepo()

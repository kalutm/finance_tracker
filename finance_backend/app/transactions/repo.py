from sqlmodel import Session, select
from app.models.transaction import Transaction
from sqlalchemy import func
from typing import List, Tuple
from decimal import Decimal


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

    def save_transaction(
        self, session: Session, transaction: Transaction
    ) -> Transaction:
        session.add(transaction)
        session.flush()
        session.refresh(transaction)

        return transaction

    def delete_transaction(self, session: Session, transaction: Transaction):
        session.delete(transaction)
        session.flush()

    def get_transaction_summary_for_type(
        self, session: Session, type, start_date, end_date, user_id
    ) -> Decimal:
        return session.exec(
            select(func.coalesce(func.sum(Transaction.amount), 0))
            .where(Transaction.user_id == user_id)
            .where(Transaction.type == type)
            .where(Transaction.occurred_at.between(start_date, end_date))
        ).one()

    def get_grouped_transaction_totals(
        self, session, user_id: str, group_field
    ) -> List[Tuple]:
        stmt = (
            select(group_field, func.sum(Transaction.amount).label("total"))
            .where(Transaction.user_id == user_id)
            .group_by(group_field)
        )
        return session.exec(stmt).all()


# FastApi dependency provider
def get_transaction_repo() -> TransactionRepo:
    return TransactionRepo()

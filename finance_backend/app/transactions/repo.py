from sqlmodel import Session, select
from app.models.transaction import Transaction
from sqlalchemy import _or, func
from typing import List

def list_user_transactions(
    session: Session, user_id, limit, offset, account_id, category_id, start, end
) -> List[Transaction]:
    totalstmt = (
        select(func.count())
        .select_from(Transaction)
        .where(
            Transaction.user_id == user_id,
            Transaction.account_id == account_id,
            Transaction.category_id == category_id,
            Transaction.occurred_at.between(start, end),
        )
    )
    total = session.exec(totalstmt)

    stmt = (
        select(Transaction)
        .where(
            Transaction.user_id == user_id,
            Transaction.account_id == account_id,
            Transaction.category_id == category_id,
            Transaction.occurred_at.between(start, end),
        )
        .limit(limit)
        .offset(offset)
    )

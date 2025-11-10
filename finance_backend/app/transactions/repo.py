from sqlmodel import Session, select
from app.models.transaction import Transaction
from sqlalchemy import func
from typing import List, Tuple


def list_user_transactions(
    session: Session, user_id, limit, offset, account_id, category_id, start, end
) -> Tuple[List[Transaction], int]:
    conditions = [Transaction.user_id == user_id]
    if account_id:
        conditions.append(Transaction.account_id == account_id)
    if category_id:
        conditions.append(Transaction.category_id == category_id)
    if start and end:
        conditions.append(Transaction.occurred_at.between(start, end))
    elif start:
        conditions.append(Transaction.occurred_at >= start)
    elif end:
        conditions.append(Transaction.occurred_at <= end)

    totalstmt = select(func.count()).select_from(Transaction).where(*conditions)
    total = session.exec(totalstmt).one()

    stmt = select(Transaction).where(*conditions).limit(limit).offset(offset)

    transactions = session.exec(stmt).all()
    return transactions, total


def get_transaction_for_user(session: Session, id, user_id) -> Transaction:
    return session.exec(
        select(Transaction).where(Transaction.id == id, Transaction.user_id == user_id)
    ).first()


def get_transfer_transactions(
    session: Session, transfer_group_id, user_id
) -> List[Transaction]:
    return session.exec(
        select(Transaction).where(
            Transaction.transfer_group_id == transfer_group_id,
            Transaction.user_id == user_id,
        )
    ).all()


def save_transaction(session: Session, transaction: Transaction) -> Transaction:
    session.add(transaction)
    session.flush()
    session.refresh(transaction)

    return transaction


def delete_transaction(session: Session, transaction: Transaction):
    session.delete(transaction)
    session.flush()

from sqlmodel import select, Session
from sqlalchemy import or_, func
from ..models.account import Account
from ..models.transaction import Transaction
from typing import List, Optional


def get_accounts_by_user_id(session: Session, user_id) -> List[Account]:
    return session.exec(select(Account).where(Account.user_id == user_id))


def list_user_accounts(
    session: Session, user_id, limit, offset, active
) -> tuple[List[Account], int]:
    total_stmt = (
        select(func.count())
        .select_from(Account)
        .where(
            Account.user_id == user_id,
            Account.active == active if active is not None else True,
        )
    )
    total = session.exec(total_stmt).one()
    stmt = (
        select(Account)
        .where(
            Account.user_id == user_id,
            Account.active == active if active is not None else True,
        )
        .order_by(Account.created_at.desc())
        .limit(limit)
        .offset(offset)
    )
    results = session.exec(stmt).all()
    return results, int(total)


def get_account_for_user(session, account_id, user_id) -> Optional[Account]:
    return session.exec(
        select(Account).where(Account.id == account_id, Account.user_id == user_id)
    ).first()


def save_account(session: Session, account: Account) -> Account:
    session.add(account)
    session.flush()
    session.refresh(account)

    return account


def get_account_by_id(session: Session, id) -> Account:
    return session.exec(select(Account).where(Account.id == id).with_for_update()).first()


def delete_account(session: Session, account: Account):
    session.delete(account)
    session.flush()


# helper
def count_transactions_for_account(session: Session, account_id) -> int:
    count_stmt = (
        select(func.count())
        .select_from(Transaction)
        .where(Transaction.account_id == account_id)
    )
    return session.exec(count_stmt).one()

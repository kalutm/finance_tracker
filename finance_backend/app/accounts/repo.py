from sqlmodel import select, Session
from sqlalchemy import or_
from ..models.account import Account
from typing import List, Optional


def get_accounts_by_user_id(session: Session, user_id) -> List[Account]:
    return session.exec(select(Account).where(Account.user_id == user_id))


def list_user_accounts(session: Session, user_id, limit, offset, active):
    accounts = session.exec(
        select(Account).where(Account.user_id == user_id, Account.active == active).limit(limit).offset(offset)
    ).all()


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
    return session.exec(select(Account).where(Account.id == id)).first()


def delete_account(session: Session, account: Account):
    session.delete(account)
    session.flush()
    session.refresh(account)
    return account

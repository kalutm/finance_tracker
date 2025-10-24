from sqlmodel import select, Session
from sqlalchemy import or_
from ..models.account import Account
from typing import List

def get_all_accounts(session: Session) -> List[Account]:
    return session.exec(select(Account))

def get_accounts_by_user_id(session: Session, user_id) -> List[Account]:
    return session.exec(select(Account).where(Account.user_id == user_id))

def save_account(session: Session, account: Account) -> Account:
    session.add(account)
    session.commit()
    session.refresh(account)

    return account


def get_account_by_id(session: Session, id) -> Account:
    return session.exec(select(Account).where(Account.id == id)).first()

def delete_account(session: Session, account: Account):
    session.delete(account)
    session.commit()
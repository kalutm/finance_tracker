from sqlmodel import Session
from app.models.user import User
from app.models.account import Account
from app.models.enums import AccountType
from ..accounts import repo
from typing import List


def get_accounts(session: Session) -> List[Account]:
    return repo.get_all_accounts(session)

def get_user_accounts(session: Session, user_id) -> List[Account]:
    return repo.get_accounts_by_user_id(session, user_id)

def create_account(session: Session, user_id, name, type, currency) -> Account:
    account_type = AccountType.CASH
    if type.lower() == "wallet":
        account_type = AccountType.WALLET
    elif type.lower() == "bank":
        account_type = AccountType.BANK

    account = Account(user_id=user_id, name=name, type=account_type, currency=currency)
    refreshed_account = repo.save_account(session, account)
    return refreshed_account

def get_account(session: Session, id) -> Account:
    return repo.get_account_by_id(session, id)

def update_account(session: Session, id, account_name) -> Account:
    account = repo.get_account_by_id(session, id)
    account.name = account_name
    updated_account = repo.save_account(session, account)
    return updated_account

def delete_account(session: Session, id):
    account = repo.get_account_by_id(session, id)
    repo.delete_account(session, account)
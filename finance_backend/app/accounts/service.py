from sqlmodel import Session
from sqlalchemy.exc import IntegrityError
from app.models.user import User
from app.models.account import Account
from app.models.enums import AccountType
from ..accounts.exceptions import (
    AccountError,
    AccountNameAlreadyTaken,
    AccountNotFound,
    UserNotAuthorizedForThisAccount,
    CouldnotDeleteAccount
    
)
from ..accounts import repo
from typing import List


def get_user_accounts(session: Session, user_id, limit, offset, active) -> tuple[List[Account], int]:
    return repo.list_user_accounts(session, user_id, limit, offset, active)

def create_account(session: Session, user_id, name, type, currency) -> Account:    
    account = Account(user_id=user_id, name=name, type=type, currency=currency)
    try:
        refreshed_account = repo.save_account(session, account)
        session.commit()
        return refreshed_account
    except IntegrityError:
        session.rollback()
        raise AccountNameAlreadyTaken("please use a different Account name")

def get_account(session: Session, id, user_id) -> Account:
    account = repo.get_account_for_user(session, id, user_id)
    if not account:
        raise AccountNotFound("couldnot find account please create another one")
    return account

def update_account(session: Session, id, update_data, user_id) -> Account:
    account = repo.get_account_for_user(session, id, user_id)
    if not account:
        raise AccountNotFound("couldnot find account")
    try:
        for field, value in update_data.items():
            if value is not None:
                setattr(account, field, value)
        updated_account = repo.save_account(session, account)
        session.commit()
        return updated_account
    except IntegrityError:
        session.rollback()
        raise AccountNameAlreadyTaken("please use a different Account name")

def delete_account(session: Session, id, user_id):
    account = repo.get_account_for_user(session, id, user_id)
    if not account:
        raise AccountNotFound("couldnot find account")
    if repo.count_transactions_for_account(session, id) > 0:
        raise CouldnotDeleteAccount("Cannot hard-delete account with transactions. Consider deactivating.")
    repo.delete_account(session, account)
    session.commit()

def deactivate_account(session: Session, id, user_id) -> Account:
    account = repo.get_account_for_user(session, id, user_id)
    if not account:
        raise AccountNotFound("couldnot find account")
    
    account.active = False
    deactivated_account = repo.save_account(session, account)
    session.commit()
    return deactivated_account

def restore_account(session: Session, id, user_id) -> Account:
    account = repo.get_account_for_user(session, id, user_id)
    if not account:
        raise AccountNotFound("couldnot find account")
    
    account.active = True
    restored_account = repo.save_account(session, account)
    session.commit()
    return restored_account
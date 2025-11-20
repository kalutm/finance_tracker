from typing import List, Tuple, Optional
from sqlmodel import Session
from sqlalchemy.exc import IntegrityError
from fastapi import Depends

from ..models.account import Account
from ..accounts.exceptions import (
    AccountError,
    AccountNameAlreadyTaken,
    AccountNotFound,
    UserNotAuthorizedForThisAccount,
    CouldnotDeleteAccount,
)
from ..accounts.repo import AccountRepository, get_account_repo


class AccountService:
    def __init__(self, repo: AccountRepository):
        self.repo = repo

    def get_user_accounts(self, session: Session, user_id, limit: int, offset: int, active: Optional[bool]) -> Tuple[List[Account], int]:
        return self.repo.list_user_accounts(session, user_id, limit, offset, active)

    def create_account(self, session: Session, user_id, name, type, currency) -> Account:
        account = Account(user_id=user_id, name=name, type=type, currency=currency)
        try:
            refreshed_account = self.repo.save_account(session, account)
            session.commit()
            return refreshed_account
        except IntegrityError:
            session.rollback()
            raise AccountNameAlreadyTaken("please use a different Account name")

    def get_account(self, session: Session, id, user_id) -> Account:
        account = self.repo.get_account_for_user(session, id, user_id)
        if not account:
            raise AccountNotFound("couldnot find account please create another one")
        return account

    def update_account(self, session: Session, id, update_data: dict, user_id) -> Account:
        account = self.repo.get_account_for_user(session, id, user_id)
        if not account:
            raise AccountNotFound("couldnot find account")
        try:
            for field, value in update_data.items():
                if value is not None:
                    setattr(account, field, value)
            updated_account = self.repo.save_account(session, account)
            session.commit()
            return updated_account
        except IntegrityError:
            session.rollback()
            raise AccountNameAlreadyTaken("please use a different Account name")

    def delete_account(self, session: Session, id, user_id):
        account = self.repo.get_account_for_user(session, id, user_id)
        if not account:
            raise AccountNotFound("couldnot find account")
        if self.repo.count_transactions_for_account(session, id) > 0:
            raise CouldnotDeleteAccount("Cannot hard-delete account with transactions. Consider deactivating.")
        self.repo.delete_account(session, account)
        session.commit()

    def deactivate_account(self, session: Session, id, user_id) -> Account:
        account = self.repo.get_account_for_user(session, id, user_id)
        if not account:
            raise AccountNotFound("couldnot find account")

        account.active = False
        deactivated_account = self.repo.save_account(session, account)
        session.commit()
        return deactivated_account

    def restore_account(self, session: Session, id, user_id) -> Account:
        account = self.repo.get_account_for_user(session, id, user_id)
        if not account:
            raise AccountNotFound("couldnot find account")

        account.active = True
        restored_account = self.repo.save_account(session, account)
        session.commit()
        return restored_account


# FastAPI provider
def get_account_service(repo: AccountRepository = Depends(get_account_repo)) -> AccountService:
    return AccountService(repo)

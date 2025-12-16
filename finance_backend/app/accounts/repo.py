from typing import List, Optional, Tuple
from sqlmodel import select, Session
from sqlalchemy import func
from ..models.account import Account
from ..models.transaction import Transaction


class AccountRepository:

    def get_accounts_by_user_id(self, session: Session, user_id) -> List[Account]:
        return session.exec(select(Account).where(Account.user_id == user_id)).all()

    def list_user_accounts(
        self, session: Session, user_id, limit: int, offset: int, active: Optional[bool]
    ) -> Tuple[List[Account], int]:
        if active is None:
            filters = [Account.user_id == user_id]
        else:
            filters = [Account.user_id == user_id, Account.active == active]

        total_stmt = select(func.count()).select_from(Account).where(*filters)
        total = session.exec(total_stmt).one()
        stmt = (
            select(Account)
            .where(*filters)
            .order_by(Account.created_at.desc())
            .limit(limit)
            .offset(offset)
        )
        results = session.exec(stmt).all()
        return results, int(total)

    def get_account_for_user(
        self, session: Session, account_id, user_id
    ) -> Optional[Account]:
        return session.exec(
            select(Account).where(Account.id == account_id, Account.user_id == user_id)
        ).first()

    def get_account_balances(self, session: Session, user_id):
        return session.exec(
            select(Account.id, Account.name, Account.balance).where(
                Account.user_id == user_id
            )
        ).all()

    def save_account(self, session: Session, account: Account) -> Account:
        session.add(account)
        session.flush()
        session.refresh(account)
        return account

    def get_account_by_id(self, session: Session, id) -> Optional[Account]:
        return session.exec(
            select(Account).where(Account.id == id).with_for_update()
        ).first()

    def delete_account(self, session: Session, account: Account):
        session.delete(account)
        session.flush()

    # helper
    def count_transactions_for_account(self, session: Session, account_id) -> int:
        count_stmt = (
            select(func.count())
            .select_from(Transaction)
            .where(Transaction.account_id == account_id)
        )
        return session.exec(count_stmt).one()


# FastApi dependency provider
def get_account_repo() -> AccountRepository:
    return AccountRepository()

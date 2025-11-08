from sqlmodel import Session
from app.transactions import repo
from app.models.transaction import Transaction
from typing import List
def get_user_transactions(session: Session, user_id, limit, offset, account_id, category_id, start, end) -> List[Transaction]:
    return repo.list_user_transactions(session, user_id, limit, offset, account_id, category_id, start, end)

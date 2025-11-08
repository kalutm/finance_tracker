from fastapi import APIRouter, Depends, Path, Query, HTTPException, status
from app.api.deps import get_current_user, get_session
from sqlmodel import Session
from app.transactions import service
from typing import Annotated, Optional
from datetime import datetime
from app.transactions.schemas import TransactionsOut, TransactionCreate, TransactionOut

router = APIRouter(prefix="/transactions", tags=["Transaction"])


@router.get("/", response_model=TransactionsOut)
def get_user_transactions(
    limit: int = Query(
        50, ge=1, le=500, title="limit", description="amount of result per page"
    ),
    offset: int = Query(
        0, ge=0, title="offset", description="position compared to 0th result"
    ),
    account_id: int = Query(
        title="account-id",
        description="filtering transaction's based on an account",
    ),
    category_id: int = Query(
        title="category-id", description="filtering transaction's based on a category"
    ),
    start: datetime = Query(
        title="start-date", description="starting date to filter the transaction's"
    ),
    end: datetime = Query(
        title="end-date", description="ending date to filter the transaction's"
    ),
    session: Session = Depends(get_session),
    current_user: service.User = Depends(get_current_user),
):
    transactions, total = service.get_user_transactions(
        session, current_user.id, limit, offset, account_id, category_id, start, end
    )

    transaction_outs = []
    for category in transactions:
        transaction_outs.append(TransactionsOut.model_validate(category))

    transaction_out = TransactionsOut(transactions=transaction_outs, total=total)
    return transaction_out

@router.post("/", response_model=TransactionOut, status_code=status.HTTP_201_CREATED)
def create_transaction(
        transaction_data: TransactionCreate,
        session: Session = Depends(get_session),
        current_user: service.User = Depends(get_current_user),
):
        transaction = service.create_account(
            session,
            current_user.id,
            transaction_data.model_dump(exclude_unset=True)
        )
        transaction_out = TransactionOut.model_validate(transaction)
        return transaction_out
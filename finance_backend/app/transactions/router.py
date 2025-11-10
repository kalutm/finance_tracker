from fastapi import APIRouter, Depends, Path, Query, HTTPException, status
from app.api.deps import get_current_user, get_session
from app.models.user import User
from sqlmodel import Session
from app.transactions.service import TransactionsService
from typing import Annotated, Optional
from datetime import datetime
from app.transactions.schemas import (
    TransactionsOut,
    TransactionCreate,
    TransactionOut,
    TransferTransactionCreate,
    TransactionPatch,
    TransferTransactionsOut,
)
from app.transactions.exceptions import (
    InsufficientBalance,
    TransactionNotFound,
    InvalidAmount,
    CanNotUpdateTransaction,
    TransactionError,
)

router = APIRouter(prefix="/transactions", tags=["Transaction"])


@router.get("/", response_model=TransactionsOut)
def get_user_transactions(
    limit: int = Query(
        50, ge=1, le=500, title="limit", description="amount of result per page"
    ),
    offset: int = Query(
        0, ge=0, title="offset", description="position compared to 0th result"
    ),
    account_id: Optional[int] = Query(
        None,
        title="account-id",
        description="filtering transaction's based on an account",
    ),
    category_id: Optional[int] = Query(
        None,
        title="category-id",
        description="filtering transaction's based on a category",
    ),
    start: Optional[datetime] = Query(
        None,
        title="start-date",
        description="starting date to filter the transaction's",
    ),
    end: Optional[datetime] = Query(
        None, title="end-date", description="ending date to filter the transaction's"
    ),
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_user),
):
    transaction_service = TransactionsService(session)
    transactions, total = transaction_service.get_user_transactions(
        current_user.id, limit, offset, account_id, category_id, start, end
    )

    transaction_outs = []
    for transaction in transactions:
        transaction_outs.append(TransactionOut.model_validate(transaction))

    transactions_out = TransactionsOut(transactions=transaction_outs, total=total)
    return transactions_out


@router.post("/", response_model=TransactionOut, status_code=status.HTTP_201_CREATED)
def create_transaction(
    transaction_data: TransactionCreate,
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_user),
):
    try:
        transaction_service = TransactionsService(session)

        transaction = transaction_service.create_income_expense_transaction(
            transaction_data.model_dump(exclude_unset=True),
            current_user.id,
        )
        transaction_out = TransactionOut.model_validate(transaction)

        return transaction_out
    except InsufficientBalance as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
    except InvalidAmount as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))


@router.post(
    "/transfer",
    response_model=TransferTransactionsOut,
    status_code=status.HTTP_201_CREATED,
)
def create_transaction(
    transaction_data: TransferTransactionCreate,
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_user),
):
    try:
        transaction_service = TransactionsService(session)

        txn_out, txn_in = transaction_service.create_transfer_transaction(
            transaction_data, current_user.id
        )
        
        transfer_transactions_out = TransferTransactionsOut(
            outgoing_transaction=TransactionOut.model_validate(txn_out),
            incoming_transaction=TransactionOut.model_validate(txn_in),
        )
        return transfer_transactions_out
    except InsufficientBalance as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
    except InvalidAmount as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))


@router.get("/{id}", response_model=TransactionOut)
def get_transaction(
    id: Annotated[
        int,
        Path(
            title="Transaction-id",
            description="The id of a Transaction",
            ge=1,
            examples=[1, 2, 3, 4, 5, 6, 7],
        ),
    ],
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_user),
):
    try:
        transaction_service = TransactionsService(session)
        transaction = transaction_service.get_transaction(id, current_user.id)
        return TransactionOut.model_validate(transaction)
    except TransactionNotFound as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))


@router.patch("/{id}", response_model=TransactionOut)
def update_transaction(
    transaction_data: TransactionPatch,
    id: Annotated[
        int,
        Path(
            title="Transaction-id",
            description="The id of a Transaction",
            ge=1,
            examples=[1, 2, 3, 4, 5, 6, 7],
        ),
    ],
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_user),
):
    try:
        transaction_service = TransactionsService(session)
        updated_transaction = transaction_service.update_transaction(
            transaction_data, id, current_user.id
        )

        return TransactionOut.model_validate(updated_transaction)
    except TransactionNotFound as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))
    except InvalidAmount as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
    except InsufficientBalance as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
    except CanNotUpdateTransaction as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))


@router.delete("/{id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_transaction(
    id: Annotated[
        int,
        Path(
            title="Transaction-id",
            description="The id of a Transaction",
            ge=1,
            examples=[1, 2, 3, 4, 5, 6, 7],
        ),
    ],
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_user),
):
    try:
        transaction_service = TransactionsService(session)
        transaction_service.delete_transaction(id, current_user.id)
    except TransactionNotFound as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))
    except TransactionError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))

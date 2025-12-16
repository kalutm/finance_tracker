from fastapi import APIRouter, Depends, Path, Query, HTTPException, status
from sqlmodel import Session
from app.api.deps import get_current_user, get_session
from app.models.user import User
from app.models.enums import TransactionType
from app.transactions.service import TransactionsService, get_transaction_service
from typing import Annotated, Optional, List
from uuid import UUID
from datetime import datetime
from app.transactions.schemas import (
    TransactionsOut,
    TransactionCreate,
    BulkTransactionCreate,
    TransactionOut,
    TransferTransactionCreate,
    TransactionPatch,
    TransferTransactionsOut,
    TransactionSummaryOut,
    TransactionStatsOut,
    TimeSeries,
    AccountBalancesOut
)
from app.transactions.exceptions import (
    InsufficientBalance,
    TransactionNotFound,
    InvalidAmount,
    CanNotUpdateTransaction,
    TransactionError,
    InvalidTransferTransaction,
)

router = APIRouter(prefix="/transactions", tags=["Transaction"])


@router.get("/", response_model=TransactionsOut)
def get_user_transactions(
    limit: int = Query(
        1000, ge=1, le=1000, title="limit", description="amount of result per page"
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
    type: Optional[TransactionType] = Query(
        None,
        title="Transaction Type",
        description="Type of the Transaction i.e INCOME, EXPENSE or Transfer",
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
    transaction_service: TransactionsService = Depends(get_transaction_service),
):
    transactions, total = transaction_service.get_user_transactions(
        session,
        current_user.id,
        limit,
        offset,
        account_id,
        category_id,
        type,
        start,
        end,
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
    transaction_service: TransactionsService = Depends(get_transaction_service),
):
    try:
        transaction = transaction_service.create_income_expense_transaction(
            session,
            transaction_data.model_dump(exclude_unset=True),
            current_user.id,
        )
        transaction_out = TransactionOut.model_validate(transaction)

        return transaction_out
    except InsufficientBalance as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={"code": "INSUFFICIENT_BALANCE", "message": str(e)},
        )
    except InvalidAmount as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={"code": "INVALID_AMOUNT", "message": str(e)},
        )


@router.post("/bulk", status_code=status.HTTP_201_CREATED)
def create_transactions_bulk(
    payload: BulkTransactionCreate,
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_user),
    transaction_service: TransactionsService = Depends(get_transaction_service),
):
    return transaction_service.create_transactions_bulk(
        session,
        payload.transactions,
        current_user.id,
    )


@router.post(
    "/transfer",
    response_model=TransferTransactionsOut,
    status_code=status.HTTP_201_CREATED,
)
def create_transaction(
    transaction_data: TransferTransactionCreate,
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_user),
    transaction_service: TransactionsService = Depends(get_transaction_service),
):
    try:
        txn_out, txn_in = transaction_service.create_transfer_transaction(
            session, transaction_data, current_user.id
        )

        transfer_transactions_out = TransferTransactionsOut(
            outgoing_transaction=TransactionOut.model_validate(txn_out),
            incoming_transaction=TransactionOut.model_validate(txn_in),
        )
        return transfer_transactions_out
    except InsufficientBalance as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={"code": "INSUFFICIENT_BALANCE", "message": str(e)},
        )
    except InvalidAmount as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={"code": "INVALID_AMOUNT", "message": str(e)},
        )


@router.get("/summary", response_model=TransactionSummaryOut)
def get_transaction_summary(
    month: str | None = Query(None, pattern=r"^\d{4}-\d{2}$"),
    date_from: datetime | None = None,
    date_to: datetime | None = None,
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_user),
    transaction_service: TransactionsService = Depends(get_transaction_service),
):
    return transaction_service.get_transaction_summary(
        session, month, date_from, date_to, current_user.id
    )


@router.get("/stats", response_model=List[TransactionStatsOut])
def get_transaction_stats(
    by: str = Query("category", enum=["category", "account", "type"]),
    date_from: datetime | None = None,
    date_to: datetime | None = None,
    limit: int = 10,
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_user),
    transaction_service: TransactionsService = Depends(get_transaction_service),
):
    return transaction_service.get_transaction_stats(
        session, by, date_from, date_to, limit, current_user.id
    )


@router.get("/timeseries", response_model=List[TimeSeries])
def get_timeseries(
    date_from: datetime,
    date_to: datetime,
    granularity: str = Query("day", enum=["day", "week", "month"]),
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_user),
    transaction_service: TransactionsService = Depends(get_transaction_service),
):
    return transaction_service.get_timeseries(
        session, granularity, date_from, date_to, current_user.id
    )


@router.get("/balances", response_model=AccountBalancesOut)
def get_account_balances(
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_user),
    transaction_service: TransactionsService = Depends(get_transaction_service),
):
    total, account_balances = transaction_service.get_account_balances(session, current_user.id)
    return AccountBalancesOut(total_balance=total, accounts=account_balances)


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
    transaction_service: TransactionsService = Depends(get_transaction_service),
):
    try:
        transaction = transaction_service.get_transaction(session, id, current_user.id)
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
    transaction_service: TransactionsService = Depends(get_transaction_service),
):
    try:
        updated_transaction = transaction_service.update_transaction(
            session, transaction_data, id, current_user.id
        )
        return TransactionOut.model_validate(updated_transaction)
    except TransactionNotFound as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))
    except InvalidAmount as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={"code": "INVALID_AMOUNT", "message": str(e)},
        )
    except InsufficientBalance as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={"code": "INSUFFICIENT_BALANCE", "message": str(e)},
        )
    except CanNotUpdateTransaction as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={"code": "CANNOT_UPDATE_TRANSACTION", "message": str(e)},
        )


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
    transaction_service: TransactionsService = Depends(get_transaction_service),
):
    try:
        transaction_service.delete_transaction(session, id, current_user.id)
    except TransactionNotFound as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))
    except InsufficientBalance as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={"code": "INSUFFICIENT_BALANCE", "message": str(e)},
        )


@router.delete("/transfer/{transfer_group_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_transfer_transaction(
    transfer_group_id: Annotated[
        UUID,
        Path(
            title="Transfer-group-id",
            description="The global id of Transfer Transaction's",
        ),
    ],
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_user),
    transaction_service: TransactionsService = Depends(get_transaction_service),
):
    try:
        transaction_service.delete_transfer_transaction(
            session, transfer_group_id, current_user.id
        )
    except InvalidTransferTransaction as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={"code": "INVALID_TRANSFER_TRANSACTION", "message": str(e)},
        )
    except InsufficientBalance as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={"code": "INSUFFICIENT_BALANCE", "message": str(e)},
        )

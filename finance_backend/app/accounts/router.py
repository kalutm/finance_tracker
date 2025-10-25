from fastapi import APIRouter, Depends, Path, Query, HTTPException, status
from ..db.session import Session, get_session
from ..accounts.schemas import AccountsOut, AccountOut, AccountCreate, AccountUpdate
from app.accounts import service
from app.api.deps import get_current_user
from typing import Annotated, Optional

router = APIRouter(
    prefix="/accounts", dependencies=[Depends(get_current_user)], tags=["account"]
)


@router.get("/", response_model=AccountsOut)
def get_user_accounts(
    limit = Annotated[
        int,
        Query(50, ge=1, le=500, title="limit", description="amount of result per page"),
    ],
    offset = Annotated[
        int,
        Query(0, ge=0, title="offset", description="position compared to 0th result"),
    ],
    active = Annotated[
        bool,
        Query(True, title="active", description="describes if the account is deleted or not (can be Undone)")
    ],
    current_user: service.User = Depends(get_current_user),
    session: Session = Depends(get_session),
):
    accounts, total = service.get_user_accounts(session, current_user.id, limit, offset, active)

    return AccountsOut(accounts=accounts, total=total)


@router.post("/", response_model=AccountOut, status_code=status.HTTP_201_CREATED)
def create_account(
    account_data: AccountCreate,
    current_user: service.User = Depends(get_current_user),
    session: Session = Depends(get_session),
):
    try:
        account = service.create_account(
            session,
            current_user.id,
            account_data.name,
            account_data.type,
            account_data.currency,
        )
        return AccountOut(
            id=account.id,
            name=account.name,
            type=account.type,
            currency=account.currency,
            balance=account.balance,
            active=account.active,
            created_at=account.created_at,
        )
    except service.AccountNameAlreadyTaken as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))


@router.get("/{id}", response_model=AccountOut)
def get_account(
    id: Annotated[
        int,
        Path(
            title="Account-id",
            description="The id of an account",
            ge=1,
            examples=[1, 2, 3, 4, 5, 6, 7],
        ),
    ],
    session: Session = Depends(get_session),
    current_user: service.User = Depends(get_current_user),
):
    try:
        account = service.get_account(session, id, current_user.id)
        return AccountOut(
            id=account.id,
            name=account.name,
            type=account.type,
            currency=account.currency,
            balance=account.balance,
            active=account.active,
            created_at=account.created_at,
        )
    except service.AccountNotFound as e:
        raise HTTPException(status_code=404, detail=str(e))


@router.patch("/{id}", response_model=AccountOut)
def update_account(
    id: Annotated[
        int,
        Path(
            title="Account-id",
            description="The id of an account",
            ge=1,
            examples=[1, 2, 3, 4, 5, 6, 7],
        ),
    ],
    account_data: AccountUpdate,
    session: Session = Depends(get_session),
    current_user: service.User = Depends(get_current_user),
):
    try:
        update_data = account_data.model_dump(exclude_unset=True)
        updated_account = service.update_account(
            session, id, update_data, current_user.id
        )
        return AccountOut(
            id=updated_account.id,
            name=updated_account.name,
            type=updated_account.type,
            currency=updated_account.currency,
            balance=updated_account.balance,
            active=updated_account.active,
            created_at=updated_account.created_at,
        )
    except service.AccountNotFound as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))
    except service.AccountNameAlreadyTaken as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))

@router.patch("/{id}/deactivate", response_model=AccountOut, status_code=status.HTTP_200_OK)
def deactivate_account(
    id: Annotated[
        int,
        Path(
            title="Account-id",
            description="The id of an account",
            ge=1,
            examples=[1, 2, 3, 4, 5, 6, 7],
        ),
    ],
    session: Session = Depends(get_session),
    current_user: service.User = Depends(get_current_user),
):
    try:
        deactivated_account = service.deactivate_account(session, id, current_user.id)
        return AccountOut(
            id=deactivated_account.id,
            name=deactivated_account.name,
            type=deactivated_account.type,
            currency=deactivated_account.currency,
            balance=deactivated_account.balance,
            active=deactivated_account.active,
            created_at=deactivated_account.created_at,
        )
    except service.AccountNotFound as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))

@router.delete("/{id}", response_model=None, status_code=status.HTTP_204_NO_CONTENT)
def delete_account(
    id: Annotated[
        int,
        Path(
            title="Account-id",
            description="The id of an account",
            ge=1,
            examples=[1, 2, 3, 4, 5, 6, 7],
        ),
    ],
    session: Session = Depends(get_session),
    current_user: service.User = Depends(get_current_user),
):
    try:
        service.delete_account(session, id, current_user.id)
    except service.AccountNotFound as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))


@router.patch("/{id}/restore", response_model=AccountOut)
def restore_account(
    id: Annotated[
        int,
        Path(
            title="Account-id",
            description="The id of an account",
            ge=1,
            examples=[1, 2, 3, 4, 5, 6, 7],
        ),
    ],
    session: Session = Depends(get_session),
    current_user: service.User = Depends(get_current_user),
):

    try:
        restored_account = service.restore_account(session, id, current_user.id)
        return AccountOut(
            id=restored_account.id,
            name=restored_account.name,
            type=restored_account.type,
            currency=restored_account.currency,
            balance=restored_account.balance,
            active=restored_account.active,
            created_at=restored_account.created_at,
        )
    except service.AccountNotFound as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))

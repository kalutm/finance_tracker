from fastapi import APIRouter, Depends, Path, Query, HTTPException, status
from ..db.session import Session, get_session
from ..accounts.schemas import AccountsOut, AccountOut, AccountCreate, AccountUpdate
from ..accounts.service import AccountService, get_account_service
from app.auth.dependencies import get_current_user
from typing import Annotated, Optional
from ..accounts.exceptions import (
    AccountNameAlreadyTaken,
    AccountNotFound,
    CouldnotDeleteAccount,
)
from ..models.user import User

router = APIRouter(prefix="/accounts", tags=["account"])


@router.get("/", response_model=AccountsOut)
def get_user_accounts(
    limit: int = Query(50, ge=1, le=500),
    offset: int = Query(0, ge=0),
    active: Optional[bool] = Query(None),
    current_user: User = Depends(get_current_user),
    session: Session = Depends(get_session),
    account_service: AccountService = Depends(get_account_service),
):
    accounts, total = account_service.get_user_accounts(
        session, current_user.id, limit, offset, active
    )
    return AccountsOut(
        accounts=[AccountOut.model_validate(acc) for acc in accounts], total=total
    )


@router.post("/", response_model=AccountOut, status_code=status.HTTP_201_CREATED)
def create_account(
    account_data: AccountCreate,
    current_user: User = Depends(get_current_user),
    session: Session = Depends(get_session),
    account_service: AccountService = Depends(get_account_service),
):
    try:
        account = account_service.create_account(
            session, current_user.id, **account_data.model_dump()
        )
        return AccountOut.model_validate(account)
    except AccountNameAlreadyTaken as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))


@router.get("/{id}", response_model=AccountOut)
def get_account(
    id: Annotated[int, Path(title="Account-id", ge=1)],
    current_user: User = Depends(get_current_user),
    session: Session = Depends(get_session),
    account_service: AccountService = Depends(get_account_service),
):
    try:
        account = account_service.get_account(session, id, current_user.id)
        return AccountOut.model_validate(account)
    except AccountNotFound as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))


@router.patch("/{id}", response_model=AccountOut)
def update_account(
    id: Annotated[int, Path(title="Account-id", ge=1)],
    account_data: AccountUpdate,
    current_user: User = Depends(get_current_user),
    session: Session = Depends(get_session),
    account_service: AccountService = Depends(get_account_service),
):
    try:
        update_data = account_data.model_dump(exclude_unset=True)
        updated_account = account_service.update_account(
            session, id, update_data, current_user.id
        )
        return AccountOut.model_validate(updated_account)
    except AccountNotFound as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))
    except AccountNameAlreadyTaken as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))


@router.patch("/{id}/deactivate", response_model=AccountOut)
def deactivate_account(
    id: Annotated[int, Path(title="Account-id", ge=1)],
    current_user: User = Depends(get_current_user),
    session: Session = Depends(get_session),
    account_service: AccountService = Depends(get_account_service),
):
    try:
        deactivated = account_service.deactivate_account(session, id, current_user.id)
        return AccountOut.model_validate(deactivated)
    except AccountNotFound as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))


@router.delete("/{id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_account(
    id: Annotated[int, Path(title="Account-id", ge=1)],
    current_user: User = Depends(get_current_user),
    session: Session = Depends(get_session),
    account_service: AccountService = Depends(get_account_service),
):
    try:
        account_service.delete_account(session, id, current_user.id)
    except AccountNotFound as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))
    except CouldnotDeleteAccount as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))


@router.patch("/{id}/restore", response_model=AccountOut)
def restore_account(
    id: Annotated[int, Path(title="Account-id", ge=1)],
    current_user: User = Depends(get_current_user),
    session: Session = Depends(get_session),
    account_service: AccountService = Depends(get_account_service),
):
    try:
        restored = account_service.restore_account(session, id, current_user.id)
        return AccountOut.model_validate(restored)
    except AccountNotFound as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))

from fastapi import APIRouter, Depends, Path, Query, HTTPException, status
from ..db.session import Session, get_session
from ..accounts.schemas import AccountsOut, AccountOut, AccountCreate, AccountUpdate
from app.accounts import service
from app.api.deps import get_current_user
from typing import Annotated, Optional

router = APIRouter(
    prefix="/accounts", tags=["account"]
)


@router.get("/", response_model=AccountsOut)
def get_user_accounts(
    limit: int = Query(
        50, ge=1, le=500, title="limit", description="amount of result per page"
    ),
    offset: int = Query(
        0, ge=0, title="offset", description="position compared to 0th result"
    ),
    active: Optional[bool] = Query(
        None,
        title="active",
        description="describes if the account is deleted or not (can be Undone)",
    ),
    current_user: service.User = Depends(get_current_user),
    session: Session = Depends(get_session),
):
    accounts, total = service.get_user_accounts(
        session, current_user.id, limit, offset, active
    )

    account_outs = []
    for account in accounts:
        account_outs.append(AccountOut.model_validate(account))

    return AccountsOut(accounts=account_outs, total=total)


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
            **account_data.model_dump()
        )
        account_out = AccountOut.model_validate(account)
        return account_out
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
        account_out = AccountOut.model_validate(account)
        return account_out
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
        account_out = AccountOut.model_validate(updated_account)
        return account_out
    except service.AccountNotFound as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))
    except service.AccountNameAlreadyTaken as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))


@router.patch(
    "/{id}/deactivate", response_model=AccountOut, status_code=status.HTTP_200_OK
)
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
        account_out = AccountOut.model_validate(deactivated_account)
        return account_out
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
    except service.CouldnotDeleteAccount as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))


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
        account_out = AccountOut.model_validate(restored_account)
        return account_out
    except service.AccountNotFound as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))

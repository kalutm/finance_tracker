from fastapi import APIRouter, Depends, Path
from ..db.session import Session, get_session
from ..accounts.schemas import Accounts, AccountCreate
from app.accounts import service
from app.api.deps import get_current_user
from typing import Annotated

router = APIRouter(
    prefix="/accounts", dependencies=[Depends(get_current_user)], tags=["account"]
)


@router.get("/allaccounts")
def get_all_accounts(session: Session = Depends(get_session)) -> Accounts:
    return Accounts(accounts=service.get_accounts(session))


@router.get("/")
def get_user_accounts(
    current_user: service.User = Depends(get_current_user),
    session: Session = Depends(get_session),
) -> Accounts:
    accounts = service.get_user_accounts(session, current_user.id)

    return Accounts(accounts=accounts)


@router.post("/")
def create_account(
    account_data: AccountCreate,
    current_user: service.User = Depends(get_current_user),
    session: Session = Depends(get_session),
) -> service.Account:
    account = service.create_account(
        session,
        current_user.id,
        account_data.name,
        account_data.type,
        account_data.currency,
    )
    return account


@router.get("/{id}")
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
) -> service.Account:
    account = service.get_account(session, id)
    return account


@router.put("/{id}")
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
    account_name: str,
    session: Session = Depends(get_session),
) -> service.Account:
    updated_account = service.update_account(session, id, account_name)
    return updated_account


@router.delete("/{id}")
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
):
    service.delete_account(session, id)

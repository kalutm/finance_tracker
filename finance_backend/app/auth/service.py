from datetime import timedelta, datetime

from jose import JWTError
from sqlalchemy.exc import IntegrityError
from sqlmodel import Session
from ..models.user import User
from ..models.enums import Provider
from ..auth.schemas import UserOut
from ..auth.exceptions import (
    UserAlreadyExists,
    UserNotFound,
    InvalidCredentials,
    AccountNotVerified,
    GoogleTokenInvalid,
    AccountExistsWithDifferentProvider,
    InvalidVerificationToken,
    AccountAlreadyVerified,
    RateLimitExceeded,
    InvalidAccessToken,
    InvalidRefreshToken,
)
from ..auth.utils import (
    create_tokens_for_user,
    hash_password,
    verify_password,
    validate_google_token,
)
from ..auth.jwt import create_access_token, verify_access_token, verify_refresh_token
from ..auth.repo import (
    get_local_user_by_email,
    get_user_by_email,
    get_google_user_by_provider_id,
    get_google_only_user_by_email,
    save_user,
    delete_user
)
from typing import Tuple


def register_user(
    session: Session, email: str, password: str, access_min: int, refresh_days: int
) -> Tuple[str, str]:
    email = email.strip().lower()
    existing_local = get_local_user_by_email(session, email)
    if existing_local:
        raise UserAlreadyExists(email)

    hashed = hash_password(password)

    existing_google = get_google_only_user_by_email(session, email)

    # Case 1 existing google user
    if existing_google:
        # upgrade google-only to local+google
        existing_google.password_hash = hashed
        existing_google.provider = Provider.LOCAL_GOOGLE
        try:
            session.commit()
            session.refresh(existing_google)
        except IntegrityError:
            session.rollback()
            raise
        return create_tokens_for_user(
            str(existing_google.id), existing_google.email, access_min, refresh_days
        )

    # Case 2 no existing google user -> create a new local user
    user = User(email=email, password_hash=hashed, provider=Provider.LOCAL)
    try:
        save_user(session, user)
    except IntegrityError:
        session.rollback()
        raise UserAlreadyExists(email)

    return create_tokens_for_user(str(user.id), user.email, access_min, refresh_days)


def login_local(
    session: Session, email: str, password: str, access_min: int, refresh_days: int
) -> tuple[str, str]:
    email = email.strip().lower()

    # check if user already registerd
    user = get_local_user_by_email(session, email)
    if not user:
        google_only = get_google_only_user_by_email(session, email)
        # if logged in with google before, suggest the user to do it again
        if google_only:
            raise InvalidCredentials("Use Google Sign-In for this account or register with the email")
        raise InvalidCredentials("Incorrect email or password")

    if not user.password_hash or not verify_password(password, user.password_hash):
        raise InvalidCredentials("Incorrect email or password")

    if not user.is_verified:
        raise AccountNotVerified()

    return create_tokens_for_user(str(user.id), user.email, access_min, refresh_days)


def login_google(
    session: Session,
    id_token: str,
    access_min: int,
    refresh_days: int,
    google_client_id,
) -> tuple[str, str]:

    info = validate_google_token(id_token, google_client_id)

    google_sub = info.get("sub")
    email = info.get("email", "").strip().lower()

    # Case 1: Existing Google user
    user = get_google_user_by_provider_id(session, google_sub)
    if user:
        return create_tokens_for_user(str(user.id), email, access_min, refresh_days)

    # Case 2: Existing local user → upgrade
    existing_local = get_local_user_by_email(session, email)

    if existing_local:
        if existing_local.provider == Provider.LOCAL:
            existing_local.provider = Provider.LOCAL_GOOGLE
            existing_local.provider_id = google_sub
            save_user(session, existing_local)
            return create_tokens_for_user(
                str(existing_local.id), existing_local.email, access_min, refresh_days
            )

        raise AccountExistsWithDifferentProvider()

    # Case 3: New Google user
    new_user = User(email=email, provider=Provider.GOOGLE, provider_id=google_sub)
    save_user(session, new_user)

    return create_tokens_for_user(
        str(new_user.id), new_user.email, access_min, refresh_days
    )


def verify_email(session: Session, token: str) -> str:
    try:
        payload = verify_access_token(jw_token=token)
    except JWTError:
        raise InvalidVerificationToken("Invalid or expired token")

    email = payload.get("sub")
    if not email:
        raise InvalidVerificationToken("Invalid verification token")

    user = get_user_by_email(session, email)
    if not user:
        raise UserNotFound()

    user.is_verified = True
    save_user(session, user)

    return "Email verified successfully"


def resend_email(session: Session, email: str, access_min: int, cooldown: int) -> str:
    user = get_user_by_email(session, email)
    if not user:
        raise UserNotFound()
    if user.is_verified:
        raise AccountAlreadyVerified()

    if user.last_verification_email:
        now = datetime.now()
        if now - user.last_verification_email < timedelta(seconds=cooldown):
            raise RateLimitExceeded()
    user.last_verification_email = datetime.now()
    save_user(session, user)

    return create_access_token({"sub": user.email}, timedelta(minutes=access_min))


def refresh(refresh_token: str, access_min: int):
    try:
        payload = verify_refresh_token(refresh_token)
    except JWTError:
        raise InvalidRefreshToken()

    user_id = payload.get("id") if payload else None
    if not user_id:
        raise InvalidRefreshToken()

    return create_access_token(payload, timedelta(minutes=access_min))

def get_current_user_info(user: User) -> UserOut:
    return UserOut(
        id=str(user.id),
        email=user.email,
        is_verified=user.is_verified,
        provider=user.provider.value,
    )

def delete_current_user(session: Session, user: User) -> str:
    delete_user(session, user)
    return "Your account has been deleted"
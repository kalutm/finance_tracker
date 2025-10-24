from datetime import timedelta
from fastapi import APIRouter, Depends, HTTPException, status, BackgroundTasks
from fastapi.security import OAuth2PasswordRequestForm
from ..db.session import Session, get_session
from ..auth import service
from ..auth.dependencies import get_current_user
from ..auth.emailer import send_verification_email
from ..auth.jwt import create_access_token
from ..auth.schemas import (
    UserCreate,
    LoginIn,
    GoogleLoginIn,
    EmailIn,
    TokenOut,
    AccessTokenOut,
    UserOut
)
from ..core.settings import settings


router = APIRouter(prefix="/auth", tags=["auth"])

ACCESS_TOKEN_EXPIRE_MINUTES = settings.ACCESS_TOKEN_EXPIRE_MINUTES
REFRESH_TOKEN_EXPIRE_DAYS = settings.REFRESH_TOKEN_EXPIRE_DAYS
GOOGLE_CLIENT_ID = settings.GOOGLE_SERVER_CLIENT_ID_WEB


@router.post("/register", response_model=TokenOut)
def register(
    user_data: UserCreate,
    background: BackgroundTasks,
    session: Session = Depends(get_session),
):
    try:
        access, refresh = service.register_user(
            session,
            user_data.email,
            user_data.password,
            ACCESS_TOKEN_EXPIRE_MINUTES,
            REFRESH_TOKEN_EXPIRE_DAYS,
        )
        verification_token = create_access_token(
            user_data={"sub": user_data.email},
            delta=timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES),
        )
        background.add_task(
            send_verification_email, user_data.email, verification_token
        )
        return TokenOut(acc_jwt=access, ref_jwt=refresh, token_type="bearer")
    except service.UserAlreadyExists as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/login_form")
def login_form(data: OAuth2PasswordRequestForm = Depends(), session: Session = Depends(get_session)):
    access, refresh = service.login_local(
        session,
        data.username,  # treat username as email
        data.password,
        ACCESS_TOKEN_EXPIRE_MINUTES,
        REFRESH_TOKEN_EXPIRE_DAYS,
    )
    return {"access_token": access, "token_type": "bearer"}



@router.post("/login", response_model=TokenOut)
def login_local(user_data: LoginIn, session: Session = Depends(get_session)):
    try:
        access, refresh = service.login_local(
            session,
            user_data.email,
            user_data.password,
            ACCESS_TOKEN_EXPIRE_MINUTES,
            REFRESH_TOKEN_EXPIRE_DAYS,
        )
        return TokenOut(acc_jwt=access, ref_jwt=refresh, token_type="bearer")
    except service.InvalidCredentials as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
    except service.AccountNotVerified:
        raise HTTPException(
            status_code=403,
            detail="Email not verified! please verify your email before you login",
        )


@router.post("/login/google", response_model=TokenOut)
def login_google(user_data: GoogleLoginIn, session: Session = Depends(get_session)):
    try:
        access, refresh = service.login_google(
            session,
            user_data.id_token,
            ACCESS_TOKEN_EXPIRE_MINUTES,
            REFRESH_TOKEN_EXPIRE_DAYS,
            GOOGLE_CLIENT_ID,
        )

        return TokenOut(acc_jwt=access, ref_jwt=refresh, token_type="bearer")
    except service.GoogleTokenInvalid as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
    except service.AccountExistsWithDifferentProvider:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Account email already exists with different provider. Contact support.",
        )


@router.get("/verify")
def verify_email(token: str, session: Session = Depends(get_session)):
    try:
        message = service.verify_email(session, token)
        return {"message": message}
    except service.InvalidVerificationToken as e:
        raise HTTPException(status_code=400, detail=str(e))
    except service.UserNotFound:
        raise HTTPException(
            status_code=404, detail="User not found! please register before you verify"
        )


@router.post("/resend-verification")
def resend_verification(
    email_in: EmailIn,
    background: BackgroundTasks,
    session: Session = Depends(get_session),
):
    try:
        token = service.resend_email(
            session,
            email_in.email,
            ACCESS_TOKEN_EXPIRE_MINUTES,
            settings.COOLDOWN_VERIFICATION_EMAIL_SECONDS,
        )
        background.add_task(send_verification_email, email_in.email, token)
        return {"message": "Verification email resent"}

    except service.AccountAlreadyVerified:
        raise HTTPException(status_code=400, detail="User has already been verified")
    except service.RateLimitExceeded:
        raise HTTPException(
            status_code=400, detail="Please wait before resending again"
        )
    except service.UserNotFound:
        raise HTTPException(
            status_code=404, detail="User not found! please register before you verify"
        )


@router.post("/refresh")
def refresh_token(refresh_token: str) -> AccessTokenOut:
    try:
        new_access_token = service.refresh(refresh_token, ACCESS_TOKEN_EXPIRE_MINUTES)
        return AccessTokenOut(acc_jwt=new_access_token, token_type="bearer")
    except service.InvalidRefreshToken:
        raise HTTPException(status_code=401, detail="Invalid refresh token")


# protected routes
@router.get("/me")
def get_me(user: service.User = Depends(get_current_user)) -> UserOut:
    return service.get_current_user_info(user)


@router.delete("/me")
def delete_my_account(
    current_user: service.User = Depends(get_current_user),
    session: Session = Depends(get_session),
):
    message = service.delete_current_user(session, current_user)
    return {"detail": message}


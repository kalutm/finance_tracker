import requests
from fastapi import APIRouter, HTTPException, Depends, status
from ...models.user import Users
from sqlmodel import Session, select
from sqlalchemy import or_
from sqlalchemy.exc import IntegrityError
from ...db.session import get_session
from ...auth.jwt import create_access_token, verify_access_token, create_refresh_token, verify_refresh_token
from ...auth.verification import send_verification_email
from ...auth.dependencies import get_current_user
from ...models.validation_models import TokenOut, UserOut, AccessTokenOut, UserCreate, LoginIn, GoogleLoginIn, EmailIn
from ...models.enums import Provider
from ...auth.security import hash_password, verify_password
from jose import JWTError
from datetime import timedelta, datetime
import os
from dotenv import load_dotenv

load_dotenv()


ACCESS_TOKEN_EXPIRE_TIME_MIN = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES"))
REFRESH_TOKEN_EXPIRE_DAYS = int(os.getenv("REFRESH_TOKEN_EXPIRE_DAYS"))
GOOGLE_CLIENT_ID = os.getenv("GOOGLE_SERVER_CLIENT_ID_WEB")

router = APIRouter()


@router.post("/register")
async def register(user_data: UserCreate, session: Session = Depends(get_session)) -> TokenOut:
    email = user_data.email.strip().lower()

    existing_local = session.exec(
        select(Users).where(
            Users.email == email,
            or_(Users.provider == Provider.LOCAL, Users.provider == Provider.LOCAL_GOOGLE)
        )
    ).first()
    if existing_local:
        raise HTTPException(status_code=400, detail="This email is already registered")

    hashed = hash_password(user_data.password)

    existing_google = session.exec(
        select(Users).where(
            Users.email == email,
            Users.provider == Provider.GOOGLE
        )
    ).first()

    if existing_google:
        existing_google.password_hash = hashed
        existing_google.provider = Provider.LOCAL_GOOGLE
        try:
            session.commit()
            session.refresh(existing_google)
        except IntegrityError:
            session.rollback()
            raise HTTPException(status_code=500, detail="Could not upgrade account, try again")
        
        user_email = existing_google.email
        user_info = {"id": str(existing_google.id), "email": user_email}
        jw_token = create_access_token(user_info, timedelta(minutes=ACCESS_TOKEN_EXPIRE_TIME_MIN))
        refr_jwt = create_refresh_token(user_info, timedelta(days=REFRESH_TOKEN_EXPIRE_DAYS))
        ver_jwt = create_access_token(user_data={"sub": user_email}, delta=timedelta(minutes=ACCESS_TOKEN_EXPIRE_TIME_MIN))

        await send_verification_email(email=user_email, token=ver_jwt)
        return TokenOut(acc_jwt=jw_token, ref_jwt=refr_jwt, token_type="bearer")

    new_user = Users(email=email, password_hash=hashed, provider=Provider.LOCAL)
    session.add(new_user)
    try:
        session.commit()
        session.refresh(new_user)
    except IntegrityError:
        session.rollback()
        raise HTTPException(status_code=400, detail="Email already registered")
    
    new_user_email = new_user.email
    new_user_info = {"id": str(new_user.id), "email": new_user.email}
    jw_token = create_access_token(new_user_info, timedelta(minutes=ACCESS_TOKEN_EXPIRE_TIME_MIN))
    refre_token = create_refresh_token(new_user_info, timedelta(days=REFRESH_TOKEN_EXPIRE_DAYS))
    ver_token = create_access_token(user_data={"sub": new_user_email}, delta=timedelta(minutes=ACCESS_TOKEN_EXPIRE_TIME_MIN))

    await send_verification_email(email=new_user_email, token=ver_token)
    return TokenOut(acc_jwt=jw_token,ref_jwt=refre_token, token_type="bearer")


@router.post("/login")
def login_local(user_data: LoginIn, session: Session = Depends(get_session)) -> TokenOut:
    email = user_data.email.strip().lower()

    user = session.exec(
        select(Users).where(
            Users.email == email,
            or_(
                Users.provider == Provider.LOCAL,
                Users.provider == Provider.LOCAL_GOOGLE
            )
        )
    ).first()

    if not user:
        google_only = session.exec(
            select(Users).where(
                Users.email == email,
                Users.provider == Provider.GOOGLE
            )
        ).first()
        if google_only:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Account exists and is Google-only. Use Google Sign-In."
            )
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Incorrect email or password")

    if not user.password_hash or not verify_password(user_data.password, user.password_hash):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Incorrect email or password")
    
    if not user.is_verified:
        raise HTTPException(status_code=403, detail="Email not verified. Please verify before you log in")

    user_info = {"id": str(user.id), "email": user.email}
    token = create_access_token(user_info, timedelta(minutes=ACCESS_TOKEN_EXPIRE_TIME_MIN))
    ref_token = create_refresh_token(user_info, timedelta(days=REFRESH_TOKEN_EXPIRE_DAYS))
    return TokenOut(acc_jwt=token, ref_jwt=ref_token, token_type="bearer")


@router.post("/login/google")
def login_google(user_data: GoogleLoginIn, session: Session = Depends(get_session))-> TokenOut:

    resp = requests.get(f"https://oauth2.googleapis.com/tokeninfo?id_token={user_data.id_token}")
    if resp.status_code != 200:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid Google token")
    info = resp.json()

    if info.get("aud") != GOOGLE_CLIENT_ID:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Token audience mismatch")

    google_sub = info.get("sub")
    email = info.get("email", "").strip().lower()

    user = session.exec(select(Users).where(Users.provider_id == google_sub)).first()
    if user:
        user_info = {"id": str(user.id), "email": user.email}
        token = create_access_token(user_info, timedelta(minutes=ACCESS_TOKEN_EXPIRE_TIME_MIN))
        refresh = create_refresh_token(user_info, timedelta(days=REFRESH_TOKEN_EXPIRE_DAYS))
        return TokenOut(acc_jwt=token, ref_jwt=refresh, token_type="bearer")

    existing_local = session.exec(
        select(Users).where(Users.email == email)
    ).first()

    if existing_local:
        if existing_local.provider == Provider.LOCAL:
            existing_local.provider = Provider.LOCAL_GOOGLE
            existing_local.provider_id = google_sub
            session.commit()
            session.refresh(existing_local)

            user_info = {"id": str(existing_local.id), "email": existing_local.email}
            token = create_access_token(user_info, timedelta(minutes=ACCESS_TOKEN_EXPIRE_TIME_MIN))
            refresh = create_refresh_token(user_info, timedelta(days=REFRESH_TOKEN_EXPIRE_DAYS))
            return TokenOut(acc_jwt=token, ref_jwt=refresh, token_type="bearer")

        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST,
                            detail="Account email already exists with different provider. Contact support.")

    new_user = Users(email=email, provider=Provider.GOOGLE, provider_id=google_sub)
    session.add(new_user)
    session.commit()
    session.refresh(new_user)

    user_info = {"id": str(new_user.id), "email": new_user.email}
    token = create_access_token(user_info, timedelta(minutes=ACCESS_TOKEN_EXPIRE_TIME_MIN))
    refresh = create_refresh_token(user_info, timedelta(days=REFRESH_TOKEN_EXPIRE_DAYS))
    return TokenOut(acc_jwt=token, ref_jwt=refresh, token_type="bearer")

@router.get("/verify")
async def verify_email(token: str, session: Session = Depends(get_session)):
    try:
        payload = verify_access_token(jw_token=token)
        if payload is None:
            raise HTTPException(status_code=401, detail="Invalid token")
        email: str = payload.get("sub")
        if email is None:
            raise HTTPException(status_code=400, detail="Invalid token")
        
        user = session.exec(select(Users).where(Users.email == email)).first()
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        user.is_verified = True
        session.commit()
        return {"message": "Email verified successfully! Please return to the app and login"}
    except JWTError:
        raise HTTPException(status_code=400, detail="Invalid or expired token")
    
@router.post("/resend-verification")
async def resend_verification(email_in: EmailIn, session: Session = Depends(get_session)):
    user = session.exec(select(Users).where(Users.email == email_in.email)).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found! please register before you verify")
    if user.is_verified:
        raise HTTPException(status_code=400, detail="User has already been verified")

    if user.last_verification_email:
        cooldown = timedelta(seconds=60)
        now = datetime.now()
        if now - user.last_verification_email < cooldown:
            raise HTTPException(status_code=429, detail="Please wait before resending again")

    token = create_access_token({"sub": user.email}, timedelta(minutes=ACCESS_TOKEN_EXPIRE_TIME_MIN))

    await send_verification_email(user.email, token)

    user.last_verification_email = datetime.now()
    session.commit()

    return {"message": "Verification email resent"}

@router.post("/refresh")
def refresh_token(refresh_token: str) -> AccessTokenOut:
    try:
        payload = verify_refresh_token(refresh_token)
        if payload is None:
            raise HTTPException(status_code=401, detail="Invalid refresh token")
        user_id: str = payload.get("id")
        if user_id is None:
            raise HTTPException(status_code=401, detail="Invalid refresh token")
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid refresh token")

    new_access_token = create_access_token(payload, timedelta(minutes=15))
    return AccessTokenOut(acc_jwt=new_access_token, token_type="bearer")

# protected routes
@router.get("/me")
def get_me(user: Users = Depends(get_current_user)) -> UserOut:
    return UserOut(id=str(user.id), email=user.email, is_verified=user.is_verified, provider=user.provider.value)

@router.delete("/me")
async def delete_my_account(current_user: Users = Depends(get_current_user), session: Session = Depends(get_session)):
    session.delete(current_user)
    session.commit()
    return {"detail": "Your account has been deleted"}
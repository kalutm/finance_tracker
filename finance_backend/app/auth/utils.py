from datetime import timedelta

import requests
from ..auth.jwt import create_access_token, create_refresh_token
from passlib.context import CryptContext
from typing import Dict
from ..auth.exceptions import GoogleTokenInvalid

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def hash_password(password: str) -> str:
    return pwd_context.hash(password)

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)

ACCESS_MIN = 15  # defaults (or import from settings)

def create_tokens_for_user(user_id: str, email: str, access_minutes: int, refresh_days: int) -> tuple[str, str]:
    payload = {"id": user_id, "email": email}
    access = create_access_token(payload, timedelta(minutes=access_minutes))
    refresh = create_refresh_token(payload, timedelta(days=refresh_days))
    return access, refresh

def validate_google_token(id_token: str, google_client_id: str) -> Dict:
    resp = requests.get(f"https://oauth2.googleapis.com/tokeninfo?id_token={id_token}")

    if resp.status_code != 200:
        raise GoogleTokenInvalid("Invalid Google token")

    info = resp.json()

    if info.get("aud") != google_client_id:
        raise GoogleTokenInvalid("Token audience mismatch")

    return info
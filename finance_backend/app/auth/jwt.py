import jwt
from datetime import datetime, timedelta
from typing import Dict
from app.core.settings import settings

SECRET_KEY = settings.SECRET_KEY
REFRESH_SECRET_KEY = settings.REFRESH_SECRET_KEY
ALGORITHM = settings.ALGORITHM

def create_access_token(user_data: dict, delta: timedelta) -> str:
    encode = user_data.copy()
    expire_date = datetime.now() + delta
    encode.update({"exp": expire_date})
    jw_token = jwt.encode(payload=encode, key=SECRET_KEY, algorithm=ALGORITHM)
    return jw_token

def create_refresh_token(user_data: dict, delta: timedelta) -> str:
    encode = user_data.copy()
    expire_date = datetime.now() + delta
    encode.update({"exp": expire_date})
    ref_jwt = jwt.encode(payload=encode, key=REFRESH_SECRET_KEY, algorithm=ALGORITHM)
    return ref_jwt

def verify_access_token(jw_token: str) -> Dict:
    try:
        payload = jwt.decode(jwt=jw_token, key=SECRET_KEY, algorithms=[ALGORITHM])
        return payload
    except jwt.ExpiredSignatureError:
        return None
    except jwt.InvalidTokenError:
        return None

def verify_refresh_token(ref_jwt: str) -> Dict:
    try:
        payload = jwt.decode(jwt=ref_jwt, key=REFRESH_SECRET_KEY, algorithms=[ALGORITHM])
        return payload
    except jwt.ExpiredSignatureError:
        return None
    except jwt.InvalidTokenError:
        return None
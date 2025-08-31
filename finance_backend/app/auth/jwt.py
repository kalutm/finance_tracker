import jwt, os
from dotenv import load_dotenv
from datetime import datetime, timedelta

load_dotenv()

SECRET_KEY = os.getenv("SECRET_KEY")
REFRESH_SECRET_KEY = os.getenv("REFRESH_SECRET_KEY")
ALGORITHM = os.getenv("ALGORITHM")

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

def verify_access_token(jw_token: str):
    try:
        payload = jwt.decode(jwt=jw_token, key=SECRET_KEY, algorithms=[ALGORITHM])
        return payload
    except jwt.ExpiredSignatureError:
        return None
    except jwt.InvalidTokenError:
        return None

def verify_refresh_token(ref_jwt: str):
    try:
        payload = jwt.decode(jwt=ref_jwt, key=REFRESH_SECRET_KEY, algorithms=[ALGORITHM])
        return payload
    except jwt.ExpiredSignatureError:
        return None
    except jwt.InvalidTokenError:
        return None
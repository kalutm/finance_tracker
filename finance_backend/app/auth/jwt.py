import jwt, os
from dotenv import load_dotenv
from datetime import datetime, timedelta

load_dotenv()

SECRET_KEY = os.getenv("SECRET_KEY")
ALGORITHM = os.getenv("ALGORITHM")

def create_access_token(user_data: dict, delta: timedelta) -> str:
    encode = user_data.copy()
    expire_date = datetime.now() + delta
    encode.update({"exp": expire_date})
    jw_token = jwt.encode(payload=encode, key=SECRET_KEY, algorithm=ALGORITHM)
    return jw_token

def verify_access_token(jw_token: str):
    try:
        payload = jwt.decode(jwt=jw_token, key=SECRET_KEY, algorithms=[ALGORITHM])
        return payload
    except jwt.ExpiredSignatureError:
        return None
    except jwt.InvalidTokenError:
        return None


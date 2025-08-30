from fastapi import Depends, HTTPException
from fastapi.security import OAuth2PasswordBearer
from auth.jwt import verify_access_token

oauth2shceme = OAuth2PasswordBearer(tokenUrl="/login")

def get_current_user(token: str = Depends(oauth2shceme)):
    payload = verify_access_token(token)
    if payload is None:
        return HTTPException(status_code=401, detail="Invalid or expired token")
    return payload

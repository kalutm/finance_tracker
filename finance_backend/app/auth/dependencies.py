from fastapi import Depends, HTTPException
from fastapi.security import OAuth2PasswordBearer
from app.auth.jwt import verify_access_token
from app.db.session import get_session, Session
from sqlmodel import select
from app.models.user import User

oauth2shceme = OAuth2PasswordBearer(tokenUrl="/v1/auth/login_form")

def get_current_user(
    session: Session = Depends(get_session),
    token: str = Depends(oauth2shceme),
) -> User:
    payload = verify_access_token(token)
    if not payload or "id" not in payload:
        raise HTTPException(status_code=401, detail="Invalid or expired token")

    current_user = session.exec(select(User).where(User.id == payload.get("id"))).first()
    if not current_user:
        raise HTTPException(status_code=404, detail="User not found")
    return current_user

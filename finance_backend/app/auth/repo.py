from sqlmodel import select, Session
from sqlalchemy import or_
from ..models.user import Users
from ..models.enums import Provider

def get_user_by_email(session: Session, email: str) -> Users | None:
    return session.exec(select(Users).where(Users.email == email)).first()

def get_local_user_by_email(session: Session, email: str) -> Users | None:
    return session.exec(
        select(Users).where(
            Users.email == email,
            or_(Users.provider == Provider.LOCAL, Users.provider == Provider.LOCAL_GOOGLE)
        )
    ).first()

def get_google_user_by_provider_id(session: Session, provider_id: str) -> Users | None:
    return session.exec(select(Users).where(Users.provider_id == provider_id)).first()

def get_google_only_user_by_email(session: Session, email: str) -> Users | None:
    return session.exec(
        select(Users).where(
            Users.email == email,
            Users.provider == Provider.GOOGLE
        )
    ).first()
    
def get_user_by_id(session: Session, user_id: str) -> Users | None:
    return session.exec(select(Users).where(Users.id == user_id)).first()

def save_user(session: Session, user: Users):
    session.add(user)
    session.commit()
    session.refresh(user)
    return user

def delete_user(session: Session, user: Users):
    session.delete(user)
    session.commit()

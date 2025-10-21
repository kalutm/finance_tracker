from sqlmodel import select, Session
from sqlalchemy import or_
from ..models.user import User
from ..models.enums import Provider


def get_user_by_email(session: Session, email: str) -> User | None:
    return session.exec(select(User).where(User.email == email)).first()


def get_local_user_by_email(session: Session, email: str) -> User | None:
    return session.exec(
        select(User).where(
            User.email == email,
            or_(
                User.provider == Provider.LOCAL, User.provider == Provider.LOCAL_GOOGLE
            ),
        )
    ).first()


def get_google_user_by_provider_id(session: Session, provider_id: str) -> User | None:
    return session.exec(
        select(User).where(
            User.provider_id == provider_id,
            or_(
                User.provider == Provider.GOOGLE, User.provider == Provider.LOCAL_GOOGLE
            ),
        )
    ).first()


def get_google_only_user_by_email(session: Session, email: str) -> User | None:
    return session.exec(
        select(User).where(User.email == email, User.provider == Provider.GOOGLE)
    ).first()


def get_user_by_id(session: Session, user_id: str) -> User | None:
    return session.exec(select(User).where(User.id == user_id)).first()


def save_user(session: Session, user: User):
    session.add(user)
    session.commit()
    session.refresh(user)
    return user


def delete_user(session: Session, user: User):
    session.delete(user)
    session.commit()

import pytest
from sqlmodel import Session
from app.tests.conftest import override_get_session, db_session, create_test_database
from app.auth import repo, service
from app.models.user import User
from app.auth.exceptions import (
    UserAlreadyExists, InvalidCredentials, AccountNotVerified, InvalidVerificationToken
)


def test_register_user_creates_new_local_user(monkeypatch, db_session: Session):
    """Should create new user and return tokens."""
    # mock dependencies
    monkeypatch.setattr(repo, "get_local_user_by_email", lambda s, e: None)
    monkeypatch.setattr(repo, "get_google_only_user_by_email", lambda s, e: None)
    monkeypatch.setattr(service, "hash_password", lambda pw: "hashed_pw")
    monkeypatch.setattr(repo, "save_user", lambda s, u: None)
    monkeypatch.setattr(service, "create_tokens_for_user", lambda uid, em, a, r: ("acc", "ref"))

    acc, ref = service.register_user(db_session, "user@example.com", "pw", 15, 30)

    assert acc == "acc"
    assert ref == "ref"


def test_register_user_raises_if_user_exists(monkeypatch, db_session: Session):
    
    monkeypatch.setattr(repo, "get_local_user_by_email", lambda s, e: User(id=1, email=e))
    with pytest.raises(UserAlreadyExists):
        service.register_user(db_session, "exists@example.com", "pw", 15, 30)



def test_login_local_success(monkeypatch, db_session: Session):
    fake_user = User(id=1, email="x@test.com", password_hash="hashed", is_verified=True)
    monkeypatch.setattr(repo, "get_local_user_by_email", lambda s, e: fake_user)
    monkeypatch.setattr(service, "verify_password", lambda p, h: True)
    monkeypatch.setattr(service, "create_tokens_for_user", lambda *a, **kw: ("a", "r"))

    acc, ref = service.login_local(db_session, "x@test.com", "pw", 15, 30)
    assert acc == "a" and ref == "r"


def test_login_local_invalid_password(monkeypatch, db_session: Session):
    fake_user = User(id=1, email="x@test.com", password_hash="hashed", is_verified=True)
    monkeypatch.setattr(repo, "get_local_user_by_email", lambda s, e: fake_user)
    monkeypatch.setattr(service, "verify_password", lambda p, h: False)

    with pytest.raises(InvalidCredentials):
        service.login_local(db_session, "x@test.com", "wrong", 15, 30)


def test_login_local_unverified_account(monkeypatch, db_session: Session):
    fake_user = User(id=1, email="x@test.com", password_hash="h", is_verified=False)
    monkeypatch.setattr(repo, "get_local_user_by_email", lambda s, e: fake_user)
    monkeypatch.setattr(service, "verify_password", lambda p, h: True)

    with pytest.raises(AccountNotVerified):
        service.login_local(db_session, "x@test.com", "pw", 15, 30)


def test_verify_email_success(monkeypatch, db_session: Session):
    fake_user = User(id=1, email="u@test.com", is_verified=False)

    monkeypatch.setattr(service, "verify_access_token", lambda jw_token: {"sub": "u@test.com"})
    monkeypatch.setattr(repo, "get_user_by_email", lambda s, e: fake_user)
    monkeypatch.setattr(repo, "save_user", lambda s, u: setattr(u, "is_verified", True))

    msg = service.verify_email(db_session, "fake_token")
    assert msg == "Email verified successfully"
    assert fake_user.is_verified is True


def test_verify_email_invalid_token(monkeypatch, db_session: Session):
    from jose import JWTError
    monkeypatch.setattr(service, "verify_access_token", lambda jw_token: (_ for _ in ()).throw(JWTError()))
    with pytest.raises(InvalidVerificationToken):
        service.verify_email(db_session, "bad_token")

import pytest
from types import SimpleNamespace
from datetime import datetime, timedelta
from jose import JWTError

from app.auth import service as service_module
from app.auth.service import UserService
from app.models.user import User
from app.auth.exceptions import (
    UserAlreadyExists,
    UserNotFound,
    InvalidCredentials,
    AccountNotVerified,
    InvalidVerificationToken,
    AccountAlreadyVerified,
    RateLimitExceeded,
    InvalidRefreshToken,
)

# Fake Repo class to help instanciating mock repo objects
class FakeRepo:
    def __init__(self, **fns):
        self._fns = fns

    def get_local_user_by_email(self, session, email):
        fn = self._fns.get("get_local_user_by_email")
        return fn(session, email) if fn else None

    def get_google_only_user_by_email(self, session, email):
        fn = self._fns.get("get_google_only_user_by_email")
        return fn(session, email) if fn else None

    def get_user_by_email(self, session, email):
        fn = self._fns.get("get_user_by_email")
        return fn(session, email) if fn else None

    def get_google_user_by_provider_id(self, session, pid):
        fn = self._fns.get("get_google_user_by_provider_id")
        return fn(session, pid) if fn else None

    def save_user(self, session, user):
        fn = self._fns.get("save_user")
        return fn(session, user) if fn else None

    def delete_user(self, session, user):
        fn = self._fns.get("delete_user")
        return fn(session, user) if fn else None


def test_register_user_success(monkeypatch):
    fake_repo = FakeRepo(
        get_local_user_by_email=lambda s, e: None,
        get_google_only_user_by_email=lambda s, e: None,
        save_user=lambda s, u: None,
    )

    monkeypatch.setattr(service_module, "hash_password", lambda pw: "hashed_pw")
    monkeypatch.setattr(service_module, "create_tokens_for_user", lambda uid, em, a, r: ("acc", "ref"))

    svc = UserService(fake_repo)
    acc, ref = svc.register_user(None, "user@example.com", "pw", 15, 30)

    assert acc == "acc"
    assert ref == "ref"


def test_register_user_user_already_exists():
    fake_repo = FakeRepo(get_local_user_by_email=lambda s, e: User(id=1, email=e))
    svc = UserService(fake_repo)

    with pytest.raises(UserAlreadyExists):
        svc.register_user(None, "exists@example.com", "pw", 15, 30)


def test_login_local_success(monkeypatch):
    fake_user = User(id=1, email="x@test.com", password_hash="hashed", is_verified=True)
    fake_repo = FakeRepo(get_local_user_by_email=lambda s, e: fake_user)

    monkeypatch.setattr(service_module, "verify_password", lambda p, h: True)
    monkeypatch.setattr(service_module, "create_tokens_for_user", lambda *a, **kw: ("a", "r"))

    svc = UserService(fake_repo)
    acc, ref = svc.login_local(None, "x@test.com", "pw", 15, 30)

    assert acc == "a"
    assert ref == "r"


def test_login_local_invalid_password(monkeypatch):
    fake_user = User(id=1, email="x@test.com", password_hash="hashed", is_verified=True)
    fake_repo = FakeRepo(get_local_user_by_email=lambda s, e: fake_user)

    monkeypatch.setattr(service_module, "verify_password", lambda p, h: False)

    svc = UserService(fake_repo)
    with pytest.raises(InvalidCredentials):
        svc.login_local(None, "x@test.com", "wrong", 15, 30)


def test_login_local_unverified_account(monkeypatch):
    fake_user = User(id=1, email="x@test.com", password_hash="h", is_verified=False)
    fake_repo = FakeRepo(get_local_user_by_email=lambda s, e: fake_user)

    monkeypatch.setattr(service_module, "verify_password", lambda p, h: True)

    svc = UserService(fake_repo)
    with pytest.raises(AccountNotVerified):
        svc.login_local(None, "x@test.com", "pw", 15, 30)


def test_verify_email_success(monkeypatch):
    fake_user = User(id=1, email="u@test.com", is_verified=False)

    fake_repo = FakeRepo(
        get_user_by_email=lambda s, e: fake_user,
        save_user=lambda s, u: setattr(u, "is_verified", True),
    )

    monkeypatch.setattr(service_module, "verify_access_token", lambda jw_token: {"sub": "u@test.com"})

    svc = UserService(fake_repo)
    msg = svc.verify_email(None, "fake_token")

    assert msg == "Email verified successfully"
    assert fake_user.is_verified is True


def test_verify_email_invalid_token(monkeypatch):
    fake_repo = FakeRepo()
    # cause verify_access_token to raise JWTError
    monkeypatch.setattr(service_module, "verify_access_token", lambda jw_token: (_ for _ in ()).throw(JWTError()))

    svc = UserService(fake_repo)
    with pytest.raises(InvalidVerificationToken):
        svc.verify_email(None, "bad_token")


def test_resend_email_success(monkeypatch):
    fake_user = User(id=1, email="u@test.com", is_verified=False)
    now = datetime.now()

    def _save(session, u):
        # emulate saving by setting last_verification_email to now
        setattr(u, "last_verification_email", now)
        return u

    fake_repo = FakeRepo(get_user_by_email=lambda s, e: fake_user, save_user=_save)
    monkeypatch.setattr(service_module, "create_access_token", lambda u, d: "acc")

    svc = UserService(fake_repo)
    token = svc.resend_email(None, "u@test.com", 15, 1)

    assert token == "acc"
    assert fake_user.last_verification_email == now


def test_resend_email_user_not_found():
    fake_repo = FakeRepo(get_user_by_email=lambda s, e: None)
    svc = UserService(fake_repo)
    with pytest.raises(UserNotFound):
        svc.resend_email(None, "notfound@email.com", 15, 1)


def test_resend_email_account_already_verified():
    fake_user = User(id=1, email="already@email.com", is_verified=True)
    fake_repo = FakeRepo(get_user_by_email=lambda s, e: fake_user)
    svc = UserService(fake_repo)
    with pytest.raises(AccountAlreadyVerified):
        svc.resend_email(None, "already@email.com", 15, 1)


def test_resend_email_rate_limit_exceeded():
    # set last_verification_email to now so cooldown check fails for cooldown>=1
    fake_user = User(id=1, email="ratelimit@email.com", is_verified=False)
    fake_user.last_verification_email = datetime.now()
    fake_repo = FakeRepo(get_user_by_email=lambda s, e: fake_user)
    svc = UserService(fake_repo)

    with pytest.raises(RateLimitExceeded):
        svc.resend_email(None, "ratelimit@email.com", 15, 60)


def test_refresh_success(monkeypatch):
    fake_repo = FakeRepo()
    monkeypatch.setattr(service_module, "verify_refresh_token", lambda ref: {"id": 1, "email": "user@example.com", "exp": 30})
    monkeypatch.setattr(service_module, "create_access_token", lambda p, d: "acc")

    svc = UserService(fake_repo)
    token = svc.refresh("ref", 15)

    assert token == "acc"


def test_refresh_invalid_refresh_token(monkeypatch):
    fake_repo = FakeRepo()
    monkeypatch.setattr(service_module, "verify_refresh_token", lambda ref: (_ for _ in ()).throw(JWTError()))

    svc = UserService(fake_repo)
    with pytest.raises(InvalidRefreshToken):
        svc.refresh("ref", 15)


def test_refresh_invalid_refresh_token_payload_none(monkeypatch):
    fake_repo = FakeRepo()
    monkeypatch.setattr(service_module, "verify_refresh_token", lambda ref: None)

    svc = UserService(fake_repo)
    with pytest.raises(InvalidRefreshToken):
        svc.refresh("ref", 15)

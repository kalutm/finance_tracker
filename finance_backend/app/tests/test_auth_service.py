# tests/test_auth_service.py
import pytest
from unittest.mock import MagicMock

# import the service and exceptions from your package
from app.auth import service
from app.auth.exceptions import UserAlreadyExists, InvalidCredentials, AccountNotVerified

class DummyUser:
    def __init__(self, id, email, password_hash=None, provider="LOCAL", is_verified=True):
        self.id = id
        self.email = email
        self.password_hash = password_hash
        self.provider = provider
        self.is_verified = is_verified
        self.provider_id = None

@pytest.fixture
def fake_session():
    # a dumb object that has .exec method used by your repo functions.
    class S:
        def __init__(self):
            self._data = {}
        def exec(self, *args, **kwargs):
            return MagicMock(first=MagicMock(return_value=None))
        def commit(self): pass
        def refresh(self, obj): pass
    return S()

def test_register_user_creates_user_and_sends_email(monkeypatch, fake_session):
    # Arrange: make repo.get_local_user_by_email return None, and repo.add_user behave normally
    monkeypatch.setattr(service, "get_local_user_by_email", lambda session, email: None)
    created = DummyUser(id=1, email="new@example.com")
    def fake_add_user(session, user):
        user.id = 1
        return user
    monkeypatch.setattr(service, "add_user", fake_add_user)

    # stub token creation and email send
    monkeypatch.setattr(service, "create_tokens_for_user", lambda uid, email, a, r: ("acc", "ref"))
    sent = {}
    def fake_send_verification_email(email, token):
        sent["email"] = email
        sent["token"] = token
    monkeypatch.setattr(service, "send_verification_email", fake_send_verification_email)

    # Act
    access, refresh = service.register_user(
        session=fake_session,
        email="new@example.com",
        password="password123",
        access_min=15,
        refresh_days=7,
    )

    # Assert
    assert access == "acc"
    assert refresh == "ref"
    # if your service returns verification token or calls send_verification_email, assert that:
    # assert sent["email"] == "new@example.com"

def test_login_local_raises_for_bad_credentials(monkeypatch, fake_session):
    # make get_local_user_by_email return None => invalid credentials
    monkeypatch.setattr(service, "get_local_user_by_email", lambda session, email: None)

    with pytest.raises(InvalidCredentials):
        service.login_local(fake_session, "noone@example.com", "pass", 15, 7)

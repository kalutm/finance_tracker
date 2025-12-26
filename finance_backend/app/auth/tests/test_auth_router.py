import pytest
from types import SimpleNamespace
from fastapi.testclient import TestClient
from app.tests.conftest import override_get_current_user
from finance_backend.main import app
from app.auth import service

client = TestClient(app)


def _clear_override(dep):
    app.dependency_overrides.pop(dep, None)

# Tests
def test_register_success(monkeypatch):
    # fake service instance exposing register_user(...)
    fake_service = SimpleNamespace(
        register_user=lambda session, email, password, access_exp, refresh_exp: ("fake_access", "fake_refresh")
    )
    # override the DI provider used by router
    app.dependency_overrides[service.get_user_service] = lambda: fake_service

    # mock the emailer.send_verification_email (side effect) so it does nothing
    def mock_send_email_verification(email, token):
        pass

    monkeypatch.setattr("app.auth.router.send_verification_email", mock_send_email_verification)

    payload = {"email": "test@example.com", "password": "secret123"}
    response = client.post("/v1/auth/register", json=payload)

    _clear_override(service.get_user_service)

    assert response.status_code == 200
    data = response.json()
    assert data["acc_jwt"] == "fake_access"
    assert data["ref_jwt"] == "fake_refresh"
    assert data["token_type"] == "bearer"


def test_register_user_already_exists():
    # fake service that raises the same exception the real service would
    def _raise(*a, **k):
        raise service.UserAlreadyExists("duplicate@example.com", "User already exists")

    fake_service = SimpleNamespace(register_user=_raise)
    app.dependency_overrides[service.get_user_service] = lambda: fake_service

    payload = {"email": "duplicate@example.com", "password": "pass123"}
    response = client.post("/v1/auth/register", json=payload)

    _clear_override(service.get_user_service)

    assert response.status_code == 400
    # The router converts the exception to HTTP 400 with the exception message
    response.json()["detail"] == "User already exists"


def test_login_success():
    fake_service = SimpleNamespace(
        login_local=lambda session, email, password, access_exp, refresh_exp: ("access123", "refresh123")
    )
    app.dependency_overrides[service.get_user_service] = lambda: fake_service

    payload = {"email": "user@example.com", "password": "pw"}
    response = client.post("/v1/auth/login", json=payload)

    _clear_override(service.get_user_service)

    assert response.status_code == 200
    data = response.json()
    assert data["acc_jwt"] == "access123"
    assert data["ref_jwt"] == "refresh123"
    assert data["token_type"] == "bearer"


def test_login_invalid_credentials():
    def _raise(*a, **k):
        raise service.InvalidCredentials("Invalid credentials")

    fake_service = SimpleNamespace(login_local=_raise)
    app.dependency_overrides[service.get_user_service] = lambda: fake_service

    payload = {"email": "wrong@example.com", "password": "wrong"}
    response = client.post("/v1/auth/login", json=payload)

    _clear_override(service.get_user_service)

    assert response.status_code == 400
    assert response.json()["detail"] == "Invalid credentials"


def test_login_account_not_verified():
    def _raise(*a, **k):
        raise service.AccountNotVerified()

    fake_service = SimpleNamespace(login_local=_raise)
    app.dependency_overrides[service.get_user_service] = lambda: fake_service

    payload = {"email": "unverifiedemail@example.com", "password": "unverified"}
    response = client.post("/v1/auth/login", json=payload)

    _clear_override(service.get_user_service)

    assert response.status_code == 403
    assert response.json()["detail"] == "Email not verified! please verify your email before you login"


def test_login_google_success():
    fake_service = SimpleNamespace(
        login_google=lambda session, id_token, access_exp, refresh_exp, google_client_id: ("fake_google_acc", "fake_google_ref")
    )
    app.dependency_overrides[service.get_user_service] = lambda: fake_service

    payload = {"id_token": "fake google id token"}
    response = client.post("/v1/auth/login/google", json=payload)

    _clear_override(service.get_user_service)

    assert response.status_code == 200
    data = response.json()
    assert data["acc_jwt"] == "fake_google_acc"
    assert data["ref_jwt"] == "fake_google_ref"
    assert data["token_type"] == "bearer"


def test_login_google_google_token_invalid():
    def _raise(*a, **k):
        raise service.GoogleTokenInvalid("Invalid Google Token")

    fake_service = SimpleNamespace(login_google=_raise)
    app.dependency_overrides[service.get_user_service] = lambda: fake_service

    payload = {"id_token": "fake google id token"}
    response = client.post("/v1/auth/login/google", json=payload)

    _clear_override(service.get_user_service)

    assert response.status_code == 400
    assert response.json()["detail"] == "Invalid Google Token"


def test_login_google_account_exists_with_different_provider():
    def _raise(*a, **k):
        raise service.AccountExistsWithDifferentProvider()

    fake_service = SimpleNamespace(login_google=_raise)
    app.dependency_overrides[service.get_user_service] = lambda: fake_service

    payload = {"id_token": "fake google id token"}
    response = client.post("/v1/auth/login/google", json=payload)

    _clear_override(service.get_user_service)

    assert response.status_code == 400
    assert response.json()["detail"] == "Account email already exists with different provider. Contact support."


def test_verify_email_success():
    fake_service = SimpleNamespace(verify_email=lambda session, token: "Email verified successfully")
    app.dependency_overrides[service.get_user_service] = lambda: fake_service

    payload = {"token": "fake verification token"}
    response = client.get("/v1/auth/verify", params=payload)

    _clear_override(service.get_user_service)

    assert response.status_code == 200
    assert response.json()["message"] == "Email verified successfully"


def test_verify_email_invalid_verification_token():
    def _raise(*a, **k):
        raise service.InvalidVerificationToken("Invalid Token")

    fake_service = SimpleNamespace(verify_email=_raise)
    app.dependency_overrides[service.get_user_service] = lambda: fake_service

    payload = {"token": "Invalid Verification Token"}
    response = client.get("/v1/auth/verify", params=payload)

    _clear_override(service.get_user_service)

    assert response.status_code == 400
    assert response.json()["detail"] == "Invalid Token"


def test_verify_email_user_not_found():
    def _raise(*a, **k):
        raise service.UserNotFound()

    fake_service = SimpleNamespace(verify_email=_raise)
    app.dependency_overrides[service.get_user_service] = lambda: fake_service

    payload = {"token": "user not found in db sent a verification email"}
    response = client.get("/v1/auth/verify", params=payload)

    _clear_override(service.get_user_service)

    assert response.status_code == 404
    assert response.json()["detail"] == "User not found! please register before you verify"


def test_resend_verification_success(monkeypatch):
    fake_service = SimpleNamespace(resend_email=lambda session, email, acc, cooldown: "fake verification token")
    app.dependency_overrides[service.get_user_service] = lambda: fake_service

    # mock the emailer side-effect
    def mock_send_email_verification(email, token):
        pass

    monkeypatch.setattr("app.auth.router.send_verification_email", mock_send_email_verification)

    payload = {"email": "resendverificationemail@example.com"}
    response = client.post("/v1/auth/resend-verification", json=payload)

    _clear_override(service.get_user_service)

    assert response.status_code == 200
    assert response.json()["message"] == "Verification email resent"


def test_resend_verification_account_already_verified():
    def _raise(*a, **k):
        raise service.AccountAlreadyVerified()

    fake_service = SimpleNamespace(resend_email=_raise)
    app.dependency_overrides[service.get_user_service] = lambda: fake_service

    payload = {"email": "emailalreadyverified@example.com"}
    response = client.post("/v1/auth/resend-verification", json=payload)

    _clear_override(service.get_user_service)

    assert response.status_code == 400
    assert response.json()["detail"] == "User has already been verified"


def test_resend_verification_rate_limit_exceeded():
    def _raise(*a, **k):
        raise service.RateLimitExceeded()

    fake_service = SimpleNamespace(resend_email=_raise)
    app.dependency_overrides[service.get_user_service] = lambda: fake_service

    payload = {"email": "ratelimitexceeded@example.com"}
    response = client.post("/v1/auth/resend-verification", json=payload)

    _clear_override(service.get_user_service)

    assert response.status_code == 400
    assert response.json()["detail"] == "Please wait before resending again"


def test_resend_verification_user_not_found():
    def _raise(*a, **k):
        raise service.UserNotFound()

    fake_service = SimpleNamespace(resend_email=_raise)
    app.dependency_overrides[service.get_user_service] = lambda: fake_service

    payload = {"email": "usernotfound@example.com"}
    response = client.post("/v1/auth/resend-verification", json=payload)

    _clear_override(service.get_user_service)

    assert response.status_code == 404
    assert response.json()["detail"] == "User not found! please register before you verify"


def test_refresh_success():
    fake_service = SimpleNamespace(refresh=lambda ref, acc_exp: "new fake access token")
    app.dependency_overrides[service.get_user_service] = lambda: fake_service

    payload = {"token": "fake refresh token"}
    response = client.post("/v1/auth/refresh", json=payload)

    _clear_override(service.get_user_service)

    assert response.status_code == 200
    data = response.json()
    assert data["acc_jwt"] == "new fake access token"
    assert data["token_type"] == "bearer"


def test_refresh_invalid_refresh_token():
    def _raise(*a, **k):
        raise service.InvalidRefreshToken()

    fake_service = SimpleNamespace(refresh=_raise)
    app.dependency_overrides[service.get_user_service] = lambda: fake_service

    payload = {"token": "fake refresh token"}
    response = client.post("/v1/auth/refresh", json=payload)

    _clear_override(service.get_user_service)

    assert response.status_code == 401
    assert response.json()["detail"] == "Invalid refresh token"


def test_get_me_success(monkeypatch, override_get_current_user):
    # override the service to provide get_current_user_info(user)
    def mock_get_user_info(user):
        return {"id": str(user.id), "email": user.email, "provider": user.provider, "is_verified": user.is_verified}

    fake_service = SimpleNamespace(get_current_user_info=mock_get_user_info)
    app.dependency_overrides[service.get_user_service] = lambda: fake_service

    response = client.get("/v1/auth/me")

    _clear_override(service.get_user_service)

    assert response.status_code == 200
    data = response.json()
    assert data["email"] == "fake@user.com"
    assert data["is_verified"] is True


def test_delete_my_account_success(monkeypatch, override_get_current_user):
    def mock_delete_user(session, user):
        assert user.email == "fake@user.com"
        return "Account deleted successfully"

    fake_service = SimpleNamespace(delete_current_user=mock_delete_user)
    app.dependency_overrides[service.get_user_service] = lambda: fake_service

    response = client.delete("/v1/auth/me")

    _clear_override(service.get_user_service)

    assert response.status_code == 200
    data = response.json()
    assert data["detail"] == "Account deleted successfully"


def test_get_me_unauthorized():
    # do NOT override get_user_service or get_current_user -> should be 401
    response = client.get("/v1/auth/me")
    assert response.status_code == 401
    assert response.json()["detail"].lower() == "not authenticated"


def test_delete_my_account_unauthorized():
    # do NOT override get_user_service or get_current_user -> should be 401
    response = client.delete("/v1/auth/me")
    assert response.status_code == 401
    assert response.json()["detail"].lower() == "not authenticated"

import pytest
from fastapi.testclient import TestClient
from app.main import app
from app.auth import service
from app.tests.conftest import override_get_current_user


client = TestClient(app)


def test_register_success(monkeypatch):
    # mock the service.register_user to return fake tokens
    def mock_register_user(session, email, password, access_exp, refresh_exp):
        return "fake_access", "fake_refresh"
    # mock the emailer.send verification email to do nothing
    def mock_send_email_verificatoin(email, token):
        pass

    monkeypatch.setattr(service, "register_user", mock_register_user)
    monkeypatch.setattr("app.auth.router.send_verification_email", mock_send_email_verificatoin)

    # Prepare payload
    payload = {
        "email": "test@example.com",
        "password": "secret123"
    }

    # Send request
    response = client.post("v1/auth/register", json=payload)

    # Assert response
    assert response.status_code == 200
    data = response.json()
    assert data["acc_jwt"] == "fake_access"
    assert data["ref_jwt"] == "fake_refresh"
    assert data["token_type"] == "bearer"


def test_register_user_already_exists(monkeypatch):
    # Mock service.register_user to raise exception
    def mock_register_user(session, email, password, access_exp, refresh_exp):
        raise service.UserAlreadyExists("duplicate@example.com", "User already exists")

    monkeypatch.setattr(service, "register_user", mock_register_user)

    payload = {
        "email": "duplicate@example.com",
        "password": "pass123"
    }

    response = client.post("v1/auth/register", json=payload)

    # Assert the router handled it properly
    assert response.status_code == 400
    assert response.json()["detail"] == "User already exists"


def test_login_success(monkeypatch):
    # mock service.login_local to return fake token's
    def mock_login_local(session, email, password, access_exp, refresh_exp):
        return "access123", "refresh123"
    
    monkeypatch.setattr(service, "login_local", mock_login_local)

    payload = {"email": "user@example.com", "password": "pw"}
    response = client.post("v1/auth/login", json=payload)

    # assert responses
    assert response.status_code == 200
    data = response.json()
    assert data["acc_jwt"] == "access123"
    assert data["ref_jwt"] == "refresh123"
    assert data["token_type"] == "bearer"


def test_login_invalid_credentials(monkeypatch):
    # mock service.login_local to raise exception
    def mock_login_local(session, email, password, access_exp, refresh_exp):
        raise service.InvalidCredentials("Invalid credentials")

    monkeypatch.setattr(service, "login_local", mock_login_local)

    payload = {"email": "wrong@example.com", "password": "wrong"}
    response = client.post("v1/auth/login", json=payload)

    # assert that the router handled it properly
    assert response.status_code == 400
    assert response.json()["detail"] == "Invalid credentials"


def test_login_account_not_verified(monkeypatch):
    # mock service.login_local to raise exception
    def mock_login_local(session, email, password, access_exp, refresh_exp):
        raise service.AccountNotVerified()

    monkeypatch.setattr(service, "login_local", mock_login_local)

    payload = {"email": "unverifiedemail@example.com", "password": "unverified"}
    response = client.post("v1/auth/login", json=payload)

    # assert that the router handled it properly
    assert response.status_code == 403
    assert response.json()["detail"] == "Email not verified! please verify your email before you login"


def test_login_google_success(monkeypatch):
    # mock service.login_google to return fake token's
    def mock_login_google(session, id_token, access_exp, refresh_exp, google_client_id):
        return "fake_google_acc", "fake_google_ref"
    
    monkeypatch.setattr(service, "login_google", mock_login_google)

    payload = {"id_token": "fake google id token"}
    response = client.post("v1/auth/login/google", json=payload)

    # assert response
    assert response.status_code == 200
    data = response.json()
    assert data["acc_jwt"] == "fake_google_acc"
    assert data["ref_jwt"] == "fake_google_ref"
    assert data["token_type"] == "bearer"


def test_login_google_google_token_invalid(monkeypatch):
    # mock service.login_google to raise exception
    def mock_login_google(session, id_token, access_exp, refresh_exp, google_client_id):
        raise service.GoogleTokenInvalid("Invalid Google Token")

    monkeypatch.setattr(service, "login_google", mock_login_google)

    payload = {"id_token": "fake google id token"}
    response = client.post("v1/auth/login/google", json=payload)

    # assert that the router handled it properly
    assert response.status_code == 400
    assert response.json()["detail"] == "Invalid Google Token"


def test_login_google_account_exists_with_different_provider(monkeypatch):
    # mock service.login_google to raise exception
    def mock_login_google(session, id_token, access_exp, refresh_exp, google_client_id):
        raise service.AccountExistsWithDifferentProvider()

    monkeypatch.setattr(service, "login_google", mock_login_google)

    payload = {"id_token": "fake google id token"}
    response = client.post("v1/auth/login/google", json=payload)

    # assert that the router handled it properly
    assert response.status_code == 400
    assert response.json()["detail"] == "Account email already exists with different provider. Contact support."


def test_verify_email_success(monkeypatch):
    # mock service.verify_email to return fake successful message
    def mock_verify_email(session, token):
        return "Email verified successfully"
    
    monkeypatch.setattr(service, "verify_email", mock_verify_email)

    payload = {"token": "fake verification token"}
    response = client.get("v1/auth/verify", params=payload)

    # assert response
    assert response.status_code == 200
    assert response.json()["message"] == "Email verified successfully"


def test_verify_email_invalid_verification_token(monkeypatch):
    # mock service.verfy_email to raise an error
    def mock_verify_email(session, token):
        raise service.InvalidVerificationToken("Invalid Token")
    
    monkeypatch.setattr(service, "verify_email", mock_verify_email)

    payload = {"token": "Invalid Verification Token"}
    response = client.get("v1/auth/verify", params=payload)

    # assert that the router handles the exception properly
    assert response.status_code == 400
    assert response.json()["detail"] == "Invalid Token"


def test_verify_email_user_not_found(monkeypatch):
    # mock service.verfy_email to raise an error
    def mock_verify_email(session, token):
        raise service.UserNotFound()
    
    monkeypatch.setattr(service, "verify_email", mock_verify_email)

    payload = {"token": "user not found in db sent a verification email"}
    response = client.get("v1/auth/verify", params=payload)

    # assert that the router handles the exception properly
    assert response.status_code == 404
    assert response.json()["detail"] == "User not found! please register before you verify"


def test_resend_verification_success(monkeypatch):
    # mock service.resend_email to return fake successful resent email message
    def mock_resend_email(session, email, acc, cooldown):
        return "fake verification token"
    # mock the emailer.send verification email to do nothing
    def mock_send_email_verificatoin(email, token):
        pass
    
    monkeypatch.setattr(service, "resend_email", mock_resend_email)
    monkeypatch.setattr("app.auth.router.send_verification_email", mock_send_email_verificatoin)

    payload = {"email": "resendverificationemail@example.com"}
    response = client.post("v1/auth/resend-verification", json=payload)

    # assert response
    assert response.status_code == 200
    assert response.json()["message"] == "Verification email resent"


def test_resend_verification_account_already_verified(monkeypatch):
    # mock service.resend_email to raise exception
    def mock_resend_email(session, email, acc, cooldown):
        raise service.AccountAlreadyVerified()
    
    monkeypatch.setattr(service, "resend_email", mock_resend_email)
    
    payload = {"email": "emailalreadyverified@example.com"}
    response = client.post("v1/auth/resend-verification", json=payload)

    # assert that the endpoint handles the exception properly
    assert response.status_code == 400
    assert response.json()["detail"] == "User has already been verified"


def test_resend_verification_rate_limit_exceeded(monkeypatch):
    # mock service.resend_email to raise exception
    def mock_resend_email(session, email, acc, cooldown):
        raise service.RateLimitExceeded()
    
    monkeypatch.setattr(service, "resend_email", mock_resend_email)
    
    payload = {"email": "ratelimitexceeded@example.com"}
    response = client.post("v1/auth/resend-verification", json=payload)

    # assert that the endpoint handles the exception properly
    assert response.status_code == 400
    assert response.json()["detail"] == "Please wait before resending again"


def test_resend_verification_user_not_found(monkeypatch):
    # mock service.resend_email to raise exception
    def mock_resend_email(session, email, acc, cooldown):
        raise service.UserNotFound()
    
    monkeypatch.setattr(service, "resend_email", mock_resend_email)
    
    payload = {"email": "usernotfound@example.com"}
    response = client.post("v1/auth/resend-verification", json=payload)

    # assert that the endpoint handles the exception properly
    assert response.status_code == 404
    assert response.json()["detail"] == "User not found! please register before you verify"


def test_refresh_success(monkeypatch):
    # mock service.refresh to return fake access token
    def mock_refresh(ref, acc_exp):
        return "new fake access token"

    monkeypatch.setattr(service, "refresh", mock_refresh)

    payload = {"refresh_token": "fake refresh token"}
    response = client.post("/v1/auth/refresh", params=payload)

    # assert response
    assert response.status_code == 200
    data = response.json()
    assert data["acc_jwt"] == "new fake access token"
    assert data["token_type"] == "bearer"


def test_refresh_invalid_refresh_token(monkeypatch):
    # mock service.refresh to raise exception
    def mock_refresh(ref, acc_exp):
        raise service.InvalidRefreshToken()

    monkeypatch.setattr(service, "refresh", mock_refresh)
    
    payload = {"refresh_token": "fake refresh token"}
    response = client.post("/v1/auth/refresh", params=payload)

    # assert that the router handles the exception properly
    assert response.status_code == 401
    assert response.json()["detail"] == "Invalid refresh token"


def test_get_me_success(monkeypatch, override_get_current_user):
    # Mock the service.get_user_info to return fake user
    def mock_get_user_info(user):
        return {"id": user.id, "email": user.email, "provider": user.provider, "is_verified": user.is_verified}

    # Apply monkeypatches
    monkeypatch.setattr(service, "get_current_user_info", mock_get_user_info)

    response = client.get("/v1/auth/me")

    assert response.status_code == 200
    data = response.json()
    assert data["email"] == "fake@user.com"
    assert data["is_verified"] is True


def test_delete_my_account_success(monkeypatch, override_get_current_user):
    # mock service.delete_user to return fake message
    def mock_delete_user(session, user):
        assert user.email == "fake@user.com"
        return "Account deleted successfully"

    # Apply monkeypatches
    monkeypatch.setattr(service, "delete_current_user", mock_delete_user)

    response = client.delete("/v1/auth/me")

    assert response.status_code == 200
    data = response.json()
    assert data["detail"] == "Account deleted successfully"


def test_get_me_unauthorized(monkeypatch):
    # Mock the service.get_user_info to return fake user
    def mock_get_user_info(user):
        return {"id": user.id, "email": user.email, "provider": user.provider, "is_verified": user.is_verified}

    # Apply monkeypatches
    monkeypatch.setattr(service, "get_current_user_info", mock_get_user_info)

    response = client.get("/v1/auth/me")

    assert response.status_code == 401
    assert response.json()["detail"] == "Not authenticated"
    

def test_delete_my_account_unauthorized(monkeypatch):
     # mock service.delete_user to return fake message
    def mock_delete_user(session, user):
        assert user.email == "fake@user.com"
        return "Account deleted successfully"

    # Apply monkeypatches
    monkeypatch.setattr(service, "delete_current_user", mock_delete_user)

    response = client.delete("/v1/auth/me")

    assert response.status_code == 401
    assert response.json()["detail"] == "Not authenticated"
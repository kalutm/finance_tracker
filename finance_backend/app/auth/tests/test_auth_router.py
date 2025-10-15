import pytest
from fastapi.testclient import TestClient
from app.main import app
from app.auth import service



client = TestClient(app)


def test_register_success(monkeypatch):
    # Mock the service.register_user to return fake tokens
    def mock_register_user(session, email, password, access_exp, refresh_exp):
        return "fake_access", "fake_refresh"
    
    monkeypatch.setattr(service, "register_user", mock_register_user)

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

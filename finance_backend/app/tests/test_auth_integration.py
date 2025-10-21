import pytest
from fastapi.testclient import TestClient
from sqlmodel import Session, select
from app.models.user import User
from app.models.enums import Provider


def test_register_returns_token(client: TestClient, db_session: Session):
    """
    After registration, user receives tokens (access + refresh).
    """
    res = client.post(
        "v1/auth/register",
        json={"email": "newuser@example.com", "password": "secret123"},
    )
    assert res.status_code == 200
    body = res.json()

    assert "acc_jwt" in body
    assert "ref_jwt" in body
    assert body["token_type"] == "bearer"

    # DB check
    user = db_session.exec(select(User).where(User.email == "newuser@example.com")).first()
    assert user is not None
    assert user.is_verified is False


def test_login_requires_verification(client: TestClient, db_session: Session):
    """
    Ensure an unverified user cannot log in.
    """
    # register user
    client.post(
        "v1/auth/register",
        json={"email": "newuser@example.com", "password": "secret123"},
    )

    # Try logging in before verification
    response = client.post(
        "v1/auth/login",
        json={
            "email": "newuser@example.com",
            "password": "secret123",
        },
    )

    assert response.status_code in (400, 403, 401)
    assert "verify" in response.text.lower()


def test_verified_user_can_login_and_get_token(client: TestClient, db_session: Session):
    """
    After a user is verified, they can log in and get a token.
    """
    # register user
    client.post(
        "v1/auth/register",
        json={"email": "newuser@example.com", "password": "secret123"},
    )
    # manually verify user
    user = db_session.exec(select(User).where(User.email == "newuser@example.com")).first()
    user.is_verified = True
    db_session.commit()
    

    # Attempt login
    response = client.post(
        "v1/auth/login",
        json={
            "email": "newuser@example.com",
            "password": "secret123",
        },
    )

    assert response.status_code == 200
    body = response.json()
    assert "acc_jwt" in body
    assert body["token_type"] == "bearer"


def test_protected_route_requires_auth(client: TestClient):
    """
    /auth/me should reject requests without valid Authorization header.
    """
    res = client.get("v1/auth/me")
    assert res.status_code == 401
    assert "not authenticated" in res.text.lower()


def test_access_protected_route_with_valid_token(client: TestClient, db_session: Session):
    """
    Full flow:
    - Register → verify → login → call /auth/me with token
    """
    # Step 1: Register
    reg_res = client.post(
        "v1/auth/register",
        json={"email": "alice@example.com", "password": "secret123"},
    )
    assert reg_res.status_code == 200

    # Step 2: Mark user as verified manually (simulate email verification)
    user = db_session.exec(select(User).where(User.email == "alice@example.com")).first()
    user.is_verified = True
    db_session.commit()

    # Step 3: Login
    login_res = client.post(
        "v1/auth/login",
        json={"email": "alice@example.com", "password": "secret123"},
    )
    assert login_res.status_code == 200
    token = login_res.json()["acc_jwt"]

    # Step 4: Access protected route
    me_res = client.get("v1/auth/me", headers={"Authorization": f"Bearer {token}"})
    assert me_res.status_code == 200
    me_data = me_res.json()

    # Step 5: Validate response
    assert me_data["email"] == "alice@example.com"
    assert me_data["is_verified"] is True
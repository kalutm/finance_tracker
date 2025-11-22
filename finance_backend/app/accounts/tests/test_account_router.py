import pytest
from fastapi.testclient import TestClient
from unittest.mock import Mock
from uuid import UUID
from app.main import app
from app.accounts.service import AccountService, get_account_service
from app.models.account import Account
from app.models.enums import AccountType
from app.accounts.exceptions import AccountNameAlreadyTaken, AccountNotFound
from app.tests.conftest import override_get_current_user


# demo uid
uid = UUID(int=0x12345678123456781234567812345678)

# helpers
@pytest.fixture
def mock_account_service():
    return Mock(spec=AccountService)

@pytest.fixture
def client():
    with TestClient(app) as client:
        yield client

@pytest.fixture
def client_with_mocked_service(client, mock_account_service):
    app.dependency_overrides[get_account_service] = lambda: mock_account_service
    yield client
    app.dependency_overrides.pop(get_account_service, None)

# Tests
def test_get_accounts_router(client_with_mocked_service, mock_account_service, override_get_current_user):
    mock_acc = Account(id=1, name="Test Acc", type=AccountType.BANK, currency="USD", user_id=uid)

    # Service returns tuple: (list of accounts, total_count)
    mock_account_service.get_user_accounts.return_value = ([mock_acc], 1)

    response = client_with_mocked_service.get("v1/accounts/")

    assert response.status_code == 200
    data = response.json()
    assert data["total"] == 1
    assert data["accounts"][0]["name"] == "Test Acc"

def test_create_account_router_success(client_with_mocked_service, mock_account_service, override_get_current_user):
    payload = {"name": "New Bank", "type": AccountType.BANK, "currency": "USD"}
    mock_acc = Account(id=5, **payload, user_id=uid)
    mock_account_service.create_account.return_value = mock_acc

    response = client_with_mocked_service.post("v1/accounts/", json=payload)

    assert response.status_code == 201
    assert response.json()["name"] == "New Bank"
    mock_account_service.create_account.assert_called_once()

def test_create_account_router_handle_duplicate(client_with_mocked_service, mock_account_service, override_get_current_user):
    mock_account_service.create_account.side_effect = AccountNameAlreadyTaken("Exists")
    payload = {"name": "Dup Bank", "type": AccountType.BANK, "currency": "USD"}

    response = client_with_mocked_service.post("v1/accounts/", json=payload)

    assert response.status_code == 400
    assert "Exists" in response.json()["detail"]

def test_get_account_not_found(client_with_mocked_service, mock_account_service, override_get_current_user):
    mock_account_service.get_account.side_effect = AccountNotFound("Nope")

    response = client_with_mocked_service.get("v1/accounts/999")

    assert response.status_code == 404
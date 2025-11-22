import pytest
from unittest.mock import Mock
from fastapi.testclient import TestClient
from uuid import UUID
from decimal import Decimal
from app.main import app
from app.transactions.service import TransactionsService, get_transaction_service
from app.models.transaction import Transaction, TransactionType
from app.transactions.exceptions import InsufficientBalance, InvalidAmount
from app.tests.conftest import override_get_current_user


# demo uid
uid = UUID(int=0x12345678123456781234567812345678)

# helpers
@pytest.fixture
def mock_service():
    return Mock(spec=TransactionsService)

@pytest.fixture
def client():
    with TestClient(app) as test_client:
        yield test_client

@pytest.fixture
def client_with_mock(client, mock_service):
    app.dependency_overrides[get_transaction_service] = lambda: mock_service
    yield client
    app.dependency_overrides.pop(get_transaction_service, None)

# Tests 

def test_create_transaction_201(client_with_mock, mock_service, override_get_current_user):
    payload = {
        "account_id": 1, 
        "category_id": 1, 
        "amount": 50.5, 
        "currency": "ETB",
        "type": "EXPENSE",
        "date": "2023-01-01T12:00:00"
    }
    
    # Prepare return object
    mock_txn = Transaction(id=1, **payload, user_id=uid)
    mock_service.create_income_expense_transaction.return_value = mock_txn
    
    response = client_with_mock.post("v1/transactions/", json=payload)
    
    assert response.status_code == 201
    data = response.json()
    assert data["amount"] == "50.5"
    assert data["type"] == "EXPENSE"

def test_create_transaction_insufficient_balance(client_with_mock, mock_service, override_get_current_user):
    mock_service.create_income_expense_transaction.side_effect = InsufficientBalance("No money")
    payload = {"account_id": 1, "amount": 100, "currency": "ETB", "type": "EXPENSE"}
    
    response = client_with_mock.post("v1/transactions/", json=payload)
    
    assert response.status_code == 400
    assert response.json()["detail"]["code"] == "INSUFFICIENT_BALANCE"

def test_create_transfer_201(client_with_mock, mock_service, override_get_current_user):
    payload = {
        "account_id": 1,
        "to_account_id": 2,
        "amount": 50,
        "type": "TRANSFER",
        "currency": "ETB"
    }
    # Service returns tuple (out, in)
    t_out = Transaction(id=1 ,user_id=uid, account_id=1, currency="ETB", type=TransactionType.TRANSFER, amount=50)
    t_in = Transaction(id=2, user_id=uid, account_id=2, currency="ETB", type=TransactionType.TRANSFER, amount=50)
    mock_service.create_transfer_transaction.return_value = (t_out, t_in)
    
    response = client_with_mock.post("v1/transactions/transfer", json=payload)
    
    assert response.status_code == 201
    data = response.json()
    assert "outgoing_transaction" in data
    assert "incoming_transaction" in data

def test_get_summary(client_with_mock, mock_service, override_get_current_user):
    mock_summary = {
        "month": "2025-11",
        "total_income": Decimal("1000"),
        "total_expense": Decimal("500"),
        "net_savings": Decimal("500"),
    }
    mock_service.get_transaction_summary.return_value = mock_summary
    
    # Test query param validation regex
    response = client_with_mock.get("/v1/transactions/summary?month=2025-11")
    assert response.status_code == 200
    assert response.json()["net_savings"] == "500"

def test_get_summary_invalid_date_format(client_with_mock, mock_service, override_get_current_user):
    response = client_with_mock.get("v1/transactions/summary?month=2025/11") # Wrong format
    assert response.status_code == 422 # Validation Error / unprocesible content

def test_delete_transfer_transaction(client_with_mock, mock_service, override_get_current_user):
    group_id = "123e4567-e89b-12d3-a456-426614174000"
    mock_service.delete_transfer_transaction.return_value = None
    
    response = client_with_mock.delete(f"v1/transactions/transfer/{group_id}")
    
    assert response.status_code == 204 # No Content
    mock_service.delete_transfer_transaction.assert_called_once()
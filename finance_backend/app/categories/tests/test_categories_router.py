import pytest
from fastapi.testclient import TestClient
from uuid import UUID
from unittest.mock import Mock
from finance_backend.app.main import app
from app.categories.service import CategoriesService, get_categories_service
from app.models.category import Category
from app.models.enums import CategoryType
from app.tests.conftest import override_get_current_user
from app.categories.exceptions import (
    CategoryNameAlreadyTaken, 
    CategoryNotFound, 
    CouldnotDeleteCategory,
)

# demo uid
uid = UUID(int=0x12345678123456781234567812345678)

# helpers
@pytest.fixture
def mock_service():
    return Mock(spec=CategoriesService)

@pytest.fixture
def client():
    with TestClient(app) as client:
        yield client

@pytest.fixture
def client_with_mock(client, mock_service):
    app.dependency_overrides[get_categories_service] = lambda: mock_service
    yield client
    app.dependency_overrides.pop(get_categories_service, None)

# Tests
def test_get_categories_query_params(client_with_mock, mock_service, override_get_current_user):
    # Test that query params are passed to service correctly.

    mock_service.get_user_categories.return_value = ([], 0)
    
    # Calling with specific filters
    response = client_with_mock.get("v1/categories/?limit=10&offset=5&type=INCOME&active=true")
    
    assert response.status_code == 200
    # Check service was called with correct args
    args, _ = mock_service.get_user_categories.call_args
    # args structure: (session, user_id, limit, offset, type, active)
    assert args[2] == 10       # limit
    assert args[3] == 5        # offset
    assert args[4] == CategoryType.INCOME
    assert args[5] is True     # active

def test_create_category_201(client_with_mock, mock_service, override_get_current_user):
    payload = {"name": "Rent", "type": "EXPENSE", "description": "Monthly"}

    mock_cat = Category(id=1, **payload, user_id=uid)
    mock_service.create_category.return_value = mock_cat
    
    response = client_with_mock.post("v1/categories/", json=payload)
    
    assert response.status_code == 201
    data = response.json()
    assert data["name"] == "Rent"
    assert data["id"] == 1

def test_create_category_400_duplicate(client_with_mock, mock_service, override_get_current_user):
    mock_service.create_category.side_effect = CategoryNameAlreadyTaken("Taken")
    payload = {"name": "Rent", "type": "EXPENSE", "description": "Monthly"}
    
    response = client_with_mock.post("v1/categories/", json=payload)
    
    assert response.status_code == 400
    assert "Taken" in response.json()["detail"]

def test_get_category_404(client_with_mock, mock_service, override_get_current_user):
    mock_service.get_category.side_effect = CategoryNotFound("Missing")
    
    response = client_with_mock.get("v1/categories/999")
    
    assert response.status_code == 404

def test_update_category_partial(client_with_mock, mock_service, override_get_current_user):
    mock_cat = Category(id=1, name="New Name", type="EXPENSE", user_id=uid)
    mock_service.update_category.return_value = mock_cat
    
    # Patch only the name
    response = client_with_mock.patch("v1/categories/1", json={"name": "New Name"})
    
    assert response.status_code == 200
    assert response.json()["name"] == "New Name"
    
    # Verify service call arguments
    args, _ = mock_service.update_category.call_args
    # update_category structure: (session, id, user_id, update_data)
    assert args[3] == {"name": "New Name"} # Ensure only provided fields are sent

def test_actions_deactivate_restore(client_with_mock, mock_service, override_get_current_user):
    mock_cat = Category(id=1, name="Test", user_id=uid, active=False, type=CategoryType.EXPENSE)
    mock_service.deactivate_category.return_value = mock_cat
    
    # Test Deactivate
    resp = client_with_mock.patch("v1/categories/1/deactivate")
    assert resp.status_code == 200
    
    # Test Restore
    mock_cat.active = True
    mock_service.restore_category.return_value = mock_cat
    resp = client_with_mock.patch("v1/categories/1/restore")
    assert resp.status_code == 200

def test_delete_category_conflict(client_with_mock, mock_service, override_get_current_user):
    """Test the 400 Bad Request when transactions exist."""
    mock_service.delete_category.side_effect = CouldnotDeleteCategory("Trans exists")
    
    response = client_with_mock.delete("v1/categories/1")
    
    assert response.status_code == 400
    assert "Trans exists" in response.json()["detail"]

def test_delete_category_success(client_with_mock, mock_service, override_get_current_user):
    mock_service.delete_category.return_value = None
    
    response = client_with_mock.delete("v1/categories/1")
    
    assert response.status_code == 204
    assert response.content == b"" # No Content
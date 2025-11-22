import pytest
from unittest.mock import Mock, MagicMock
from sqlalchemy.exc import IntegrityError
from sqlmodel import Session
from uuid import UUID
from app.categories.service import CategoriesService
from app.categories.repo import CategoriesRepo
from app.models.category import Category
from app.models.enums import CategoryType
from app.categories.exceptions import (
    CategoryNameAlreadyTaken, 
    CategoryNotFound, 
    CouldnotDeleteCategory
)

# demo uid
uid = UUID(int=0x12345678123456781234567812345678)

@pytest.fixture
def mock_repo():
    return Mock(spec=CategoriesRepo)

@pytest.fixture
def mock_session():
    return Mock(spec=Session)

@pytest.fixture
def service(mock_repo):
    return CategoriesService(repo=mock_repo)


def test_create_category_success(service, mock_repo, mock_session):
    # Mock Repo returning the category
    mock_repo.save_category.side_effect = lambda s, c: c 
    
    res = service.create_category(mock_session, uid, "Food", CategoryType.EXPENSE, "desc")
    
    assert res.name == "Food"
    assert res.type == CategoryType.EXPENSE
    mock_session.commit.assert_called_once()

def test_create_category_duplicate_name(service, mock_repo, mock_session):
    # Simulate DB constraint error (name duplication)
    mock_repo.save_category.side_effect = IntegrityError(None, None, None)
    
    with pytest.raises(CategoryNameAlreadyTaken):
        service.create_category(mock_session, uid, "Duplicate", CategoryType.EXPENSE, "desc")
    
    mock_session.rollback.assert_called_once()

def test_get_category_not_found(service, mock_repo, mock_session):
    mock_repo.get_category_for_user.return_value = None
    
    with pytest.raises(CategoryNotFound):
        service.get_category(mock_session, 999, uid)

def test_update_category_success(service, mock_repo, mock_session):
    # Existing category
    existing = Category(id=1, name="Old Name", description="Old", user_id=uid)
    mock_repo.get_category_for_user.return_value = existing
    mock_repo.save_category = lambda s, c: c
    
    update_data = {"name": "New Name"} # Description should remain "Old"
    
    res = service.update_category(mock_session, 1, uid, update_data)
    
    assert res.name == "New Name"
    assert res.description == "Old" # Should not change
    mock_session.commit.assert_called_once()

def test_update_category_duplicate_name(service, mock_repo, mock_session):
    existing = Category(id=1, name="Old", user_id=uid)
    mock_repo.get_category_for_user.return_value = existing
    mock_repo.save_category.side_effect = IntegrityError(None, None, None)
    
    with pytest.raises(CategoryNameAlreadyTaken):
        service.update_category(mock_session, 1, uid, {"name": "Taken Name"})
    
    mock_session.rollback.assert_called_once()

def test_deactivate_category(service, mock_repo, mock_session):
    cat = Category(id=1, active=True, user_id=uid)
    mock_repo.get_category_for_user.return_value = cat
    mock_repo.save_category = lambda s, c: c
    
    res = service.deactivate_category(mock_session, 1, uid)
    
    assert res.active is False
    mock_session.commit.assert_called_once()

def test_delete_category_safe(service, mock_repo, mock_session):
    #Test hard delete when NO transactions exist.

    cat = Category(id=1, user_id=uid)
    mock_repo.get_category_for_user.return_value = cat
    # Zero transactions
    mock_repo.count_transactions_for_categories.return_value = 0
    
    service.delete_category(mock_session, 1, uid)
    
    mock_repo.delete_category.assert_called_once_with(mock_session, cat)
    mock_session.commit.assert_called_once()

def test_delete_category_unsafe(service, mock_repo, mock_session):
    # Test hard delete fails when transactions exist.

    cat = Category(id=1, user_id=uid)
    mock_repo.get_category_for_user.return_value = cat
    # 5 Transactions exist
    mock_repo.count_transactions_for_categories.return_value = 5
    
    with pytest.raises(CouldnotDeleteCategory) as exc:
        service.delete_category(mock_session, 1, uid)
    
    assert "Cannot hard-delete" in str(exc.value)
    mock_repo.delete_category.assert_not_called()
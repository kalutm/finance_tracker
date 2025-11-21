import pytest
from unittest.mock import Mock, MagicMock
from sqlalchemy.exc import IntegrityError
from sqlmodel import Session

from app.accounts.service import AccountService
from app.accounts.repo import AccountRepository
from app.models.account import Account
from app.accounts.exceptions import AccountNameAlreadyTaken, CouldnotDeleteAccount

@pytest.fixture
def mock_repo():
    return Mock(spec=AccountRepository)

@pytest.fixture
def mock_session():
    # We mock the DB session so session.commit() doesn't actually try to hit a DB
    return Mock(spec=Session)

@pytest.fixture
def account_service(mock_repo):
    return AccountService(repo=mock_repo)

def test_create_account_success(account_service, mock_repo, mock_session):
    user_id = 1
    account_data = {"name": "Cash", "type": "CASH", "currency": "USD"}
    
    # Mock repo to return the account passed to it
    mock_repo.save_account.side_effect = lambda session, acc: acc

    result = account_service.create_account(mock_session, user_id, **account_data)

    assert result.name == "Cash"
    assert result.user_id == user_id
    mock_repo.save_account.assert_called_once()
    mock_session.commit.assert_called_once() # Important: Verify logic commits transaction

def test_create_account_duplicate_name(account_service, mock_repo, mock_session):
    mock_repo.save_account.side_effect = IntegrityError(None, None, None)
    
    with pytest.raises(AccountNameAlreadyTaken):
        account_service.create_account(mock_session, 1, "Duplicate", "BANK", "USD")
    
    mock_session.rollback.assert_called_once() # Verify rollback on error

def test_delete_account_with_transactions_fails(account_service, mock_repo, mock_session):
    account_id = 99
    user_id = 1
    mock_account = Account(id=account_id, user_id=user_id)
    
    mock_repo.get_account_for_user.return_value = mock_account
    # Simulate logic: Account has 5 transactions
    mock_repo.count_transactions_for_account.return_value = 5 
    
    with pytest.raises(CouldnotDeleteAccount):
        account_service.delete_account(mock_session, account_id, user_id)
    
    # Ensure we strictly did NOT call delete
    mock_repo.delete_account.assert_not_called()

def test_deactivate_account(account_service, mock_repo, mock_session):
    account = Account(id=1, active=True)
    mock_repo.get_account_for_user.return_value = account
    mock_repo.save_account.return_value = account
    
    result = account_service.deactivate_account(mock_session, 1, 1)
    
    assert result.active is False
    mock_session.commit.assert_called_once()
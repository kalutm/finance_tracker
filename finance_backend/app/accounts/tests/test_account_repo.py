import pytest
from app.models.account import Account
from app.models.user import User
from app.models.enums import AccountType
from app.accounts.repo import AccountRepository
from app.tests.conftest import db_session, create_test_database, create_test_user


def test_save_and_get_account(db_session):
    repo = AccountRepository()
    user = create_test_user(db_session)
    
    # 1. Test Create/Save
    new_account = Account(
        user_id=user.id, 
        name="Main Bank", 
        type=AccountType.BANK, 
        currency="USD"
    )
    saved_account = repo.save_account(db_session, new_account)
    db_session.commit()

    assert saved_account.id is not None
    assert saved_account.name == "Main Bank"

    # 2. Test Get by ID
    fetched_account = repo.get_account_for_user(db_session, saved_account.id, user.id)
    assert fetched_account is not None
    assert fetched_account.id == saved_account.id

def test_list_user_accounts_filtering(db_session):
    repo = AccountRepository()
    user = create_test_user(db_session)
    
    # Create 1 active, 1 inactive
    acc1 = Account(user_id=user.id, name="Active Acc", type=AccountType.CASH, currency="USD", active=True)
    acc2 = Account(user_id=user.id, name="Inactive Acc", type=AccountType.CASH, currency="USD", active=False)
    repo.save_account(db_session, acc1)
    repo.save_account(db_session, acc2)
    db_session.commit()

    # Test getting ALL
    accounts, total = repo.list_user_accounts(db_session, user.id, limit=10, offset=0, active=None)
    assert total == 2
    assert len(accounts) == 2

    # Test getting ONLY ACTIVE
    accounts, total = repo.list_user_accounts(db_session, user.id, limit=10, offset=0, active=True)
    assert total == 1
    assert accounts[0].name == "Active Acc"

def test_delete_account(db_session):
    repo = AccountRepository()
    user = create_test_user(db_session)
    
    acc = Account(user_id=user.id, name="To Delete", type=AccountType.CASH, currency="USD")
    repo.save_account(db_session, acc)
    db_session.commit()

    repo.delete_account(db_session, acc)
    db_session.commit()

    fetched = repo.get_account_for_user(db_session, acc.id, user.id)
    assert fetched is None
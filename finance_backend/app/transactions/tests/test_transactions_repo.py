import pytest
from datetime import datetime, timedelta
from decimal import Decimal
from app.transactions.repo import TransactionRepo
from app.models.transaction import Transaction
from app.models.enums import TransactionType, CategoryType, AccountType
from app.models.user import User
from app.models.account import Account
from app.models.category import Category
from app.tests.conftest import db_session, create_test_database, create_test_user

# no layer below so nothing to mock just instanciate the repo
repo = TransactionRepo()

# Helpers
def create_setup(db_session):
    # Creates a User, Account, and Category for testing transactions.
    user = create_test_user(db_session, "txn_repo@test.com", "x")

    acc = Account(user_id=user.id, name="Bank", type=AccountType.BANK, currency="USD", balance=1000)
    db_session.add(acc)

    cat = Category(user_id=user.id, name="Food", type=CategoryType.EXPENSE)
    db_session.add(cat)
    db_session.commit()
    db_session.refresh(acc)
    db_session.refresh(cat)
    return user, acc, cat

def create_txn(db_session, user_id, acc_id, cat_id, amount, type, date=None):
    if date is None:
        date = datetime.now()
    txn = Transaction(
        user_id=user_id, account_id=acc_id, category_id=cat_id,
        amount=Decimal(amount), type=type, occurred_at=date, description="test"
    )
    db_session.add(txn)
    db_session.commit()
    db_session.refresh(txn)
    return txn

# Tests

def test_list_transactions_filtering(db_session):
    user, acc, cat = create_setup(db_session)
    
    # 1. Old Expense
    t1 = create_txn(db_session, user.id, acc.id, cat.id, 50, TransactionType.EXPENSE, date=datetime(2025, 1, 1))
    # 2. Recent Income
    t2 = create_txn(db_session, user.id, acc.id, cat.id, 100, TransactionType.INCOME, date=datetime(2025, 12, 1))
    # 3. Transfer (No category usually, but for list test it's fine)
    t3 = create_txn(db_session, user.id, acc.id, None, 20, TransactionType.TRANSFER, date=datetime(2025, 12, 2))

    # Test Filter: Date Range (Should only get t2 and t3)
    txns, count = repo.list_user_transactions(
        db_session, user.id, limit=10, offset=0, account_id=None, category_id=None, type=None,
        start=datetime(2025, 6, 1), end=datetime(2025, 12, 31)
    )
    assert count == 2
    ids = [t.id for t in txns]
    assert t2.id in ids
    assert t3.id in ids
    assert t1.id not in ids

    # Test Filter: Type (Income only)
    txns, count = repo.list_user_transactions(
        db_session, user.id, 10, 0, None, None, TransactionType.INCOME, None, None
    )
    assert count == 1
    assert txns[0].id == t2.id

def test_get_transfer_group(db_session):
    user, acc, _ = create_setup(db_session)
    
    group_id = "123e4567-e89b-12d3-a456-426614174000" # Mock UUID
    
    # Manually create two linked transactions
    t_out = Transaction(user_id=user.id, account_id=acc.id, amount=50, type=TransactionType.TRANSFER, transfer_group_id=group_id, is_outgoing=True)
    t_in = Transaction(user_id=user.id, account_id=acc.id, amount=50, type=TransactionType.TRANSFER, transfer_group_id=group_id, is_outgoing=False)
    
    db_session.add(t_out)
    db_session.add(t_in)
    db_session.commit()
    
    results = repo.get_transfer_transactions(db_session, group_id, user.id)
    assert len(results) == 2
    ids = [t.id for t in results]
    assert t_out.id in ids
    assert t_in.id in ids

def test_get_transaction_summary_sum(db_session):
    user, acc, cat = create_setup(db_session)
    
    # Add 3 expenses of 20 each = 60 total
    create_txn(db_session, user.id, acc.id, cat.id, 20, TransactionType.EXPENSE, date=datetime(2025, 11, 5))
    create_txn(db_session, user.id, acc.id, cat.id, 20, TransactionType.EXPENSE, date=datetime(2025, 11, 10))
    create_txn(db_session, user.id, acc.id, cat.id, 20, TransactionType.EXPENSE, date=datetime(2025, 11, 15))
    
    # Filter for Nov 2025
    start = datetime(2025, 11, 1)
    end = datetime(2025, 11, 30)
    
    total = repo.get_transaction_summary_for_type(db_session, TransactionType.EXPENSE, start, end, user.id)
    assert total == Decimal("60.00")

def test_get_grouped_stats(db_session):
    #Test the 'Group By' logic for the pie charts.
    user, acc, cat1 = create_setup(db_session)
    
    cat2 = Category(user_id=user.id, name="Transport", type=CategoryType.EXPENSE)
    db_session.add(cat2)
    db_session.commit()
    
    # 100 Food, 50 Transport
    create_txn(db_session, user.id, acc.id, cat1.id, 100, TransactionType.EXPENSE)
    create_txn(db_session, user.id, acc.id, cat2.id, 50, TransactionType.EXPENSE)
    
    results = repo.get_grouped_transaction_totals(db_session, user.id, Transaction.category_id)
    
    # Results is list of tuples (category_id, total_amount)
    assert len(results) == 2
    
    # Verify mapping
    res_dict = {r[0]: r[1] for r in results}
    assert res_dict[cat1.id] == 100
    assert res_dict[cat2.id] == 50
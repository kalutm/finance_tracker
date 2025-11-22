import pytest
from unittest.mock import Mock, MagicMock, call
from decimal import Decimal
from uuid import uuid4, UUID
from app.transactions.service import TransactionsService
from app.transactions.repo import TransactionRepo
from app.accounts.repo import AccountRepository
from app.models.transaction import Transaction, TransactionType
from app.models.account import Account
from app.models.category import Category
from app.transactions.schemas import TransferTransactionCreate, TransactionPatch
from app.transactions.exceptions import (
    InsufficientBalance, 
    InvalidAmount, 
    CanNotUpdateTransaction,
    InvalidTransferTransaction
)

# demo uid
uid = UUID(int=0x12345678123456781234567812345678)

# helpers
@pytest.fixture
def mock_txn_repo():
    return Mock(spec=TransactionRepo)

@pytest.fixture
def mock_acc_repo():
    return Mock(spec=AccountRepository)

@pytest.fixture
def service(mock_txn_repo, mock_acc_repo):
    return TransactionsService(mock_txn_repo, mock_acc_repo)

@pytest.fixture
def mock_session():
    return Mock()

# Tests

def test_create_expense_success(service, mock_txn_repo, mock_acc_repo, mock_session):
    user_id = uid
    # Account has 100
    mock_account = Account(id=1, balance=Decimal("100.00"))
    mock_acc_repo.get_account_for_user.return_value = mock_account
    mock_txn_repo.save_transaction.side_effect = lambda s, t: t
    
    data = {"account_id": 1, "amount": Decimal("40.00"), "type": TransactionType.EXPENSE}
    
    service.create_income_expense_transaction(mock_session, data, user_id)
    
    # Logic: Balance should decrease
    assert mock_account.balance == Decimal("60.00")
    mock_session.commit.assert_called_once()

def test_create_expense_insufficient_funds(service, mock_txn_repo, mock_acc_repo, mock_session):
    mock_account = Account(id=1, balance=Decimal("10.00"))
    mock_acc_repo.get_account_for_user.return_value = mock_account
    
    data = {"account_id": 1, "amount": Decimal("50.00"), "type": TransactionType.EXPENSE}
    
    with pytest.raises(InsufficientBalance):
        service.create_income_expense_transaction(mock_session, data, 1)
    
    # Balance should not change
    assert mock_account.balance == Decimal("10.00")

def test_create_transfer_success(service, mock_txn_repo, mock_acc_repo, mock_session):
    user_id = uid
    # Sender: 100, Receiver: 0
    sender = Account(id=1, balance=Decimal("100.00"))
    receiver = Account(id=2, balance=Decimal("0.00"))
    
    # Mock Repo to return correct account based on ID
    def get_acc(sess, id, uid):
        return sender if id == 1 else receiver
    mock_acc_repo.get_account_for_user.side_effect = get_acc
    mock_txn_repo.save_transaction = lambda s, t: t
    
    transfer_data = TransferTransactionCreate(
        account_id=1, to_account_id=2, amount=Decimal("50.00"), 
        currency="USD", description="Test", type=TransactionType.TRANSFER, occurred_at=None
    )
    
    txn_out, txn_in = service.create_transfer_transaction(mock_session, transfer_data, user_id)
    
    # Check Balances
    assert sender.balance == Decimal("50.00")
    assert receiver.balance == Decimal("50.00")
    
    # Check Transactions linked
    assert txn_out.transfer_group_id == txn_in.transfer_group_id
    assert txn_out.is_outgoing is True
    assert txn_in.is_outgoing is False
    mock_session.commit.assert_called_once()

def test_update_transaction_expense_balance_adjustment(service, mock_txn_repo, mock_acc_repo, mock_session):
    # Old: Expense 50. Account now has 50 remaining (original was 100).
    # New: Expense 80. Account should go down by another 30.
    
    old_txn = Transaction(id=1, account_id=1, amount=Decimal("50.00"), type=TransactionType.EXPENSE)
    account = Account(id=1, balance=Decimal("50.00"))
    
    mock_txn_repo.get_transaction_for_user.return_value = old_txn
    mock_acc_repo.get_account_for_user.return_value = account
    
    patch = TransactionPatch(amount=Decimal("80.00"))
    
    service.update_transaction(mock_session, patch, 1, 1)
    
    # Offset = 80 - 50 = 30.
    # Expense type: balance -= offset -> 50 - 30 = 20.
    assert account.balance == Decimal("20.00")
    assert old_txn.amount == Decimal("80.00")

def test_delete_transfer_reverts_balances(service, mock_txn_repo, mock_acc_repo, mock_session):
    group_id = uuid4()
    # Sender previously sent 50. Current Bal: 50. Should revert to 100.
    sender = Account(id=1, balance=Decimal("50.00"))
    # Receiver previously got 50. Current Bal: 50. Should revert to 0.
    receiver = Account(id=2, balance=Decimal("50.00"))
    
    t_out = Transaction(account_id=1, amount=50, is_outgoing=True)
    t_in = Transaction(account_id=2, amount=50, is_outgoing=False)
    
    mock_txn_repo.get_transfer_transactions.return_value = [t_out, t_in]
    mock_acc_repo.get_account_for_user.side_effect = lambda s, id, u: sender if id == 1 else receiver
    
    service.delete_transfer_transaction(mock_session, group_id, 1)
    
    assert sender.balance == Decimal("100.00")
    assert receiver.balance == Decimal("0.00")
    assert mock_txn_repo.delete_transaction.call_count == 2

def test_get_stats_calculation(service, mock_txn_repo, mock_acc_repo, mock_session):
    # Mock Repo returns: Cat A: 50, Cat B: 50. Total 100.
    # Expecting 50% each.
    mock_data = [(1, 50), (2, 50)] # (cat_id, total)
    mock_txn_repo.get_grouped_transaction_totals.return_value = mock_data
    
    # Mock Session get for Category names
    def get_mock(model, id):
        return Category(name="A") if id == 1 else Category(name="B")
    mock_session.get.side_effect = get_mock
    
    stats = service.get_transaction_stats(mock_session, "category", 1)
    
    assert len(stats) == 2
    assert stats[0]["percentage"] == Decimal("50.00")
    assert stats[1]["percentage"] == Decimal("50.00")
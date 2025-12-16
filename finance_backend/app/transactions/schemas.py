from pydantic import BaseModel
from decimal import Decimal
from typing import Optional, List
from uuid import UUID
from datetime import datetime
from app.models.enums import TransactionType


class TransactionOut(BaseModel):
    id: int
    account_id: int
    category_id: Optional[int] = None
    amount: Decimal
    merchant: Optional[str] = None
    currency: str
    type: TransactionType
    is_outgoing: Optional[bool] = None
    description: Optional[str] = None
    transfer_group_id: Optional[UUID] = None
    occurred_at: datetime
    created_at: datetime

    model_config = {"from_attributes": True}


class TransferTransactionsOut(BaseModel):
    outgoing_transaction: TransactionOut
    incoming_transaction: TransactionOut


class TransactionsOut(BaseModel):
    transactions: List[TransactionOut]
    total: int


class TransactionCreate(BaseModel):
    account_id: int
    category_id: Optional[int] = None
    amount: Decimal
    merchant: Optional[str] = None
    currency: str
    type: TransactionType
    description: Optional[str] = None
    occurred_at: Optional[datetime] = None
    message_id: Optional[str] = None

class BulkTransactionCreate(BaseModel):
    transactions: List[TransactionCreate]

class TransferTransactionCreate(BaseModel):
    account_id: int
    to_account_id: int
    amount: Decimal
    currency: str
    type: TransactionType
    description: Optional[str] = None
    occurred_at: Optional[datetime] = None


class TransactionPatch(BaseModel):
    category_id: Optional[int] = None
    amount: Optional[Decimal] = None
    merchant: Optional[str] = None
    description: Optional[str] = None
    occurred_at: Optional[datetime] = None


class TransactionSummaryOut(BaseModel):
    total_income: Decimal
    total_expense: Decimal
    net_savings: Decimal
    transactions_count: int


class TransactionStatsOut(BaseModel):
    name: str
    total: Decimal
    percentage: Decimal
    transaction_count: int

class TimeSeries(BaseModel):
    date: datetime
    income: Decimal
    expense: Decimal
    net: Decimal

class AccountBalance(BaseModel):
    id: int
    name: str
    balance: Decimal

class AccountBalancesOut(BaseModel):
    total_balance: Decimal
    accounts: List[AccountBalance]
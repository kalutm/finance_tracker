from pydantic import BaseModel
from decimal import Decimal
from typing import Optional, List
from uuid import UUID
from datetime import datetime
from app.models.enums import TransactionType

class TransactionOut(BaseModel):
    id: int
    account_id: int
    category_id: Optional[int]
    amount: Decimal
    merchant: Optional[str]
    currency: str
    type: TransactionType
    description: Optional[str]
    transfer_group_id: Optional[UUID]
    occurred_at: datetime
    created_at: datetime

    class Config:
        from_attributes = True

class TransactionsOut(BaseModel):
    transactions: List[TransactionOut]
    total: int

class TransactionCreate(BaseModel):
    account_id: int
    category_id: Optional[int]
    amount: Decimal
    merchant: Optional[str]
    currency: str
    type: TransactionType
    description: Optional[str]
    occurred_at: Optional[datetime]
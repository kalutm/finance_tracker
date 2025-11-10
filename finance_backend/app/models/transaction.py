from sqlmodel import SQLModel, Field
from typing import Optional
from decimal import Decimal
from sqlalchemy import Column, Numeric
from uuid import UUID
from datetime import datetime
from ..models.common import now_utc
from ..models.enums import TransactionType

class Transaction(SQLModel, table=True):
    __tablename__ = "transactions"
    id: Optional[int] = Field(default=None, primary_key=True)
    user_id: UUID = Field(nullable=False, foreign_key="users.id", index=True)
    account_id: int = Field(nullable=False, foreign_key="accounts.id", index=True)
    category_id: Optional[int] = Field(nullable=True, foreign_key="categories.id", index=True)
    amount: Decimal = Field(sa_column=Column(Numeric(18, 4), nullable=False))
    merchant: Optional[str] = Field(nullable=True)
    currency: str = Field(default="USD", nullable=False, max_length=3)
    type: TransactionType = Field(nullable=False)
    description: Optional[str] = Field(nullable=True)
    transfer_group_id: Optional[UUID] = Field(default=None, nullable=True, index=True)
    is_outgoing: Optional[bool] = Field(default=None, nullable=True)
    created_at: datetime = Field(default_factory=now_utc)
    occurred_at: datetime = Field(default_factory=now_utc, nullable=False, description="Date the transaction occurred", index=True)
    
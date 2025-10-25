from sqlmodel import SQLModel, Field, Relationship, UniqueConstraint
from decimal import Decimal
from sqlalchemy import Column, Numeric
from typing import Optional
from uuid import UUID
from datetime import datetime
from ..models.common import now_utc
from ..models.enums import AccountType

class Account(SQLModel, table=True):
    __tablename__ = "accounts"
    __table_args__ = (
        UniqueConstraint("user_id", "name", name="uq_account_user_name"),
    )

    id: Optional[int] = Field(default=None, primary_key=True)
    user_id: UUID = Field(nullable=False, foreign_key="users.id", index=True)
    balance: Decimal = Field(
        sa_column=Column(Numeric(18, 4), default=0, nullable=False),  
        default=Decimal("0.00"),
    )
    name: str = Field(nullable=False)
    type: AccountType = Field(nullable=False)
    currency: str = Field(default="USD", nullable=False, max_length=3, description="ISO 4217 code")
    active: bool = Field(default=True)
    created_at: datetime = Field(default_factory=now_utc)
    updated_at: Optional[datetime] = Field(default_factory=now_utc, sa_column=Column(onupdate=now_utc))

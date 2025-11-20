from sqlmodel import SQLModel, Field, UniqueConstraint
from decimal import Decimal
from sqlalchemy import Column, Numeric, ForeignKey
from typing import Optional
from uuid import UUID
from datetime import datetime
from ..models.common import now_utc
from ..models.enums import AccountType
import sqlalchemy as sa


class Account(SQLModel, table=True):
    __tablename__ = "accounts"
    __table_args__ = (
        UniqueConstraint("user_id", "name", name="uq_account_user_name"),
    )
    id: Optional[int] = Field(default=None, primary_key=True)
    user_id: UUID = Field(
        sa_column=Column(ForeignKey("users.id", ondelete="CASCADE"), nullable=False,  index=True)
    )
    balance: Decimal = Field(
        default=Decimal("0.00"),
        sa_column=Column(Numeric(18, 4), nullable=False)
    )
    name: str = Field(nullable=False)
    type: AccountType = Field(nullable=False)
    currency: str = Field(default="USD", nullable=False, max_length=3)
    active: bool = Field(default=True)
    created_at: datetime = Field(default_factory=now_utc)
    updated_at: datetime = Field(
        default=None,
        sa_column=Column(
            sa.DateTime, server_default=sa.func.now(), onupdate=sa.func.now()
        ),
    )

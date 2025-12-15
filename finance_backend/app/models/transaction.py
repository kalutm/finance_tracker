from sqlmodel import SQLModel, Field
from typing import Optional
from decimal import Decimal
from sqlalchemy import Column, Numeric, ForeignKey, Integer
from uuid import UUID
from datetime import datetime
from ..models.common import now_utc
from ..models.enums import TransactionType


from sqlmodel import SQLModel, Field
from sqlalchemy import Column, Integer, ForeignKey, Numeric, Index
from typing import Optional
from decimal import Decimal
from datetime import datetime

class Transaction(SQLModel, table=True):
    __tablename__ = "transactions"

    __table_args__ = (
        Index(
            "uniq_transactions_user_message",
            "user_id",
            "message_id",
            unique=True,
            postgresql_where=Column("message_id").isnot(None),
        ),
    )

    id: Optional[int] = Field(default=None, primary_key=True)

    user_id: UUID = Field(
        sa_column=Column(
            ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
            index=True,
        )
    )

    account_id: int = Field(
        sa_column=Column(
            Integer,
            ForeignKey("accounts.id", ondelete="CASCADE"),
            nullable=False,
            index=True,
        )
    )

    category_id: Optional[int] = Field(
        default=None,
        sa_column=Column(
            Integer,
            ForeignKey("categories.id", ondelete="CASCADE"),
            nullable=True,
            index=True,
        )
    )

    amount: Decimal = Field(sa_column=Column(Numeric(18, 4), nullable=False))
    merchant: Optional[str] = Field(default=None, nullable=True)
    currency: str = Field(default="USD", nullable=False, max_length=3)
    type: TransactionType = Field(nullable=False)
    description: Optional[str] = Field(default=None, nullable=True)
    transfer_group_id: Optional[UUID] = Field(default=None, nullable=True, index=True)
    is_outgoing: Optional[bool] = Field(default=None, nullable=True)

    created_at: datetime = Field(default_factory=now_utc)
    occurred_at: datetime = Field(
        default_factory=now_utc,
        nullable=False,
        index=True,
        description="Date the transaction occurred",
    )

    message_id: Optional[str] = Field(default=None, nullable=True)
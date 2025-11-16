from sqlmodel import SQLModel, Field
from typing import Optional
from decimal import Decimal
from sqlalchemy import Column, Numeric, ForeignKey, Integer
from datetime import datetime
from uuid import UUID
from ..models.common import now_utc
from ..models.enums import BudgetPeriod


class Budget(SQLModel, table=True):
    __tablename__ = "budgets"
    id: Optional[int] = Field(default=None, primary_key=True)
    user_id: UUID = Field(
        sa_column=Column(
            ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
        )
    )
    category_id: int = Field(
        sa_column=Column(
            Integer,
            ForeignKey("categories.id", ondelete="CASCADE"),
            nullable=False,
            index=True,
        ),
    )
    amount_limit: Decimal = Field(sa_column=Column(Numeric(18, 4), nullable=False))
    period: BudgetPeriod = Field(nullable=False)
    start_date: datetime = Field(nullable=False)
    end_date: Optional[datetime] = Field(default=None, nullable=True)
    created_at: datetime = Field(default_factory=now_utc)

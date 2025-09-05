from sqlmodel import SQLModel, Field
from typing import Optional
from decimal import Decimal
from sqlalchemy import Column, Numeric
from datetime import datetime
from uuid import uuid4, UUID
from ..models.common import now_utc
from ..models.enums import BudgetPeriod

class Budgets(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    user_id: UUID = Field(nullable=False, foreign_key="users.id", index=True)
    category_id: int = Field(nullable=False, foreign_key="categories.id", index=True)
    amount_limit: Decimal = Field(sa_column=Column(Numeric(18,4), nullable=False))
    period: BudgetPeriod = Field(nullable=False)
    start_date: datetime = Field(nullable=False)
    end_date: Optional[datetime] = Field(nullable=True)
    created_at: datetime = Field(default_factory=now_utc)

from sqlmodel import SQLModel, Field
from typing import Optional
from datetime import datetime

class Transactions(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    user_id: str
    account_id: int
    amount: float
    currency: str = "USD"
    category_id: Optional[int] = None
    description: Optional[str] = None
    occurred_at: datetime = Field(default_factory=datetime.now)

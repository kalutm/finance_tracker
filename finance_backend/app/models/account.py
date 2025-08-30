from sqlmodel import SQLModel, Field, Relationship
from typing import Optional
from uuid import UUID

class Account(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    user_id: UUID = Field(foreign_key="users.id")
    name: str
    type: str
    currency: str = "USD"
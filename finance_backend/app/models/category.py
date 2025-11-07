from sqlmodel import SQLModel, Field, Relationship, UniqueConstraint
from typing import Optional
from uuid import UUID
from datetime import datetime
from .common import now_utc
from .enums import CategoryType

class Category(SQLModel, table=True):
    __tablename__ = "categories"
    __table_args__ = (
        UniqueConstraint("user_id", "name", name="uq_category_user_name"),
    )

    id: Optional[int] = Field(default=None, primary_key=True)
    user_id: UUID = Field(foreign_key="users.id", nullable=False, index=True)
    name: str = Field(nullable=False)
    active: bool = Field(default=True)
    type: CategoryType = Field(nullable=False)
    created_at: datetime = Field(default_factory=now_utc)
    description: str = Field(nullable=True)
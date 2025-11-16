from sqlmodel import SQLModel, Field, UniqueConstraint
from typing import Optional
from sqlalchemy import Column, ForeignKey
from uuid import UUID
from datetime import datetime
from ..models.common import now_utc
from ..models.enums import CategoryType


class Category(SQLModel, table=True):
    __tablename__ = "categories"
    __table_args__ = (
        UniqueConstraint("user_id", "name", name="uq_category_user_name"),
    )
    id: Optional[int] = Field(default=None, primary_key=True)
    user_id: UUID = Field(
        sa_column=Column(ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    )
    name: str = Field(nullable=False)
    active: bool = Field(default=True)
    type: CategoryType = Field(nullable=False)
    created_at: datetime = Field(default_factory=now_utc)
    description: Optional[str] = Field(nullable=True)

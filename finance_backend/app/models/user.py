from sqlmodel import SQLModel, Field, Column
from typing import Optional
from datetime import datetime
from uuid import uuid4, UUID
from ..models.common import now_utc
from app.models.enums import Provider


class User(SQLModel, table=True):
    __tablename__ = "users"

    id: UUID = Field(default_factory=uuid4, primary_key=True)
    email: str = Field(nullable=False, unique=True, index=True)
    password_hash: Optional[str] = Field(nullable=True)
    provider: Provider = Field(nullable=False)
    provider_id: Optional[str] = Field(nullable=True)
    is_verified: bool = Field(default=False)
    last_verification_email: Optional[datetime] = Field(nullable=True)
    created_at: datetime = Field(default_factory=now_utc)
    updated_at: Optional[datetime] = Field(
        default_factory=now_utc,
        sa_column=Column(onupdate=now_utc)
    )

from sqlmodel import SQLModel, Field
from typing import Optional
from datetime import datetime
from uuid import uuid4, UUID
from app.models.enums import Provider 

class Users(SQLModel, table=True):
    id: UUID = Field(default_factory=uuid4, primary_key=True)
    email: str = Field(nullable=False, unique=True)
    password_hash: Optional[str] = Field(nullable=True)
    created_at: datetime = Field(default_factory=datetime.now)
    provider: Provider = Field(nullable=False)       # 'local', 'google' or 'local+google'
    provider_id: Optional[str] = Field(nullable=True)
    is_verified: bool = Field(default=False)
    last_verification_email: Optional[datetime] = Field(nullable=True)
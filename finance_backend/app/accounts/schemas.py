from pydantic import BaseModel
from app.models.account import Account
from app.models.enums import AccountType
from typing import List, Optional
from decimal import Decimal
from datetime import datetime


class AccountOut(BaseModel):
    id: int
    name: str
    type: AccountType
    currency: str
    balance: Decimal
    active: bool
    created_at: datetime

    model_config = {"from_attributes": True}
    
class AccountsOut(BaseModel):
    accounts: List[AccountOut]
    total: int


class AccountCreate(BaseModel):
    name: str
    type: AccountType
    currency: str
    
class AccountUpdate(BaseModel):
    name: Optional[str] = None
    type: Optional[AccountType] = None 

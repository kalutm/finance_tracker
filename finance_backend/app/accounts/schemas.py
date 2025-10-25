from pydantic import BaseModel
from app.models.account import Account
from app.models.enums import AccountType
from typing import List, Optional
from decimal import Decimal
from datetime import datetime

class AccountsOut(BaseModel):
    accounts: List[Account]
    total: int

class AccountCreate(BaseModel):
    name: str
    type: AccountType
    currency: str
    
class AccountUpdate(BaseModel):
    name: Optional[str] = None
    type: Optional[AccountType] = None 

class AccountOut(BaseModel):
    id: int
    name: str
    type: AccountType
    currency: str
    balance: Decimal
    active: bool
    created_at: datetime

    class Config:
        from_attributes = True
    
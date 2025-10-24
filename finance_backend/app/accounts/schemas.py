from pydantic import BaseModel
from app.models.account import Account
from typing import List
class Accounts(BaseModel):
    accounts: List[Account]

class AccountCreate(BaseModel):
    name: str
    type: str
    currency: str
    

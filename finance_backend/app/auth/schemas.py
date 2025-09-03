# migrated from models.validation_models

from pydantic import BaseModel

class TokenOut(BaseModel):
    acc_jwt: str
    ref_jwt: str
    token_type: str

class AccessTokenOut(BaseModel):
    acc_jwt: str
    token_type: str

class TokenIn(BaseModel):
    token: str

class EmailIn(BaseModel):
    email: str

class LoginIn(BaseModel):
    email: str
    password: str

class GoogleLoginIn(BaseModel):
    id_token: str

class UserCreate(BaseModel):
    email: str
    password: str

class AccountCreate(BaseModel):
    user_id: str
    name: str
    type: str
    currency: str = "USD"

class UserOut(BaseModel):
    id: str
    email: str
    is_verified: bool
    provider: str
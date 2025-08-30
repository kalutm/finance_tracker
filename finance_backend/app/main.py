from fastapi import FastAPI, Depends
from sqlmodel import select
from app.models.account import Account
from app.models.user import Users
from app.db.session import get_session, Session
from app.api.v1.auth import router as auth_route
app = FastAPI()

app.include_router(router=auth_route)

@app.get("/")
def welcome():
    return {"welcome": "welcome"}
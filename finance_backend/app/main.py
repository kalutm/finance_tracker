from fastapi import FastAPI
from app.auth.router import router as auth_route
app = FastAPI()

app.include_router(router=auth_route)

@app.get("/")
def welcome():
    return {"welcome": "welcome To Finance Tracker"}
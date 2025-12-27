from fastapi import FastAPI
from app.api.v1 import api_router
app = FastAPI(title="Finance Tracker")

app.include_router(router=api_router)

@app.get("/health")
def health():
    return {"status": "ok"}
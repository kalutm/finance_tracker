from fastapi import APIRouter
from app.api.deps import get_current_user, get_session, Depends
from app.auth.router import router as auth_router
from app.accounts.router import router as accounts_router
from app.categories.router import router as categories_router
from app.transactions.router import router as transactions_router
# import others as you implement

api_router = APIRouter(prefix="/v1", dependencies=[Depends(get_session)])

api_router.include_router(auth_router)
api_router.include_router(accounts_router)
api_router.include_router(categories_router)
api_router.include_router(transactions_router)
from pydantic import BaseModel
from app.models.enums import CategoryType
from datetime import datetime
from typing import Optional, List

class CategoryOut(BaseModel):
    id: int
    name: str
    type: CategoryType
    created_at: datetime

    model_config = {"from_attributes": True}

class CategoriesOut(BaseModel):
    categories: List[CategoryOut]
    total: int

class CategoryCreate(BaseModel):
    name: str
    type: CategoryType

class CategoryUpdate(BaseModel):
    name: Optional[str] = None
    type: Optional[CategoryType] = None

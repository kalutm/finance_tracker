from pydantic import BaseModel
from app.models.enums import CategoryType
from datetime import datetime
from typing import Optional, List

class CategoryOut(BaseModel):
    id: int
    name: str
    active: bool
    type: CategoryType
    created_at: datetime
    description: str

    model_config = {"from_attributes": True}

class CategoriesOut(BaseModel):
    categories: List[CategoryOut]
    total: int

class CategoryCreate(BaseModel):
    name: str
    type: CategoryType
    description: str

class CategoryUpdate(BaseModel):
    name: Optional[str] = None
    type: Optional[CategoryType] = None
    description: str = None

from sqlmodel import Session, select, func
from app.models.category import Category
from app.models.enums import CategoryType
from typing import List

def list_user_categories(session: Session, user_id, limit, offset, type) -> tuple[List[Category], int]:
    total_stmt = select(func.count()).select_from(Category).where(Category.user_id == user_id, True if type is None else Category.type == type)
    total = session.exec(total_stmt).one()

    query_stmt = select(Category).where(Category.user_id == user_id, True if type is None else Category.type == type).order_by(Category.created_at.desc()).limit(limit=limit).offset(offset=offset)
    categories = session.exec(query_stmt).all()

    return categories, int(total)

def get_category_for_user(session: Session, id, user_id) -> Category:
    return session.exec(select(Category).where(Category.id == id, Category.user_id == user_id)).first()

def save_category(session: Session, category: Category) -> Category:
    session.add(category)
    session.flush()
    session.refresh(category)

    return category

def delete_category(session: Session, category: Category):
    session.delete(category)
    session.flush()
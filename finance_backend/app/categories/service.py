from app.models.user import User
from app.models.category import Category
from app.categories import repo
from sqlmodel import Session
from sqlalchemy.exc import IntegrityError
from typing import Tuple, List
from app.categories.exceptions import (
    CategoryNameAlreadyTaken,
    CategoryError,
    CategoryNotFound,
)


def get_user_categories(
    session: Session, user_id, limit, offset, type, active
) -> Tuple[List[Category], int]:
    return repo.list_user_categories(session, user_id, limit, offset, type, active)


def create_category(session: Session, user_id, name, type, description) -> Category:
    category = Category(user_id=user_id, name=name, type=type, description=description)
    try:
        refreshed_category = repo.save_category(session, category)
        session.commit()
        return refreshed_category
    except IntegrityError:
        session.rollback()
        raise CategoryNameAlreadyTaken(
            "This Category name has already been taken please use another name"
        )


def get_category(session: Session, id, user_id) -> Category:
    category = repo.get_category_for_user(session, id, user_id)
    if not category:
        raise CategoryNotFound("couldnot find this category please create another one")
    return category


def update_category(session: Session, id, user_id, update_data) -> Category:
    category = repo.get_category_for_user(session, id, user_id)

    if not category:
        raise CategoryNotFound("couldnot find category")
    for field, value in update_data.items():
        if value is not None:
            setattr(category, field, value)

    try:
        refreshed_category = repo.save_category(session, category)
        session.commit()
        return refreshed_category
    except IntegrityError:
        session.rollback()
        raise CategoryNameAlreadyTaken(
            "This Category name has already been taken please use another name"
        )


def deactivate_category(session: Session, id, user_id) -> Category:
    category = repo.get_category_for_user(session, id, user_id)
    if not category:
        raise CategoryNotFound("couldnot find category")
    
    category.active = False
    deactivated_category = repo.save_category(session, category)
    session.commit()
    return deactivated_category

def restore_category(session: Session, id, user_id) -> Category:
    category = repo.get_category_for_user(session, id, user_id)
    if not category:
        raise CategoryNotFound("couldnot find category")
    
    category.active = True
    restored_category = repo.save_category(session, category)
    session.commit()
    return restored_category


def delete_category(session: Session, id, user_id):
    Category = repo.get_category_for_user(session, id, user_id)
    if not Category:
        raise CategoryNotFound("couldnot find category")
    # if repo.count_transactions_for_account(session, id) > 0:
    #     raise CategoryError("Cannot hard-delete account with transactions. Consider deactivating.")
    repo.delete_category(session, Category)
    session.commit()

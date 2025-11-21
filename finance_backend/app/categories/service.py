from fastapi import Depends
from app.models.category import Category
from app.categories.repo import CategoriesRepo, get_category_repo
from sqlmodel import Session
from sqlalchemy.exc import IntegrityError
from typing import Tuple, List
from app.categories.exceptions import (
    CategoryNameAlreadyTaken,
    CategoryError,
    CategoryNotFound,
    CouldnotDeleteCategory
)

class CategoriesService():
    def __init__(self, repo: CategoriesRepo):
        self.repo = repo

    def get_user_categories(
        self, session: Session, user_id, limit, offset, type, active
    ) -> Tuple[List[Category], int]:
        return self.repo.list_user_categories(session, user_id, limit, offset, type, active)


    def create_category(self, session: Session, user_id, name, type, description) -> Category:
        category = Category(user_id=user_id, name=name, type=type, description=description)
        try:
            refreshed_category = self.repo.save_category(session, category)
            session.commit()
            return refreshed_category
        except IntegrityError:
            session.rollback()
            raise CategoryNameAlreadyTaken(
                "This Category name has already been taken please use another name"
            )


    def get_category(self, session: Session, id, user_id) -> Category:
        category = self.repo.get_category_for_user(session, id, user_id)
        if not category:
            raise CategoryNotFound("couldnot find this category please create another one")
        return category


    def update_category(self, session: Session, id, user_id, update_data) -> Category:
        category = self.repo.get_category_for_user(session, id, user_id)

        if not category:
            raise CategoryNotFound("couldnot find category")
        for field, value in update_data.items():
            if value is not None:
                setattr(category, field, value)

        try:
            refreshed_category = self.repo.save_category(session, category)
            session.commit()
            return refreshed_category
        except IntegrityError:
            session.rollback()
            raise CategoryNameAlreadyTaken(
                "This Category name has already been taken please use another name"
            )


    def deactivate_category(self, session: Session, id, user_id) -> Category:
        category = self.repo.get_category_for_user(session, id, user_id)
        if not category:
            raise CategoryNotFound("couldnot find category")
        
        category.active = False
        deactivated_category = self.repo.save_category(session, category)
        session.commit()
        return deactivated_category

    def restore_category(self, session: Session, id, user_id) -> Category:
        category = self.repo.get_category_for_user(session, id, user_id)
        if not category:
            raise CategoryNotFound("couldnot find category")
        
        category.active = True
        restored_category = self.repo.save_category(session, category)
        session.commit()
        return restored_category


    def delete_category(self, session: Session, id, user_id):
        Category = self.repo.get_category_for_user(session, id, user_id)
        if not Category:
            raise CategoryNotFound("couldnot find category")
        if self.repo.count_transactions_for_categories(session, id) > 0:
            raise CouldnotDeleteCategory("Cannot hard-delete category with transactions. Consider deactivating.")
        self.repo.delete_category(session, Category)
        session.commit()

# Fast Api Dependency provider
def get_categories_service(repo: CategoriesRepo = Depends(get_category_repo)) -> CategoriesService:
    return CategoriesService(repo)
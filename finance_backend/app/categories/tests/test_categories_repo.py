import pytest
from app.categories.repo import CategoriesRepo
from app.models.category import Category
from app.models.user import User
from app.models.enums import CategoryType
from app.tests.conftest import db_session, create_test_user, create_test_database

# no layer below so nothing to mock just instanciate the repo
repo = CategoriesRepo()

def create_category_db(session, user_id, name, type=CategoryType.EXPENSE, active=True):
    cat = Category(user_id=user_id, name=name, type=type, active=active, description="desc")
    session.add(cat)
    session.commit()
    session.refresh(cat)
    return cat



def test_create_and_get_category(db_session):
    user = create_test_user(db_session)

    # Test Save
    new_cat = Category(user_id=user.id, name="Groceries", type=CategoryType.EXPENSE, description="Food")
    saved = repo.save_category(db_session, new_cat)
    db_session.commit()
    
    assert saved.id is not None
    assert saved.name == "Groceries"

    # Test Get
    fetched = repo.get_category_for_user(db_session, saved.id, user.id)
    assert fetched is not None
    assert fetched.id == saved.id

def test_get_category_isolation(db_session):
    # Ensure User A cannot fetch User B's category.

    user_a = create_test_user(db_session, "a@test.com")
    user_b = create_test_user(db_session, "b@test.com")
    
    cat_a = create_category_db(db_session, user_a.id, "User A Cat")
    
    # User B tries to get User A's category
    fetched = repo.get_category_for_user(db_session, cat_a.id, user_b.id)
    assert fetched is None

def test_list_categories_filters(db_session):
    # Thoroughly test the filtering logic (Type and Active status).

    user = create_test_user(db_session)
    
    # Setup Data:
    # 1. Active Expense
    c1 = create_category_db(db_session, user.id, "Food", CategoryType.EXPENSE, True)
    # 2. Active Income
    c2 = create_category_db(db_session, user.id, "Salary", CategoryType.INCOME, True)
    # 3. Inactive Expense
    c3 = create_category_db(db_session, user.id, "Old Rent", CategoryType.EXPENSE, False)
    
    # Get All (No filters) - Should return all categories regardles off their type and activeness
    
    cats, total = repo.list_user_categories(db_session, user.id, 10, 0, None, None)
    assert total == 3
    names = [c.name for c in cats]
    assert "Food" in names
    assert "Old Rent" in names
    assert "Salary" in names
    
    # Filter: Type=EXPENSE, Active=None (All)
    cats, total = repo.list_user_categories(db_session, user.id, 10, 0, type=CategoryType.EXPENSE, active=None)
    assert total == 2
    names = [c.name for c in cats]
    assert "Food" in names
    assert "Old Rent" in names
    assert "Salary" not in names

    # Filter: Type=None, Active=True (Only Active)
    cats, total = repo.list_user_categories(db_session, user.id, 10, 0, type=None, active=True)
    assert total == 2
    names = [c.name for c in cats]
    assert "Food" in names
    assert "Salary" in names
    assert "Old Rent" not in names

    # Filter: Type=INCOME, Active=True
    cats, total = repo.list_user_categories(db_session, user.id, 10, 0, type=CategoryType.INCOME, active=True)
    assert total == 1
    assert cats[0].name == "Salary"

def test_list_pagination(db_session):

    user = create_test_user(db_session)
    
    # Create 15 categories
    for i in range(15):
        create_category_db(db_session, user.id, f"Cat {i}")
        
    # Page 1: Limit 5
    cats, total = repo.list_user_categories(db_session, user.id, limit=5, offset=0, type=None, active=None)
    assert total == 15
    assert len(cats) == 5
    
    # Page 2: Offset 5
    cats_p2, _ = repo.list_user_categories(db_session, user.id, limit=5, offset=5, type=None, active=None)
    assert len(cats_p2) == 5
    assert cats[0].id != cats_p2[0].id

def test_delete_category(db_session):

    user = create_test_user(db_session)
    cat = create_category_db(db_session, user.id, "To Delete")
    
    repo.delete_category(db_session, cat)
    db_session.commit()
    
    assert repo.get_category_for_user(db_session, cat.id, user.id) is None
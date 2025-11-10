from fastapi import APIRouter, Depends, Path, Query, HTTPException, status
from app.api.deps import get_current_user, get_session
from app.models.enums import CategoryType
from app.categories import service
from sqlmodel import Session
from app.categories.schemas import CategoryCreate, CategoryOut, CategoriesOut, CategoryUpdate
from typing import Annotated, Optional

router = APIRouter(prefix="/categories", tags=["category"])

@router.get("/", response_model=CategoriesOut)
def get_user_categories(
    limit: int = Query(
        50, ge=1, le=500, title="limit", description="amount of result per page"
    ),
    offset: int = Query(
        0, ge=0, title="offset", description="position compared to 0th result"
    ),
    active: Optional[bool] = Query(
        None,
        title="active",
        description="describes if the category is deleted or not (can be Undone)",
    ),
    type: Optional[CategoryType] = Query(
        None, title="Category Type", description="Type of the category i.e INCOME, EXPENSE or BOTH"
    ),
    session: Session = Depends(get_session),
    current_user: service.User = Depends(get_current_user)
):
    categories, total = service.get_user_categories(session, current_user.id, limit, offset, type, active)

    category_outs = []
    for category in categories:
        category_outs.append(CategoryOut.model_validate(category))

    categories_out = CategoriesOut(categories=category_outs, total=total)
    return categories_out

@router.post("/", response_model=CategoryOut, status_code=status.HTTP_201_CREATED)
def create_category(
    category_data: CategoryCreate,
    session: Session = Depends(get_session),
    current_user: service.User = Depends(get_current_user)
    ):
    try:
        category = service.create_category(
            session,
            current_user.id,
            **category_data.model_dump()
        )
        category_out = CategoryOut.model_validate(category)
        return category_out

    except service.CategoryNameAlreadyTaken as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
    
@router.get("/{id}", response_model=CategoryOut)
def get_category(
    id: Annotated[
        int,
        Path(
            title="Category-id",
            description="The id of a Category",
            ge=1,
            examples=[1, 2, 3, 4, 5, 6, 7],
        ),
    ],
    session: Session = Depends(get_session),
    current_user: service.User = Depends(get_current_user)
):
    try:
        category = service.get_category(session, id, current_user.id)
        category_out = CategoryOut.model_validate(category)
        return category_out
    except service.CategoryNotFound as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))

@router.patch("/{id}", response_model=CategoryOut)
def update_category(
    id: Annotated[
        int,
        Path(
            title="Category-id",
            description="The id of a Category",
            ge=1,
            examples=[1, 2, 3, 4, 5, 6, 7],
        ),
    ],
    category_data: CategoryUpdate,
    session: Session = Depends(get_session),
    current_user: service.User = Depends(get_current_user)
):
    try:
        update_data = category_data.model_dump(exclude_unset=True)
        updated_category = service.update_category(session, id, current_user.id, update_data)
        
        category_out = CategoryOut.model_validate(updated_category)
        return category_out
    except service.CategoryNameAlreadyTaken as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
    except service.CategoryNotFound as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))


@router.patch(
    "/{id}/deactivate", response_model=CategoryOut, status_code=status.HTTP_200_OK
)
def deactivate_category(
    id: Annotated[
        int,
        Path(
            title="Category-id",
            description="The id of a Category",
            ge=1,
            examples=[1, 2, 3, 4, 5, 6, 7],
        ),
    ],
    session: Session = Depends(get_session),
    current_user: service.User = Depends(get_current_user),
):
    try:
        deactivated_category = service.deactivate_category(session, id, current_user.id)
        category_out = CategoryOut.model_validate(deactivated_category)
        return category_out
    except service.CategoryNotFound as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))


@router.patch("/{id}/restore", response_model=CategoryOut)
def restore_category(
    id: Annotated[
        int,
        Path(
            title="Category-id",
            description="The id of a Category",
            ge=1,
            examples=[1, 2, 3, 4, 5, 6, 7],
        ),
    ],
    session: Session = Depends(get_session),
    current_user: service.User = Depends(get_current_user),
):

    try:
        restored_category = service.restore_category(session, id, current_user.id)
        category_out = CategoryOut.model_validate(restored_category)
        return category_out
    except service.CategoryNotFound as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))
    

@router.delete("/{id}", response_model=None, status_code=status.HTTP_204_NO_CONTENT)
def delete_category(
    id: Annotated[
        int,
        Path(
            title="Category-id",
            description="The id of a Category",
            ge=1,
            exampes=[1, 2, 3, 4, 5, 6, 7],
        ),
    ],
    session: Session = Depends(get_session),
    current_user: service.User = Depends(get_current_user)
):
    try:
        service.delete_category(session, id, current_user.id)
    except service.CategoryNotFound as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))
    except service.CouldnotDeleteCategory as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
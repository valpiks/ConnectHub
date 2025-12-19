from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.core.dependencies import get_current_user
from app.models.user import User
from app.services.admin import AdminService
from app.schemas.common import MessageResponse
from app.schemas.tag import AdminTagCreateResponse, AdminTagModerateResponse


router = APIRouter(prefix="/api/admin/tags", tags=["Admin - Tags"])


@router.post("/tags", response_model=AdminTagCreateResponse, status_code=status.HTTP_201_CREATED)
def create_tag(
    name: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Создать новый тег (только для админов).
    """
    service = AdminService(db)
    return service.create_tag(current_user, name)


@router.delete("/tags/{tag_id}", response_model=MessageResponse, status_code=status.HTTP_200_OK)
def delete_tag(
    tag_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Удалить тег (только для админов).
    """
    service = AdminService(db)
    return service.delete_tag(current_user, tag_id)


@router.post("/moderation", response_model=AdminTagModerateResponse, status_code=status.HTTP_200_OK)
def moderate_tag(
    tag_id: int,
    action: str,  # "approve" or "reject"
    comment: str = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Модерация тега (только для админов).
    """
    service = AdminService(db)
    return service.moderate_tag(current_user, tag_id, action, comment)

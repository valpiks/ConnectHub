from fastapi import APIRouter, Depends, UploadFile, File
from sqlalchemy.orm import Session

from app.database import get_db
from app.core.dependencies import get_current_user
from app.models.user import User
from app.services.file import FileService
from app.schemas.common import MessageResponse
from app.schemas.file_responses import FileUploadResponse, FileUrlResponse


router = APIRouter(prefix="/api/files", tags=["Files"])


@router.post("/profile/avatar", response_model=FileUploadResponse)
async def upload_profile_avatar(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Загрузить аватар профиля.
    Автоматически обновляет avatar_url пользователя.
    """
    service = FileService(db)
    return await service.upload_profile_avatar(current_user, file)


@router.delete("/profile/avatar", response_model=MessageResponse)
def delete_profile_avatar(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Удалить аватар профиля.
    """
    service = FileService(db)
    return service.delete_profile_avatar(current_user)


@router.post("/events/{event_id}/image", response_model=FileUploadResponse)
async def upload_event_image(
    event_id: str,
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Загрузить изображение мероприятия.
    Только владелец мероприятия может загружать изображения.
    """
    service = FileService(db)
    return await service.upload_event_image(current_user, event_id, file)


@router.delete("/events/{event_id}/image", response_model=MessageResponse)
def delete_event_image(
    event_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Удалить изображение мероприятия.
    """
    service = FileService(db)
    return service.delete_event_image(current_user, event_id)


@router.get("/{file_path:path}")
def get_file(file_path: str, db: Session = Depends(get_db)):
    """
    Получить файл (просмотр inline).
    """
    # Note: Using db just to init service, though minio get might not need DB, 
    # but BaseService requires it.
    service = FileService(db)
    return service.get_file(file_path)


@router.get("/url/{file_path:path}", response_model=FileUrlResponse)
def get_file_url(file_path: str, db: Session = Depends(get_db)):
    """
    Получить presigned URL файла.
    """
    service = FileService(db)
    return service.get_file_url(file_path)

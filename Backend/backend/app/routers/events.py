from typing import Optional

from fastapi import APIRouter, Depends, status, Query
from sqlalchemy.orm import Session

from app.database import get_db
from app.core.dependencies import get_current_user
from app.models.user import User
from app.schemas.event import (
    EventCreateRequest,
    EventEditRequest,
    EventInfoResponse,
    SearchEventInfoResponse,
    AddUsersRequest,
    EventCreateResponse,
)
from app.schemas.tag import AddTagsRequest, RemoveTagsRequest
from app.schemas.common import MessageResponse
from app.services.event import EventService


router = APIRouter(prefix="/api/events", tags=["Events"])


@router.post("/", response_model=EventCreateResponse, status_code=status.HTTP_201_CREATED)
def create_event(
    request: EventCreateRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Создать мероприятие.
    """
    service = EventService(db)
    return service.create_event(current_user, request)


@router.put("/{event_id}/edit", response_model=EventInfoResponse, status_code=status.HTTP_200_OK)
def edit_event(
    event_id: str,
    request: EventEditRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Редактировать мероприятие.
    """
    service = EventService(db)
    return service.edit_event(current_user, event_id, request)


@router.delete("/{event_id}/remove", response_model=MessageResponse, status_code=status.HTTP_200_OK)
def delete_event(
    event_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Удалить мероприятие.
    """
    service = EventService(db)
    return service.delete_event(current_user, event_id)


@router.post("/{event_id}/tags", response_model=EventInfoResponse, status_code=status.HTTP_200_OK)
def add_tags_to_event(
    event_id: str,
    request: AddTagsRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Добавить теги к мероприятию.
    """
    service = EventService(db)
    return service.add_tags_to_event(current_user, event_id, request)


@router.post("/{event_id}/users", response_model=MessageResponse, status_code=status.HTTP_200_OK)
def add_users_to_event(
    event_id: str,
    request: AddUsersRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Добавить пользователей к мероприятию.
    """
    service = EventService(db)
    return service.add_users_to_event(current_user, event_id, request)


@router.post("/{event_id}/add", response_model=MessageResponse, status_code=status.HTTP_200_OK)
def join_event(
    event_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Присоединиться к мероприятию.
    """
    service = EventService(db)
    return service.join_event(current_user, event_id)


@router.delete("/{event_id}/tags", response_model=EventInfoResponse)
def remove_tags_from_event(
    event_id: str,
    request: RemoveTagsRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    service = EventService(db)
    return service.remove_tags_from_event(current_user, event_id, request.tag_ids)


@router.post("/{event_id}/leave", response_model=MessageResponse, status_code=status.HTTP_200_OK)
def leave_event(
    event_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Выйти из события (удалить себя из участников).
    """
    service = EventService(db)
    return service.leave_event(current_user, event_id)


@router.get("/friends", response_model=SearchEventInfoResponse)
def get_friend_events(
    text: Optional[str] = None,
    offset: int = Query(0, ge=0),
    limit: int = Query(10, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Получить события, в которых участвуют или являются организаторами друзья текущего пользователя.
    В списках participants и owners у тех, кто является другом, поле isFriend = true.
    """
    service = EventService(db)
    return service.get_friend_events(current_user, text, offset, limit)


@router.get("/{event_id}/info", response_model=EventInfoResponse)
def get_event_info(event_id: str, db: Session = Depends(get_db)):
    """
    Получить информацию о мероприятии.
    """
    service = EventService(db)
    return service.get_event_info(event_id)


@router.get("/recommendation", response_model=SearchEventInfoResponse)
def get_event_recommendations(
    text: Optional[str] = None,
    offset: int = Query(0, ge=0),
    limit: int = Query(10, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Получить рекомендации мероприятий.
    """
    service = EventService(db)
    return service.get_event_recommendations(current_user, text, offset, limit)


@router.post("/{event_id}/cancel", response_model=MessageResponse, status_code=status.HTTP_200_OK)
def cancel_event(
    event_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Скрыть ивент из подборки (cancel).
    """
    service = EventService(db)
    return service.cancel_event_for_user(current_user, event_id)


@router.get("/search", response_model=SearchEventInfoResponse)
def search_events(
    text: Optional[str] = None,
    tags: Optional[str] = None,  # Comma-separated tags
    offset: int = Query(0, ge=0),
    limit: int = Query(10, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Поиск мероприятий.
    """
    service = EventService(db)
    return service.search_events(current_user, text, tags, offset, limit)

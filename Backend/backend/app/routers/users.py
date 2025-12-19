from typing import Optional

from fastapi import APIRouter, Depends, status, Query
from sqlalchemy.orm import Session

from app.database import get_db
from app.core.dependencies import get_current_user
from app.models.user import User
from app.models.enums import FriendStatus
from app.schemas.user import (
    ProfileResponse,
    OtherProfileResponse,
    EditRequest,
    UserIdRequest,
    SearchResponse,
    FriendsResponse,
    FriendRequestsResponse
)
from app.schemas.tag import AddTagsRequest, UserTagsResponse
from app.schemas.event import SearchEventInfoResponse
from app.services.user import UserService
from app.schemas.common import MessageResponse


router = APIRouter(prefix="/api/users", tags=["Users"])


@router.get("/profile", response_model=ProfileResponse)
def get_profile(
    current_user: User = Depends(get_current_user), db: Session = Depends(get_db)
):
    """
    Получить профиль текущего пользователя.
    """
    service = UserService(db)
    return service.get_profile(current_user)


@router.put("/edit", response_model=ProfileResponse)
def edit_profile(
    request: EditRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Изменить информацию текущего пользователя.
    """
    service = UserService(db)
    return service.edit_profile(current_user, request)


@router.get("/profile/{uuid}", response_model=OtherProfileResponse)
def get_profile_by_uuid(uuid: str, db: Session = Depends(get_db)):
    """
    Получить профиль пользователя по UUID.
    """
    service = UserService(db)
    return service.get_profile_by_uuid(uuid)


@router.get("/events", response_model=SearchEventInfoResponse)
def get_user_events(
    text: Optional[str] = None,
    offset: int = Query(0, ge=0),
    limit: int = Query(10, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Получить события пользователя.
    """
    service = UserService(db)
    return service.get_user_events(current_user, text, offset, limit)


@router.get("/friends", response_model=FriendsResponse)
def get_friends(
    text: Optional[str] = None,
    offset: int = Query(0, ge=0),
    limit: int = Query(10, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Получить друзей пользователя.
    """
    service = UserService(db)
    return service.get_friends(current_user, text, offset, limit)


@router.get("/friend-requests", response_model=FriendRequestsResponse)
def get_friend_requests(
    text: Optional[str] = None,
    offset: int = Query(0, ge=0),
    limit: int = Query(10, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Получить входящие запросы в друзья.
    """
    service = UserService(db)
    return service.get_friend_requests(current_user, text, offset, limit)


@router.post("/friends/remove", response_model=MessageResponse, status_code=status.HTTP_200_OK)
def remove_friend(
    request: UserIdRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Удалить пользователя из друзей.
    """
    service = UserService(db)
    return service.remove_friend(current_user, request.id)


@router.get("/recommendation", response_model=SearchResponse)
def get_recommendations(
    text: Optional[str] = None,
    offset: int = Query(0, ge=0),
    limit: int = Query(10, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Поиск пользователей по рекомендациям (на основе seeking_tags).
    """
    service = UserService(db)
    return service.get_recommendations(current_user, text, offset, limit)


@router.post("/cancel", response_model=MessageResponse, status_code=status.HTTP_200_OK)
def cancel_user(
    request: UserIdRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Скрыть пользователя из подборки (cancel).
    """
    service = UserService(db)
    return service.cancel_user(current_user, request.id)


@router.get("/search", response_model=SearchResponse)
def search_users(
    text: Optional[str] = None,
    tags: Optional[str] = None,  # Comma-separated tags
    offset: int = Query(0, ge=0),
    limit: int = Query(10, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Поиск пользователей по тексту и тегам.
    """
    service = UserService(db)
    return service.search_users(current_user, text, tags, offset, limit)


@router.post("/match", response_model=MessageResponse, status_code=status.HTTP_200_OK)
def match_user(
    request: UserIdRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Отправить запрос на добавление в друзья.
    """
    service = UserService(db)
    return service.match_user(current_user, request.id)


@router.post("/match-confirmation", response_model=MessageResponse, status_code=status.HTTP_200_OK)
def match_confirmation(
    request: UserIdRequest,
    friend_status: FriendStatus = Query(..., alias="status"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Принять или отклонить запрос в друзья.
    """
    service = UserService(db)
    return service.match_confirmation(current_user, request.id, friend_status)


# ========== User Tags Endpoints ==========


@router.get("/tags/", response_model=UserTagsResponse)
def get_user_tags(
    type: str = Query("ALL", description="ALL, OWN, or SEEKING"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Получить теги пользователя.
    """
    service = UserService(db)
    return service.get_user_tags(current_user, type)


@router.post("/tags/add", response_model=MessageResponse, status_code=status.HTTP_200_OK)
def add_user_tags(
    request: AddTagsRequest,
    type: str = Query("OWN", description="OWN or SEEKING"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Добавить теги пользователю.
    """
    service = UserService(db)
    return service.add_user_tags(current_user, request.tags, type)


@router.delete("/tags/remove/{tag_id}", response_model=MessageResponse, status_code=status.HTTP_200_OK)
def remove_user_tag(
    tag_id: int,
    type: str = Query("OWN", description="OWN or SEEKING"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Удалить тег у пользователя.
    """
    service = UserService(db)
    return service.remove_user_tag(current_user, tag_id, type)

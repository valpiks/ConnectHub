from uuid import UUID
from typing import Optional, List
from datetime import datetime
from app.models.friendship import Friendship
from sqlalchemy import or_
from app.models.event_skip import EventSkip
from app.models.event import Event
from app.models.user import User
from app.models.tag import Tag
from app.models.enums import EventStatus, FriendStatus, TagStatus, UserRole
from app.schemas.event import (
    EventCreateRequest,
    EventEditRequest,
    EventInfoResponse,
    SearchEventInfoResponse,
    AddUsersRequest,
)
from app.schemas.tag import AddTagsRequest, TagInfo
from app.schemas.user import OtherProfileResponse, BasicUserInfo
from fastapi import HTTPException, status
from app.core.exceptions import ForbiddenError, EventNotFoundError, InvalidUUIDError
from app.services.base import BaseService
from app.services.tag_util import get_or_create_tag, delete_tag_if_unused


class EventService(BaseService):
    def _user_to_other_profile(self, user: User) -> OtherProfileResponse:
        return OtherProfileResponse(
            uuid=user.uuid,
            tag=user.tag,
            name=user.name,
            role=user.role,
            status=user.status,
            city=user.city,
            institution=user.institution,
            specialization=user.specialization,
            bio=user.bio,
            avatar_url=user.avatar_url,
            created_at=user.created_at,
            own_tags=[
                TagInfo(id=t.id, name=t.name)
                for t in user.own_tags
            ],
            seeking_tags=[
                TagInfo(id=t.id, name=t.name)
                for t in user.seeking_tags
            ],
        )

    def _user_to_basic_info(self, user: User, is_friend: bool = False) -> BasicUserInfo:
        return BasicUserInfo(
            uuid=user.uuid,
            tag=user.tag,
            name=user.name,
            avatar_url=user.avatar_url,
            is_friend=is_friend,
        )

    def _event_to_response(self, event: Event) -> EventInfoResponse:
        return EventInfoResponse(
            id=event.id,
            title=event.title,
            description=event.description,
            venue=event.venue,
            category=event.category,
            max_users_count=event.max_users_count,
            start_date=event.start_date,
            end_date=event.end_date,
            status=event.status,
            image_url=event.image_url,
            tags=[
                TagInfo(id=t.id, name=t.name, description=t.description)
                for t in event.tags
            ],
            participants=[self._user_to_basic_info(u) for u in event.participants],
            owners=[self._user_to_basic_info(u) for u in event.owners],
            prize=event.prize_fund,
        )

    def create_event(self, current_user: User, request: EventCreateRequest):
        event = Event(
            title=request.title,
            description=request.description,
            venue=request.venue,
            category=request.category,
            max_users_count=request.max_users_count,
            start_date=request.start_date,
            end_date=request.end_date,
            created_at=datetime.utcnow(),
            prize_fund=request.prize,
        )
        event.owners.append(current_user)

        self.db.add(event)
        self.db.commit()
        self.db.refresh(event)

        return {"message": "Мероприятие создано", "id": str(event.id)}

    def edit_event(
        self, current_user: User, event_id: str, request: EventEditRequest
    ) -> EventInfoResponse:
        try:
            uuid = UUID(event_id)
        except ValueError:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST, detail="Неверный формат ID"
            )

        event = self.db.query(Event).filter(Event.id == uuid).first()
        if not event:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, detail="Мероприятие не найдено"
            )

        if current_user not in event.owners:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Нет прав на редактирование",
            )

        if request.title is not None:
            event.title = request.title
        if request.description is not None:
            event.description = request.description
        if request.venue is not None:
            event.venue = request.venue
        if request.category is not None:
            event.category = request.category
        if request.max_users_count is not None:
            event.max_users_count = request.max_users_count
        if request.start_date is not None:
            event.start_date = request.start_date
        if request.end_date is not None:
            event.end_date = request.end_date
        if request.prize is not None:
            event.prize_fund = request.prize

        self.db.commit()
        return self._event_to_response(event)

    def delete_event(self, current_user: User, event_id: str):
        try:
            uuid = UUID(event_id)
        except ValueError:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST, detail="Неверный формат ID"
            )

        event: Event = self.db.query(Event).filter(Event.id == uuid).first()
        if not event:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, detail="Мероприятие не найдено"
            )

        if current_user not in event.owners:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN, detail="Нет прав на удаление"
            )

        if event.start_date > datetime.now():
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Нельзя удалить или закрыть событие которое уже идет",
            )

        if event.participants and event.start_date < datetime.now():
            event.status = EventStatus.CANCELLED
        else:
            self.db.delete(event)

        self.db.commit()
        return {"message": "Мероприятие удалено"}

    def add_tags_to_event(
        self, current_user: User, event_id: str, request: AddTagsRequest
    ) -> EventInfoResponse:
        try:
            uuid = UUID(event_id)
        except ValueError:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST, detail="Неверный формат ID"
            )

        event = self.db.query(Event).filter(Event.id == uuid).first()
        if not event:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, detail="Мероприятие не найдено"
            )

        if current_user not in event.owners:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Нет прав на редактирование",
            )

        for tag_name in request.tags:
            tag = get_or_create_tag(self.db, current_user, tag_name)
            if tag not in event.tags:
                event.tags.append(tag)

        self.db.commit()
        return self._event_to_response(event)
    

    def add_users_to_event(
        self, current_user: User, event_id: str, request: AddUsersRequest
    ):
        try:
            uuid = UUID(event_id)
        except ValueError:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST, detail="Неверный формат ID"
            )

        event = self.db.query(Event).filter(Event.id == uuid).first()
        if not event:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, detail="Мероприятие не найдено"
            )

        if current_user not in event.owners:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Нет прав на редактирование",
            )

        for user_id in request.user_ids:
            try:
                user_uuid = UUID(user_id)
            except ValueError:
                continue

            user = self.db.query(User).filter(User.uuid == user_uuid).first()
            if user and user not in event.participants:
                event.participants.append(user)

        self.db.commit()
        return {"message": "Пользователи добавлены"}

    def join_event(self, current_user: User, event_id: str):
        try:
            uuid = UUID(event_id)
        except ValueError:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST, detail="Неверный формат ID"
            )

        event = self.db.query(Event).filter(Event.id == uuid).first()
        if not event:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, detail="Мероприятие не найдено"
            )

        if (
            event.max_users_count > 0
            and len(event.participants) >= event.max_users_count
        ):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Максимальное количество участников достигнуто",
            )

        if current_user not in event.participants:
            event.participants.append(current_user)
            self.db.commit()

        return {"message": "Вы присоединились к мероприятию"}

    def get_event_info(self, event_id: str) -> EventInfoResponse:
        try:
            uuid = UUID(event_id)
        except ValueError:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST, detail="Неверный формат ID"
            )

        event = self.db.query(Event).filter(Event.id == uuid).first()
        if not event:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, detail="Мероприятие не найдено"
            )

        return self._event_to_response(event)


    def get_friend_events(
            self,
            current_user: User,
            text: Optional[str],
            offset: int,
            limit: int,
        ) -> SearchEventInfoResponse:
            # 1. Ищем друзей (ACCEPTED)
            friendships = (
                self.db.query(Friendship)
                .filter(
                    or_(
                        Friendship.user_id == current_user.uuid,
                        Friendship.friend_id == current_user.uuid,
                    ),
                    Friendship.status == FriendStatus.ACCEPTED,
                )
                .all()
            )
            friend_ids = {
                f.friend_id if f.user_id == current_user.uuid else f.user_id
                for f in friendships
            }
            if not friend_ids:
                return SearchEventInfoResponse(events=[])

            # 2. События, где в участниках или владельцах есть друзья
            query = self.db.query(Event).filter(
                or_(
                    Event.participants.any(User.uuid.in_(friend_ids)),
                    Event.owners.any(User.uuid.in_(friend_ids)),
                )
            )

            # опционально можно ограничить статусами PLANNED/ACTIVE, если нужно
            # query = query.filter(Event.status.in_([EventStatus.PLANNED, EventStatus.ACTIVE]))

            if text:
                query = query.filter(
                    or_(
                        Event.title.ilike(f"%{text}%"),
                        Event.description.ilike(f"%{text}%"),
                    )
                )

            events = query.offset(offset).limit(limit).all()

            # 3. Собираем EventInfoResponse и отмечаем друзей
            result = []
            for event in events:
                result.append(
                    EventInfoResponse(
                        id=event.id,
                        title=event.title,
                        description=event.description,
                        venue=event.venue,
                        category=event.category,
                        max_users_count=event.max_users_count,
                        start_date=event.start_date,
                        end_date=event.end_date,
                        status=event.status,
                        image_url=event.image_url,
                        prize=event.prize_fund,
                        tags=[TagInfo(id=t.id, name=t.name) for t in event.tags],
                        participants=[
                            self._user_to_basic_info(
                                u,
                                is_friend=(u.uuid in friend_ids),
                            )
                            for u in event.participants
                        ],
                        owners=[
                            self._user_to_basic_info(
                                u,
                                is_friend=(u.uuid in friend_ids),
                            )
                            for u in event.owners
                        ],
                    )
                )

            return SearchEventInfoResponse(events=result)

    def get_event_recommendations(
        self, current_user: User, text: Optional[str], offset: int, limit: int
    ) -> SearchEventInfoResponse:
        query = self.db.query(Event)

        query = query.filter(
            ~Event.owners.any(User.uuid == current_user.uuid),
            ~Event.participants.any(User.uuid == current_user.uuid),
        )

        from app.models.enums import EventStatus

        query = query.filter(
            Event.status.in_([EventStatus.PLANNED, EventStatus.ACTIVE])
        )

        from app.models.event_skip import EventSkip

        skip_subq = (
            self.db.query(EventSkip.event_id)
            .filter(EventSkip.user_id == current_user.uuid)
            .subquery()
        )
        query = query.filter(~Event.id.in_(skip_subq))

        if text:
            query = query.filter(
                or_(
                    Event.title.ilike(f"%{text}%"), Event.description.ilike(f"%{text}%")
                )
            )

        seeking_tag_names = [t.name for t in current_user.seeking_tags]
        if seeking_tag_names:
            query = query.filter(Event.tags.any(Tag.name.in_(seeking_tag_names)))

        events = query.all()
        scored = sorted(
            events,
            key=lambda e: self._event_match_score(current_user, e),
            reverse=True,
        )
        page = scored[offset : offset + limit]
        return SearchEventInfoResponse(
            events=[self._event_to_response(e) for e in page],
        )

    def search_events(
        self,
        current_user: User,
        text: Optional[str],
        tags: Optional[str],
        offset: int,
        limit: int,
    ) -> SearchEventInfoResponse:
        query = self.db.query(Event)
        query = query.filter(
            ~Event.owners.any(User.uuid == current_user.uuid),
            ~Event.participants.any(User.uuid == current_user.uuid),
        )

        if text:
            query = query.filter(
                or_(
                    Event.title.ilike(f"%{text}%"), Event.description.ilike(f"%{text}%")
                )
            )

        if tags:
            tag_list = [t.strip() for t in tags.split(",") if t.strip()]
            if tag_list:
                query = query.filter(Event.tags.any(Tag.name.in_(tag_list)))

        events = query.offset(offset).limit(limit).all()

        return SearchEventInfoResponse(
            events=[self._event_to_response(e) for e in events]
        )

    def cancel_event_for_user(self, current_user: User, event_id: str):
        try:
            uuid = UUID(event_id)
        except ValueError:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Неверный ID",
            )

        event = self.db.query(Event).filter(Event.id == uuid).first()
        if not event:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Ивент не найден",
            )

        existing = (
            self.db.query(EventSkip)
            .filter(
                EventSkip.user_id == current_user.uuid,
                EventSkip.event_id == uuid,
            )
            .first()
        )
        if existing:
            return {"message": "Ивент уже скрыт"}

        skip = EventSkip(user_id=current_user.uuid, event_id=uuid)
        self.db.add(skip)
        self.db.commit()
        return {"message": "Ивент скрыт из рекомендаций"}
    
    def remove_tags_from_event(
    self, current_user: User, event_id: str, tag_ids: list[int]
    ) -> EventInfoResponse:
        try:
            uuid = UUID(event_id)
        except ValueError:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Неверный ID",
            )

        event = self.db.query(Event).filter(Event.id == uuid).first()
        if not event:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Ивент не найден",
            )

        if current_user not in event.owners:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Нет прав редактировать этот ивент",
            )

        if not tag_ids:
            return self._event_to_response(event)

        tags = self.db.query(Tag).filter(Tag.id.in_(tag_ids)).all()
        by_id = {t.id: t for t in tags}

        for tag_id in tag_ids:
            tag = by_id.get(tag_id)
            if tag and tag in event.tags:
                event.tags.remove(tag)
                delete_tag_if_unused(self.db, tag)

        self.db.commit()
        return self._event_to_response(event)
    
    
    def leave_event(self, current_user: User, event_id: str):
        try:
            uuid = UUID(event_id)
        except ValueError:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Неверный ID",
            )

        event = self.db.query(Event).filter(Event.id == uuid).first()
        if not event:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Ивент не найден",
            )

        # просто убираем пользователя из участников, если он там есть
        if current_user in event.participants:
            event.participants.remove(current_user)
            self.db.commit()

        return {"message": "Вы вышли из события"}

    def _event_match_score(self, current_user: User, event: Event) -> int:
        user_tags = {t.id for t in current_user.seeking_tags}
        event_tags = {t.id for t in event.tags}
        return len(user_tags & event_tags)

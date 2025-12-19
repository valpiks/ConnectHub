from uuid import UUID
from typing import Optional, List
from datetime import datetime

from fastapi import HTTPException, status
from sqlalchemy import or_

from app.config import settings
from app.models.user_skip import UserSkip
from app.models.user import User
from app.models.tag import Tag
from app.models.friendship import Friendship
from app.models.event import Event
from app.models.enums import FriendStatus, TagStatus, UserRole
from app.schemas.user import (
    EditRequest,
    FriendRequestItem,
    FriendRequestsResponse,
    ProfileResponse,
    OtherProfileResponse,
    TagInfo,
    FriendsResponse,
    SearchResponse,
)
from app.schemas.event import EventInfoResponse, SearchEventInfoResponse
from app.schemas.tag import UserTagsResponse
from app.core.exceptions import UserNotFoundError
from app.services.base import BaseService
from app.services.tag_util import get_or_create_tag, delete_tag_if_unused
from app.services.chat import ChatService


class UserService(BaseService):
    def _user_to_profile_response(self, user: User) -> ProfileResponse:
        return ProfileResponse(
            uuid=user.uuid,
            tag=user.tag,
            name=user.name,
            email=user.email,
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

    def get_profile(self, current_user: User) -> ProfileResponse:
        return self._user_to_profile_response(current_user)

    def edit_profile(self, current_user: User, request: EditRequest) -> ProfileResponse:
        current_user.name = request.name
        current_user.status = request.status
        current_user.city = request.city
        current_user.institution = request.institution
        current_user.specialization = request.specialization
        current_user.bio = request.bio

        if request.tag is not None:
            existing = (
                self.db.query(User)
                .filter(User.tag == request.tag, User.uuid != current_user.uuid)
                .first()
            )
            if existing:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST, detail="Тег уже занят"
                )

            cleaned_tag = "".join(c for c in request.tag if c.isalnum() or c == "_")
            if cleaned_tag and cleaned_tag[0].isdigit():
                cleaned_tag = "_" + cleaned_tag
            current_user.tag = cleaned_tag

        self.db.commit()
        self.db.refresh(current_user)
        self.logger.info(f"Profile updated for user: {current_user.email}")
        return self._user_to_profile_response(current_user)

    def get_profile_by_uuid(self, uuid_str: str) -> OtherProfileResponse:
        try:
            user_uuid = UUID(uuid_str)
        except ValueError:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST, detail="Неверный формат UUID"
            )

        user = self.db.query(User).filter(User.uuid == user_uuid).first()
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, detail="Пользователь не найден"
            )

        return self._user_to_other_profile(user)

    def get_user_events(
        self, current_user: User, text: Optional[str], offset: int, limit: int
    ) -> SearchEventInfoResponse:
        query = self.db.query(Event).filter(
            or_(
                Event.participants.any(uuid=current_user.uuid),
                Event.owners.any(uuid=current_user.uuid),
            )
        )

        if text:
            query = query.filter(
                or_(
                    Event.title.ilike(f"%{text}%"), Event.description.ilike(f"%{text}%")
                )
            )

        total = query.count()
        events: List[Event] = query.offset(offset).limit(limit).all()

        events_response = []
        for event in events:
            events_response.append(
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
                    tags=[
                        TagInfo(id=t.id, name=t.name)
                        for t in event.tags
                    ],
                    participants=[
                        self._user_to_other_profile(u) for u in event.participants
                    ],
                    owners=[self._user_to_other_profile(u) for u in event.owners],
                )
            )

        return SearchEventInfoResponse(events=events_response, total=total)

    def get_friends(
        self, current_user: User, text: Optional[str], offset: int, limit: int
    ) -> FriendsResponse:
        query = self.db.query(Friendship).filter(
            or_(
                Friendship.user_id == current_user.uuid,
                Friendship.friend_id == current_user.uuid,
            ),
            Friendship.status == FriendStatus.ACCEPTED,
        )

        total = query.count()
        friendships = query.offset(offset).limit(limit).all()

        friends_list = []
        for f in friendships:
            friend = f.friend if f.user_id == current_user.uuid else f.user
            if text and text.lower() not in friend.name.lower():
                continue
            friends_list.append(self._user_to_other_profile(friend))

        return FriendsResponse(friends_list=friends_list, friends_count=total)

    def get_friend_requests(
    self, current_user: User, text: Optional[str], offset: int, limit: int
) -> FriendRequestsResponse:
        query = self.db.query(Friendship).filter(
            or_(
                Friendship.friend_id == current_user.uuid,
                Friendship.user_id == current_user.uuid,
            ),
            FriendStatus.PENDING == Friendship.status,
        )

        total = query.count()
        friendships = query.offset(offset).limit(limit).all()

        items: List[FriendRequestItem] = []
        for f in friendships:
            if f.friend_id == current_user.uuid:
                other = f.user
                is_incoming = True
            else:
                other = f.friend
                is_incoming = False

            if text and text.lower() not in other.name.lower():
                continue

            items.append(
                FriendRequestItem(
                    user=self._user_to_other_profile(other),
                    is_incoming=is_incoming,
                )
            )

        return FriendRequestsResponse(requests=items, total=total)

    def get_recommendations(
        self, current_user: User, text: Optional[str], offset: int, limit: int
    ) -> SearchResponse:
        query = self.db.query(User).filter(User.uuid != current_user.uuid)

        friend_subq = (
            self.db.query(Friendship.friend_id)
            .filter(Friendship.user_id == current_user.uuid)
            .union(
                self.db.query(Friendship.user_id).filter(
                    Friendship.friend_id == current_user.uuid
                )
            )
            .subquery()
        )

        query = query.filter(~User.uuid.in_(friend_subq))

        skip_subq = (
            self.db.query(UserSkip.to_user_id)
            .filter(UserSkip.from_user_id == current_user.uuid)
            .subquery()
        )

        query = query.filter(~User.uuid.in_(skip_subq))

        if text:
            query = query.filter(
                or_(User.name.ilike(f"%{text}%"), User.tag.ilike(f"%{text}%"))
            )

        seeking_tag_names = [t.name for t in current_user.seeking_tags]
        if seeking_tag_names:
            query = query.filter(User.own_tags.any(Tag.name.in_(seeking_tag_names)))

        users = query.all()
        scored = sorted(
            users,
            key=lambda u: self._user_match_score(current_user, u),
            reverse=True,
        )

        total = len(scored)
        page = scored[offset : offset + limit]
        return SearchResponse(
            users=[self._user_to_other_profile(u) for u in page],
            total=total,
        )

    def search_users(
        self,
        current_user: User,
        text: Optional[str],
        tags: Optional[str],
        offset: int,
        limit: int,
    ) -> SearchResponse:
        query = self.db.query(User).filter(User.uuid != current_user.uuid)

        if text:
            query = query.filter(
                or_(User.name.ilike(f"%{text}%"), User.tag.ilike(f"%{text}%"))
            )

        if tags:
            tag_list = [t.strip() for t in tags.split(",") if t.strip()]
            if tag_list:
                query = query.filter(User.own_tags.any(Tag.name.in_(tag_list)))

        total = query.count()
        users = query.offset(offset).limit(limit).all()

        return SearchResponse(
            users=[self._user_to_other_profile(u) for u in users], total=total
        )

    def match_user(self, current_user: User, target_id: str):
        try:
            target_uuid = UUID(target_id)
        except ValueError:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST, detail="Неверный формат UUID"
            )

        target_user = self.db.query(User).filter(User.uuid == target_uuid).first()
        if not target_user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, detail="Пользователь не найден"
            )

        existing = (
            self.db.query(Friendship)
            .filter(
                or_(
                    (Friendship.user_id == current_user.uuid)
                    & (Friendship.friend_id == target_uuid),
                    (Friendship.user_id == target_uuid)
                    & (Friendship.friend_id == current_user.uuid),
                )
            )
            .first()
        )

        if existing:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Запрос в друзья уже существует",
            )

        friendship = Friendship(
            user_id=current_user.uuid,
            friend_id=target_uuid,
            status=FriendStatus.PENDING,
        )
        self.db.add(friendship)
        self.db.commit()

        # In mock/demo mode certain users auto-accept friend requests and create a chat.
        if settings.mock_mode and target_user.email in (
            "mock1@example.com",
            "mock2@example.com",
        ):
            friendship.status = FriendStatus.ACCEPTED
            self.db.commit()

            chat_service = ChatService(self.db)
            chat_service.create_chat_for_friendship(current_user.uuid, target_uuid)

            return {"message": "Мок-пользователь автоматически принял запрос и создан чат"}

        return {"message": "Запрос в друзья отправлен"}

    def match_confirmation(
        self, current_user: User, requester_id: str, friend_status: FriendStatus
    ):
        try:
            requester_uuid = UUID(requester_id)
        except ValueError:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST, detail="Неверный формат UUID"
            )

        friendship = (
            self.db.query(Friendship)
            .filter(
                Friendship.user_id == requester_uuid,
                Friendship.friend_id == current_user.uuid,
                Friendship.status == FriendStatus.PENDING,
            )
            .first()
        )

        if not friendship:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Запрос в друзья не найден",
            )

        if friendship.status == FriendStatus.BLOCKED:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Пользователь заблокирован",
            )

        if friend_status == FriendStatus.REJECT:
            self.db.delete(friendship)
            self.db.commit()
            return {"message": "Статус обновлен"}

        friendship.status = friend_status
        self.db.commit()

        chat_service = ChatService(self.db)
        chat_service.create_chat_for_friendship(
            friendship.user_id, friendship.friend_id
        )

        return {"message": "Статус обновлен, чат создан"}

    def get_user_tags(self, current_user: User, type_str: str) -> UserTagsResponse:
        own_tags = [
            TagInfo(id=t.id, name=t.name)
            for t in current_user.own_tags
        ]
        seeking_tags = [
            TagInfo(id=t.id, name=t.name)
            for t in current_user.seeking_tags
        ]

        if type_str.upper() == "OWN":
            return UserTagsResponse(own_tags=own_tags, seeking_tags=[])
        elif type_str.upper() == "SEEKING":
            return UserTagsResponse(own_tags=[], seeking_tags=seeking_tags)
        else:
            return UserTagsResponse(own_tags=own_tags, seeking_tags=seeking_tags)

    def add_user_tags(self, current_user: User, tags: List[str], type_str: str):
        for tag_name in tags:
            tag = get_or_create_tag(self.db, current_user, tag_name)

            if type_str.upper() == "SEEKING":
                if tag not in current_user.seeking_tags:
                    current_user.seeking_tags.append(tag)
            else:
                if tag not in current_user.own_tags:
                    current_user.own_tags.append(tag)

        self.db.commit()
        return {"message": "Теги успешно добавлены"}

    def remove_user_tag(self, current_user: User, tag_id: int, type_str: str):
        tag = self.db.query(Tag).filter(Tag.id == tag_id).first()
        if not tag:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Тег не найден",
            )

        if type_str.upper() == "SEEKING":
            if tag in current_user.seeking_tags:
                current_user.seeking_tags.remove(tag)
            else:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Тег не найден в seeking",
                )
        else:
            if tag in current_user.own_tags:
                current_user.own_tags.remove(tag)
            else:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Тег не найден в own",
                )

        delete_tag_if_unused(self.db, tag)
        self.db.commit()

        return {"message": "Тег удалён"}
    
    def remove_friend(self, current_user: User, target_id: str):
        try:
            target_uuid = UUID(target_id)
        except ValueError:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Неверный UUID",
            )

        if target_uuid == current_user.uuid:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Нельзя удалить себя из друзей",
            )

        friendships = (
            self.db.query(Friendship)
            .filter(
                Friendship.status == FriendStatus.ACCEPTED,
                or_(
                    (Friendship.user_id == current_user.uuid)
                    & (Friendship.friend_id == target_uuid),
                    (Friendship.user_id == target_uuid)
                    & (Friendship.friend_id == current_user.uuid),
                ),
            )
            .all()
        )

        if not friendships:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Пользователь не находится в друзьях",
            )

        for f in friendships:
            self.db.delete(f)

        self.db.commit()
        return {"message": "Пользователь удалён из друзей"}

    def cancel_user(self, current_user: User, target_id: str):
        try:
            target_uuid = UUID(target_id)
        except ValueError:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Неверный UUID",
            )

        if target_uuid == current_user.uuid:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Нельзя отменить самого себя",
            )

        target_user = self.db.query(User).filter(User.uuid == target_uuid).first()
        if not target_user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Пользователь не найден",
            )
        existing = (
            self.db.query(UserSkip)
            .filter(
                UserSkip.from_user_id == current_user.uuid,
                UserSkip.to_user_id == target_uuid,
            )
            .first()
        )

        if existing:
            return {"message": "Пользователь уже скрыт"}

        skip = UserSkip(from_user_id=current_user.uuid, to_user_id=target_uuid)
        self.db.add(skip)
        self.db.commit()
        return {"message": "Пользователь скрыт из рекомендаций"}

    def _user_match_score(self, current_user: User, other: User) -> int:
        cur_own = {t.id for t in current_user.own_tags}
        cur_seeking = {t.id for t in current_user.seeking_tags}
        other_own = {t.id for t in other.own_tags}
        other_seeking = {t.id for t in other.seeking_tags}

        return len(cur_seeking & other_own) + len(cur_own & other_seeking)

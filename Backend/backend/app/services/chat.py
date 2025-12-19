from datetime import datetime
from typing import List
from uuid import UUID

from fastapi import HTTPException, status
from sqlalchemy import or_

from app.models.chat import Chat
from app.models.message import Message
from app.models.user import User
from app.schemas.chat import ChatSummary, ChatMessage
from app.schemas.user import OtherProfileResponse, TagInfo
from app.services.base import BaseService


class ChatService(BaseService):
    def _get_or_create_chat(self, user1_id: UUID, user2_id: UUID) -> Chat:
        a, b = sorted([user1_id, user2_id])
        chat = (
            self.db.query(Chat)
            .filter(Chat.user1_id == a, Chat.user2_id == b)
            .first()
        )
        if chat:
            return chat

        chat = Chat(user1_id=a, user2_id=b, created_at=datetime.utcnow())
        self.db.add(chat)
        self.db.commit()
        self.db.refresh(chat)
        return chat

    def create_chat_for_friendship(self, user1_id: UUID, user2_id: UUID) -> Chat:
        return self._get_or_create_chat(user1_id, user2_id)

    def list_chats(self, current_user: User) -> List[ChatSummary]:
        chats = (
            self.db.query(Chat)
            .filter(
                or_(
                    Chat.user1_id == current_user.uuid,
                    Chat.user2_id == current_user.uuid,
                )
            )
            .all()
        )

        summaries: List[ChatSummary] = []
        for c in chats:
            companion = c.user2 if c.user1_id == current_user.uuid else c.user1
            last_msg = c.messages[-1] if c.messages else None

            summaries.append(
                ChatSummary(
                    id=c.id,
                    companion=OtherProfileResponse(
                        uuid=companion.uuid,
                        tag=companion.tag,
                        name=companion.name,
                        role=companion.role,
                        status=companion.status,
                        city=companion.city,
                        institution=companion.institution,
                        specialization=companion.specialization,
                        bio=companion.bio,
                        avatar_url=companion.avatar_url,
                        created_at=companion.created_at,
                        own_tags=[
                            TagInfo(id=t.id, name=t.name) for t in companion.own_tags
                        ],
                        seeking_tags=[
                            TagInfo(id=t.id, name=t.name)
                            for t in companion.seeking_tags
                        ],
                    ),
                    last_message=last_msg.content if last_msg else None,
                    last_message_at=last_msg.created_at if last_msg else None,
                )
            )

        return summaries

    def list_messages(
        self, current_user: User, chat_id: str, offset: int, limit: int
    ) -> List[ChatMessage]:
        try:
            chat_uuid = UUID(chat_id)
        except ValueError:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Неверный UUID чата",
            )

        chat = self.db.query(Chat).filter(Chat.id == chat_uuid).first()
        if not chat:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Чат не найден",
            )

        if current_user.uuid not in (chat.user1_id, chat.user2_id):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Нет доступа к чату",
            )

        messages = (
            self.db.query(Message)
            .filter(Message.chat_id == chat_uuid)
            .order_by(Message.created_at.asc())
            .offset(offset)
            .limit(limit)
            .all()
        )

        return [
            ChatMessage(
                id=m.id,
                chat_id=m.chat_id,
                sender_id=m.sender_id,
                content=m.content,
                created_at=m.created_at,
            )
            for m in messages
        ]

    def save_message(self, chat_id: UUID, sender: User, content: str) -> Message:
        msg = Message(chat_id=chat_id, sender_id=sender.uuid, content=content)
        self.db.add(msg)
        self.db.commit()
        self.db.refresh(msg)
        return msg


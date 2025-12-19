from datetime import datetime
from typing import Optional, List
from uuid import UUID

from pydantic import BaseModel, Field

from app.schemas.user import OtherProfileResponse


class ChatSummary(BaseModel):
    id: UUID
    companion: OtherProfileResponse
    last_message: Optional[str] = Field(None, alias="lastMessage")
    last_message_at: Optional[datetime] = Field(None, alias="lastMessageAt")

    class Config:
        from_attributes = True
        populate_by_name = True


class ChatMessage(BaseModel):
    id: int
    chat_id: UUID = Field(..., alias="chatId")
    sender_id: UUID = Field(..., alias="senderId")
    content: str
    created_at: datetime = Field(..., alias="createdAt")

    class Config:
        from_attributes = True
        populate_by_name = True


class SendMessageRequest(BaseModel):
    content: str


ChatListResponse = List[ChatSummary]
ChatMessagesResponse = List[ChatMessage]


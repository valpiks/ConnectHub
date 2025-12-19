from typing import List, Dict
from uuid import UUID as UUID_t

from fastapi import APIRouter, Depends, Query, WebSocket, WebSocketDisconnect, status
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_user
from app.core.security import decode_token
from app.database import get_db
from app.models.chat import Chat
from app.models.user import User
from app.schemas.chat import ChatSummary, ChatMessage, ChatListResponse, ChatMessagesResponse
from app.services.chat import ChatService


router = APIRouter(prefix="/api/chats", tags=["Chats"])


@router.get("/", response_model=ChatListResponse)
def get_chats(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    service = ChatService(db)
    return service.list_chats(current_user)


@router.get("/{chat_id}/messages", response_model=ChatMessagesResponse)
def get_chat_messages(
    chat_id: str,
    offset: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=200),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    service = ChatService(db)
    return service.list_messages(current_user, chat_id, offset, limit)


class ConnectionManager:
    def __init__(self) -> None:
        self.active: Dict[UUID_t, list[WebSocket]] = {}

    async def connect(self, chat_id: UUID_t, websocket: WebSocket) -> None:
        await websocket.accept()
        self.active.setdefault(chat_id, []).append(websocket)

    def disconnect(self, chat_id: UUID_t, websocket: WebSocket) -> None:
        if chat_id in self.active:
            self.active[chat_id] = [
                ws for ws in self.active[chat_id] if ws is not websocket
            ]
            if not self.active[chat_id]:
                del self.active[chat_id]

    async def broadcast(self, chat_id: UUID_t, data: dict) -> None:
        for ws in self.active.get(chat_id, []):
            await ws.send_json(data)


manager = ConnectionManager()


@router.websocket("/ws/{chat_id}")
async def chat_ws(websocket: WebSocket, chat_id: str, db: Session = Depends(get_db)):
    token = websocket.query_params.get("token")
    if not token:
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
        return

    try:
        payload = decode_token(token)
        user_uuid = UUID_t(payload.get("sub"))
    except Exception:
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
        return

    user = db.query(User).filter(User.uuid == user_uuid).first()
    if not user:
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
        return

    try:
        chat_uuid = UUID_t(chat_id)
    except ValueError:
        await websocket.close(code=status.WS_1003_UNSUPPORTED_DATA)
        return

    chat = db.query(Chat).filter(Chat.id == chat_uuid).first()
    if not chat or user.uuid not in (chat.user1_id, chat.user2_id):
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
        return

    await manager.connect(chat_uuid, websocket)
    service = ChatService(db)

    try:
        while True:
            data = await websocket.receive_json()
            content = data.get("content")
            if not content:
                continue

            msg = service.save_message(chat_uuid, user, content)
            await manager.broadcast(
                chat_uuid,
                {
                    "id": msg.id,
                    "chatId": str(msg.chat_id),
                    "senderId": str(msg.sender_id),
                    "content": msg.content,
                    "createdAt": msg.created_at.isoformat(),
                },
            )
    except WebSocketDisconnect:
        manager.disconnect(chat_uuid, websocket)


from typing import Generator

from fastapi import Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session

from app.database import get_db
from app.core.security import decode_token
from app.core.exceptions import InvalidTokenError, UserNotFoundError
from app.models.user import User





security = HTTPBearer()


def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: Session = Depends(get_db)
) -> User:
    """Get the current authenticated user from JWT token."""
    token = credentials.credentials
    payload = decode_token(token)
    
    uuid_str: str = payload.get("sub")
    if uuid_str is None:
        raise InvalidTokenError(message="Не удалось получить данные пользователя из токена")

    from uuid import UUID
    try:
        user_uuid = UUID(uuid_str)
    except ValueError:
        raise InvalidTokenError(message=f"Неверный формат ID пользователя в токене: {uuid_str}")

    user = db.query(User).filter(User.uuid == user_uuid).first()
    if user is None:
        raise UserNotFoundError()
    
    return user


def get_current_active_user(current_user: User = Depends(get_current_user)) -> User:
    """Get the current active user."""
    return current_user

from datetime import timedelta
from typing import Optional

from app.models.user import User
from app.models.enums import UserRole
from app.schemas.auth import RegisterRequest, LoginRequest
from app.core.security import (
    get_password_hash,
    verify_password,
    create_access_token,
    create_refresh_token,
    verify_token_type,
)
from app.core.exceptions import (
    UserAlreadyExistsError,
    UserNotFoundError,
    InvalidCredentialsError,
    InvalidTokenError,
)
from app.services.base import BaseService

class AuthService(BaseService):
    def register(self, request: RegisterRequest):
        existing_user = self.db.query(User).filter(User.email == request.email).first()
        if existing_user:
            self.logger.warning(f"Registration attempt with existing email: {request.email}")
            raise UserAlreadyExistsError()
        
        hashed_password = get_password_hash(request.password)
        user = User(
            name=request.name,
            email=request.email,
            password=hashed_password,
            role=UserRole.ROLE_USER
        )
        
        # Generate tokens
        access_token = create_access_token(data={"sub": str(user.uuid)})
        refresh_token = create_refresh_token(data={"sub": str(user.uuid)})
        
        user.refresh_token = refresh_token
        
        self.db.add(user)
        self.db.commit()
        self.db.refresh(user)
        
        self.logger.info(f"New user registered: {user.email}")
        return access_token, refresh_token

    def authenticate(self, request: LoginRequest):
        user = self.db.query(User).filter(User.email == request.email).first()
        if not user:
            self.logger.warning(f"Login attempt with non-existent email: {request.email}")
            raise UserNotFoundError()
        
        if not verify_password(request.password, user.password):
            self.logger.warning(f"Invalid password for user: {request.email}")
            raise InvalidCredentialsError()
        
        access_token = create_access_token(data={"sub": str(user.uuid)})
        refresh_token = create_refresh_token(data={"sub": str(user.uuid)})
        
        user.refresh_token = refresh_token
        self.db.commit()
        
        self.logger.info(f"User logged in: {user.email}")
        return access_token, refresh_token

    def refresh_token(self, token: str):
        payload = verify_token_type(token, "refresh")
        uuid_str = payload.get("sub")
        
        try:
             from uuid import UUID
             user_uuid = UUID(uuid_str)
        except ValueError:
             raise InvalidTokenError(message="Invalid UUID in token")

        user = self.db.query(User).filter(User.uuid == user_uuid).first()
        if not user:
            raise UserNotFoundError()
        
        if user.refresh_token != token:
            user.refresh_token = None
            self.db.commit()
            self.logger.warning(f"Refresh token reuse detected for user: {user.email}")
            raise InvalidTokenError(message="Токен скомпрометирован")
        
        access_token = create_access_token(data={"sub": str(user.uuid)})
        refresh_token = create_refresh_token(data={"sub": str(user.uuid)})
        
        user.refresh_token = refresh_token
        self.db.commit()
        
        self.logger.info(f"Token refreshed for user: {user.email}")
        return access_token, refresh_token

    def logout(self, token: str):
        try:
            payload = verify_token_type(token, "refresh")
            uuid_str = payload.get("sub")
            
            from uuid import UUID
            user_uuid = UUID(uuid_str)
            
            user = self.db.query(User).filter(User.uuid == user_uuid).first()
            if user:
                user.refresh_token = None
                self.db.commit()
                self.logger.info(f"User logged out: {user.email}")
        except Exception as e:
            self.logger.error(f"Error during logout: {e}")
            # We don't raise here usually to ensure logout succeeds from client perspective
            pass

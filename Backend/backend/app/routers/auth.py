from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.services.auth import AuthService
from app.schemas.auth import RegisterRequest, LoginRequest, TokenResponse, TokenRequest
from app.schemas.common import MessageResponse


router = APIRouter(prefix="/api/auth", tags=["Authentication"])


@router.post("/register", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
def register(
    request: RegisterRequest, 
    db: Session = Depends(get_db)
):
    """
    Регистрация нового пользователя.
    
    Создает нового пользователя и возвращает токены авторизации.
    """
    service = AuthService(db)
    access_token, refresh_token = service.register(request)
    
    return TokenResponse(access_token=access_token, refresh_token=refresh_token)


@router.post("/login", response_model=TokenResponse)
def login(
    request: LoginRequest, 
    db: Session = Depends(get_db)
):
    """
    Вход пользователя в систему.
    
    Проверяет учетные данные и возвращает токены авторизации.
    """
    service = AuthService(db)
    access_token, refresh_token = service.authenticate(request)
    
    return TokenResponse(access_token=access_token, refresh_token=refresh_token)


@router.post("/logout", response_model=MessageResponse, status_code=status.HTTP_200_OK)
def logout(
    request: TokenRequest,
    db: Session = Depends(get_db)
):
    """
    Выход пользователя из системы.
    
    Инвалидирует refresh token.
    """
    service = AuthService(db)
    service.logout(request.token)
    
    return {"message": "Выход выполнен успешно"}


@router.post("/refresh", response_model=TokenResponse)
def refresh(
    request: TokenRequest,
    db: Session = Depends(get_db)
):
    """
    Обновление токенов.
    
    Использует refresh token для получения новой пары токенов.
    """
    service = AuthService(db)
    access_token, new_refresh_token = service.refresh_token(request.token)
    
    return TokenResponse(access_token=access_token, refresh_token=new_refresh_token)

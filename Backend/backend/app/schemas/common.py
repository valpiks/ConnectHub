from typing import Optional, Any, List
from pydantic import BaseModel, Field


class ApiResponse(BaseModel):
    """Generic API response."""
    success: bool = True
    message: Optional[str] = None
    data: Optional[Any] = None


class ErrorContent(BaseModel):
    """Error content structure."""
    code: str = Field(..., description="Код ошибки для программной обработки")
    message: str = Field(..., description="Человекочитаемое сообщение об ошибке")
    details: Optional[Any] = Field(default=None, description="Дополнительные детали")


class ApiError(BaseModel):
    """
    Стандартный формат ответа об ошибке.
    
    Все ошибки API возвращаются в этом формате.
    
    Error Codes:
        - VALIDATION_ERROR: Ошибка валидации данных
        - INVALID_UUID: Неверный формат UUID
        - INVALID_FILE_TYPE: Недопустимый тип файла
        - FILE_TOO_LARGE: Файл > 10MB
        - INVALID_CREDENTIALS: Неверный пароль
        - TOKEN_EXPIRED: Токен истек
        - INVALID_TOKEN: Недействительный токен
        - FORBIDDEN: Доступ запрещен
        - ADMIN_REQUIRED: Нужны права админа
        - USER_NOT_FOUND: Пользователь не найден
        - EVENT_NOT_FOUND: Мероприятие не найдено
        - FILE_NOT_FOUND: Файл не найден
        - USER_ALREADY_EXISTS: Email занят
        - STORAGE_ERROR: Ошибка MinIO
        - INTERNAL_ERROR: Внутренняя ошибка
    """
    error: ErrorContent

    class Config:
        json_schema_extra = {
            "example": {
                "error": {
                    "code": "USER_NOT_FOUND",
                    "message": "Пользователь не найден",
                    "details": None
                }
            }
        }


class MessageResponse(BaseModel):
    """Simple message response."""
    message: str

    class Config:
        json_schema_extra = {
            "example": {
                "message": "Операция выполнена успешно"
            }
        }

"""
Custom exceptions for the application.
All exceptions extend AppException for consistent error handling.
"""
from typing import Optional, Any


class AppException(Exception):
    """Base exception for application errors."""
    
    def __init__(
        self,
        message: str,
        error_code: str = "INTERNAL_ERROR",
        status_code: int = 500,
        details: Optional[Any] = None
    ):
        self.message = message
        self.error_code = error_code
        self.status_code = status_code
        self.details = details
        super().__init__(self.message)


# ========== Authentication Errors ==========

class AuthenticationError(AppException):
    """Authentication related errors."""
    
    def __init__(self, message: str = "Ошибка аутентификации", details: Optional[Any] = None):
        super().__init__(
            message=message,
            error_code="AUTHENTICATION_ERROR",
            status_code=401,
            details=details
        )


class InvalidCredentialsError(AuthenticationError):
    """Invalid login credentials."""
    
    def __init__(self, message: str = "Неверный email или пароль"):
        super().__init__(message=message)
        self.error_code = "INVALID_CREDENTIALS"


class TokenExpiredError(AuthenticationError):
    """JWT token has expired."""
    
    def __init__(self, message: str = "Токен истек"):
        super().__init__(message=message)
        self.error_code = "TOKEN_EXPIRED"


class InvalidTokenError(AuthenticationError):
    """Invalid JWT token."""
    
    def __init__(self, message: str = "Недействительный токен"):
        super().__init__(message=message)
        self.error_code = "INVALID_TOKEN"


# ========== Authorization Errors ==========

class ForbiddenError(AppException):
    """Access forbidden."""
    
    def __init__(self, message: str = "Доступ запрещен", details: Optional[Any] = None):
        super().__init__(
            message=message,
            error_code="FORBIDDEN",
            status_code=403,
            details=details
        )


class AdminRequiredError(ForbiddenError):
    """Admin role required."""
    
    def __init__(self, message: str = "Требуются права администратора"):
        super().__init__(message=message)
        self.error_code = "ADMIN_REQUIRED"


# ========== Not Found Errors ==========

class NotFoundError(AppException):
    """Resource not found."""
    
    def __init__(self, message: str = "Ресурс не найден", resource: Optional[str] = None):
        super().__init__(
            message=message,
            error_code="NOT_FOUND",
            status_code=404,
            details={"resource": resource} if resource else None
        )


class UserNotFoundError(NotFoundError):
    """User not found."""
    
    def __init__(self, message: str = "Пользователь не найден"):
        super().__init__(message=message, resource="user")
        self.error_code = "USER_NOT_FOUND"


class EventNotFoundError(NotFoundError):
    """Event not found."""
    
    def __init__(self, message: str = "Мероприятие не найдено"):
        super().__init__(message=message, resource="event")
        self.error_code = "EVENT_NOT_FOUND"


class TagNotFoundError(NotFoundError):
    """Tag not found."""
    
    def __init__(self, message: str = "Тег не найден"):
        super().__init__(message=message, resource="tag")
        self.error_code = "TAG_NOT_FOUND"


class FileNotFoundError(NotFoundError):
    """File not found."""
    
    def __init__(self, message: str = "Файл не найден"):
        super().__init__(message=message, resource="file")
        self.error_code = "FILE_NOT_FOUND"


# ========== Validation Errors ==========

class ValidationError(AppException):
    """Validation error."""
    
    def __init__(self, message: str = "Ошибка валидации", details: Optional[Any] = None):
        super().__init__(
            message=message,
            error_code="VALIDATION_ERROR",
            status_code=400,
            details=details
        )


class InvalidUUIDError(ValidationError):
    """Invalid UUID format."""
    
    def __init__(self, message: str = "Неверный формат UUID"):
        super().__init__(message=message)
        self.error_code = "INVALID_UUID"


class InvalidFileTypeError(ValidationError):
    """Invalid file type."""
    
    def __init__(self, message: str = "Недопустимый тип файла", allowed_types: Optional[list] = None):
        super().__init__(message=message, details={"allowed_types": allowed_types})
        self.error_code = "INVALID_FILE_TYPE"


class FileTooLargeError(ValidationError):
    """File exceeds size limit."""
    
    def __init__(self, message: str = "Файл слишком большой", max_size_mb: int = 10):
        super().__init__(message=message, details={"max_size_mb": max_size_mb})
        self.error_code = "FILE_TOO_LARGE"


# ========== Conflict Errors ==========

class ConflictError(AppException):
    """Resource conflict."""
    
    def __init__(self, message: str = "Конфликт данных", details: Optional[Any] = None):
        super().__init__(
            message=message,
            error_code="CONFLICT",
            status_code=409,
            details=details
        )


class UserAlreadyExistsError(ConflictError):
    """User with this email already exists."""
    
    def __init__(self, message: str = "Пользователь с таким email уже существует"):
        super().__init__(message=message)
        self.error_code = "USER_ALREADY_EXISTS"


class TagAlreadyExistsError(ConflictError):
    """Tag with this name already exists."""
    
    def __init__(self, message: str = "Тег с таким именем уже существует"):
        super().__init__(message=message)
        self.error_code = "TAG_ALREADY_EXISTS"


class FriendshipAlreadyExistsError(ConflictError):
    """Friendship request already exists."""
    
    def __init__(self, message: str = "Запрос в друзья уже существует"):
        super().__init__(message=message)
        self.error_code = "FRIENDSHIP_ALREADY_EXISTS"


# ========== Business Logic Errors ==========

class BusinessLogicError(AppException):
    """Business logic error."""
    
    def __init__(self, message: str, details: Optional[Any] = None):
        super().__init__(
            message=message,
            error_code="BUSINESS_ERROR",
            status_code=400,
            details=details
        )


class EventFullError(BusinessLogicError):
    """Event has reached max participants."""
    
    def __init__(self, message: str = "Максимальное количество участников достигнуто"):
        super().__init__(message=message)
        self.error_code = "EVENT_FULL"


class UserBlockedError(BusinessLogicError):
    """User is blocked."""
    
    def __init__(self, message: str = "Пользователь заблокирован"):
        super().__init__(message=message)
        self.error_code = "USER_BLOCKED"


# ========== External Service Errors ==========

class ExternalServiceError(AppException):
    """External service error (MinIO, etc.)."""
    
    def __init__(self, message: str = "Ошибка внешнего сервиса", service: str = "unknown"):
        super().__init__(
            message=message,
            error_code="EXTERNAL_SERVICE_ERROR",
            status_code=502,
            details={"service": service}
        )


class StorageError(ExternalServiceError):
    """File storage error."""
    
    def __init__(self, message: str = "Ошибка хранилища файлов"):
        super().__init__(message=message, service="minio")
        self.error_code = "STORAGE_ERROR"

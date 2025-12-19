from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    # Database
    database_url: str = "postgresql://user:password@localhost:5432/connecthub"
    
    # JWT
    jwt_secret_key: str = "NeRealSecretKeyForFreaksAniMeTrackAPIAndAniMeTrackAPP"
    jwt_algorithm: str = "HS256"
    access_token_expire_minutes: int = 60
    refresh_token_expire_days: int = 7
    
    # MinIO
    minio_endpoint: str = "localhost:9000"
    minio_access_key: str = "minioadmin"
    minio_secret_key: str = "minioadmin123"
    minio_bucket: str = "connecthub-bucket"
    minio_secure: bool = False
    
    # App
    app_name: str = "ConnectHub API"
    debug: bool = False

    # Mock / demo mode
    mock_mode: bool = False
    
    class Config:
        env_file = ".env"
        case_sensitive = False


@lru_cache()
def get_settings() -> Settings:
    return Settings()


settings = get_settings()

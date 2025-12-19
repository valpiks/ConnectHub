import io
from uuid import UUID, uuid4
from fastapi import UploadFile
from fastapi.responses import StreamingResponse
from minio import Minio
from minio.error import S3Error

from app.config import settings
from app.models.user import User
from app.models.event import Event
from app.core.exceptions import (
    InvalidUUIDError, InvalidFileTypeError, FileTooLargeError, FileNotFoundError,
    EventNotFoundError, ForbiddenError, StorageError
)
from app.services.base import BaseService

class FileService(BaseService):
    ALLOWED_IMAGE_TYPES = {"image/jpeg", "image/png", "image/gif", "image/webp"}
    MAX_FILE_SIZE = 10 * 1024 * 1024  # 10 MB

    def _get_minio_client(self) -> Minio:
        return Minio(
            settings.minio_endpoint,
            access_key=settings.minio_access_key,
            secret_key=settings.minio_secret_key,
            secure=settings.minio_secure
        )

    def _ensure_bucket_exists(self, client: Minio, bucket_name: str):
        if not client.bucket_exists(bucket_name):
            client.make_bucket(bucket_name)

    def _validate_image_file(self, file: UploadFile):
        if file.content_type not in self.ALLOWED_IMAGE_TYPES:
            raise InvalidFileTypeError(
                message=f"Недопустимый тип файла: {file.content_type}",
                allowed_types=list(self.ALLOWED_IMAGE_TYPES)
            )

    async def _upload_to_minio(self, file: UploadFile, folder: str) -> str:
        try:
            client = self._get_minio_client()
            self._ensure_bucket_exists(client, settings.minio_bucket)
            
            file_extension = file.filename.split(".")[-1] if "." in file.filename else "jpg"
            unique_filename = f"{folder}/{uuid4()}.{file_extension}"
            
            content = await file.read()
            if len(content) > self.MAX_FILE_SIZE:
                raise FileTooLargeError(max_size_mb=self.MAX_FILE_SIZE // (1024 * 1024))
            
            content_stream = io.BytesIO(content)
            
            client.put_object(
                settings.minio_bucket,
                unique_filename,
                content_stream,
                length=len(content),
                content_type=file.content_type or "application/octet-stream"
            )
            
            return unique_filename
        except (FileTooLargeError, InvalidFileTypeError):
            raise
        except S3Error as e:
            raise StorageError(message=f"Ошибка загрузки файла: {str(e)}")

    async def upload_profile_avatar(self, current_user: User, file: UploadFile):
        self._validate_image_file(file)
        
        if current_user.avatar_url:
            try:
                client = self._get_minio_client()
                client.remove_object(settings.minio_bucket, current_user.avatar_url)
            except S3Error:
                pass
        
        filename = await self._upload_to_minio(file, "avatars")
        
        current_user.avatar_url = filename
        self.db.commit()
        
        return {"fileName": filename, "message": "Аватар профиля загружен успешно"}

    def delete_profile_avatar(self, current_user: User):
        if not current_user.avatar_url:
            raise FileNotFoundError(message="Аватар не найден")
        
        try:
            client = self._get_minio_client()
            client.remove_object(settings.minio_bucket, current_user.avatar_url)
        except S3Error as e:
            raise StorageError(message=f"Ошибка удаления файла: {str(e)}")
        
        current_user.avatar_url = ""
        self.db.commit()
        return {"message": "Аватар удален успешно"}

    async def upload_event_image(self, current_user: User, event_id: str, file: UploadFile):
        try:
            event_uuid = UUID(event_id)
        except ValueError:
            raise InvalidUUIDError()
        
        event = self.db.query(Event).filter(Event.id == event_uuid).first()
        if not event:
            raise EventNotFoundError()
        
        if current_user not in event.owners:
            raise ForbiddenError(message="Нет прав на загрузку изображения")
        
        self._validate_image_file(file)
        
        if event.image_url:
            try:
                client = self._get_minio_client()
                client.remove_object(settings.minio_bucket, event.image_url)
            except S3Error:
                pass
        
        filename = await self._upload_to_minio(file, "events")
        
        event.image_url = filename
        self.db.commit()
        
        return {"fileName": filename, "message": "Изображение мероприятия загружено успешно"}

    def delete_event_image(self, current_user: User, event_id: str):
        try:
            event_uuid = UUID(event_id)
        except ValueError:
            raise InvalidUUIDError()
        
        event = self.db.query(Event).filter(Event.id == event_uuid).first()
        if not event:
            raise EventNotFoundError()
        
        if current_user not in event.owners:
            raise ForbiddenError(message="Нет прав на удаление изображения")
        
        if not event.image_url:
            raise FileNotFoundError(message="Изображение не найдено")
        
        try:
            client = self._get_minio_client()
            client.remove_object(settings.minio_bucket, event.image_url)
        except S3Error as e:
            raise StorageError(message=f"Ошибка удаления файла: {str(e)}")
        
        event.image_url = None
        self.db.commit()
        return {"message": "Изображение удалено успешно"}

    def get_file(self, file_path: str):
        try:
            client = self._get_minio_client()
            response = client.get_object(settings.minio_bucket, file_path)
            stat = client.stat_object(settings.minio_bucket, file_path)
            content_type = stat.content_type or "application/octet-stream"
            
            return StreamingResponse(
                response,
                media_type=content_type,
                headers={"Content-Disposition": f"inline; filename=\"{file_path.split('/')[-1]}\""}
            )
        except S3Error as e:
            if e.code == "NoSuchKey":
                raise FileNotFoundError()
            raise StorageError(message=f"Ошибка чтения файла: {str(e)}")

    def get_file_url(self, file_path: str):
        try:
            client = self._get_minio_client()
            try:
                client.stat_object(settings.minio_bucket, file_path)
            except S3Error as e:
                if e.code == "NoSuchKey":
                    raise FileNotFoundError()
                raise
            
            url = client.presigned_get_object(settings.minio_bucket, file_path, expires=3600)
            return {"url": url}
        except FileNotFoundError:
            raise
        except S3Error as e:
            raise StorageError(message=f"Ошибка получения URL: {str(e)}")

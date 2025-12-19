from pydantic import BaseModel, Field


class FileUploadResponse(BaseModel):
    """Response for successful file/image upload."""
    file_name: str = Field(..., alias="fileName")
    message: str

    class Config:
        populate_by_name = True
        json_schema_extra = {
            "example": {
                "fileName": "avatars/3f1e3c8a-1234-4f7a-b321-avatar.png",
                "message": "Файл успешно загружен",
            }
        }


class FileUrlResponse(BaseModel):
    """Response with presigned file URL."""
    url: str = Field(..., description="Временная ссылка для скачивания файла")


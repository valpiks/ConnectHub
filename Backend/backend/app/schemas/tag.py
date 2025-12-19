from typing import List, Set

from pydantic import BaseModel, Field

from app.models.enums import TagStatus


class AddTagsRequest(BaseModel):
    """Request for adding tags to user or event."""
    tags: Set[str] = Field(..., min_length=1, max_length=20)

    class Config:
        json_schema_extra = {
            "example": {
                "tags": ["backend", "python", "fastapi"]
            }
        }


class TagInfo(BaseModel):
    """Tag info for responses."""
    id: int
    name: str

    class Config:
        from_attributes = True


class UserTagResponse(BaseModel):
    """Response with single type of user tags."""
    type: str
    tags: List[TagInfo]


class UserTagsResponse(BaseModel):
    """Response with all user tags."""
    own_tags: List[TagInfo] = Field(default_factory=list, alias="ownTags")
    seeking_tags: List[TagInfo] = Field(default_factory=list, alias="seekingTags")

    class Config:
        populate_by_name = True


class RemoveTagsRequest(BaseModel):
    """Request body for removing tags from event."""
    tag_ids: List[int] = Field(..., alias="tagIds")

    class Config:
        populate_by_name = True


class AdminTagCreateResponse(BaseModel):
    """Response for tag creation by admin."""
    id: int
    name: str
    message: str


class AdminTagModerateResponse(BaseModel):
    """Response for tag moderation by admin."""
    message: str
    status: TagStatus


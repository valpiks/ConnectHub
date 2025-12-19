from datetime import datetime
from typing import Optional, List, Set
from uuid import UUID

from pydantic import BaseModel, Field

from app.models.enums import EventStatus, EventCategory
from app.schemas.user import OtherProfileResponse, BasicUserInfo
from app.schemas.tag import TagInfo


class EventCreateRequest(BaseModel):
    """Request body for creating an event."""
    title: str
    description: Optional[str] = None
    venue: Optional[str] = None
    category: Optional[EventCategory] = None
    max_users_count: int = Field(0, alias="maxUsersCount")
    start_date: Optional[datetime] = Field(None, alias="startDate")
    end_date: Optional[datetime] = Field(None, alias="endDate")
    prize: Optional[int] = None

    class Config:
        populate_by_name = True


class EventEditRequest(BaseModel):
    """Request body for editing an event."""
    title: Optional[str] = None
    description: Optional[str] = None
    venue: Optional[str] = None
    category: Optional[EventCategory] = None
    max_users_count: Optional[int] = Field(None, alias="maxUsersCount")
    start_date: Optional[datetime] = Field(None, alias="startDate")
    end_date: Optional[datetime] = Field(None, alias="endDate")
    status: Optional[EventStatus] = None
    prize: Optional[int] = None

    class Config:
        populate_by_name = True


class AddUsersRequest(BaseModel):
    """Request for adding users to event."""
    user_ids: List[str] = Field(..., alias="userIds")

    class Config:
        populate_by_name = True


class EventInfoResponse(BaseModel):
    """Detailed event information."""
    id: UUID
    title: str
    description: Optional[str] = None
    venue: Optional[str] = None
    category: Optional[EventCategory] = None
    max_users_count: int = Field(0, alias="maxUsersCount")
    start_date: Optional[datetime] = Field(None, alias="startDate")
    end_date: Optional[datetime] = Field(None, alias="endDate")
    status: EventStatus
    image_url: Optional[str] = Field(None, alias="imageUrl")
    tags: List[TagInfo] = Field(default_factory=list)
    participants: List[BasicUserInfo] = Field(default_factory=list)
    owners: List[BasicUserInfo] = Field(default_factory=list)
    prize: Optional[int] = None

    class Config:
        from_attributes = True
        populate_by_name = True


class SearchEventInfoResponse(BaseModel):
    """Response with event search results (without total count)."""
    events: List[EventInfoResponse]


class EventCreateResponse(BaseModel):
    """Response for successful event creation."""
    id: UUID
    message: str

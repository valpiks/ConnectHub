from datetime import date
from typing import Optional, List, Set
from uuid import UUID

from pydantic import BaseModel, EmailStr, Field

from app.models.enums import UserRole, UserStatus
from app.schemas.tag import TagInfo


class ProfileResponse(BaseModel):
    """Response with user profile data."""
    uuid: UUID
    tag: str
    name: str
    email: EmailStr
    role: UserRole
    status: Optional[UserStatus] = None
    city: Optional[str] = None
    institution: Optional[str] = None
    specialization: Optional[str] = None
    bio: Optional[str] = ""
    avatar_url: Optional[str] = Field(default="", alias="avatarUrl")
    created_at: Optional[date] = Field(None, alias="createdAt")
    own_tags: List[TagInfo] = Field(default_factory=list, alias="ownTags")
    seeking_tags: List[TagInfo] = Field(default_factory=list, alias="seekingTags")

    class Config:
        from_attributes = True
        populate_by_name = True


class OtherProfileResponse(BaseModel):
    """Response with other user's profile data (no email)."""
    uuid: UUID
    tag: str
    name: str
    role: UserRole
    status: Optional[UserStatus] = None
    city: Optional[str] = None
    institution: Optional[str] = None
    specialization: Optional[str] = None
    bio: Optional[str] = ""
    avatar_url: Optional[str] = Field(default="", alias="avatarUrl")
    created_at: Optional[date] = Field(None, alias="createdAt")
    own_tags: List[TagInfo] = Field(default_factory=list, alias="ownTags")
    seeking_tags: List[TagInfo] = Field(default_factory=list, alias="seekingTags")

    class Config:
        from_attributes = True
        populate_by_name = True


class EditRequest(BaseModel):
    """Request for editing user profile."""
    name: Optional[str] = None
    tag: Optional[str] = None
    status: Optional[UserStatus] = None
    city: Optional[str] = None
    institution: Optional[str] = None
    specialization: Optional[str] = None
    bio: Optional[str] = None


class UserIdRequest(BaseModel):
    """Request with user ID."""
    id: str


class BasicUserInfo(BaseModel):
    """Lightweight user info for nested DTOs (e.g., event participants)."""
    uuid: UUID
    tag: str
    name: str
    avatar_url: Optional[str] = Field(default="", alias="avatarUrl")

    class Config:
        from_attributes = True
        populate_by_name = True


class SearchResponse(BaseModel):
    """Response with paginated user search results."""
    users: List[OtherProfileResponse]
    total: int


class FriendsResponse(BaseModel):
    """Response with friends list."""
    friends_list: List[OtherProfileResponse] = Field(..., alias="friendsList")
    friends_count: int = Field(..., alias="friendsCount")

    class Config:
        populate_by_name = True


class FriendRequestItem(BaseModel):
    user: OtherProfileResponse
    is_incoming: bool = Field(..., alias="isIncoming")

    class Config:
        populate_by_name = True


class FriendRequestsResponse(BaseModel):
    requests: List[FriendRequestItem]
    total: int

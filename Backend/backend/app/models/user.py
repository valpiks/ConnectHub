import uuid
from datetime import date
from typing import TYPE_CHECKING, List, Set

from sqlalchemy import Column, String, Text, Date, Enum, Table, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from app.database import Base
from app.models.enums import UserRole, UserStatus


if TYPE_CHECKING:
    from app.models.tag import Tag


# Association tables for many-to-many relationships
user_own_tags = Table(
    "user_own_tags",
    Base.metadata,
    Column("user_uuid", UUID(as_uuid=True), ForeignKey("users.uuid"), primary_key=True),
    Column("tag_id", ForeignKey("tags.id"), primary_key=True),
)

user_seeking_tags = Table(
    "user_seeking_tags",
    Base.metadata,
    Column("user_uuid", UUID(as_uuid=True), ForeignKey("users.uuid"), primary_key=True),
    Column("tag_id", ForeignKey("tags.id"), primary_key=True),
)


class User(Base):
    __tablename__ = "users"

    uuid = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    tag = Column(String, unique=True, nullable=False, default=lambda: str(uuid.uuid4()))
    name = Column(String(100), nullable=False)
    email = Column(String, unique=True, nullable=False)
    password = Column(String, nullable=False)
    refresh_token = Column(String, nullable=True)
    
    status = Column(String, nullable=True)
    city = Column(String, nullable=True)
    institution = Column(String, nullable=True)
    specialization = Column(String, nullable=True)
    
    role = Column(Enum(UserRole), nullable=False, default=UserRole.ROLE_USER)
    bio = Column(Text, default="")
    avatar_url = Column(String, default="")
    created_at = Column(Date, default=date.today)

    # Relationships
    own_tags = relationship(
        "Tag",
        secondary=user_own_tags,
        back_populates="users_owning",
        lazy="selectin"
    )
    seeking_tags = relationship(
        "Tag",
        secondary=user_seeking_tags,
        back_populates="users_seeking",
        lazy="selectin"
    )

    def __repr__(self):
        return f"<User {self.email}>"

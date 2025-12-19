from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import Column, Integer, String, Text, DateTime, Enum, ForeignKey
from sqlalchemy.orm import relationship

from app.database import Base
from app.models.enums import TagStatus


if TYPE_CHECKING:
    from app.models.user import User


class Tag(Base):
    __tablename__ = "tags"

    id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String, unique=True, nullable=False)
    description = Column(Text, nullable=True)
    status = Column(Enum(TagStatus), nullable=False, default=TagStatus.PENDING)
    
    created_by_user_id = Column(ForeignKey("users.uuid"), nullable=True)
    moderated_by_user_id = Column(ForeignKey("users.uuid"), nullable=True)
    
    moderated_at = Column(DateTime, nullable=True)
    moderation_comment = Column(String(500), nullable=True)
    
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    created_by = relationship(
        "User",
        foreign_keys=[created_by_user_id],
        lazy="selectin"
    )
    moderated_by = relationship(
        "User",
        foreign_keys=[moderated_by_user_id],
        lazy="selectin"
    )
    
    users_owning = relationship(
        "User",
        secondary="user_own_tags",
        back_populates="own_tags",
        lazy="selectin"
    )
    users_seeking = relationship(
        "User",
        secondary="user_seeking_tags",
        back_populates="seeking_tags",
        lazy="selectin"
    )
    
    events = relationship(
        "Event",
        secondary="event_tags",
        back_populates="tags",
        lazy="selectin"
    )

    def __repr__(self):
        return f"<Tag {self.name}>"

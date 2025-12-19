import uuid
from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import Column, Integer, String, Text, DateTime, Float, Boolean, Enum, Table, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from app.database import Base
from app.models.enums import EventStatus, EventCategory


# Association tables
event_tags = Table(
    "event_tags",
    Base.metadata,
    Column("event_id", UUID(as_uuid=True), ForeignKey("events.id"), primary_key=True),
    Column("tag_id", ForeignKey("tags.id"), primary_key=True),
)

event_participants = Table(
    "event_participants",
    Base.metadata,
    Column("event_id", UUID(as_uuid=True), ForeignKey("events.id"), primary_key=True),
    Column("user_uuid", UUID(as_uuid=True), ForeignKey("users.uuid"), primary_key=True),
)

event_owners = Table(
    "event_owners",
    Base.metadata,
    Column("event_id", UUID(as_uuid=True), ForeignKey("events.id"), primary_key=True),
    Column("user_uuid", UUID(as_uuid=True), ForeignKey("users.uuid"), primary_key=True),
)


class Event(Base):
    __tablename__ = "events"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    title = Column(String, nullable=False)
    description = Column(Text, nullable=True)
    venue = Column(String, nullable=True)
    
    category = Column(Enum(EventCategory), nullable=True)
    max_users_count = Column(Integer, default=0)
    
    start_date = Column(DateTime, nullable=True)
    end_date = Column(DateTime, nullable=True)
    
    status_transfer = Column(Boolean, default=False)
    status = Column(Enum(EventStatus), nullable=False, default=EventStatus.PLANNED)
    prize_fund = Column(Float, default=0)
    image_url = Column(String, nullable=True)
    
    created_at = Column(DateTime, default=datetime.utcnow)

    # Relationships
    tags = relationship(
        "Tag",
        secondary=event_tags,
        back_populates="events",
        lazy="selectin"
    )
    participants = relationship(
        "User",
        secondary=event_participants,
        lazy="selectin"
    )
    owners = relationship(
        "User",
        secondary=event_owners,
        lazy="selectin"
    )

    def __repr__(self):
        return f"<Event {self.title}>"

from datetime import datetime
from sqlalchemy import Column, Integer, DateTime, ForeignKey, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID

from app.database import Base


class UserSkip(Base):
    __tablename__ = "user_skip"

    id = Column(Integer, primary_key=True, autoincrement=True)
    from_user_id = Column(UUID(as_uuid=True), ForeignKey("users.uuid"), nullable=False)
    to_user_id = Column(UUID(as_uuid=True), ForeignKey("users.uuid"), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)

    __table_args__ = (
        UniqueConstraint("from_user_id", "to_user_id", name="uq_user_skip_pair"),
    )

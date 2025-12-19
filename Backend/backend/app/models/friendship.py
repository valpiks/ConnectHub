from sqlalchemy import Column, Integer, Enum, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from app.database import Base
from app.models.enums import FriendStatus


class Friendship(Base):
    __tablename__ = "friendship"

    id = Column(Integer, primary_key=True, autoincrement=True)
    
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.uuid"), nullable=False)
    friend_id = Column(UUID(as_uuid=True), ForeignKey("users.uuid"), nullable=False)
    
    status = Column(Enum(FriendStatus), nullable=False, default=FriendStatus.PENDING)

    # Relationships
    user = relationship("User", foreign_keys=[user_id], lazy="selectin")
    friend = relationship("User", foreign_keys=[friend_id], lazy="selectin")

    def __repr__(self):
        return f"<Friendship {self.user_id} -> {self.friend_id}>"

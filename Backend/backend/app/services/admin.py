from datetime import datetime
from sqlalchemy.orm import Session

from app.models.user import User
from app.models.tag import Tag
from app.models.enums import UserRole, TagStatus
from app.core.exceptions import (
    AdminRequiredError, TagNotFoundError, TagAlreadyExistsError, ValidationError
)
from app.services.base import BaseService

class AdminService(BaseService):
    def _check_admin(self, user: User):
        if user.role != UserRole.ROLE_ADMIN:
            raise AdminRequiredError()

    def create_tag(self, current_user: User, name: str):
        self._check_admin(current_user)
        
        existing = self.db.query(Tag).filter(Tag.name.ilike(name.strip().lower())).first()
        if existing:
            raise TagAlreadyExistsError()
        
        tag = Tag(
            name=name.strip().lower(),
            status=TagStatus.APPROVED,
            created_by_user_id=current_user.uuid,
            moderated_by_user_id=current_user.uuid,
            moderated_at=datetime.utcnow(),
            created_at=datetime.utcnow()
        )
        
        self.db.add(tag)
        self.db.commit()
        self.db.refresh(tag)
        
        self.logger.info(f"Tag created by admin {current_user.email}: {tag.name}")
        return {"message": "Тег создан", "id": tag.id, "name": tag.name}

    def delete_tag(self, current_user: User, tag_id: int):
        self._check_admin(current_user)
        
        tag = self.db.query(Tag).filter(Tag.id == tag_id).first()
        if not tag:
            raise TagNotFoundError()
        
        for e in list(tag.events):
            e.tags.remove(tag)
        for u in list(tag.users_owning):
            u.own_tags.remove(tag)
        for u in list(tag.users_seeking):
            u.seeking_tags.remove(tag)

        self.db.delete(tag)
        self.db.commit()

        
        self.logger.info(f"Tag deleted by admin {current_user.email}: {tag_id}")
        return {"message": "Тег удален"}

    def moderate_tag(self, current_user: User, tag_id: int, action: str, comment: str = None):
        self._check_admin(current_user)
        
        tag = self.db.query(Tag).filter(Tag.id == tag_id).first()
        if not tag:
            raise TagNotFoundError()
        
        if action.lower() == "approve":
            tag.status = TagStatus.APPROVED
        elif action.lower() == "reject":
            tag.status = TagStatus.REJECTED
        else:
            raise ValidationError(
                message="Неверное действие. Используйте 'approve' или 'reject'",
                details={"valid_actions": ["approve", "reject"]}
            )
        
        tag.moderated_by_user_id = current_user.uuid
        tag.moderated_at = datetime.utcnow()
        tag.moderation_comment = comment
        
        self.db.commit()
        
        self.logger.info(f"Tag {tag_id} moderated by admin {current_user.email}: {action}")
        return {"message": f"Тег {action}ed", "status": tag.status.value}

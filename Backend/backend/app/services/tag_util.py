from datetime import datetime

from sqlalchemy.orm import Session

from app.models.tag import Tag
from app.models.user import User
from app.models.enums import TagStatus, UserRole


def normalize_tag_name(name: str) -> str:
    return name.strip().lower()


def get_or_create_tag(
    db: Session,
    current_user: User,
    raw_name: str,
    *,
    auto_approve_for_admin: bool = True,
) -> Tag:
    name = normalize_tag_name(raw_name)
    if not name:
        raise ValueError("Пустое имя тега")

    tag = db.query(Tag).filter(Tag.name.ilike(name)).first()
    if tag:
        return tag

    status = TagStatus.PENDING
    if current_user.role == UserRole.ROLE_ADMIN and auto_approve_for_admin:
        status = TagStatus.AUTO_APPROVED

    tag = Tag(
        name=name,
        status=status,
        created_by_user_id=current_user.uuid,
        created_at=datetime.utcnow(),
    )

    if current_user.role == UserRole.ROLE_ADMIN and auto_approve_for_admin:
        tag.moderated_by_user_id = current_user.uuid
        tag.moderated_at = datetime.utcnow()

    db.add(tag)
    db.flush()
    return tag


def delete_tag_if_unused(db: Session, tag: Tag) -> None:
    # Удаляем тег только если он НИГДЕ не используется
    if not tag.users_owning and not tag.users_seeking and not tag.events:
        db.delete(tag)
        # commit снаружи, чтобы можно было батчить
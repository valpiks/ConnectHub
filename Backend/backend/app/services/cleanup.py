from datetime import datetime, timedelta

from sqlalchemy.orm import Session

from app.models.user_skip import UserSkip
from app.models.event_skip import EventSkip


def reset_skip_lists(db: Session) -> None:
    """
    Reset user and event skip lists for entries older than 1 day.

    This makes previously skipped users/events appear again in recommendations.
    """
    cutoff = datetime.utcnow() - timedelta(days=1)

    db.query(UserSkip).filter(UserSkip.created_at <= cutoff).delete(
        synchronize_session=False
    )
    db.query(EventSkip).filter(EventSkip.created_at <= cutoff).delete(
        synchronize_session=False
    )
    db.commit()


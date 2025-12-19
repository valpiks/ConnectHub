from datetime import datetime, timedelta
from typing import Dict

from sqlalchemy.orm import Session

from app.core.security import get_password_hash
from app.models.event import Event
from app.models.enums import EventStatus, EventCategory, UserRole
from app.models.user import User


MOCK_USERS: Dict[str, Dict[str, str]] = {
    "mock1@example.com": {"name": "Mock User 1", "tag": "mock1"},
    "mock2@example.com": {"name": "Mock User 2", "tag": "mock2"},
    "mock3@example.com": {"name": "Mock User 3", "tag": "mock3"},
    "mock4@example.com": {"name": "Mock User 4", "tag": "mock4"},
    "mock5@example.com": {"name": "Mock User 5", "tag": "mock5"},
    "mock6@example.com": {"name": "Mock User 6", "tag": "mock6"},
}


def create_mock_data(db: Session) -> None:
    """
    Create several mock users and events for demo/testing.
    Idempotent: safe to call multiple times.
    """
    # --- users ---
    existing_users = (
        db.query(User).filter(User.email.in_(list(MOCK_USERS.keys()))).all()
    )
    existing_by_email = {u.email: u for u in existing_users}

    for email, cfg in MOCK_USERS.items():
        if email in existing_by_email:
            continue

        user = User(
            name=cfg["name"],
            email=email,
            password=get_password_hash("password"),
            tag=cfg["tag"],
            role=UserRole.ROLE_USER,
        )
        db.add(user)

    db.commit()

    # reload to have uuids
    users = db.query(User).filter(User.email.in_(list(MOCK_USERS.keys()))).all()
    users_by_email = {u.email: u for u in users}

    # --- events ---
    # 1) Hackathon owned by mock1, participants mock2/mock3
    if not db.query(Event).filter(Event.title == "Mock Hackathon 1").first():
        owner = users_by_email.get("mock1@example.com")
        if owner:
            event = Event(
                title="Mock Hackathon 1",
                description="Большой тестовый хакатон",
                venue="Online",
                category=EventCategory.HACKATHON,
                max_users_count=200,
                start_date=datetime.utcnow(),
                end_date=datetime.utcnow() + timedelta(hours=8),
                status=EventStatus.PLANNED,
                prize_fund=100000,
            )
            event.owners.append(owner)
            for email in ("mock2@example.com", "mock3@example.com"):
                user = users_by_email.get(email)
                if user:
                    event.participants.append(user)
            db.add(event)

    # 2) Meetup owned by mock2, participants mock1/mock4
    if not db.query(Event).filter(Event.title == "Mock Meetup 1").first():
        owner = users_by_email.get("mock2@example.com")
        if owner:
            event = Event(
                title="Mock Meetup 1",
                description="Небольшая встреча разработчиков",
                venue="Коворкинг",
                category=EventCategory.MEETUP,
                max_users_count=30,
                start_date=datetime.utcnow() + timedelta(days=1),
                end_date=datetime.utcnow() + timedelta(days=1, hours=3),
                status=EventStatus.PLANNED,
                prize_fund=0,
            )
            event.owners.append(owner)
            for email in ("mock1@example.com", "mock4@example.com"):
                user = users_by_email.get(email)
                if user:
                    event.participants.append(user)
            db.add(event)

    # 3) Workshop owned by mock3, participants mock5/mock6
    if not db.query(Event).filter(Event.title == "Mock Workshop 1").first():
        owner = users_by_email.get("mock3@example.com")
        if owner:
            event = Event(
                title="Mock Workshop 1",
                description="Практический воркшоп по FastAPI",
                venue="Онлайн",
                category=EventCategory.WORKSHOP,
                max_users_count=50,
                start_date=datetime.utcnow() + timedelta(days=2),
                end_date=datetime.utcnow() + timedelta(days=2, hours=4),
                status=EventStatus.PLANNED,
                prize_fund=0,
            )
            event.owners.append(owner)
            for email in ("mock5@example.com", "mock6@example.com"):
                user = users_by_email.get(email)
                if user:
                    event.participants.append(user)
            db.add(event)

    db.commit()

import enum


class UserRole(str, enum.Enum):
    ROLE_USER = "ROLE_USER"
    ROLE_ADMIN = "ROLE_ADMIN"


class UserStatus(str, enum.Enum):
    LOOKING_FOR_TEAM = "looking_for_team"
    LOOKING_FOR_PROJECT = "looking_for_project"
    LOOKING_FOR_HACKATHON = "looking_for_hackathon"
    LOOKING_FOR_MENTOR = "looking_for_mentor"
    LOOKING_FOR_MENTEE = "looking_for_mentee"
    FREELANCE = "freelance"
    OPEN_TO_OFFERS = "open_to_offers"
    JUST_NETWORKING = "just_networking"


class TagStatus(str, enum.Enum):
    PENDING = "PENDING"
    APPROVED = "APPROVED"
    REJECTED = "REJECTED"
    AUTO_APPROVED = "AUTO_APPROVED"


class FriendStatus(str, enum.Enum):
    PENDING = "PENDING"
    ACCEPTED = "ACCEPTED"
    BLOCKED = "BLOCKED"
    REJECT = "REJECT"


class EventStatus(str, enum.Enum):
    PLANNED = "PLANNED"
    ACTIVE = "ACTIVE"
    COMPLETED = "COMPLETED"
    CANCELLED = "CANCELLED"


class EventCategory(str, enum.Enum):
    HACKATHON = "HACKATHON"
    MEETUP = "MEETUP"
    CONFERENCE = "CONFERENCE"
    WORKSHOP = "WORKSHOP"
    OTHER = "OTHER"

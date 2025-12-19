from sqlalchemy import create_engine, text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

from app.config import settings

engine = create_engine(settings.database_url)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()


def get_db():
    """Dependency for getting database session."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def run_migrations():
    """Run pending migrations for existing tables."""
    with engine.connect() as conn:
        # Add image_url to events if not exists
        conn.execute(text("""
            DO $$ 
            BEGIN
                IF NOT EXISTS (
                    SELECT 1 
                    FROM information_schema.columns 
                    WHERE table_name = 'events' AND column_name = 'image_url'
                ) THEN
                    ALTER TABLE events ADD COLUMN image_url VARCHAR NULL;
                END IF;
            END $$;
        """))
        conn.commit()


def create_tables():
    """Create all database tables and run migrations."""
    Base.metadata.create_all(bind=engine)
    run_migrations()


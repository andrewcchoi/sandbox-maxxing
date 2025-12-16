"""
Database connection and session management.
"""

import os
from urllib.parse import quote
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.models import Base

# Database URL from environment - Build from individual env vars (allows override of each component)
POSTGRES_USER = os.getenv("POSTGRES_USER", "sandbox_user")
POSTGRES_PASSWORD = os.getenv("POSTGRES_PASSWORD", "devpassword")
POSTGRES_HOST = os.getenv("POSTGRES_HOST", "postgres")
POSTGRES_PORT = os.getenv("POSTGRES_PORT", "5432")
POSTGRES_DB = os.getenv("POSTGRES_DB", "sandbox_dev")
# URL-encode credentials to prevent injection attacks from special characters (@, :, /, etc.)
DATABASE_URL = os.getenv("DATABASE_URL", f"postgresql://{quote(POSTGRES_USER, safe='')}:{quote(POSTGRES_PASSWORD, safe='')}@{POSTGRES_HOST}:{POSTGRES_PORT}/{POSTGRES_DB}")

# Create engine
engine = create_engine(DATABASE_URL, echo=False)

# Create session factory
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


def init_db():
    """Initialize database tables."""
    Base.metadata.create_all(bind=engine)


def get_db():
    """Dependency for getting database session."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

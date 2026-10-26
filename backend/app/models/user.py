import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, DateTime, Integer, Boolean, ForeignKey
from sqlalchemy.orm import relationship
from app.core.database import Base

def generate_uuid() -> str:
    return str(uuid.uuid4())

class User(Base):
    __tablename__ = "users"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    username = Column(String(100), unique=True, index=True, nullable=False)
    hashed_password = Column(String(255), nullable=False)
    display_name = Column(String(100), nullable=True)
    email = Column(String(255), unique=True, index=True, nullable=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

    # Relationships
    preferences = relationship("UserPreferences", back_populates="user", uselist=False, cascade="all, delete-orphan")
    goals = relationship("Goal", back_populates="user", cascade="all, delete-orphan")
    tasks = relationship("Task", back_populates="user", cascade="all, delete-orphan")
    xp_transactions = relationship("XPTransaction", back_populates="user", cascade="all, delete-orphan")
    focus_sessions = relationship("FocusSession", back_populates="user", cascade="all, delete-orphan")
    journal_entries = relationship("JournalEntry", back_populates="user", cascade="all, delete-orphan")
    achievements = relationship("Achievement", back_populates="user", cascade="all, delete-orphan")

class UserPreferences(Base):
    __tablename__ = "user_preferences"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False)
    available_daily_minutes = Column(Integer, default=120)
    planning_style = Column(String(50), default="balanced")  # aggressive, balanced, gentle
    reminder_time = Column(String(10), default="08:00")
    fcm_token = Column(String(255), nullable=True)
    notification_enabled = Column(Boolean, default=True)
    theme = Column(String(30), default="dark")
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

    user = relationship("User", back_populates="preferences")

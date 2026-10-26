import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, DateTime, Integer, Boolean, ForeignKey, Text
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
    device_tokens = relationship("UserDeviceToken", back_populates="user", cascade="all, delete-orphan")
    study_recommendations = relationship("StudyPlanRecommendation", back_populates="user", cascade="all, delete-orphan")
    scheduled_notifications = relationship("ScheduledNotification", back_populates="user", cascade="all, delete-orphan")

class UserPreferences(Base):
    __tablename__ = "user_preferences"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False)
    available_daily_minutes = Column(Integer, default=120)
    planning_style = Column(String(50), default="balanced")  # aggressive, balanced, gentle
    reminder_time = Column(String(10), default="08:00")
    fcm_token = Column(String(255), nullable=True)
    notification_enabled = Column(Boolean, default=True)
    reminder_lead_time_minutes = Column(Integer, default=15)
    preferred_planning_time = Column(String(10), default="07:00")
    quiet_hours_start = Column(String(10), default="22:00")
    quiet_hours_end = Column(String(10), default="06:00")
    timezone = Column(String(50), default="Asia/Kolkata")
    notify_study_reminders = Column(Boolean, default=True)
    notify_daily_plan = Column(Boolean, default=True)
    notify_overdue = Column(Boolean, default=True)
    notify_mock_tests = Column(Boolean, default=True)
    theme = Column(String(30), default="dark")
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

    user = relationship("User", back_populates="preferences")


class UserDeviceToken(Base):
    __tablename__ = "user_device_tokens"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    token = Column(String(500), nullable=False, index=True)
    platform = Column(String(20), default="android")  # android, web, ios
    device_info = Column(String(255), nullable=True)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    last_seen_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

    user = relationship("User", back_populates="device_tokens")


class StudyPlanRecommendation(Base):
    __tablename__ = "study_plan_recommendations"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    plan_date = Column(String(20), nullable=False, index=True)  # YYYY-MM-DD
    recommendation_text = Column(Text, nullable=False)
    reasoning_summary = Column(Text, nullable=True)
    task_references = Column(Text, nullable=True)  # JSON-encoded list of task IDs
    source = Column(String(50), default="grok")  # grok or deterministic_fallback
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

    user = relationship("User", back_populates="study_recommendations")


class ScheduledNotification(Base):
    __tablename__ = "scheduled_notifications"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    task_id = Column(String(36), ForeignKey("tasks.id", ondelete="SET NULL"), nullable=True, index=True)
    notification_type = Column(String(50), nullable=False)  # study_reminder, daily_plan, overdue, mock_test
    title = Column(String(255), nullable=False)
    body = Column(Text, nullable=False)
    scheduled_time = Column(DateTime, nullable=False, index=True)
    status = Column(String(30), default="pending", index=True)  # pending, sent, failed, cancelled, quiet_hours_skipped
    sent_at = Column(DateTime, nullable=True)
    error_message = Column(Text, nullable=True)
    retry_count = Column(Integer, default=0)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

    user = relationship("User", back_populates="scheduled_notifications")
    task = relationship("Task")


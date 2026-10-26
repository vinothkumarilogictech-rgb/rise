import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, DateTime, Integer, Boolean, ForeignKey
from sqlalchemy.orm import relationship
from app.core.database import Base

def generate_uuid() -> str:
    return str(uuid.uuid4())

class FocusSession(Base):
    __tablename__ = "focus_sessions"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    task_id = Column(String(36), ForeignKey("tasks.id", ondelete="SET NULL"), nullable=True)
    label = Column(String(150), default="Deep Focus Session")
    planned_duration_minutes = Column(Integer, default=25)
    actual_duration_minutes = Column(Integer, default=25)
    completed = Column(Boolean, default=True)
    xp_awarded = Column(Integer, default=10)
    started_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    ended_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

    user = relationship("User", back_populates="focus_sessions")

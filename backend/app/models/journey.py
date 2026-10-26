import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, DateTime, Integer, ForeignKey, Text
from sqlalchemy.orm import relationship
from app.core.database import Base

def generate_uuid() -> str:
    return str(uuid.uuid4())

class XPTransaction(Base):
    __tablename__ = "xp_transactions"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    amount = Column(Integer, nullable=False)
    source = Column(String(50), nullable=False)  # task, focus_session, reflection, achievement
    reference_id = Column(String(100), nullable=True)  # task_id or session_id
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), index=True)

    user = relationship("User", back_populates="xp_transactions")

class Achievement(Base):
    __tablename__ = "achievements"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    code = Column(String(50), nullable=False, index=True)  # first_step, streak_3, deep_focus, summit_walker
    title = Column(String(100), nullable=False)
    description = Column(String(255), nullable=False)
    icon = Column(String(50), default="mountain")
    unlocked_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

    user = relationship("User", back_populates="achievements")

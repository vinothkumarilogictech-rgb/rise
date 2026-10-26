import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, DateTime, Integer, Boolean, ForeignKey, Text
from sqlalchemy.orm import relationship
from app.core.database import Base

def generate_uuid() -> str:
    return str(uuid.uuid4())

class Task(Base):
    __tablename__ = "tasks"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    goal_id = Column(String(36), ForeignKey("goals.id", ondelete="SET NULL"), nullable=True, index=True)
    title = Column(String(255), nullable=False)
    description = Column(Text, nullable=True)
    category = Column(String(100), default="General")
    section = Column(String(50), default="Main Priorities")  # Morning Focus, Main Priorities, Evening Review
    priority = Column(String(20), default="medium")  # high, medium, low
    estimated_minutes = Column(Integer, default=25)
    xp_reward = Column(Integer, default=10)
    is_completed = Column(Boolean, default=False)
    completed_at = Column(DateTime, nullable=True)
    due_date = Column(String(30), nullable=True, index=True)
    why_it_matters = Column(Text, nullable=True)
    order_index = Column(Integer, default=0)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

    user = relationship("User", back_populates="tasks")
    goal = relationship("Goal", back_populates="tasks")
    completions = relationship("TaskCompletion", back_populates="task", cascade="all, delete-orphan")

class TaskCompletion(Base):
    __tablename__ = "task_completions"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    task_id = Column(String(36), ForeignKey("tasks.id", ondelete="CASCADE"), nullable=False, index=True)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    completed_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    xp_awarded = Column(Integer, default=10)

    task = relationship("Task", back_populates="completions")

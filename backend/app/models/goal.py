import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, DateTime, Integer, Float, ForeignKey, Text, Boolean
from sqlalchemy.orm import relationship
from app.core.database import Base

def generate_uuid() -> str:
    return str(uuid.uuid4())

class Goal(Base):
    __tablename__ = "goals"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    title = Column(String(255), nullable=False)
    category = Column(String(100), default="General", index=True)  # GATE 2027, Coding, Career, Well-being, Custom
    description = Column(Text, nullable=True)
    target_date = Column(String(30), nullable=True)
    status = Column(String(30), default="active")  # active, completed, archived
    progress_percentage = Column(Float, default=0.0)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

    user = relationship("User", back_populates="goals")
    milestones = relationship("GoalMilestone", back_populates="goal", cascade="all, delete-orphan", order_by="GoalMilestone.order_index")
    tasks = relationship("Task", back_populates="goal", cascade="all, delete-orphan")

class GoalMilestone(Base):
    __tablename__ = "goal_milestones"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    goal_id = Column(String(36), ForeignKey("goals.id", ondelete="CASCADE"), nullable=False, index=True)
    title = Column(String(255), nullable=False)
    is_completed = Column(Boolean, default=False)
    order_index = Column(Integer, default=0)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

    goal = relationship("Goal", back_populates="milestones")

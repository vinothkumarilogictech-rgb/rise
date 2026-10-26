from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime

class MilestoneBase(BaseModel):
    title: str
    is_completed: bool = False
    order_index: int = 0

class MilestoneCreate(MilestoneBase):
    pass

class MilestoneResponse(MilestoneBase):
    id: str
    goal_id: str
    created_at: datetime

    class Config:
        from_attributes = True

class GoalBase(BaseModel):
    title: str = Field(..., min_length=2)
    category: str = "General"  # GATE 2027, Coding Independence, Career & Work, Personal Well-being
    description: Optional[str] = None
    target_date: Optional[str] = None
    status: str = "active"

class GoalCreate(GoalBase):
    milestones: Optional[List[MilestoneCreate]] = []

class GoalUpdate(BaseModel):
    title: Optional[str] = None
    category: Optional[str] = None
    description: Optional[str] = None
    target_date: Optional[str] = None
    status: Optional[str] = None
    progress_percentage: Optional[float] = None

class GoalResponse(GoalBase):
    id: str
    user_id: str
    progress_percentage: float
    milestones: List[MilestoneResponse] = []
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime

class TaskBase(BaseModel):
    title: str = Field(..., min_length=2)
    description: Optional[str] = None
    goal_id: Optional[str] = None
    category: str = "General"
    section: str = "Main Priorities"  # Morning Focus, Main Priorities, Evening Review
    priority: str = "medium"  # high, medium, low
    estimated_minutes: int = 25
    xp_reward: int = 10
    due_date: Optional[str] = None
    start_time: Optional[str] = None
    end_time: Optional[str] = None
    weekday: Optional[str] = None
    session_type: Optional[str] = "study"
    import_batch_id: Optional[str] = None
    why_it_matters: Optional[str] = None
    order_index: int = 0

class TaskCreate(TaskBase):
    pass

class TaskUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    goal_id: Optional[str] = None
    category: Optional[str] = None
    section: Optional[str] = None
    priority: Optional[str] = None
    estimated_minutes: Optional[int] = None
    xp_reward: Optional[int] = None
    is_completed: Optional[bool] = None
    due_date: Optional[str] = None
    start_time: Optional[str] = None
    end_time: Optional[str] = None
    weekday: Optional[str] = None
    session_type: Optional[str] = None
    import_batch_id: Optional[str] = None
    why_it_matters: Optional[str] = None
    order_index: Optional[int] = None

class TaskResponse(TaskBase):
    id: str
    user_id: str
    is_completed: bool
    completed_at: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

class TaskCompletionResponse(BaseModel):
    task: TaskResponse
    xp_awarded: int
    total_xp: int
    level: int
    is_duplicate: bool

from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime

class FocusSessionCreate(BaseModel):
    task_id: Optional[str] = None
    label: str = Field(default="Deep Focus Session", max_length=150)
    planned_duration_minutes: int = Field(default=25, ge=1, le=360)
    actual_duration_minutes: int = Field(default=25, ge=1, le=360)
    completed: bool = True

class FocusSessionResponse(BaseModel):
    id: str
    user_id: str
    task_id: Optional[str] = None
    label: str
    planned_duration_minutes: int
    actual_duration_minutes: int
    completed: bool
    xp_awarded: int
    started_at: datetime
    ended_at: datetime

    class Config:
        from_attributes = True

class FocusSessionCompleteResponse(BaseModel):
    session: FocusSessionResponse
    xp_awarded: int
    total_xp: int

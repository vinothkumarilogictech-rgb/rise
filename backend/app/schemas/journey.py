from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime

class MilestoneItem(BaseModel):
    level: int
    xp_required: int
    stage_name: str
    is_reached: bool
    is_current: bool

class JourneySummaryResponse(BaseModel):
    level: int
    stage_name: str
    total_xp: int
    base_level_xp: int
    next_level_xp: int
    xp_to_next_level: int
    progress_ratio: float
    mountain_progress_percent: float
    current_streak_days: int
    tasks_completed_count: int
    focus_minutes_total: int
    daily_message: str

class XPTransactionResponse(BaseModel):
    id: str
    amount: int
    source: str
    reference_id: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True

class AchievementResponse(BaseModel):
    id: str
    code: str
    title: str
    description: str
    icon: str
    unlocked_at: datetime

    class Config:
        from_attributes = True

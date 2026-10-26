from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class UserPreferencesUpdate(BaseModel):
    display_name: Optional[str] = None
    available_daily_minutes: Optional[int] = None
    planning_style: Optional[str] = None
    reminder_time: Optional[str] = None
    fcm_token: Optional[str] = None
    notification_enabled: Optional[bool] = None
    theme: Optional[str] = None

class UserPreferencesResponse(BaseModel):
    username: str
    display_name: str
    available_daily_minutes: int
    planning_style: str
    reminder_time: str
    notification_enabled: bool
    theme: str
    updated_at: datetime

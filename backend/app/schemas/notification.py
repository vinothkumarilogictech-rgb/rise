from pydantic import BaseModel, Field
from typing import Optional, List

class DeviceTokenRegisterRequest(BaseModel):
    token: str = Field(..., min_length=10, max_length=500)
    platform: str = Field(default="android", max_length=20)
    device_info: Optional[str] = Field(default=None, max_length=255)

class DeviceTokenDeleteRequest(BaseModel):
    token: str = Field(..., min_length=10, max_length=500)

class NotificationPreferencesResponse(BaseModel):
    notification_enabled: bool
    reminder_lead_time_minutes: int
    preferred_planning_time: str
    quiet_hours_start: str
    quiet_hours_end: str
    timezone: str
    notify_study_reminders: bool
    notify_daily_plan: bool
    notify_overdue: bool
    notify_mock_tests: bool

    class Config:
        from_attributes = True

class NotificationPreferencesUpdate(BaseModel):
    notification_enabled: Optional[bool] = None
    reminder_lead_time_minutes: Optional[int] = Field(default=None, ge=0, le=120)
    preferred_planning_time: Optional[str] = None
    quiet_hours_start: Optional[str] = None
    quiet_hours_end: Optional[str] = None
    timezone: Optional[str] = None
    notify_study_reminders: Optional[bool] = None
    notify_daily_plan: Optional[bool] = None
    notify_overdue: Optional[bool] = None
    notify_mock_tests: Optional[bool] = None

class TestPushRequest(BaseModel):
    title: Optional[str] = "RISE Study Reminder — Network Theory"
    body: Optional[str] = "Session starting in 15 minutes. Begin with KCL, KVL and nodal analysis practice."
    token: Optional[str] = None

class TestPushResponse(BaseModel):
    sent: int
    failed: int
    status: str
    message: str

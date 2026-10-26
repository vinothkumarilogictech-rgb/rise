from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime

class UserRegisterRequest(BaseModel):
    username: str = Field(..., min_length=3, max_length=50)
    password: str = Field(..., min_length=6, max_length=128)
    display_name: Optional[str] = None
    available_daily_minutes: Optional[int] = 120
    planning_style: Optional[str] = "balanced"
    reminder_time: Optional[str] = "08:00"

class UserLoginRequest(BaseModel):
    username: str = Field(..., min_length=1)
    password: str = Field(..., min_length=1)

class UserResponse(BaseModel):
    id: str
    username: str
    display_name: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserResponse

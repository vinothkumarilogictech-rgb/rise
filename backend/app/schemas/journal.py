from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class JournalEntryCreate(BaseModel):
    date: str  # YYYY-MM-DD
    content: str
    prompts_answered: Optional[str] = None
    mood: Optional[str] = "focused"
    image_url: Optional[str] = None

class JournalEntryUpdate(BaseModel):
    content: Optional[str] = None
    prompts_answered: Optional[str] = None
    mood: Optional[str] = None
    image_url: Optional[str] = None

class JournalEntryResponse(BaseModel):
    id: str
    user_id: str
    date: str
    content: str
    prompts_answered: Optional[str] = None
    mood: str
    image_url: Optional[str] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

class JournalEntrySaveResponse(BaseModel):
    entry: JournalEntryResponse
    xp_awarded: int
    total_xp: int

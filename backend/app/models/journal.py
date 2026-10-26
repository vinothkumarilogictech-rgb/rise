import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, DateTime, ForeignKey, Text
from sqlalchemy.orm import relationship
from app.core.database import Base

def generate_uuid() -> str:
    return str(uuid.uuid4())

class JournalEntry(Base):
    __tablename__ = "journal_entries"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    date = Column(String(10), nullable=False, index=True)  # YYYY-MM-DD
    content = Column(Text, nullable=False)
    prompts_answered = Column(Text, nullable=True)  # JSON-encoded prompts & answers
    mood = Column(String(30), default="focused")  # focused, grateful, tired, motivated, calm
    image_url = Column(String(500), nullable=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

    user = relationship("User", back_populates="journal_entries")

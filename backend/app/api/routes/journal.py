from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime, timezone
from app.core.database import get_db
from app.models.user import User
from app.models.journal import JournalEntry
from app.schemas.journal import (
    JournalEntryCreate,
    JournalEntryUpdate,
    JournalEntryResponse,
    JournalEntrySaveResponse
)
from app.api.deps import get_current_user
from app.services.xp_service import award_xp, get_user_total_xp

router = APIRouter(prefix="/journal", tags=["Daily Journal"])

@router.get("", response_model=List[JournalEntryResponse])
def get_journal_entries(
    date: Optional[str] = None,
    limit: int = 30,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    query = db.query(JournalEntry).filter(JournalEntry.user_id == current_user.id)
    if date:
        query = query.filter(JournalEntry.date == date)
    entries = query.order_by(JournalEntry.date.desc(), JournalEntry.created_at.desc()).limit(limit).all()
    return [JournalEntryResponse.model_validate(e) for e in entries]

@router.post("", response_model=JournalEntrySaveResponse, status_code=status.HTTP_201_CREATED)
def create_journal_entry(
    req: JournalEntryCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    # Check if entry already exists for this date
    existing = db.query(JournalEntry).filter(
        JournalEntry.user_id == current_user.id,
        JournalEntry.date == req.date
    ).first()

    is_new = False
    if existing:
        entry = existing
        entry.content = req.content
        if req.prompts_answered:
            entry.prompts_answered = req.prompts_answered
        if req.mood:
            entry.mood = req.mood
        if req.image_url:
            entry.image_url = req.image_url
        entry.updated_at = datetime.now(timezone.utc)
    else:
        is_new = True
        entry = JournalEntry(
            user_id=current_user.id,
            date=req.date,
            content=req.content,
            prompts_answered=req.prompts_answered,
            mood=req.mood or "focused",
            image_url=req.image_url
        )
        db.add(entry)
    
    db.flush()

    # Award 5 XP for reflection if first time for this date
    xp_awarded = 0
    ref_id = f"journal_{req.date}"
    awarded, _ = award_xp(db, current_user.id, 5, "reflection", reference_id=ref_id)
    if awarded:
        xp_awarded = 5

    db.commit()
    db.refresh(entry)

    total_xp = get_user_total_xp(db, current_user.id)
    return JournalEntrySaveResponse(
        entry=JournalEntryResponse.model_validate(entry),
        xp_awarded=xp_awarded,
        total_xp=total_xp
    )

@router.get("/{entry_id}", response_model=JournalEntryResponse)
def get_journal_entry(
    entry_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    entry = db.query(JournalEntry).filter(
        JournalEntry.id == entry_id,
        JournalEntry.user_id == current_user.id
    ).first()
    if not entry:
        raise HTTPException(status_code=404, detail="Journal entry not found.")
    return JournalEntryResponse.model_validate(entry)

@router.patch("/{entry_id}", response_model=JournalEntryResponse)
def update_journal_entry(
    entry_id: str,
    req: JournalEntryUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    entry = db.query(JournalEntry).filter(
        JournalEntry.id == entry_id,
        JournalEntry.user_id == current_user.id
    ).first()
    if not entry:
        raise HTTPException(status_code=404, detail="Journal entry not found.")

    update_data = req.model_dump(exclude_unset=True)
    for field, val in update_data.items():
        setattr(entry, field, val)
    entry.updated_at = datetime.now(timezone.utc)

    db.commit()
    db.refresh(entry)
    return JournalEntryResponse.model_validate(entry)

@router.delete("/{entry_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_journal_entry(
    entry_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    entry = db.query(JournalEntry).filter(
        JournalEntry.id == entry_id,
        JournalEntry.user_id == current_user.id
    ).first()
    if not entry:
        raise HTTPException(status_code=404, detail="Journal entry not found.")
    db.delete(entry)
    db.commit()
    return None

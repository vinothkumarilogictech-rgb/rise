from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from datetime import datetime, timezone, timedelta
from app.core.database import get_db
from app.models.user import User
from app.models.task import Task
from app.models.focus import FocusSession
from app.schemas.focus import FocusSessionCreate, FocusSessionResponse, FocusSessionCompleteResponse
from app.api.deps import get_current_user
from app.services.xp_service import award_xp, get_user_total_xp

router = APIRouter(prefix="/focus", tags=["Focus Sessions"])

@router.get("/sessions", response_model=List[FocusSessionResponse])
def get_focus_sessions(
    limit: int = 20,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    sessions = db.query(FocusSession).filter(
        FocusSession.user_id == current_user.id
    ).order_by(FocusSession.started_at.desc()).limit(limit).all()
    return [FocusSessionResponse.model_validate(s) for s in sessions]

@router.post("/sessions", response_model=FocusSessionCompleteResponse, status_code=status.HTTP_201_CREATED)
def create_focus_session(
    req: FocusSessionCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if req.task_id:
        task = db.query(Task).filter(
            Task.id == req.task_id,
            Task.user_id == current_user.id
        ).first()
        if not task:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Associated task not found or does not belong to you."
            )

    now = datetime.now(timezone.utc)
    started = now - timedelta(minutes=req.actual_duration_minutes)

    # Award 10 XP only for completed session of at least 10 minutes
    xp_to_award = 10 if (req.completed and req.actual_duration_minutes >= 10) else 0

    session = FocusSession(
        user_id=current_user.id,
        task_id=req.task_id,
        label=req.label,
        planned_duration_minutes=req.planned_duration_minutes,
        actual_duration_minutes=req.actual_duration_minutes,
        completed=req.completed,
        xp_awarded=xp_to_award,
        started_at=started,
        ended_at=now
    )
    db.add(session)
    db.flush()

    if xp_to_award > 0:
        award_xp(db, current_user.id, xp_to_award, "focus_session", reference_id=session.id)

    db.commit()
    db.refresh(session)

    total_xp = get_user_total_xp(db, current_user.id)
    return FocusSessionCompleteResponse(
        session=FocusSessionResponse.model_validate(session),
        xp_awarded=xp_to_award,
        total_xp=total_xp
    )

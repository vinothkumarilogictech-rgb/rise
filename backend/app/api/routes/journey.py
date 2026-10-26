from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import List
from datetime import datetime, timezone, timedelta
from app.core.database import get_db
from app.models.user import User
from app.models.journey import XPTransaction, Achievement
from app.models.task import Task
from app.models.focus import FocusSession
from app.schemas.journey import (
    JourneySummaryResponse,
    MilestoneItem,
    XPTransactionResponse,
    AchievementResponse
)
from app.api.deps import get_current_user
from app.services.xp_service import calculate_level_info, get_user_total_xp, LEVEL_TIERS

router = APIRouter(prefix="/journey", tags=["Journey & Gamification"])

def compute_streak(db: Session, user_id: str) -> int:
    """Calculates active streak of completed tasks or focus sessions."""
    today = datetime.now(timezone.utc).date()
    streak = 0
    # Check up to 30 days back
    for d in range(30):
        check_date = today - timedelta(days=d)
        date_str = check_date.strftime("%Y-%m-%d")
        task_count = db.query(Task).filter(
            Task.user_id == user_id,
            Task.is_completed == True,
            func.date(Task.completed_at) == date_str
        ).count()
        if task_count == 0:
            focus_count = db.query(FocusSession).filter(
                FocusSession.user_id == user_id,
                FocusSession.completed == True,
                func.date(FocusSession.started_at) == date_str
            ).count()
            if focus_count == 0:
                if d == 0:
                    # Today hasn't completed a task yet, streak from yesterday might still be active
                    continue
                else:
                    break
        streak += 1
    return streak

@router.get("/summary", response_model=JourneySummaryResponse)
def get_journey_summary(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    total_xp = get_user_total_xp(db, current_user.id)
    level_info = calculate_level_info(total_xp)
    streak = compute_streak(db, current_user.id)

    completed_tasks_count = db.query(Task).filter(
        Task.user_id == current_user.id,
        Task.is_completed == True
    ).count()

    total_focus_minutes = db.query(
        func.coalesce(func.sum(FocusSession.actual_duration_minutes), 0)
    ).filter(
        FocusSession.user_id == current_user.id,
        FocusSession.completed == True
    ).scalar()

    daily_messages = [
        "Every focused session moves you closer to your summit.",
        "Small steps, done with fierce consistency, yield monumental results.",
        "Breathe, focus on the immediate ridge, and climb with calm discipline.",
        "Your future self will thank you for the focus you cultivate today.",
    ]
    message_idx = (datetime.now().timetuple().tm_yday) % len(daily_messages)

    return JourneySummaryResponse(
        level=level_info["level"],
        stage_name=level_info["stage_name"],
        total_xp=total_xp,
        base_level_xp=level_info["base_level_xp"],
        next_level_xp=level_info["next_level_xp"],
        xp_to_next_level=level_info["xp_to_next_level"],
        progress_ratio=level_info["progress_ratio"],
        mountain_progress_percent=level_info["mountain_progress_percent"],
        current_streak_days=streak,
        tasks_completed_count=completed_tasks_count,
        focus_minutes_total=int(total_focus_minutes or 0),
        daily_message=daily_messages[message_idx]
    )

@router.get("/milestones", response_model=List[MilestoneItem])
def get_journey_milestones(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    total_xp = get_user_total_xp(db, current_user.id)
    level_info = calculate_level_info(total_xp)
    curr_level = level_info["level"]

    milestones = []
    for tier_level, tier_xp, tier_stage in LEVEL_TIERS:
        milestones.append(
            MilestoneItem(
                level=tier_level,
                xp_required=tier_xp,
                stage_name=tier_stage,
                is_reached=total_xp >= tier_xp,
                is_current=tier_level == curr_level
            )
        )
    return milestones

@router.get("/xp-history", response_model=List[XPTransactionResponse])
def get_xp_history(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    history = db.query(XPTransaction).filter(
        XPTransaction.user_id == current_user.id
    ).order_by(XPTransaction.created_at.desc()).limit(50).all()
    return [XPTransactionResponse.model_validate(h) for h in history]

@router.get("/achievements", response_model=List[AchievementResponse])
def get_achievements(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    achs = db.query(Achievement).filter(
        Achievement.user_id == current_user.id
    ).order_by(Achievement.unlocked_at.desc()).all()
    return [AchievementResponse.model_validate(a) for a in achs]

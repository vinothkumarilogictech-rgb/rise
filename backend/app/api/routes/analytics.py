from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import List
from datetime import datetime, timezone, timedelta
from app.core.database import get_db
from app.models.user import User
from app.models.task import Task
from app.models.goal import Goal
from app.models.focus import FocusSession
from app.models.journal import JournalEntry
from app.models.journey import XPTransaction
from app.schemas.analytics import (
    AnalyticsOverviewResponse,
    WeeklyTrendResponse,
    DailyCompletionPoint,
    GoalProgressPoint
)
from app.api.deps import get_current_user
from app.services.xp_service import get_user_total_xp
from app.api.routes.journey import compute_streak

router = APIRouter(prefix="/analytics", tags=["Analytics & Progress"])

DAY_NAMES = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

def build_weekly_points(db: Session, user_id: str) -> List[DailyCompletionPoint]:
    today = datetime.now(timezone.utc).date()
    points = []
    # 7 days from (today - 6) to today
    for i in range(6, -1, -1):
        target_date = today - timedelta(days=i)
        date_str = target_date.strftime("%Y-%m-%d")
        day_name = DAY_NAMES[target_date.weekday()]

        tasks = db.query(Task).filter(Task.user_id == user_id, Task.due_date == date_str).all()
        total_tasks = len(tasks)
        completed_tasks = sum(1 for t in tasks if t.is_completed)

        focus_mins = db.query(func.coalesce(func.sum(FocusSession.actual_duration_minutes), 0)).filter(
            FocusSession.user_id == user_id,
            FocusSession.completed == True,
            func.date(FocusSession.started_at) == date_str
        ).scalar()

        xp_earned = db.query(func.coalesce(func.sum(XPTransaction.amount), 0)).filter(
            XPTransaction.user_id == user_id,
            func.date(XPTransaction.created_at) == date_str
        ).scalar()

        points.append(
            DailyCompletionPoint(
                date=date_str,
                day_name=day_name,
                completed_tasks=completed_tasks,
                total_tasks=total_tasks,
                focus_minutes=int(focus_mins or 0),
                xp_earned=int(xp_earned or 0)
            )
        )
    return points

@router.get("/overview", response_model=AnalyticsOverviewResponse)
def get_analytics_overview(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    total_completed = db.query(Task).filter(Task.user_id == current_user.id, Task.is_completed == True).count()
    total_all_tasks = db.query(Task).filter(Task.user_id == current_user.id).count()
    rate = round((total_completed / max(1, total_all_tasks)) * 100.0, 1) if total_all_tasks > 0 else 0.0

    streak = compute_streak(db, current_user.id)
    total_xp = get_user_total_xp(db, current_user.id)

    total_focus = db.query(func.coalesce(func.sum(FocusSession.actual_duration_minutes), 0)).filter(
        FocusSession.user_id == current_user.id,
        FocusSession.completed == True
    ).scalar()

    journals_count = db.query(JournalEntry).filter(JournalEntry.user_id == current_user.id).count()

    today_str = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    today_tasks = db.query(Task).filter(Task.user_id == current_user.id, Task.due_date == today_str).all()
    today_completed = sum(1 for t in today_tasks if t.is_completed)

    weekly_trend = build_weekly_points(db, current_user.id)

    # Goal breakdown
    goals = db.query(Goal).filter(Goal.user_id == current_user.id).all()
    goal_points = []
    for g in goals:
        g_tasks = db.query(Task).filter(Task.goal_id == g.id).all()
        g_total = len(g_tasks)
        g_comp = sum(1 for t in g_tasks if t.is_completed)
        progress = round((g_comp / max(1, g_total)) * 100.0, 1) if g_total > 0 else g.progress_percentage
        goal_points.append(
            GoalProgressPoint(
                goal_id=g.id,
                title=g.title,
                category=g.category,
                progress_percentage=progress,
                total_tasks=g_total,
                completed_tasks=g_comp
            )
        )

    return AnalyticsOverviewResponse(
        total_tasks_completed=total_completed,
        completion_rate_percentage=rate,
        current_streak=streak,
        best_streak=max(streak, 1) if streak > 0 else 0,
        total_focus_minutes=int(total_focus or 0),
        total_xp=total_xp,
        journal_entries_count=journals_count,
        today_completed_tasks=today_completed,
        today_total_tasks=len(today_tasks),
        weekly_trend=weekly_trend,
        goal_progress=goal_points
    )

@router.get("/weekly", response_model=WeeklyTrendResponse)
def get_weekly_trend(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    trend = build_weekly_points(db, current_user.id)
    weekly_xp = sum(p.xp_earned for p in trend)
    weekly_focus = sum(p.focus_minutes for p in trend)
    return WeeklyTrendResponse(
        days=trend,
        total_weekly_xp=weekly_xp,
        total_weekly_focus_minutes=weekly_focus
    )

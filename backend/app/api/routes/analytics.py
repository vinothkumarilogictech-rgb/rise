from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import List, Dict
from datetime import datetime, timezone, timedelta, date
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
    GoalProgressPoint,
    SubjectProgressPoint,
    MockTestSummary,
)
from app.api.deps import get_current_user
from app.services.xp_service import get_user_total_xp
from app.api.routes.journey import compute_streak

router = APIRouter(prefix="/analytics", tags=["Analytics & Progress"])

DAY_NAMES = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

def build_weekly_points(db: Session, user_id: str) -> List[DailyCompletionPoint]:
    today = date.today()
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
    today_str = date.today().strftime("%Y-%m-%d")

    # All non-break tasks
    all_tasks = db.query(Task).filter(Task.user_id == current_user.id).all()
    study_tasks = [t for t in all_tasks if getattr(t, 'session_type', 'study') != 'break']
    total_all_tasks = len(study_tasks)
    total_completed = sum(1 for t in study_tasks if t.is_completed)
    rate = round((total_completed / max(1, total_all_tasks)) * 100.0, 1) if total_all_tasks > 0 else 0.0

    streak = compute_streak(db, current_user.id)
    total_xp = get_user_total_xp(db, current_user.id)

    # Focus minutes
    recorded_focus_mins = db.query(func.coalesce(func.sum(FocusSession.actual_duration_minutes), 0)).filter(
        FocusSession.user_id == current_user.id,
        FocusSession.completed == True
    ).scalar() or 0

    planned_study_mins = sum((t.estimated_minutes or 25) for t in study_tasks)

    # Timetable adherence
    timetable_tasks = [t for t in study_tasks if t.import_batch_id]
    tt_total = len(timetable_tasks)
    tt_completed = sum(1 for t in timetable_tasks if t.is_completed)
    tt_adherence = round((tt_completed / max(1, tt_total)) * 100.0, 1) if tt_total > 0 else (rate if total_all_tasks > 0 else 0.0)

    # Overdue tasks
    overdue_count = sum(1 for t in study_tasks if not t.is_completed and t.due_date and t.due_date < today_str)

    # Journals count
    journals_count = db.query(JournalEntry).filter(JournalEntry.user_id == current_user.id).count()

    # Today's tasks
    today_tasks = [t for t in study_tasks if t.due_date == today_str]
    today_completed = sum(1 for t in today_tasks if t.is_completed)

    weekly_trend = build_weekly_points(db, current_user.id)

    # Goal breakdown
    goals = db.query(Goal).filter(Goal.user_id == current_user.id).all()
    goal_points = []
    for g in goals:
        g_tasks = [t for t in study_tasks if t.goal_id == g.id]
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

    # Subject breakdown
    subject_map: Dict[str, Dict[str, int]] = {}
    for t in study_tasks:
        subj = t.category or "General"
        if subj not in subject_map:
            subject_map[subj] = {"total": 0, "completed": 0, "minutes": 0}
        subject_map[subj]["total"] += 1
        if t.is_completed:
            subject_map[subj]["completed"] += 1
        subject_map[subj]["minutes"] += (t.estimated_minutes or 25)

    subject_points = []
    for s_name, s_data in subject_map.items():
        s_rate = round((s_data["completed"] / max(1, s_data["total"])) * 100.0, 1)
        subject_points.append(
            SubjectProgressPoint(
                subject=s_name,
                total_tasks=s_data["total"],
                completed_tasks=s_data["completed"],
                completion_rate=s_rate,
                total_minutes=s_data["minutes"]
            )
        )
    subject_points.sort(key=lambda x: x.total_minutes, reverse=True)

    # Mock tests and PYQs
    mock_tasks = [t for t in all_tasks if getattr(t, 'session_type', '') == 'mock_test' or "mock" in t.title.lower()]
    pyq_tasks = [t for t in all_tasks if getattr(t, 'session_type', '') == 'pyq' or "pyq" in t.title.lower()]

    mock_summary = MockTestSummary(
        total_mock_tests=len(mock_tasks),
        completed_mock_tests=sum(1 for t in mock_tasks if t.is_completed),
        total_pyq_sessions=len(pyq_tasks),
        completed_pyq_sessions=sum(1 for t in pyq_tasks if t.is_completed)
    )

    # Revision recommendations
    recs = []
    for sp in subject_points:
        if sp.total_tasks >= 2 and sp.completion_rate < 50.0:
            recs.append(f"Focus revision on '{sp.subject}' (completion rate {sp.completion_rate}%).")
    if overdue_count > 0:
        recs.append(f"You have {overdue_count} overdue task(s). Clear immediate bottlenecks first.")
    if not recs:
        recs.append("Study cadence is on track! Review your error logbook to consolidate formulas.")

    return AnalyticsOverviewResponse(
        total_tasks_completed=total_completed,
        total_all_tasks=total_all_tasks,
        completion_rate_percentage=rate,
        current_streak=streak,
        best_streak=max(streak, 1) if streak > 0 else 0,
        total_focus_minutes=int(recorded_focus_mins),
        planned_study_minutes=planned_study_mins,
        recorded_study_minutes=int(recorded_focus_mins),
        timetable_adherence_rate=tt_adherence,
        overdue_tasks_count=overdue_count,
        total_xp=total_xp,
        journal_entries_count=journals_count,
        today_completed_tasks=today_completed,
        today_total_tasks=len(today_tasks),
        weekly_trend=weekly_trend,
        goal_progress=goal_points,
        subject_breakdown=subject_points,
        mock_tests=mock_summary,
        revision_recommendations=recs
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

from pydantic import BaseModel
from typing import List, Dict, Any

class DailyCompletionPoint(BaseModel):
    date: str  # YYYY-MM-DD
    day_name: str
    completed_tasks: int
    total_tasks: int
    focus_minutes: int
    xp_earned: int

class GoalProgressPoint(BaseModel):
    goal_id: str
    title: str
    category: str
    progress_percentage: float
    total_tasks: int
    completed_tasks: int

class AnalyticsOverviewResponse(BaseModel):
    total_tasks_completed: int
    completion_rate_percentage: float
    current_streak: int
    best_streak: int
    total_focus_minutes: int
    total_xp: int
    journal_entries_count: int
    today_completed_tasks: int
    today_total_tasks: int
    weekly_trend: List[DailyCompletionPoint]
    goal_progress: List[GoalProgressPoint]

class WeeklyTrendResponse(BaseModel):
    days: List[DailyCompletionPoint]
    total_weekly_xp: int
    total_weekly_focus_minutes: int

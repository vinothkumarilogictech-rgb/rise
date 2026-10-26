from pydantic import BaseModel
from typing import List, Optional

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

class SubjectProgressPoint(BaseModel):
    subject: str
    total_tasks: int
    completed_tasks: int
    completion_rate: float
    total_minutes: int

class MockTestSummary(BaseModel):
    total_mock_tests: int
    completed_mock_tests: int
    total_pyq_sessions: int
    completed_pyq_sessions: int

class AnalyticsOverviewResponse(BaseModel):
    total_tasks_completed: int
    total_all_tasks: int
    completion_rate_percentage: float
    current_streak: int
    best_streak: int
    total_focus_minutes: int
    planned_study_minutes: int
    recorded_study_minutes: int
    timetable_adherence_rate: float
    overdue_tasks_count: int
    total_xp: int
    journal_entries_count: int
    today_completed_tasks: int
    today_total_tasks: int
    weekly_trend: List[DailyCompletionPoint]
    goal_progress: List[GoalProgressPoint]
    subject_breakdown: List[SubjectProgressPoint]
    mock_tests: MockTestSummary
    revision_recommendations: List[str]

class WeeklyTrendResponse(BaseModel):
    days: List[DailyCompletionPoint]
    total_weekly_xp: int
    total_weekly_focus_minutes: int

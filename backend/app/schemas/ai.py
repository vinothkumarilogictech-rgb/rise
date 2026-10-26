from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any

class AIPlanRequest(BaseModel):
    goal_title: str = Field(..., min_length=2, max_length=200)
    goal_category: Optional[str] = Field(default="General", max_length=100)
    available_minutes: Optional[int] = Field(default=120, ge=15, le=720)
    context: Optional[str] = Field(default=None, max_length=1000)

class AITaskPlanItem(BaseModel):
    title: str = Field(..., min_length=2, max_length=255)
    description: str = Field(..., max_length=1000)
    section: str = "Main Priorities"
    priority: str = "medium"
    estimated_minutes: int = Field(default=25, ge=5, le=240)
    xp_reward: int = Field(default=10, ge=5, le=50)
    why_it_matters: Optional[str] = Field(default=None, max_length=500)

class AIPlanResponse(BaseModel):
    goal_title: str
    tasks: List[AITaskPlanItem]

class AIChatMessage(BaseModel):
    role: str  # user or assistant
    content: str = Field(..., max_length=20000)

class AIChatRequest(BaseModel):
    message: str = Field(..., min_length=1, max_length=4000)
    history: Optional[List[AIChatMessage]] = Field(default=[], max_length=50)

class AIChatResponse(BaseModel):
    reply: str
    source: str
    is_fallback: bool
    notice: Optional[str] = None

class AIReviewProgressResponse(BaseModel):
    summary: str
    strengths: List[str]
    growth_opportunities: List[str]
    encouragement: str

class TimetableSessionItem(BaseModel):
    id: Optional[str] = None
    date: str  # YYYY-MM-DD
    weekday: Optional[str] = None
    start_time: str
    end_time: str
    subject: str
    topic: str
    session_type: str = "study"  # study, pyq, mock_test, revision, break, analysis
    estimated_minutes: int = 60
    priority: str = "medium"  # high, medium, low
    goal_id: Optional[str] = None
    notes: Optional[str] = None
    is_selected: bool = True

class TimetableExtractResponse(BaseModel):
    filename: str
    extracted_text_preview: str
    total_sessions_found: int
    sessions: List[TimetableSessionItem]
    source: str = "ai"

class TimetableCommitRequest(BaseModel):
    sessions: List[TimetableSessionItem]
    replace_uncompleted: bool = False
    skip_duplicates: bool = True

class TimetableCommitResponse(BaseModel):
    imported_count: int
    skipped_count: int
    replaced_count: int
    batch_id: str
    message: str

class StudyPlanRecommendationResponse(BaseModel):
    id: str
    plan_date: str
    recommendation_text: str
    reasoning_summary: Optional[str] = None
    task_references: Optional[List[str]] = None
    source: str
    created_at: str


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

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Dict, Any
from app.core.database import get_db
from app.models.user import User
from app.models.task import Task
from app.models.journey import XPTransaction
from app.schemas.ai import (
    AIPlanRequest,
    AIPlanResponse,
    AITaskPlanItem,
    AIChatRequest,
    AIChatResponse,
    AIReviewProgressResponse,
)
from app.api.deps import get_current_user
from app.services.ai_service import generate_ai_task_plan, chat_with_coach, call_grok_api
from app.services.xp_service import get_user_total_xp, calculate_level_info

router = APIRouter(prefix="/ai", tags=["AI Coach & Planning"])

@router.post("/plan", response_model=AIPlanResponse)
async def create_ai_plan(
    req: AIPlanRequest,
    current_user: User = Depends(get_current_user)
):
    daily_minutes = req.available_minutes or 120
    if current_user.preferences and current_user.preferences.available_daily_minutes:
        daily_minutes = current_user.preferences.available_daily_minutes

    tasks_raw = await generate_ai_task_plan(
        goal_title=req.goal_title,
        goal_category=req.goal_category or "General",
        available_daily_minutes=daily_minutes,
        user_context=req.context
    )

    task_items = [
        AITaskPlanItem(
            title=t.get("title", "Focused Practice Block"),
            description=t.get("description", "Execute key objective."),
            section=t.get("section", "Main Priorities"),
            priority=t.get("priority", "medium"),
            estimated_minutes=t.get("estimated_minutes", 25),
            xp_reward=t.get("xp_reward", 10),
            why_it_matters=t.get("why_it_matters", "Consistently builds capability.")
        )
        for t in tasks_raw
    ]

    return AIPlanResponse(
        goal_title=req.goal_title,
        tasks=task_items
    )

@router.post("/chat", response_model=AIChatResponse)
async def chat_coach(
    req: AIChatRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    total_xp = get_user_total_xp(db, current_user.id)
    level_info = calculate_level_info(total_xp)
    completed_today = db.query(Task).filter(
        Task.user_id == current_user.id,
        Task.is_completed == True
    ).count()

    stats = {
        "level": level_info["level"],
        "stage": level_info["stage_name"],
        "total_xp": total_xp,
        "completed_today": completed_today,
    }

    history_dicts = [{"role": m.role, "content": m.content} for m in req.history or []]

    result = await chat_with_coach(
        user_name=current_user.display_name,
        user_message=req.message,
        history=history_dicts,
        recent_stats=stats
    )

    return AIChatResponse(
        reply=result["reply"],
        source=result["source"],
        is_fallback=result["is_fallback"],
        notice=result.get("notice")
    )

@router.post("/review-progress", response_model=AIReviewProgressResponse)
async def review_progress(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    total_xp = get_user_total_xp(db, current_user.id)
    level_info = calculate_level_info(total_xp)
    completed_tasks = db.query(Task).filter(
        Task.user_id == current_user.id,
        Task.is_completed == True
    ).count()
    total_tasks = db.query(Task).filter(Task.user_id == current_user.id).count()

    summary = (
        f"You have reached Level {level_info['level']} ({level_info['stage_name']}) with {total_xp} total XP. "
        f"You've completed {completed_tasks} out of {total_tasks} tracked tasks, advancing {level_info['mountain_progress_percent']}% toward the summit."
    )
    strengths = [
        "Consistent daily action on core engineering & focus goals",
        "Pacing progress steadily without burnout or unsustainable spikes",
        "Maintaining balance between career execution and deliberate practice"
    ]
    growth = [
        "Block one 25-minute deep focus session earlier in your morning routine",
        "Document 1 key error or discovery each day in your RISE journal"
    ]
    encouragement = (
        "Every focused minute moves your trail higher up the ridge. Keep your eyes on the next immediate step!"
    )

    return AIReviewProgressResponse(
        summary=summary,
        strengths=strengths,
        growth_opportunities=growth,
        encouragement=encouragement
    )

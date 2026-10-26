import uuid
import logging
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File
from sqlalchemy.orm import Session
from typing import List, Dict, Any, Optional
from app.core.database import get_db
from app.models.user import User
from app.models.task import Task
from app.models.goal import Goal
from app.models.journey import XPTransaction
from app.schemas.ai import (
    AIPlanRequest,
    AIPlanResponse,
    AITaskPlanItem,
    AIChatRequest,
    AIChatResponse,
    AIReviewProgressResponse,
    TimetableExtractResponse,
    TimetableSessionItem,
    TimetableCommitRequest,
    TimetableCommitResponse,
    StudyPlanRecommendationResponse,
)
from app.api.deps import get_current_user
from app.services.ai_service import generate_ai_task_plan, chat_with_coach, call_grok_api, extract_timetable_from_text
from app.services.document_parser import extract_text_from_file
from app.services.xp_service import get_user_total_xp, calculate_level_info

logger = logging.getLogger(__name__)

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

@router.post("/timetable/upload", response_model=TimetableExtractResponse)
async def upload_timetable(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user)
):
    """
    Accepts timetable images (PNG, JPG, JPEG) or PDF documents.
    Extracts text using OCR/pypdf and uses Grok to extract structured study sessions.
    """
    filename = file.filename or "timetable"
    lower_name = filename.lower()
    valid_exts = (".png", ".jpg", ".jpeg", ".pdf")
    if not any(lower_name.endswith(ext) for ext in valid_exts):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Unsupported file format. Please upload PNG, JPG, JPEG, or PDF."
        )

    try:
        content = await file.read()
        extracted_text = extract_text_from_file(filename, content)
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
    except Exception as e:
        logger.error(f"Failed to process file {filename}: {e}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to process timetable file.")

    if not extracted_text or not extracted_text.strip():
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Could not extract any readable text from the uploaded document. Please check the image resolution and clarity."
        )

    # Use AI parser
    parsed_sessions = await extract_timetable_from_text(extracted_text)
    
    session_items: List[TimetableSessionItem] = []
    for s in parsed_sessions:
        session_items.append(
            TimetableSessionItem(
                id=str(uuid.uuid4()),
                date=s.get("date", datetime.utcnow().strftime("%Y-%m-%d")),
                weekday=s.get("weekday"),
                start_time=s.get("start_time", "08:00 AM"),
                end_time=s.get("end_time", "09:00 AM"),
                subject=s.get("subject", "General Study"),
                topic=s.get("topic", "Core Concepts"),
                session_type=s.get("session_type", "study"),
                estimated_minutes=s.get("estimated_minutes", 60),
                priority=s.get("priority", "medium"),
                notes=s.get("notes"),
                is_selected=True
            )
        )

    return TimetableExtractResponse(
        filename=filename,
        extracted_text_preview=extracted_text[:600] + ("..." if len(extracted_text) > 600 else ""),
        total_sessions_found=len(session_items),
        sessions=session_items,
        source="ai"
    )

@router.post("/timetable/commit", response_model=TimetableCommitResponse)
def commit_timetable(
    req: TimetableCommitRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Saves user-reviewed timetable sessions as real RISE tasks.
    Supports duplicate detection (skipping or replacing uncompleted tasks).
    Preserves all existing user records and completed tasks.
    """
    selected_sessions = [s for s in req.sessions if s.is_selected]
    if not selected_sessions:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No sessions selected for import."
        )

    batch_id = str(uuid.uuid4())
    imported_count = 0
    skipped_count = 0
    replaced_count = 0

    # Find or link to a GATE/academic goal if one exists
    gate_goal = db.query(Goal).filter(
        Goal.user_id == current_user.id,
        Goal.title.ilike("%gate%")
    ).first()
    default_goal_id = gate_goal.id if gate_goal else None

    for s in selected_sessions:
        title = f"{s.subject}: {s.topic}"
        due_date = s.date.strip() if s.date else None

        # Check for existing task on the same date with matching title or start_time
        existing_task = db.query(Task).filter(
            Task.user_id == current_user.id,
            Task.due_date == due_date,
            (Task.title == title) | (Task.start_time == s.start_time)
        ).first()

        if existing_task:
            if existing_task.is_completed:
                # Never overwrite completed tasks!
                skipped_count += 1
                continue
            elif req.replace_uncompleted:
                # Update existing uncompleted task
                existing_task.title = title
                existing_task.category = s.subject
                existing_task.start_time = s.start_time
                existing_task.end_time = s.end_time
                existing_task.weekday = s.weekday
                existing_task.session_type = s.session_type
                existing_task.estimated_minutes = s.estimated_minutes
                existing_task.priority = s.priority
                existing_task.xp_reward = 15 if s.priority == "high" else 10
                existing_task.why_it_matters = s.notes or f"Imported schedule session for {s.subject}"
                existing_task.import_batch_id = batch_id
                replaced_count += 1
                continue
            elif req.skip_duplicates:
                skipped_count += 1
                continue

        # Decide section based on start_time or session_type
        section = "Main Priorities"
        start_lower = (s.start_time or "").lower()
        if "am" in start_lower or (":" in start_lower and int(start_lower.split(":")[0]) < 12):
            section = "Morning Focus"
        elif s.session_type in ("analysis", "break") or "pm" in start_lower and (":" in start_lower and int(start_lower.split(":")[0]) in (9, 10, 11, 21, 22, 23)):
            section = "Evening Review"

        goal_id = s.goal_id or default_goal_id
        if goal_id:
            valid_goal = db.query(Goal).filter(Goal.id == goal_id, Goal.user_id == current_user.id).first()
            if not valid_goal:
                goal_id = None

        new_task = Task(
            user_id=current_user.id,
            goal_id=goal_id,
            title=title,
            description=s.notes or f"{s.subject} {s.session_type.upper()} ({s.start_time} - {s.end_time})",
            category=s.subject,
            section=section,
            priority=s.priority,
            estimated_minutes=s.estimated_minutes,
            xp_reward=15 if s.priority == "high" else 10,
            due_date=due_date,
            start_time=s.start_time,
            end_time=s.end_time,
            weekday=s.weekday,
            session_type=s.session_type,
            import_batch_id=batch_id,
            why_it_matters=s.notes or f"Timetable session: {s.subject}",
            order_index=imported_count
        )
        db.add(new_task)
        imported_count += 1

    db.commit()

    return TimetableCommitResponse(
        imported_count=imported_count,
        skipped_count=skipped_count,
        replaced_count=replaced_count,
        batch_id=batch_id,
        message=f"Successfully imported {imported_count} sessions ({skipped_count} skipped, {replaced_count} replaced)."
    )

@router.get("/study-plan/today", response_model=StudyPlanRecommendationResponse)
async def get_today_study_plan(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Returns today's active study plan recommendation or generates one.
    """
    from app.services.study_planner_service import get_or_generate_daily_study_plan
    plan = await get_or_generate_daily_study_plan(db, current_user, force_refresh=False)
    return StudyPlanRecommendationResponse(**plan)

@router.post("/study-plan/generate", response_model=StudyPlanRecommendationResponse)
async def generate_study_plan(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Explicitly forces generation/refresh of today's study plan recommendation.
    """
    from app.services.study_planner_service import get_or_generate_daily_study_plan
    plan = await get_or_generate_daily_study_plan(db, current_user, force_refresh=True)
    return StudyPlanRecommendationResponse(**plan)



import json
import logging
from datetime import datetime, timezone, date
from typing import Dict, Any, Optional, List
from sqlalchemy.orm import Session
from app.models.user import User, StudyPlanRecommendation
from app.models.task import Task
from app.models.goal import Goal
from app.models.focus import FocusSession
from app.services.ai_service import call_grok_api

logger = logging.getLogger(__name__)

async def get_or_generate_daily_study_plan(
    db: Session,
    user: User,
    force_refresh: bool = False
) -> Dict[str, Any]:
    """
    Retrieves today's cached study plan recommendation, or generates a new one
    based on the user's active tasks, GATE goals, completion record, and timetable.
    """
    today_str = date.today().strftime("%Y-%m-%d")

    # Check for existing cached recommendation for today
    if not force_refresh:
        existing = db.query(StudyPlanRecommendation).filter(
            StudyPlanRecommendation.user_id == user.id,
            StudyPlanRecommendation.plan_date == today_str,
            StudyPlanRecommendation.is_active == True
        ).order_by(StudyPlanRecommendation.created_at.desc()).first()

        if existing:
            task_ids = []
            if existing.task_references:
                try:
                    task_ids = json.loads(existing.task_references)
                except Exception:
                    task_ids = []

            return {
                "id": existing.id,
                "plan_date": existing.plan_date,
                "recommendation_text": existing.recommendation_text,
                "reasoning_summary": existing.reasoning_summary,
                "task_references": task_ids,
                "source": existing.source,
                "created_at": existing.created_at.isoformat() if existing.created_at else today_str
            }

    # Fetch today's tasks
    today_tasks = db.query(Task).filter(
        Task.user_id == user.id,
        Task.due_date == today_str
    ).order_by(Task.start_time.asc(), Task.order_index.asc()).all()

    # If no tasks explicitly due today, fetch upcoming tasks
    if not today_tasks:
        today_tasks = db.query(Task).filter(
            Task.user_id == user.id,
            Task.is_completed == False
        ).order_by(Task.due_date.asc(), Task.start_time.asc()).limit(5).all()

    # Fetch user's goals (especially GATE)
    goals = db.query(Goal).filter(Goal.user_id == user.id).all()
    gate_goals = [g.title for g in goals if "gate" in g.title.lower() or "electrical" in g.title.lower()]

    # Fetch recent completions (last 7 days)
    recent_focus_minutes = db.query(FocusSession).filter(
        FocusSession.user_id == user.id,
        FocusSession.completed == True
    ).count() * 25

    task_summaries = []
    task_ids = []
    for t in today_tasks:
        task_ids.append(t.id)
        time_str = f" [{t.start_time} - {t.end_time}]" if t.start_time else ""
        status_str = " (COMPLETED)" if t.is_completed else " (PENDING)"
        task_summaries.append(f"- {t.title}{time_str}{status_str} | Priority: {t.priority} | Est: {t.estimated_minutes}m")

    tasks_context = "\n".join(task_summaries) if task_summaries else "No scheduled tasks found for today."

    # Call Grok for personalized recommendation
    recommendation_text = None
    reasoning_summary = None
    source = "grok"

    prompt = f"""You are the RISE AI Study Planner and Head Academic Coach.
Analyze the student's scheduled sessions, target exam goals, and today's timeline.
Generate a specific, concise, high-impact study recommendation for today.

Student: {user.display_name or user.username}
Goals: {', '.join(gate_goals) if gate_goals else 'GATE 2027 Electrical Engineering & Mastery'}
Today's Date: {today_str}
Scheduled Tasks:
{tasks_context}

Rules:
1. Ground the recommendation DIRECTLY in today's actual scheduled tasks, subject names, topics, and specific start times.
2. If there is a morning session (e.g. 5:25 AM Network Theory), state it explicitly and prescribe concrete focus techniques (e.g., KCL/KVL nodal analysis, problem targets, error logging).
3. Be action-oriented and realistic. Never output generic filler like "Stay motivated today!"
4. Return strictly a JSON object with two keys:
   - "recommendation_text": (string) 2 to 3 concise, actionable sentences for today's study execution.
   - "reasoning_summary": (string) 1 brief sentence explaining why this plan optimizes their exam preparation.
"""

    messages = [
        {"role": "system", "content": "You are a study planning AI that outputs strictly valid JSON."},
        {"role": "user", "content": prompt}
    ]

    try:
        raw_response = await call_grok_api(messages, temperature=0.3)
        if raw_response:
            cleaned = raw_response.strip()
            if cleaned.startswith("```"):
                cleaned = cleaned.split("```")[1]
                if cleaned.startswith("json"):
                    cleaned = cleaned[4:]
            cleaned = cleaned.strip()
            data = json.loads(cleaned)
            if "recommendation_text" in data:
                recommendation_text = data["recommendation_text"].strip()
                reasoning_summary = data.get("reasoning_summary", "Aligned with today's scheduled priorities.")
    except Exception as e:
        logger.warning(f"Grok planner failed to generate plan: {e}")

    # Honest deterministic fallback if Grok is unavailable or failed
    if not recommendation_text:
        source = "deterministic_fallback"
        first_pending = next((t for t in today_tasks if not t.is_completed), None)
        if first_pending:
            time_part = f" at {first_pending.start_time}" if first_pending.start_time else ""
            recommendation_text = (
                f"Your priority session for today is '{first_pending.title}'{time_part}. "
                f"Focus on core problem-solving for {first_pending.estimated_minutes} minutes, "
                f"and log every conceptual mistake in your review notebook."
            )
            reasoning_summary = f"Generated by deterministic scheduler based on earliest pending task: {first_pending.title}."
        else:
            recommendation_text = (
                f"All scheduled tasks for today are completed! "
                f"Review your mistake notebook or preview tomorrow's core subjects for 20 minutes."
            )
            reasoning_summary = "Generated by deterministic scheduler based on 100% daily completion."

    # Deactivate older recommendations for today
    db.query(StudyPlanRecommendation).filter(
        StudyPlanRecommendation.user_id == user.id,
        StudyPlanRecommendation.plan_date == today_str
    ).update({"is_active": False})

    # Save to database
    record = StudyPlanRecommendation(
        user_id=user.id,
        plan_date=today_str,
        recommendation_text=recommendation_text,
        reasoning_summary=reasoning_summary,
        task_references=json.dumps(task_ids),
        source=source,
        is_active=True
    )
    db.add(record)
    db.commit()
    db.refresh(record)

    return {
        "id": record.id,
        "plan_date": record.plan_date,
        "recommendation_text": record.recommendation_text,
        "reasoning_summary": record.reasoning_summary,
        "task_references": task_ids,
        "source": record.source,
        "created_at": record.created_at.isoformat() if record.created_at else today_str
    }

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime, timezone
from app.core.database import get_db
from app.models.user import User
from app.models.task import Task, TaskCompletion
from app.models.goal import Goal
from app.schemas.task import TaskCreate, TaskUpdate, TaskResponse, TaskCompletionResponse
from app.api.deps import get_current_user
from app.services.xp_service import award_xp, calculate_level_info, get_user_total_xp

router = APIRouter(prefix="/tasks", tags=["Tasks"])

@router.get("", response_model=List[TaskResponse])
def get_tasks(
    section: Optional[str] = None,
    due_date: Optional[str] = None,
    is_completed: Optional[bool] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    query = db.query(Task).filter(Task.user_id == current_user.id)
    if section:
        query = query.filter(Task.section == section)
    if due_date:
        query = query.filter(Task.due_date == due_date)
    if is_completed is not None:
        query = query.filter(Task.is_completed == is_completed)
    
    tasks = query.order_by(Task.is_completed.asc(), Task.order_index.asc(), Task.created_at.desc()).all()
    return [TaskResponse.model_validate(t) for t in tasks]

@router.post("", response_model=TaskResponse, status_code=status.HTTP_201_CREATED)
def create_task(
    req: TaskCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    # Enforce goal ownership if linked to a goal
    if req.goal_id:
        goal = db.query(Goal).filter(Goal.id == req.goal_id, Goal.user_id == current_user.id).first()
        if not goal:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Associated goal not found.")

    # Strictly enforce server-authoritative XP reward:
    # High-priority tasks earn 15 XP, standard tasks earn 10 XP. Client arbitrary XP values are ignored.
    server_xp = 15 if req.priority == "high" else 10

    task = Task(
        user_id=current_user.id,
        goal_id=req.goal_id,
        title=req.title,
        description=req.description,
        category=req.category,
        section=req.section,
        priority=req.priority,
        estimated_minutes=req.estimated_minutes,
        xp_reward=server_xp,
        due_date=req.due_date,
        why_it_matters=req.why_it_matters,
        order_index=req.order_index
    )
    db.add(task)
    db.commit()
    db.refresh(task)
    return TaskResponse.model_validate(task)

@router.patch("/{task_id}", response_model=TaskResponse)
def update_task(
    task_id: str,
    req: TaskUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    task = db.query(Task).filter(Task.id == task_id, Task.user_id == current_user.id).first()
    if not task:
        raise HTTPException(status_code=404, detail="Task not found.")

    update_data = req.model_dump(exclude_unset=True)

    # Disallow direct modification of completion or arbitrary xp_reward through PATCH
    update_data.pop("is_completed", None)
    update_data.pop("xp_reward", None)

    if "goal_id" in update_data and update_data["goal_id"]:
        goal = db.query(Goal).filter(Goal.id == update_data["goal_id"], Goal.user_id == current_user.id).first()
        if not goal:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Associated goal not found.")

    for field, val in update_data.items():
        setattr(task, field, val)

    # If priority changed, update server-enforced XP accordingly
    if "priority" in update_data:
        task.xp_reward = 15 if task.priority == "high" else 10

    db.commit()
    db.refresh(task)
    return TaskResponse.model_validate(task)

@router.post("/{task_id}/complete", response_model=TaskCompletionResponse)
def complete_task(
    task_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    task = db.query(Task).filter(Task.id == task_id, Task.user_id == current_user.id).first()
    if not task:
        raise HTTPException(status_code=404, detail="Task not found.")

    now = datetime.now(timezone.utc)
    task.is_completed = True
    task.completed_at = now

    # Check if this task was already completed in the past to avoid duplicate XP
    existing_completion = db.query(TaskCompletion).filter(
        TaskCompletion.task_id == task.id,
        TaskCompletion.user_id == current_user.id
    ).first()

    xp_to_award = task.xp_reward or 10
    is_duplicate = False

    if existing_completion:
        is_duplicate = True
        actual_awarded = 0
    else:
        # Record completion
        completion_record = TaskCompletion(
            task_id=task.id,
            user_id=current_user.id,
            completed_at=now,
            xp_awarded=xp_to_award
        )
        db.add(completion_record)
        # Award XP idempotently through XP service
        awarded, _ = award_xp(db, current_user.id, xp_to_award, "task", reference_id=task.id)
        actual_awarded = xp_to_award if awarded else 0

    db.commit()
    db.refresh(task)

    total_xp = get_user_total_xp(db, current_user.id)
    level_info = calculate_level_info(total_xp)

    return TaskCompletionResponse(
        task=TaskResponse.model_validate(task),
        xp_awarded=actual_awarded,
        total_xp=total_xp,
        level=level_info["level"],
        is_duplicate=is_duplicate
    )

@router.post("/{task_id}/reopen", response_model=TaskResponse)
def reopen_task(
    task_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    task = db.query(Task).filter(Task.id == task_id, Task.user_id == current_user.id).first()
    if not task:
        raise HTTPException(status_code=404, detail="Task not found.")

    # Reopen task without deducting XP or modifying previous completion history
    task.is_completed = False
    task.completed_at = None
    db.commit()
    db.refresh(task)
    return TaskResponse.model_validate(task)

@router.delete("/{task_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_task(
    task_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    task = db.query(Task).filter(Task.id == task_id, Task.user_id == current_user.id).first()
    if not task:
        raise HTTPException(status_code=404, detail="Task not found.")
    db.delete(task)
    db.commit()
    return None

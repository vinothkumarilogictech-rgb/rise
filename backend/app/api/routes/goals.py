from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional
from app.core.database import get_db
from app.models.user import User
from app.models.goal import Goal, GoalMilestone
from app.schemas.goal import GoalCreate, GoalUpdate, GoalResponse, MilestoneResponse
from app.api.deps import get_current_user

router = APIRouter(prefix="/goals", tags=["Goals"])

def recalculate_goal_progress(goal: Goal):
    if not goal.milestones:
        return
    completed = sum(1 for m in goal.milestones if m.is_completed)
    goal.progress_percentage = round((completed / len(goal.milestones)) * 100.0, 1)

@router.get("", response_model=List[GoalResponse])
def get_goals(
    category: Optional[str] = None,
    status_filter: Optional[str] = "active",
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    query = db.query(Goal).filter(Goal.user_id == current_user.id)
    if status_filter and status_filter != "all":
        query = query.filter(Goal.status == status_filter)
    if category and category != "All":
        query = query.filter(Goal.category == category)
    goals = query.order_by(Goal.created_at.desc()).all()
    return [GoalResponse.model_validate(g) for g in goals]

@router.post("", response_model=GoalResponse, status_code=status.HTTP_201_CREATED)
def create_goal(
    req: GoalCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    goal = Goal(
        user_id=current_user.id,
        title=req.title,
        category=req.category,
        description=req.description,
        target_date=req.target_date,
        status=req.status
    )
    db.add(goal)
    db.flush()

    if req.milestones:
        for i, m in enumerate(req.milestones):
            milestone = GoalMilestone(
                goal_id=goal.id,
                title=m.title,
                is_completed=m.is_completed,
                order_index=m.order_index if m.order_index else i
            )
            db.add(milestone)
        db.flush()
        recalculate_goal_progress(goal)

    db.commit()
    db.refresh(goal)
    return GoalResponse.model_validate(goal)

@router.get("/{goal_id}", response_model=GoalResponse)
def get_goal(
    goal_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    goal = db.query(Goal).filter(Goal.id == goal_id, Goal.user_id == current_user.id).first()
    if not goal:
        raise HTTPException(status_code=404, detail="Goal not found.")
    return GoalResponse.model_validate(goal)

@router.patch("/{goal_id}", response_model=GoalResponse)
def update_goal(
    goal_id: str,
    req: GoalUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    goal = db.query(Goal).filter(Goal.id == goal_id, Goal.user_id == current_user.id).first()
    if not goal:
        raise HTTPException(status_code=404, detail="Goal not found.")

    update_data = req.model_dump(exclude_unset=True)
    for field, val in update_data.items():
        setattr(goal, field, val)

    db.commit()
    db.refresh(goal)
    return GoalResponse.model_validate(goal)

@router.delete("/{goal_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_goal(
    goal_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    goal = db.query(Goal).filter(Goal.id == goal_id, Goal.user_id == current_user.id).first()
    if not goal:
        raise HTTPException(status_code=404, detail="Goal not found.")
    db.delete(goal)
    db.commit()
    return None

@router.post("/{goal_id}/milestones/{milestone_id}/toggle", response_model=GoalResponse)
def toggle_milestone(
    goal_id: str,
    milestone_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    goal = db.query(Goal).filter(Goal.id == goal_id, Goal.user_id == current_user.id).first()
    if not goal:
        raise HTTPException(status_code=404, detail="Goal not found.")
    
    milestone = db.query(GoalMilestone).filter(
        GoalMilestone.id == milestone_id,
        GoalMilestone.goal_id == goal.id
    ).first()
    if not milestone:
        raise HTTPException(status_code=404, detail="Milestone not found.")

    milestone.is_completed = not milestone.is_completed
    recalculate_goal_progress(goal)
    db.commit()
    db.refresh(goal)
    return GoalResponse.model_validate(goal)

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.core.security import hash_password, verify_password, create_access_token
from app.models.user import User, UserPreferences
from app.models.goal import Goal, GoalMilestone
from app.models.task import Task
from app.schemas.auth import UserRegisterRequest, UserLoginRequest, TokenResponse, UserResponse
from app.api.deps import get_current_user
from datetime import datetime, timezone

router = APIRouter(prefix="/auth", tags=["Authentication"])

def seed_starter_goals_and_tasks(db: Session, user_id: str):
    """Seeds initial goals and tasks for the user."""
    # 1. GATE 2027 Electrical Engineering
    gate_goal = Goal(
        user_id=user_id,
        title="GATE 2027 — Electrical Engineering",
        category="GATE 2027",
        description="Comprehensive mastery of core electrical subjects, mathematics, and analytical problem-solving.",
        target_date="2027-02-15",
        progress_percentage=0.0
    )
    db.add(gate_goal)
    db.flush()

    gate_milestones = [
        "Complete Electric Circuits & Network Analysis",
        "Master Signals & Linear Control Systems",
        "Electrical Machines & Power Systems Core",
        "Solve 10 Full-Length Mock Exams & Analyze Errors",
    ]
    for i, title in enumerate(gate_milestones):
        db.add(GoalMilestone(goal_id=gate_goal.id, title=title, order_index=i))

    # 2. Coding Independence
    coding_goal = Goal(
        user_id=user_id,
        title="Coding Independence & Engineering Depth",
        category="Coding Independence",
        description="Solve complex programming challenges and build production systems without instant AI reliance.",
        target_date="2026-12-31",
        progress_percentage=0.0
    )
    db.add(coding_goal)
    db.flush()

    coding_milestones = [
        "Master Core Data Structures & Algorithm Design",
        "Build a Complete Full-Stack Architecture Independently",
        "Write Comprehensive Unit & Edge-Case Tests",
    ]
    for i, title in enumerate(coding_milestones):
        db.add(GoalMilestone(goal_id=coding_goal.id, title=title, order_index=i))

    # 3. Career & Customer Acquisition
    career_goal = Goal(
        user_id=user_id,
        title="Career & Work Growth",
        category="Career & Work",
        description="Deliver priority client/company deliverables and expand professional engineering influence.",
        target_date="2026-11-30",
        progress_percentage=0.0
    )
    db.add(career_goal)
    db.flush()

    # 4. Personal Well-being & Harmony
    wellbeing_goal = Goal(
        user_id=user_id,
        title="Rest, Sleep & Family Balance",
        category="Personal Well-being",
        description="Sustain high performance through consistent 7-8 hours sleep, exercise, and family time.",
        target_date="2026-12-31",
        progress_percentage=0.0
    )
    db.add(wellbeing_goal)
    db.flush()

    # Seed starter tasks for today
    today_str = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    starter_tasks = [
        Task(
            user_id=user_id,
            goal_id=gate_goal.id,
            title="Review Thevenin's Theorem & Solve 3 Gate PYQs",
            description="Deep focus on maximum power transfer and network reduction.",
            category="GATE 2027",
            section="Morning Focus",
            priority="high",
            estimated_minutes=45,
            xp_reward=15,
            due_date=today_str,
            why_it_matters="Network theory is the foundational pillar for power electronics and machines.",
            order_index=0
        ),
        Task(
            user_id=user_id,
            goal_id=coding_goal.id,
            title="Implement Core State Architecture Independently",
            description="Code the logic module without asking AI for 30 minutes.",
            category="Coding Independence",
            section="Main Priorities",
            priority="high",
            estimated_minutes=35,
            xp_reward=15,
            due_date=today_str,
            why_it_matters="Independent problem-solving builds deep architectural mental models.",
            order_index=1
        ),
        Task(
            user_id=user_id,
            goal_id=career_goal.id,
            title="Work Priority: Complete Daily Engineering Deliverable",
            description="Finalize key pull request or client milestone document.",
            category="Career & Work",
            section="Main Priorities",
            priority="medium",
            estimated_minutes=40,
            xp_reward=10,
            due_date=today_str,
            why_it_matters="Consistent daily delivery establishes professional trust and momentum.",
            order_index=2
        ),
        Task(
            user_id=user_id,
            goal_id=wellbeing_goal.id,
            title="Evening Reflection & Screen-Free Wind Down",
            description="Log today's key wins in the RISE Journal and relax with family.",
            category="Personal Well-being",
            section="Evening Review",
            priority="low",
            estimated_minutes=20,
            xp_reward=10,
            due_date=today_str,
            why_it_matters="Restorative recovery directly powers tomorrow's mental focus.",
            order_index=3
        ),
    ]
    for task in starter_tasks:
        db.add(task)

@router.post("/register", response_model=TokenResponse)
def register(req: UserRegisterRequest, db: Session = Depends(get_db)):
    clean_username = req.username.strip()
    if not clean_username:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Username cannot be empty."
        )

    existing = db.query(User).filter(User.username == clean_username.lower()).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Username already exists. Please choose another."
        )

    display_name = req.display_name.strip() if req.display_name and req.display_name.strip() else clean_username
    user = User(
        username=clean_username.lower(),
        hashed_password=hash_password(req.password),
        display_name=display_name
    )
    db.add(user)
    db.flush()

    preferences = UserPreferences(
        user_id=user.id,
        available_daily_minutes=req.available_daily_minutes or 120,
        planning_style=req.planning_style or "balanced",
        reminder_time=req.reminder_time or "08:00"
    )
    db.add(preferences)

    # Seed starter goals and tasks
    seed_starter_goals_and_tasks(db, user.id)

    db.commit()
    db.refresh(user)

    token = create_access_token(user.id)
    return TokenResponse(
        access_token=token,
        token_type="bearer",
        user=UserResponse.model_validate(user)
    )

@router.post("/login", response_model=TokenResponse)
def login(req: UserLoginRequest, db: Session = Depends(get_db)):
    clean_username = req.username.strip().lower()
    user = db.query(User).filter(User.username == clean_username).first()
    if not user or not verify_password(req.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid username or password."
        )

    token = create_access_token(user.id)
    return TokenResponse(
        access_token=token,
        token_type="bearer",
        user=UserResponse.model_validate(user)
    )

@router.get("/me", response_model=UserResponse)
def get_me(current_user: User = Depends(get_current_user)):
    return UserResponse.model_validate(current_user)

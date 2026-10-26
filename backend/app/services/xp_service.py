from sqlalchemy.orm import Session
from sqlalchemy import func
from app.models.journey import XPTransaction, Achievement
from app.models.task import Task, TaskCompletion
from typing import Dict, Any, Tuple
from datetime import datetime, timezone

LEVEL_TIERS = [
    (1, 0, "First Step"),
    (2, 100, "Building Momentum"),
    (3, 250, "Finding Rhythm"),
    (4, 450, "Climbing Higher"),
    (5, 700, "Ascending Ridge"),
    (6, 1000, "High Altitude"),
    (7, 1400, "Near the Summit"),
    (8, 2000, "Summit Achiever"),
    (9, 2800, "Peak Master"),
    (10, 4000, "Legend of Rise"),
]

def calculate_level_info(total_xp: int) -> Dict[str, Any]:
    level = 1
    stage_name = LEVEL_TIERS[0][2]
    base_xp = 0
    next_level_xp = LEVEL_TIERS[1][1]

    for i in range(len(LEVEL_TIERS)):
        tier_level, tier_xp, tier_stage = LEVEL_TIERS[i]
        if total_xp >= tier_xp:
            level = tier_level
            stage_name = tier_stage
            base_xp = tier_xp
            if i + 1 < len(LEVEL_TIERS):
                next_level_xp = LEVEL_TIERS[i + 1][1]
            else:
                next_level_xp = base_xp + 1500
        else:
            break

    level_span = max(1, next_level_xp - base_xp)
    xp_in_level = max(0, total_xp - base_xp)
    progress_ratio = min(1.0, max(0.0, xp_in_level / level_span))
    
    # Summit progress based on reaching Summit Achiever at 2000 XP
    summit_percent = min(100.0, round((total_xp / 2000.0) * 100.0, 1))

    return {
        "level": level,
        "stage_name": stage_name,
        "total_xp": total_xp,
        "base_level_xp": base_xp,
        "next_level_xp": next_level_xp,
        "xp_to_next_level": max(0, next_level_xp - total_xp),
        "progress_ratio": round(progress_ratio, 3),
        "mountain_progress_percent": summit_percent,
    }

def get_user_total_xp(db: Session, user_id: str) -> int:
    result = db.query(func.coalesce(func.sum(XPTransaction.amount), 0)).filter(
        XPTransaction.user_id == user_id
    ).scalar()
    return int(result or 0)

def award_xp(db: Session, user_id: str, amount: int, source: str, reference_id: str = None) -> Tuple[bool, int]:
    """
    Safely awards XP if not already awarded for this reference_id.
    Returns (awarded: bool, new_total_xp: int).
    """
    if reference_id:
        existing = db.query(XPTransaction).filter(
            XPTransaction.user_id == user_id,
            XPTransaction.source == source,
            XPTransaction.reference_id == reference_id
        ).first()
        if existing:
            # Already awarded, prevent duplication
            return False, get_user_total_xp(db, user_id)

    transaction = XPTransaction(
        user_id=user_id,
        amount=amount,
        source=source,
        reference_id=reference_id
    )
    db.add(transaction)
    db.commit()

    total_xp = get_user_total_xp(db, user_id)
    _check_achievements(db, user_id, total_xp, source)
    return True, total_xp

def _check_achievements(db: Session, user_id: str, total_xp: int, recent_source: str):
    existing_codes = set(
        code for (code,) in db.query(Achievement.code).filter(Achievement.user_id == user_id).all()
    )

    def unlock(code: str, title: str, description: str, icon: str):
        if code not in existing_codes:
            ach = Achievement(
                user_id=user_id,
                code=code,
                title=title,
                description=description,
                icon=icon,
                unlocked_at=datetime.now(timezone.utc)
            )
            db.add(ach)
            db.commit()
            existing_codes.add(code)

    if total_xp >= 10:
        unlock("first_step", "First Step Taken", "Earned your first 10 XP on the mountain.", "footprints")
    if total_xp >= 100:
        unlock("momentum_builder", "Building Momentum", "Reached Level 2 and climbed into the foothills.", "flame")
    if total_xp >= 450:
        unlock("high_climber", "High Climber", "Ascended to Level 4 high above the base camp.", "mountain")
    if total_xp >= 1000:
        unlock("altitude_conqueror", "Altitude Conqueror", "Crossed 1000 XP through sustained consistency.", "award")
    if total_xp >= 2000:
        unlock("summit_achiever", "Summit Achiever", "Reached the legendary summit of RISE.", "crown")

    if recent_source == "focus_session":
        unlock("deep_focus", "Deep Work Monk", "Completed a focused flow session.", "timer")
    elif recent_source == "reflection":
        unlock("mindful_climber", "Mindful Climber", "Completed a daily reflection journal.", "book-open")

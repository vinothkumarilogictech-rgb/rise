from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import datetime, timezone
from app.core.database import get_db
from app.models.user import User, UserPreferences
from app.schemas.preferences import UserPreferencesResponse, UserPreferencesUpdate
from app.api.deps import get_current_user

router = APIRouter(prefix="/preferences", tags=["Preferences"])

@router.get("", response_model=UserPreferencesResponse)
def get_preferences(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    prefs = current_user.preferences
    if not prefs:
        prefs = UserPreferences(user_id=current_user.id)
        db.add(prefs)
        db.commit()
        db.refresh(prefs)

    return UserPreferencesResponse(
        username=current_user.username,
        display_name=current_user.display_name or current_user.username,
        available_daily_minutes=prefs.available_daily_minutes,
        planning_style=prefs.planning_style,
        reminder_time=prefs.reminder_time,
        notification_enabled=prefs.notification_enabled,
        theme=prefs.theme,
        updated_at=prefs.updated_at or datetime.now(timezone.utc)
    )

@router.patch("", response_model=UserPreferencesResponse)
def update_preferences(
    req: UserPreferencesUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    prefs = current_user.preferences
    if not prefs:
        prefs = UserPreferences(user_id=current_user.id)
        db.add(prefs)

    if req.display_name is not None and len(req.display_name.strip()) >= 2:
        current_user.display_name = req.display_name.strip()
    if req.available_daily_minutes is not None:
        prefs.available_daily_minutes = req.available_daily_minutes
    if req.planning_style is not None:
        prefs.planning_style = req.planning_style
    if req.reminder_time is not None:
        prefs.reminder_time = req.reminder_time
    if req.fcm_token is not None:
        prefs.fcm_token = req.fcm_token
    if req.notification_enabled is not None:
        prefs.notification_enabled = req.notification_enabled
    if req.theme is not None:
        prefs.theme = req.theme
    
    prefs.updated_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(prefs)

    return UserPreferencesResponse(
        username=current_user.username,
        display_name=current_user.display_name or current_user.username,
        available_daily_minutes=prefs.available_daily_minutes,
        planning_style=prefs.planning_style,
        reminder_time=prefs.reminder_time,
        notification_enabled=prefs.notification_enabled,
        theme=prefs.theme,
        updated_at=prefs.updated_at
    )

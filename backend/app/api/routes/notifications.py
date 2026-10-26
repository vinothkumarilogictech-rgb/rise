from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from datetime import datetime, timezone
from typing import List
from app.core.database import get_db
from app.models.user import User, UserDeviceToken, UserPreferences
from app.schemas.notification import (
    DeviceTokenRegisterRequest,
    DeviceTokenDeleteRequest,
    NotificationPreferencesResponse,
    NotificationPreferencesUpdate,
    TestPushRequest,
    TestPushResponse
)
from app.api.deps import get_current_user
from app.services.fcm_service import send_push_notification

router = APIRouter(prefix="/notifications", tags=["Notifications & FCM"])

@router.post("/fcm-token", status_code=status.HTTP_200_OK)
def register_device_token(
    req: DeviceTokenRegisterRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Registers or updates an FCM device token for the authenticated user.
    Supports multi-device tokens per user and updates last seen timestamp.
    """
    token_str = req.token.strip()
    existing = db.query(UserDeviceToken).filter(
        UserDeviceToken.user_id == current_user.id,
        UserDeviceToken.token == token_str
    ).first()

    now = datetime.now(timezone.utc)
    if existing:
        existing.is_active = True
        existing.platform = req.platform
        existing.device_info = req.device_info or existing.device_info
        existing.last_seen_at = now
    else:
        new_token = UserDeviceToken(
            user_id=current_user.id,
            token=token_str,
            platform=req.platform,
            device_info=req.device_info,
            is_active=True,
            created_at=now,
            last_seen_at=now
        )
        db.add(new_token)

    # Also keep legacy preferences fcm_token field in sync
    if current_user.preferences:
        current_user.preferences.fcm_token = token_str

    db.commit()
    return {"status": "success", "message": "Device token registered successfully."}

@router.delete("/fcm-token", status_code=status.HTTP_200_OK)
def deactivate_device_token(
    req: DeviceTokenDeleteRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Deactivates an FCM device token on logout.
    """
    token_str = req.token.strip()
    token_record = db.query(UserDeviceToken).filter(
        UserDeviceToken.user_id == current_user.id,
        UserDeviceToken.token == token_str
    ).first()

    if token_record:
        token_record.is_active = False
        db.commit()

    return {"status": "success", "message": "Device token deactivated."}

@router.get("/preferences", response_model=NotificationPreferencesResponse)
def get_notification_preferences(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Retrieves user notification preferences including quiet hours and lead times.
    """
    prefs = current_user.preferences
    if not prefs:
        prefs = UserPreferences(user_id=current_user.id)
        db.add(prefs)
        db.commit()
        db.refresh(prefs)
    return NotificationPreferencesResponse.model_validate(prefs)

@router.patch("/preferences", response_model=NotificationPreferencesResponse)
def update_notification_preferences(
    req: NotificationPreferencesUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Updates user notification preferences.
    """
    prefs = current_user.preferences
    if not prefs:
        prefs = UserPreferences(user_id=current_user.id)
        db.add(prefs)
        db.commit()
        db.refresh(prefs)

    update_data = req.model_dump(exclude_unset=True)
    for field, val in update_data.items():
        setattr(prefs, field, val)

    db.commit()
    db.refresh(prefs)
    return NotificationPreferencesResponse.model_validate(prefs)

@router.post("/test-push", response_model=TestPushResponse)
def send_test_push(
    req: TestPushRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Dispatches a test push notification to all active registered devices of the user.
    """
    target_tokens: List[str] = []
    if req.token and req.token.strip():
        target_tokens = [req.token.strip()]
    else:
        target_tokens = [
            dt.token for dt in db.query(UserDeviceToken).filter(
                UserDeviceToken.user_id == current_user.id,
                UserDeviceToken.is_active == True
            ).all()
        ]

    title = req.title or "RISE Study Reminder — Network Theory"
    body = req.body or "Your 5:25 AM session is starting soon. Begin with KCL and nodal analysis."

    if not target_tokens:
        return TestPushResponse(
            sent=0,
            failed=0,
            status="no_tokens",
            message="No registered device tokens found for this user. Register a device token first or pass 'token' in the request."
        )

    result = send_push_notification(
        tokens=target_tokens,
        title=title,
        body=body,
        data={"type": "test_push", "user_id": str(current_user.id)}
    )

    # Deactivate any stale tokens identified by Firebase
    for stale in result.get("stale_tokens", []):
        db.query(UserDeviceToken).filter(UserDeviceToken.token == stale).update({"is_active": False})
        db.commit()

    return TestPushResponse(
        sent=result.get("sent", 0),
        failed=result.get("failed", 0),
        status=result.get("status", "unknown"),
        message=result.get("message", f"Attempted dispatch to {len(target_tokens)} device(s).")
    )

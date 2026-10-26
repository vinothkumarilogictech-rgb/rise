import pytest
import os
from datetime import datetime, timezone, date
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.main import app
from app.core.database import Base, get_db
from app.models.user import User, UserPreferences, UserDeviceToken, StudyPlanRecommendation, ScheduledNotification
from app.models.task import Task
from app.services.fcm_service import send_push_notification
from app.services.scheduler_service import parse_time_string, is_within_quiet_hours

TEST_DATABASE_URL = "sqlite:///./test_rise.db"
test_engine = create_engine(TEST_DATABASE_URL, connect_args={"check_same_thread": False})
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=test_engine)

def override_get_db():
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()

app.dependency_overrides[get_db] = override_get_db

@pytest.fixture(scope="module", autouse=True)
def setup_database():
    Base.metadata.create_all(bind=test_engine)
    yield
    Base.metadata.drop_all(bind=test_engine)

client = TestClient(app)

def get_auth_token(username="timetabler"):
    reg_res = client.post("/api/auth/register", json={
        "username": username,
        "password": "Password123!",
        "display_name": "Timetable Student"
    })
    if reg_res.status_code == 200:
        return reg_res.json()["access_token"]
    login_res = client.post("/api/auth/login", json={
        "username": username,
        "password": "Password123!"
    })
    return login_res.json()["access_token"]

def test_timetable_commit_and_duplicate_prevention():
    token = get_auth_token("tt_user_1")
    headers = {"Authorization": f"Bearer {token}"}

    sample_sessions = [
        {
            "id": "s1",
            "date": "2026-10-27",
            "weekday": "Tuesday",
            "start_time": "05:25 AM",
            "end_time": "06:45 AM",
            "subject": "Network Theory",
            "topic": "KCL, KVL and Nodal Analysis",
            "session_type": "study",
            "estimated_minutes": 80,
            "priority": "high",
            "notes": "10 Practice problems",
            "is_selected": True
        },
        {
            "id": "s2",
            "date": "2026-10-27",
            "weekday": "Tuesday",
            "start_time": "07:00 AM",
            "end_time": "08:00 AM",
            "subject": "Engineering Mathematics",
            "topic": "Linear Algebra Eigenvalues",
            "session_type": "study",
            "estimated_minutes": 60,
            "priority": "medium",
            "notes": "Eigenvalue formulas",
            "is_selected": True
        }
    ]

    # Initial commit
    res = client.post("/api/ai/timetable/commit", json={
        "sessions": sample_sessions,
        "skip_duplicates": True,
        "replace_uncompleted": False
    }, headers=headers)

    assert res.status_code == 200
    data = res.json()
    assert data["imported_count"] == 2
    assert data["skipped_count"] == 0

    # Repeat commit with skip_duplicates=True -> should skip both!
    res_dup = client.post("/api/ai/timetable/commit", json={
        "sessions": sample_sessions,
        "skip_duplicates": True,
        "replace_uncompleted": False
    }, headers=headers)

    assert res_dup.status_code == 200
    data_dup = res_dup.json()
    assert data_dup["imported_count"] == 0
    assert data_dup["skipped_count"] == 2

def test_study_plan_generation_and_fallback():
    token = get_auth_token("planner_user")
    headers = {"Authorization": f"Bearer {token}"}

    res = client.get("/api/ai/study-plan/today", headers=headers)
    assert res.status_code == 200
    plan = res.json()
    assert "recommendation_text" in plan
    assert len(plan["recommendation_text"]) > 10
    assert plan["source"] in ("grok", "deterministic_fallback")

def test_fcm_token_registration_and_deactivation():
    token = get_auth_token("fcm_user")
    headers = {"Authorization": f"Bearer {token}"}

    # Register token
    res = client.post("/api/notifications/fcm-token", json={
        "token": "device_token_xyz_12345",
        "platform": "android",
        "device_info": "Pixel 8 Pro"
    }, headers=headers)
    assert res.status_code == 200

    # Deactivate token on logout
    res_del = client.request("DELETE", "/api/notifications/fcm-token", json={
        "token": "device_token_xyz_12345"
    }, headers=headers)
    assert res_del.status_code == 200

def test_notification_preferences_and_quiet_hours_helpers():
    token = get_auth_token("pref_user")
    headers = {"Authorization": f"Bearer {token}"}

    # Get preferences
    res = client.get("/api/notifications/preferences", headers=headers)
    assert res.status_code == 200
    prefs = res.json()
    assert prefs["notification_enabled"] is True
    assert prefs["reminder_lead_time_minutes"] == 15

    # Update preferences
    res_update = client.patch("/api/notifications/preferences", json={
        "reminder_lead_time_minutes": 20,
        "quiet_hours_start": "23:00",
        "quiet_hours_end": "05:00"
    }, headers=headers)
    assert res_update.status_code == 200
    updated = res_update.json()
    assert updated["reminder_lead_time_minutes"] == 20
    assert updated["quiet_hours_start"] == "23:00"

    # Test quiet hours helper logic
    from datetime import time
    assert is_within_quiet_hours(time(23, 30), "23:00", "05:00") is True
    assert is_within_quiet_hours(time(3, 0), "23:00", "05:00") is True
    assert is_within_quiet_hours(time(14, 0), "23:00", "05:00") is False

def test_analytics_calculations_and_empty_states():
    token = get_auth_token("analytics_user")
    headers = {"Authorization": f"Bearer {token}"}

    res = client.get("/api/analytics/overview", headers=headers)
    assert res.status_code == 200
    data = res.json()
    assert data["completion_rate_percentage"] >= 0.0
    assert data["timetable_adherence_rate"] >= 0.0
    assert isinstance(data["subject_breakdown"], list)
    assert isinstance(data["revision_recommendations"], list)

def test_firebase_admin_initialization_and_idempotency():
    from app.services.fcm_service import init_firebase_admin, is_firebase_initialized
    import firebase_admin

    # Verify initialization succeeds with configured credentials
    success = init_firebase_admin()
    assert success is True
    assert is_firebase_initialized() is True
    assert len(firebase_admin._apps) == 1

    # Verify second initialization call is safe and idempotent
    repeat_success = init_firebase_admin()
    assert repeat_success is True
    assert len(firebase_admin._apps) == 1

def test_test_push_notification_endpoint():
    token = get_auth_token("test_push_user")
    headers = {"Authorization": f"Bearer {token}"}

    # Case 1: When user has no registered devices and passes no token
    res_no_token = client.post("/api/notifications/test-push", json={}, headers=headers)
    assert res_no_token.status_code == 200
    data_no_token = res_no_token.json()
    assert data_no_token["status"] == "no_tokens"
    assert data_no_token["sent"] == 0

    # Case 2: Register a mock device token and test dispatch handling
    client.post("/api/notifications/fcm-token", json={
        "token": "mock_device_token_for_test_push_12345",
        "platform": "android",
        "device_info": "Test Device"
    }, headers=headers)

    res_with_token = client.post("/api/notifications/test-push", json={
        "title": "Test Title",
        "body": "Test Body"
    }, headers=headers)
    assert res_with_token.status_code == 200
    data_with_token = res_with_token.json()
    assert "status" in data_with_token
    assert "sent" in data_with_token
    assert "failed" in data_with_token

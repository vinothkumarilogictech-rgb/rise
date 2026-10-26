import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.main import app
from app.core.database import Base, get_db
from app.models.user import User

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
    Base.metadata.drop_all(bind=test_engine)
    Base.metadata.create_all(bind=test_engine)
    yield
    Base.metadata.drop_all(bind=test_engine)

client = TestClient(app)

def test_health_check():
    res = client.get("/health")
    assert res.status_code == 200
    data = res.json()
    assert data["status"] == "healthy"
    assert data["database"] == "healthy"

def test_auth_registration_and_login():
    reg_payload = {
        "username": "climber",
        "password": "strongPassword123",
        "display_name": "Antigravity Climber",
        "available_daily_minutes": 150,
        "planning_style": "balanced",
        "reminder_time": "07:30"
    }
    res = client.post("/api/auth/register", json=reg_payload)
    assert res.status_code == 200
    data = res.json()
    assert "access_token" in data
    assert data["user"]["username"] == "climber"
    token = data["access_token"]

    # Verify password is saved as a secure hash and never plain-text
    db = TestingSessionLocal()
    try:
        db_user = db.query(User).filter(User.username == "climber").first()
        assert db_user is not None
        assert db_user.hashed_password != "strongPassword123"
        assert db_user.hashed_password.startswith("$2b$") or db_user.hashed_password.startswith("$2a$")
    finally:
        db.close()

    # Test login with valid credentials
    login_res = client.post("/api/auth/login", json={
        "username": "climber",
        "password": "strongPassword123"
    })
    assert login_res.status_code == 200
    assert "access_token" in login_res.json()

    # Test login with invalid credentials
    invalid_login = client.post("/api/auth/login", json={
        "username": "climber",
        "password": "wrongPassword456"
    })
    assert invalid_login.status_code == 401
    assert invalid_login.json()["detail"] == "Invalid username or password."

    # Test me endpoint
    me_res = client.get("/api/auth/me", headers={"Authorization": f"Bearer {token}"})
    assert me_res.status_code == 200
    assert me_res.json()["username"] == "climber"
    assert me_res.json()["display_name"] == "Antigravity Climber"

def test_duplicate_username_registration():
    dup_payload = {
        "username": "climber",
        "password": "anotherPassword123",
    }
    res = client.post("/api/auth/register", json=dup_payload)
    assert res.status_code == 400
    assert res.json()["detail"] == "Username already exists. Please choose another."

def test_seeded_goals_and_tasks():
    login_res = client.post("/api/auth/login", json={
        "username": "climber",
        "password": "strongPassword123"
    })
    token = login_res.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    goals_res = client.get("/api/goals", headers=headers)
    assert goals_res.status_code == 200
    goals = goals_res.json()
    assert len(goals) >= 4  # GATE, Coding, Career, Well-being

    tasks_res = client.get("/api/tasks", headers=headers)
    assert tasks_res.status_code == 200
    tasks = tasks_res.json()
    assert len(tasks) >= 4

def test_task_completion_and_xp_idempotency():
    login_res = client.post("/api/auth/login", json={
        "username": "climber",
        "password": "strongPassword123"
    })
    token = login_res.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # Create a new test task
    new_task_res = client.post("/api/tasks", headers=headers, json={
        "title": "Solve 2 Electrical Circuit Theorems",
        "section": "Morning Focus",
        "priority": "high",
        "estimated_minutes": 30,
        "xp_reward": 15
    })
    assert new_task_res.status_code == 201
    task = new_task_res.json()
    task_id = task["id"]

    # First completion should award 15 XP
    comp1 = client.post(f"/api/tasks/{task_id}/complete", headers=headers)
    assert comp1.status_code == 200
    data1 = comp1.json()
    assert data1["xp_awarded"] == 15
    assert data1["is_duplicate"] is False
    assert data1["total_xp"] >= 15

    # Second completion of same task should NOT award XP (duplicate prevention)
    comp2 = client.post(f"/api/tasks/{task_id}/complete", headers=headers)
    assert comp2.status_code == 200
    data2 = comp2.json()
    assert data2["xp_awarded"] == 0
    assert data2["is_duplicate"] is True

    # Reopen task
    reopen_res = client.post(f"/api/tasks/{task_id}/reopen", headers=headers)
    assert reopen_res.status_code == 200
    assert reopen_res.json()["is_completed"] is False

    # Third completion after reopening should NOT award XP repeatedly
    comp3 = client.post(f"/api/tasks/{task_id}/complete", headers=headers)
    assert comp3.status_code == 200
    assert comp3.json()["xp_awarded"] == 0

def test_focus_session_xp():
    login_res = client.post("/api/auth/login", json={
        "username": "climber",
        "password": "strongPassword123"
    })
    token = login_res.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    focus_res = client.post("/api/focus/sessions", headers=headers, json={
        "label": "GATE 2027 Math Flow",
        "planned_duration_minutes": 25,
        "actual_duration_minutes": 25,
        "completed": True
    })
    assert focus_res.status_code == 201
    data = focus_res.json()
    assert data["xp_awarded"] == 10

def test_daily_journal_and_reflection():
    login_res = client.post("/api/auth/login", json={
        "username": "climber",
        "password": "strongPassword123"
    })
    token = login_res.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    journal_res = client.post("/api/journal", headers=headers, json={
        "date": "2026-10-25",
        "content": "Today I maintained deep focus for 45 minutes on GATE Electrical practice without distractions.",
        "mood": "motivated"
    })
    assert journal_res.status_code == 201
    assert journal_res.json()["xp_awarded"] == 5

def test_journey_summary():
    login_res = client.post("/api/auth/login", json={
        "username": "climber",
        "password": "strongPassword123"
    })
    token = login_res.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    journey_res = client.get("/api/journey/summary", headers=headers)
    assert journey_res.status_code == 200
    data = journey_res.json()
    assert data["total_xp"] > 0
    assert "mountain_progress_percent" in data
    assert "stage_name" in data
    assert data["level"] >= 1

def test_server_enforces_task_xp_and_disallows_tampering():
    login_res = client.post("/api/auth/login", json={
        "username": "climber",
        "password": "strongPassword123"
    })
    token = login_res.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # Malicious client sends arbitrary 9999 XP reward for a normal task
    create_res = client.post("/api/tasks", headers=headers, json={
        "title": "Practice GATE PYQs",
        "priority": "medium",
        "xp_reward": 9999
    })
    assert create_res.status_code == 201
    created_task = create_res.json()
    # Server MUST override arbitrary XP to 10 for medium priority
    assert created_task["xp_reward"] == 10

    # Malicious client tries to PATCH xp_reward to 5000 and is_completed to True
    patch_res = client.patch(f"/api/tasks/{created_task['id']}", headers=headers, json={
        "xp_reward": 5000,
        "is_completed": True
    })
    assert patch_res.status_code == 200
    patched_task = patch_res.json()
    assert patched_task["xp_reward"] == 10
    assert patched_task["is_completed"] is False

def test_ai_plan_and_chat_endpoints():
    login_res = client.post("/api/auth/login", json={
        "username": "climber",
        "password": "strongPassword123"
    })
    token = login_res.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # AI Plan generation
    plan_res = client.post("/api/ai/plan", headers=headers, json={
        "goal_title": "GATE 2027 Electrical Engineering",
        "goal_category": "GATE 2027",
        "available_minutes": 120
    })
    assert plan_res.status_code == 200
    plan_data = plan_res.json()
    assert len(plan_data["tasks"]) > 0
    for task_item in plan_data["tasks"]:
        assert "title" in task_item
        assert task_item["xp_reward"] in (10, 15)

    # AI Chat coaching
    chat_res = client.post("/api/ai/chat", headers=headers, json={
        "message": "How do I maintain consistency without burning out?"
    })
    assert chat_res.status_code == 200
    chat_data = chat_res.json()
    assert "reply" in chat_data
    assert len(chat_data["reply"]) > 20
    assert chat_data["source"] in ("assistant", "grok")

def test_user_data_isolation():
    # Register second user
    reg2_res = client.post("/api/auth/register", json={
        "username": "climber2",
        "password": "strongPassword123",
        "display_name": "Second Climber"
    })
    assert reg2_res.status_code == 200
    token2 = reg2_res.json()["access_token"]
    headers2 = {"Authorization": f"Bearer {token2}"}

    # User 1 login
    login_res = client.post("/api/auth/login", json={
        "username": "climber",
        "password": "strongPassword123"
    })
    token1 = login_res.json()["access_token"]
    headers1 = {"Authorization": f"Bearer {token1}"}

    # User 1 creates task
    t1 = client.post("/api/tasks", headers=headers1, json={"title": "User 1 Secret Task"}).json()

    # User 2 attempts to complete User 1's task (must return 404)
    forbidden_comp = client.post(f"/api/tasks/{t1['id']}/complete", headers=headers2)
    assert forbidden_comp.status_code == 404

    # User 2 attempts to delete User 1's task (must return 404)
    forbidden_del = client.delete(f"/api/tasks/{t1['id']}", headers=headers2)
    assert forbidden_del.status_code == 404

    # User 2 attempts to link a focus session to User 1's task (must return 404)
    forbidden_focus = client.post("/api/focus/sessions", headers=headers2, json={
        "task_id": t1['id'],
        "label": "Deep work on task",
        "actual_duration_minutes": 25,
        "completed": True
    })
    assert forbidden_focus.status_code == 404

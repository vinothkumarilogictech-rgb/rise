# RISE Backend API Reference

Base URL (Local): `http://localhost:8000/api`
Base URL (Render): `https://<YOUR-RENDER-SERVICE>.onrender.com/api`

All protected endpoints require the HTTP header:
```http
Authorization: Bearer <ACCESS_TOKEN>
```

---

## 1. Authentication

### `POST /auth/register`
Creates an account and initializes starter goals (GATE EE, Coding, Career, Well-being) and user preferences.
- **Request Body:**
  ```json
  {
    "email": "user@example.com",
    "password": "securePassword123",
    "display_name": "Alex",
    "available_daily_minutes": 120,
    "planning_style": "balanced",
    "reminder_time": "08:00"
  }
  ```
- **Response (200):**
  ```json
  {
    "access_token": "jwt.token.here",
    "token_type": "bearer",
    "user": {
      "id": "uuid-v4",
      "email": "user@example.com",
      "display_name": "Alex",
      "created_at": "2026-10-25T12:00:00Z"
    }
  }
  ```

### `POST /auth/login`
- **Request Body:**
  ```json
  {
    "email": "user@example.com",
    "password": "securePassword123"
  }
  ```
- **Response (200):** Same as `POST /auth/register`.

### `GET /auth/me`
Returns current authenticated user details.

---

## 2. Goals & Milestones

### `GET /goals`
Query params: `category` (optional), `status_filter` (active, completed, archived, all).
- **Response (200):** Array of goal objects with milestones and progress percentage.

### `POST /goals`
- **Request Body:**
  ```json
  {
    "title": "GATE 2027 Electrical Engineering",
    "category": "GATE 2027",
    "description": "Master core syllabus topics and mock tests.",
    "target_date": "2027-02-15",
    "milestones": [
      { "title": "Network Analysis & Circuits", "is_completed": false, "order_index": 0 }
    ]
  }
  ```

### `POST /goals/{goal_id}/milestones/{milestone_id}/toggle`
Toggles milestone completion and recalculates overall goal percentage.

### `PATCH /goals/{goal_id}` & `DELETE /goals/{goal_id}`

---

## 3. Tasks & XP Engine

### `GET /tasks`
Query params: `section` ("Morning Focus", "Main Priorities", "Evening Review"), `due_date`, `is_completed`.

### `POST /tasks`
- **Request Body:**
  ```json
  {
    "title": "Practice 5 High-Yield Gate PYQs Independently",
    "goal_id": "optional-uuid",
    "category": "GATE 2027",
    "section": "Main Priorities",
    "priority": "high",
    "estimated_minutes": 35,
    "xp_reward": 15,
    "due_date": "2026-10-25",
    "why_it_matters": "Active retrieval builds test-day confidence."
  }
  ```

### `POST /tasks/{task_id}/complete`
Marks task as completed and awards XP idempotently.
- **Response (200):**
  ```json
  {
    "task": { ... },
    "xp_awarded": 15,
    "total_xp": 115,
    "level": 2,
    "is_duplicate": false
  }
  ```

### `POST /tasks/{task_id}/reopen`
Reopens a task. XP is not deducted, and re-completing will not award duplicate XP.

---

## 4. AI Coach & Task Planning

### `POST /ai/plan`
Uses Grok (or intelligent domain fallback) to break down a goal into actionable daily tasks.
- **Request Body:**
  ```json
  {
    "goal_title": "Prepare for GATE Electrical Engineering",
    "goal_category": "GATE 2027",
    "available_minutes": 120,
    "context": "Focus on signal processing and network synthesis"
  }
  ```

### `POST /ai/chat`
Conversational AI coach powered by Grok.
- **Request Body:**
  ```json
  {
    "message": "I feel stuck on circuit theorem proofs.",
    "history": []
  }
  ```

### `POST /ai/review-progress`
Generates a personalized review of the user's weekly wins and growth opportunities.

---

## 5. Mountain Journey

### `GET /journey/summary`
Returns level, current stage, total XP, XP needed for next level, progress ratio, mountain percent, streak, and daily message.

### `GET /journey/milestones`
Returns all 10 mountain tiers with status flags (`is_reached`, `is_current`).

### `GET /journey/achievements`
Returns unlocked badges and milestones.

---

## 6. Focus Sessions

### `POST /focus/sessions`
Records a completed focus flow block and awards 10 XP.

---

## 7. Daily Journal

### `POST /journal`
Saves today's reflection and awards 5 XP for maintaining self-awareness.

---

## 8. Analytics

### `GET /analytics/overview`
Aggregated stats: completion rate, 7-day trend, goal progress breakdown, total focus minutes.

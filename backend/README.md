# RISE — Backend API & Microservices

FastAPI + SQLAlchemy + PostgreSQL (Neon) + Alembic + Grok AI integration.

## Features
- **Secure Authentication**: PyJWT + bcrypt password hashing.
- **Goals & Milestones**: Structured long-term goal hierarchy (GATE 2027, Coding, Career, Well-being).
- **Task Scheduling & Idempotent XP Engine**: Daily categorized task planning (Morning Focus, Main Priorities, Evening Review) with duplicate XP prevention.
- **Gamified Mountain Journey**: 10-tier mountain stages, XP ledger, and automatic achievement unlocking.
- **Deep Focus Tracker**: Pomodoro-style flow sessions awarding XP.
- **Daily Reflection Journal**: Date-indexed reflections and prompt responses.
- **Productivity Analytics**: Real-time stats, 7-day completion trends, and goal progression.
- **AI Coach & Task Architect**: Powered by Grok (xAI) with graceful fallback and intelligent structured planning.

---

## Local Development Setup

### 1. Prerequisites
- Python 3.11+
- Virtual environment (recommended)

### 2. Install Dependencies
```bash
pip install -r requirements.txt
```

### 3. Environment Variables
Copy `.env.example` to `.env`:
```bash
cp .env.example .env
```
Default `.env` configuration:
```env
APP_ENV=development
DATABASE_URL=sqlite:///./rise.db
GROK_API_KEY=
GROK_MODEL=grok-2-latest
JWT_SECRET_KEY=rise_super_secret_jwt_key_change_in_production_1234567890
ACCESS_TOKEN_EXPIRE_MINUTES=43200
CORS_ORIGINS=*
FCM_ENABLED=false
```

### 4. Database Migrations
```bash
alembic upgrade head
```

### 5. Run the Server
```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```
API Documentation will be live at:
- Swagger UI: `http://localhost:8000/docs`
- Redoc: `http://localhost:8000/redoc`
- Health check: `http://localhost:8000/health`

### 6. Run Automated Tests
```bash
pytest -v
```

---

## Neon Cloud PostgreSQL Configuration
To connect to Neon:
1. Create a PostgreSQL project on [Neon.tech](https://neon.tech).
2. Copy the connection string (with SSL mode enabled):
   ```env
   DATABASE_URL=postgresql://user:password@ep-sample-123456.us-east-2.aws.neon.tech/neondb?sslmode=require
   ```
3. Run `alembic upgrade head`.

---

## Grok AI Setup
Set your xAI API key in `.env`:
```env
GROK_API_KEY=xai-YOUR_API_KEY_HERE
GROK_MODEL=grok-2-latest
```
If `GROK_API_KEY` is not provided, the API automatically uses the intelligent built-in coaching assistant without breaking or crashing any features.

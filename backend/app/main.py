from fastapi import FastAPI, Depends
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from sqlalchemy import text
from app.core.config import settings
from app.core.database import Base, engine, get_db
import app.models  # ensure all models are registered
from app.api.routes import (
    auth,
    goals,
    tasks,
    ai,
    journey,
    focus,
    journal,
    analytics,
    preferences,
)

# Initialize database tables safely
try:
    Base.metadata.create_all(bind=engine)
except Exception:
    # If database is spinning up (e.g. Neon cold-start), don't crash module import.
    # The /health endpoint will accurately report database readiness.
    pass

app = FastAPI(
    title="RISE — Personal Growth System API",
    description="Backend API for RISE: AI Life Coach, Habit System & Gamified Mountain Progression",
    version="1.0.0"
)

# CORS Configuration
# Allowed methods and headers per requirement 4:
# Include Authorization, Content-Type, Accept, etc.
# Do not use wildcard origins with credentials enabled.
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origin_list,
    allow_origin_regex=r"^https?://(localhost|127\.0\.0\.1)(:\d+)?$",
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
    allow_headers=["Authorization", "Content-Type", "Accept", "Origin", "X-Requested-With"],
)

# Health Check Endpoints (available at /health and /api/health)
@app.get("/health", tags=["System"])
@app.get("/api/health", tags=["System"])
def health_check(db: Session = Depends(get_db)):
    db_status = "healthy"
    try:
        db.execute(text("SELECT 1"))
    except Exception as e:
        db_status = f"unhealthy: {str(e)}"

    return {
        "status": "healthy" if db_status == "healthy" else "degraded",
        "app": "RISE API",
        "environment": settings.APP_ENV,
        "database": db_status,
        "grok_configured": bool(settings.GROK_API_KEY),
        "fcm_enabled": settings.FCM_ENABLED,
    }

# Register API Routers
app.include_router(auth.router, prefix="/api")
app.include_router(goals.router, prefix="/api")
app.include_router(tasks.router, prefix="/api")
app.include_router(ai.router, prefix="/api")
app.include_router(journey.router, prefix="/api")
app.include_router(focus.router, prefix="/api")
app.include_router(journal.router, prefix="/api")
app.include_router(analytics.router, prefix="/api")
app.include_router(preferences.router, prefix="/api")

@app.get("/", tags=["System"])
def root():
    return {
        "message": "Welcome to RISE — Your Personal Growth System API",
        "docs_url": "/docs",
        "health_url": "/health"
    }

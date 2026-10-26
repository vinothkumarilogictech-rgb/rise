# RISE System Architecture

## Overview
**RISE** is a personal growth system that blends an AI life coach, productivity planner, habit tracker, and mountain expedition game.

```
┌────────────────────────────────────────────────────────────────┐
│                       Flutter Android App                      │
│   (Presentation, State Management, Custom Canvas, Offline UI)   │
└─────────────────────────────────┬──────────────────────────────┘
                                  │ HTTPS / REST (JWT Bearer)
                                  ▼
┌────────────────────────────────────────────────────────────────┐
│                    FastAPI Backend Service                     │
│  - Auth & Security (PyJWT + bcrypt)                            │
│  - XP & Gamification Engine (Idempotent Ledger)                │
│  - AI Service (Grok xAI Client + Structured Fallbacks)         │
│  - Business Logic (Goals, Tasks, Focus, Journal, Analytics)    │
└──────────────┬──────────────────────────────────┬──────────────┘
               │                                  │
               ▼                                  ▼
┌───────────────────────────────┐  ┌─────────────────────────────┐
│  Neon PostgreSQL (Production) │  │          Grok xAI           │
│   or SQLite (Local / Dev)     │  │   (api.x.ai/v1/chat/...)    │
└───────────────────────────────┘  └─────────────────────────────┘
```

## Core Architectural Decisions

### 1. Separation of Concerns
- `backend/`: Manages persistence, authentication, authorization, AI prompt orchestration, and XP transaction integrity. No client-specific secrets or Grok credentials leak to the client.
- `flutter_app/`: Focuses purely on visual excellence, reactive state management (Provider), smooth 60fps animations, custom canvas mountain painting, and intuitive tactile interactions.

### 2. Idempotent XP Engine
- XP cannot be duplicated or farmed by toggling task completion repeatedly.
- Every XP reward is backed by an `XPTransaction` record linked to a `reference_id` (task ID, session ID, or reflection date).
- The user's total XP and level are derived deterministically.

### 3. Graceful AI Degradation
- If `GROK_API_KEY` is not provided, the system does not crash or throw unhandled exceptions.
- The AI service provides rich, tailored planning templates (especially for GATE Electrical Engineering and software engineering independence) and friendly coaching responses with clear attribution notices.

### 4. Mountain Progression Geometry
- The mountain ascent is divided into 10 distinct milestones:
  1. First Step (0 XP)
  2. Building Momentum (100 XP)
  3. Finding Rhythm (250 XP)
  4. Climbing Higher (450 XP)
  5. Ascending Ridge (700 XP)
  6. High Altitude (1000 XP)
  7. Near the Summit (1400 XP)
  8. Summit Achiever (2000 XP)
  9. Peak Master (2800 XP)
  10. Legend of Rise (4000 XP)
- Rendered on Android via Flutter CustomPainter with layered mountain ridges, starfields, glowing beacon trail, and smooth position lerping.

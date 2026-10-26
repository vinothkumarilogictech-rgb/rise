# Render & Neon PostgreSQL Deployment Guide

This guide describes how to deploy the RISE backend to **Render** with a **Neon Cloud PostgreSQL** database.

---

## 1. Setup Neon PostgreSQL Database

1. Sign up or log in at [https://neon.tech](https://neon.tech).
2. Click **Create Project**, name it `rise-production`, and select your nearest AWS region.
3. In the Neon dashboard, navigate to **Connection Details**.
4. Select **PostgreSQL Connection String** and ensure `sslmode=require` is appended:
   ```
   postgresql://rise_owner:PASSWORD@ep-sample-123456.us-east-2.aws.neon.tech/rise?sslmode=require
   ```
5. Keep this connection string ready for the Render environment variables.

---

## 2. Deploy Backend on Render

1. Log in to [Render](https://render.com).
2. Click **New +** -> **Web Service**.
3. Connect your Git repository containing the `backend/` directory.
4. Fill in the service configuration:
   - **Name**: `rise-api`
   - **Root Directory**: `backend`
   - **Runtime**: `Python 3`
   - **Build Command**:
     ```bash
     pip install -r requirements.txt && alembic upgrade head
     ```
   - **Start Command**:
     ```bash
     uvicorn app.main:app --host 0.0.0.0 --port $PORT
     ```
   - **Health Check Path**: `/health`

5. In the **Environment Variables** tab, add:
   | Key | Value | Description |
   |---|---|---|
   | `APP_ENV` | `production` | Production environment flag |
   | `DATABASE_URL` | *Your Neon connection string* | Neon PostgreSQL URI with sslmode=require |
   | `JWT_SECRET_KEY` | *Generate random 64-char key* | Secret for signing auth tokens |
   | `GROK_API_KEY` | *Your xAI API Key* | Optional: for Grok AI coach & task generation |
   | `GROK_MODEL` | `grok-2-latest` | Model name |
   | `CORS_ORIGINS` | `*` | Or specific frontend web URLs |
   | `FCM_ENABLED` | `false` | Set to true when Firebase is configured |

6. Click **Create Web Service**.

> [!NOTE]
> Free-tier instances on Render spin down during periods of inactivity. The first request after a sleep period may take 20–30 seconds. The Flutter mobile app handles network timeouts and retries gracefully.

---

## 3. Verify Deployment

Once Render displays **Deploy Succeeded**, verify your service:
```bash
curl https://rise-api.onrender.com/health
```
Expected response:
```json
{
  "status": "healthy",
  "app": "RISE API",
  "environment": "production",
  "database": "healthy",
  "grok_configured": true,
  "fcm_enabled": false
}
```

---

## 4. Connect Flutter App to Render

Build the Flutter Android APK using the Render URL:
```bash
flutter build apk --release --dart-define=API_BASE_URL=https://rise-api.onrender.com/api
```

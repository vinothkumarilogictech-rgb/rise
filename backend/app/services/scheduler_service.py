import logging
import asyncio
from datetime import datetime, timezone, timedelta, date, time
from typing import Optional
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from sqlalchemy.orm import Session
from app.core.database import SessionLocal
from app.models.user import User, UserDeviceToken, ScheduledNotification
from app.models.task import Task
from app.services.fcm_service import send_push_notification
from app.services.study_planner_service import get_or_generate_daily_study_plan

logger = logging.getLogger(__name__)

scheduler: Optional[AsyncIOScheduler] = None

def parse_time_string(time_str: str) -> Optional[time]:
    """
    Parses various time formats such as '05:25 AM', '5:25 PM', '17:30', '05:25'.
    """
    if not time_str:
        return None
    cleaned = time_str.strip().upper()
    formats = ["%I:%M %p", "%I:%M%p", "%H:%M", "%I %p"]
    for fmt in formats:
        try:
            return datetime.strptime(cleaned, fmt).time()
        except ValueError:
            pass
    return None

def is_within_quiet_hours(current_time: time, start_str: str, end_str: str) -> bool:
    """
    Determines whether current_time falls within quiet hours (e.g. 22:00 to 06:00).
    """
    start_t = parse_time_string(start_str) or time(22, 0)
    end_t = parse_time_string(end_str) or time(6, 0)

    if start_t <= end_t:
        return start_t <= current_time <= end_t
    else:  # Overnight interval (e.g. 22:00 to 06:00)
        return current_time >= start_t or current_time <= end_t

async def check_and_dispatch_study_reminders():
    """
    Periodic job (runs every 60 seconds).
    Reads upcoming scheduled tasks from the persistent SQLite database,
    evaluates reminder lead time and quiet hours,
    and sends FCM push notifications without duplicate delivery.
    """
    db: Session = SessionLocal()
    try:
        now_utc = datetime.now(timezone.utc)
        today_str = date.today().strftime("%Y-%m-%d")
        current_clock = now_utc.time()

        # Find users with reminders enabled
        users = db.query(User).all()
        for user in users:
            prefs = user.preferences
            if not prefs or not prefs.notification_enabled or not prefs.notify_study_reminders:
                continue

            lead_mins = prefs.reminder_lead_time_minutes or 15
            quiet_start = prefs.quiet_hours_start or "22:00"
            quiet_end = prefs.quiet_hours_end or "06:00"

            # Check uncompleted tasks for today with start_time
            tasks = db.query(Task).filter(
                Task.user_id == user.id,
                Task.due_date == today_str,
                Task.is_completed == False,
                Task.start_time != None
            ).all()

            for task in tasks:
                parsed_t = parse_time_string(task.start_time)
                if not parsed_t:
                    continue

                task_dt = datetime.combine(date.today(), parsed_t)
                reminder_dt = task_dt - timedelta(minutes=lead_mins)
                diff_seconds = (now_utc.replace(tzinfo=None) - reminder_dt).total_seconds()

                # Dispatch if we are within the trigger window (-120s to +300s)
                if -120 <= diff_seconds <= 300:
                    # Check deduplication record in ScheduledNotification table
                    existing_notif = db.query(ScheduledNotification).filter(
                        ScheduledNotification.user_id == user.id,
                        ScheduledNotification.task_id == task.id,
                        ScheduledNotification.notification_type == "study_reminder",
                        ScheduledNotification.status.in_(["sent", "quiet_hours_skipped"])
                    ).first()

                    if existing_notif:
                        continue  # Already handled, prevent duplicate

                    # Check quiet hours
                    if is_within_quiet_hours(current_clock, quiet_start, quiet_end):
                        skipped_record = ScheduledNotification(
                            user_id=user.id,
                            task_id=task.id,
                            notification_type="study_reminder",
                            title=f"RISE Study Reminder — {task.category or 'Study Session'}",
                            body=f"{task.title} starts at {task.start_time}.",
                            scheduled_time=reminder_dt,
                            status="quiet_hours_skipped",
                            error_message="Skipped due to user quiet hours."
                        )
                        db.add(skipped_record)
                        db.commit()
                        continue

                    # Fetch active device tokens
                    active_tokens = [
                        dt.token for dt in db.query(UserDeviceToken).filter(
                            UserDeviceToken.user_id == user.id,
                            UserDeviceToken.is_active == True
                        ).all()
                    ]

                    title = f"RISE Study Reminder — {task.category or 'Study Session'}"
                    body = f"{task.title} starts at {task.start_time}. {task.why_it_matters or 'Begin with focused practice.'}"

                    notif_record = ScheduledNotification(
                        user_id=user.id,
                        task_id=task.id,
                        notification_type="study_reminder",
                        title=title,
                        body=body,
                        scheduled_time=reminder_dt,
                        status="pending"
                    )
                    db.add(notif_record)
                    db.commit()
                    db.refresh(notif_record)

                    # Send push
                    result = send_push_notification(
                        tokens=active_tokens,
                        title=title,
                        body=body,
                        data={"task_id": str(task.id), "type": "study_reminder"}
                    )

                    notif_record.status = "sent" if result.get("sent", 0) > 0 else "logged"
                    notif_record.sent_at = datetime.now(timezone.utc)
                    db.commit()

                    # Handle any deactivated tokens
                    for stale in result.get("stale_tokens", []):
                        db.query(UserDeviceToken).filter(UserDeviceToken.token == stale).update({"is_active": False})
                        db.commit()
    except Exception as e:
        logger.error(f"Error in check_and_dispatch_study_reminders scheduler job: {e}")
    finally:
        db.close()

def start_scheduler():
    global scheduler
    if scheduler and scheduler.running:
        return

    scheduler = AsyncIOScheduler()
    scheduler.add_job(
        check_and_dispatch_study_reminders,
        "interval",
        seconds=60,
        id="study_session_reminders",
        replace_existing=True
    )
    scheduler.start()
    logger.info("APScheduler persistent reminder worker successfully started.")

def shutdown_scheduler():
    global scheduler
    if scheduler and scheduler.running:
        scheduler.shutdown(wait=False)
        logger.info("APScheduler worker shut down.")

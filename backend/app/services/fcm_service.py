import os
import json
import logging
import threading
from typing import List, Dict, Any, Optional

logger = logging.getLogger(__name__)

_firebase_initialized = False
_init_lock = threading.Lock()

def is_firebase_initialized() -> bool:
    """Checks whether Firebase Admin SDK is initialized."""
    try:
        import firebase_admin
        return bool(firebase_admin._apps)
    except Exception:
        return False

def init_firebase_admin() -> bool:
    """
    Initializes Firebase Admin SDK safely without duplicate initialization.
    Reads credentials from:
    1. FIREBASE_SERVICE_ACCOUNT_PATH (or legacy FIREBASE_CREDENTIALS_PATH)
    2. FIREBASE_SERVICE_ACCOUNT_JSON (raw JSON string for cloud/container deployment)
    Never exposes private credentials or keys in logs.
    """
    global _firebase_initialized
    with _init_lock:
        try:
            import firebase_admin
            from firebase_admin import credentials

            # Check if default app is already initialized
            if firebase_admin._apps:
                _firebase_initialized = True
                return True

            from app.core.config import settings

            if not settings.FCM_ENABLED:
                logger.info("FCM is disabled in settings (FCM_ENABLED=False).")
                return False

            cred_path = settings.resolved_firebase_credentials_path
            cred_json = settings.FIREBASE_SERVICE_ACCOUNT_JSON

            cred = None
            if cred_path and os.path.exists(cred_path):
                # Verify file is not empty
                if os.path.getsize(cred_path) > 0:
                    logger.info(f"Initializing Firebase Admin from service-account file: {os.path.basename(cred_path)}")
                    cred = credentials.Certificate(cred_path)
                else:
                    logger.warning(f"Firebase service account file is empty: {cred_path}")
            elif cred_json and cred_json.strip():
                logger.info("Initializing Firebase Admin from FIREBASE_SERVICE_ACCOUNT_JSON environment variable.")
                parsed_json = json.loads(cred_json.strip())
                cred = credentials.Certificate(parsed_json)

            if cred:
                app_options: Dict[str, Any] = {}
                if settings.FIREBASE_PROJECT_ID:
                    app_options["projectId"] = settings.FIREBASE_PROJECT_ID

                firebase_admin.initialize_app(cred, options=app_options if app_options else None)
                _firebase_initialized = True
                logger.info("Firebase Admin SDK successfully initialized.")
                return True
            else:
                logger.info(
                    "Firebase Admin credentials not configured or file not found. "
                    "FCM remote pushes will run in logging/dry-run mode until credentials are provided."
                )
                return False
        except Exception as e:
            logger.warning(f"Unable to initialize Firebase Admin SDK: {e}")
            return False

def send_push_notification(
    tokens: List[str],
    title: str,
    body: str,
    data: Optional[Dict[str, str]] = None
) -> Dict[str, Any]:
    """
    Sends FCM push notifications to the provided device tokens.
    Never exposes service account private keys or secrets.
    Returns status, sent count, failure count, and identified stale tokens.
    """
    if not tokens:
        return {"sent": 0, "failed": 0, "stale_tokens": [], "status": "no_tokens"}

    is_ready = init_firebase_admin()
    if not is_ready:
        logger.info(f"[FCM Dry-Run] To: {len(tokens)} token(s) | Title: '{title}' | Body: '{body}'")
        return {
            "sent": 0,
            "failed": len(tokens),
            "stale_tokens": [],
            "status": "credentials_unconfigured",
            "message": "Firebase Admin credentials not found. Notification logged safely in dry-run mode."
        }

    from firebase_admin import messaging

    success_count = 0
    failure_count = 0
    stale_tokens = []

    clean_data = {k: str(v) for k, v in (data or {}).items()}

    # Send using MulticastMessage for efficiency across multiple devices
    try:
        message = messaging.MulticastMessage(
            notification=messaging.Notification(
                title=title,
                body=body,
            ),
            data=clean_data,
            tokens=tokens,
            android=messaging.AndroidConfig(
                priority="high",
                notification=messaging.AndroidNotification(
                    channel_id="rise_study_reminders",
                    sound="default",
                ),
            ),
        )

        response = messaging.send_each_for_multicast(message)
        success_count = response.success_count
        failure_count = response.failure_count

        for idx, resp in enumerate(response.responses):
            if not resp.success:
                token = tokens[idx]
                err = resp.exception
                # Check for stale or invalid tokens
                if isinstance(err, (messaging.UnregisteredError, messaging.SenderIdMismatchError)):
                    stale_tokens.append(token)
                logger.warning(f"FCM delivery failed for token {token[:12]}...: {err}")

        return {
            "sent": success_count,
            "failed": failure_count,
            "stale_tokens": stale_tokens,
            "status": "delivered" if success_count > 0 else "failed"
        }
    except Exception as e:
        logger.error(f"FCM multicast dispatch error: {e}")
        return {
            "sent": 0,
            "failed": len(tokens),
            "stale_tokens": [],
            "status": "error",
            "message": str(e)
        }

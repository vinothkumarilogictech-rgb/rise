import json
import logging
from typing import Dict, Any, List, Optional
import httpx
from app.core.config import settings

logger = logging.getLogger(__name__)

SYSTEM_COACH_PROMPT = """You are the RISE AI Coach — a highly capable, knowledgeable, practical conversational AI mentor.

Core Directives:
1. Direct Answer First: ALWAYS answer the user's latest question, greeting, calculation, or request directly, accurately, and thoughtfully before offering any extra guidance.
2. Versatile Expertise:
   - Greetings & General Conversation: Respond naturally, warmly, and concisely (e.g., User: "hi" → "Hi! How can I help you today?").
   - Educational & Exam Preparation: Provide practical, structured plans and explanations (e.g. GATE 2027 Electrical Engineering, physics, calculus, or revision schedules).
   - Coding & Engineering: Provide clear, working code examples, explain concepts from first principles, and guide debugging step by step.
   - Daily Planning & Productivity: Build realistic, balanced schedules respecting stated time limits and rest intervals.
   - Math & Fact Queries: Give direct, accurate answers immediately (e.g., "25 × 4 = 100").
3. Contextual Understanding:
   - Use the ongoing conversation history to understand follow-up questions, pronouns, and references.
   - Never repeat previous responses unless specifically asked.
   - Reference RISE goals or personal XP only when directly relevant to the user's prompt.
   - Never force generic motivational templates or mountain metaphors into unrelated answers.
4. Tone & Clarity: Friendly, natural, concise, and structured with clean markdown where helpful.
5. Precision: If key details are missing to answer a technical bug or planning prompt, ask a concise clarifying question. If uncertain, state so honestly."""

async def call_grok_api(messages: List[Dict[str, str]], temperature: float = 0.7) -> Optional[str]:
    """
    Calls the AI completions API using standard OpenAI-compatible completions format.
    Dynamically routes to Groq (https://api.groq.com/openai/v1), xAI (https://api.x.ai/v1), or custom endpoint.
    Includes automatic model fallback if rate limits (HTTP 429) are encountered.
    Returns the response text or None if the API key is missing or request fails.
    """
    if not settings.GROK_API_KEY:
        logger.warning("GROK_API_KEY is not configured in environment.")
        return None

    headers = {
        "Authorization": f"Bearer {settings.GROK_API_KEY}",
        "Content-Type": "application/json",
    }

    # Primary and fallback models
    models_to_try = [settings.resolved_model]
    if settings.GROK_API_KEY.startswith("gsk_"):
        if "openai/gpt-oss-120b" in models_to_try:
            models_to_try.append("qwen/qwen3.8-27b")
        else:
            models_to_try.append("openai/gpt-oss-120b")

    endpoint = settings.grok_endpoint

    for model in models_to_try:
        payload = {
            "model": model,
            "messages": messages,
            "temperature": temperature,
            "max_tokens": 1200,
        }

        try:
            async with httpx.AsyncClient(timeout=30.0) as client:
                response = await client.post(
                    endpoint,
                    headers=headers,
                    json=payload
                )
                if response.status_code == 200:
                    data = response.json()
                    return data["choices"][0]["message"]["content"]
                elif response.status_code == 429:
                    logger.warning(f"AI API rate limit (429) with model '{model}'. Retrying with fallback...")
                    continue
                else:
                    logger.error(f"AI API returned HTTP {response.status_code} from {endpoint}: {response.text}")
                    return None
        except Exception as e:
            logger.error(f"Exception contacting AI API ({endpoint}) with model '{model}': {e}")

    return None

async def generate_ai_task_plan(
    goal_title: str,
    goal_category: str,
    available_daily_minutes: int,
    user_context: Optional[str] = None
) -> List[Dict[str, Any]]:
    """
    Generates structured tasks for a goal.
    Uses the AI model if available, otherwise generates a tailored starter plan.
    """
    prompt = f"""Generate a realistic, focused 3-to-4 task action plan for the goal: "{goal_title}" in category "{goal_category}".
The user has approximately {available_daily_minutes} minutes available today.
User preferences/context: {user_context or 'Consistent gradual daily progress'}.

You must return a valid JSON array of objects with the following keys:
- "title": (string) Specific, actionable task title.
- "description": (string) Brief 1-2 sentence instruction.
- "section": ("Morning Focus" | "Main Priorities" | "Evening Review")
- "priority": ("high" | "medium" | "low")
- "estimated_minutes": (integer between 15 and 50)
- "xp_reward": (10 for normal, 15 for high priority)
- "why_it_matters": (string) A concise 1-sentence motivation on how this builds long-term capability.

Return strictly raw JSON with no markdown backticks."""

    messages = [
        {"role": "system", "content": "You are a world-class task architect that outputs only strict valid JSON."},
        {"role": "user", "content": prompt}
    ]

    response_text = await call_grok_api(messages, temperature=0.3)
    if response_text:
        try:
            cleaned = response_text.strip()
            if cleaned.startswith("```"):
                cleaned = cleaned.split("```")[1]
                if cleaned.startswith("json"):
                    cleaned = cleaned[4:]
            cleaned = cleaned.strip()
            tasks = json.loads(cleaned)
            if isinstance(tasks, list) and len(tasks) > 0:
                return tasks
        except Exception as e:
            logger.warning(f"Failed to parse AI JSON plan response: {e}")

    # Fallback tailored templates if API key is absent or returns non-JSON
    lower_title = goal_title.lower()
    if "gate" in lower_title or "electrical" in lower_title:
        return [
            {
                "title": f"Study Core Concept for {goal_title}",
                "description": "Complete 35 minutes of focused review on key theorems and formulas.",
                "section": "Morning Focus",
                "priority": "high",
                "estimated_minutes": 35,
                "xp_reward": 15,
                "why_it_matters": "Core conceptual clarity is required to solve high-weightage numerical problems."
            },
            {
                "title": "Solve 5 Previous Years Questions (PYQs)",
                "description": "Work through 5 standard exam problems independently under timed conditions.",
                "section": "Main Priorities",
                "priority": "high",
                "estimated_minutes": 45,
                "xp_reward": 15,
                "why_it_matters": "Active retrieval and calculation practice directly correlates with test day speed."
            },
            {
                "title": "Error Log & Concept Retention Review",
                "description": "Document incorrect answers in an error logbook and summarize the mistake.",
                "section": "Evening Review",
                "priority": "medium",
                "estimated_minutes": 20,
                "xp_reward": 10,
                "why_it_matters": "Systematic error analysis prevents repeating the same conceptual traps."
            }
        ]
    elif "code" in lower_title or "coding" in lower_title or "software" in lower_title:
        return [
            {
                "title": "Deep Focus: Build Core Feature Module Independently",
                "description": "Implement the next component logic for 40 minutes without instant AI assistance.",
                "section": "Morning Focus",
                "priority": "high",
                "estimated_minutes": 40,
                "xp_reward": 15,
                "why_it_matters": "Solving coding problems independently builds genuine engineering confidence."
            },
            {
                "title": "Inspect & Debug Edge Cases",
                "description": "Add boundary condition tests and handle possible null or network failure states.",
                "section": "Main Priorities",
                "priority": "medium",
                "estimated_minutes": 30,
                "xp_reward": 10,
                "why_it_matters": "Robust edge-case handling is the hallmark of senior software architects."
            },
            {
                "title": "Architectural Reflection & Git Commit",
                "description": "Write a clean commit log and document key learnings from today's session.",
                "section": "Evening Review",
                "priority": "low",
                "estimated_minutes": 15,
                "xp_reward": 10,
                "why_it_matters": "Daily documentation cements design knowledge into long-term memory."
            }
        ]
    else:
        return [
            {
                "title": f"Execute Main Priority for {goal_title}",
                "description": "Complete the most impactful 40-minute action block toward your goal.",
                "section": "Morning Focus",
                "priority": "high",
                "estimated_minutes": 40,
                "xp_reward": 15,
                "why_it_matters": "Focusing on your primary lever first creates undeniable forward momentum."
            },
            {
                "title": "Deliberate Practice & Skill Deepening",
                "description": "Review progress, refine details, and address any current bottlenecks.",
                "section": "Main Priorities",
                "priority": "medium",
                "estimated_minutes": 30,
                "xp_reward": 10,
                "why_it_matters": "Deliberate refinement turns rough work into polished mastery."
            },
            {
                "title": "Day Wrap-up & Tomorrow Preparation",
                "description": "Review completed milestones and prepare materials for your next session.",
                "section": "Evening Review",
                "priority": "low",
                "estimated_minutes": 15,
                "xp_reward": 10,
                "why_it_matters": "Clearing the mental runway ensures a calm and focused tomorrow."
            }
        ]

async def chat_with_coach(
    user_name: str,
    user_message: str,
    history: List[Dict[str, str]],
    recent_stats: Optional[Dict[str, Any]] = None
) -> Dict[str, Any]:
    """
    Conversational AI coaching handler.
    Always answers the user's specific query using live AI.
    Never returns repetitive canned motivational boilerplate.
    """
    if not settings.GROK_API_KEY:
        return {
            "reply": "AI service is not configured yet. Please configure GROK_API_KEY in backend/.env to enable conversational AI.",
            "source": "system",
            "is_fallback": True,
            "notice": "AI service is not configured yet."
        }

    stats_context = ""
    if recent_stats:
        stats_context = (
            f" [User Context: Level {recent_stats.get('level', 1)}, "
            f"XP: {recent_stats.get('total_xp', 0)}, "
            f"Tasks completed today: {recent_stats.get('completed_today', 0)}]"
        )

    system_message = {
        "role": "system",
        "content": f"{SYSTEM_COACH_PROMPT}\nYou are speaking with {user_name}.{stats_context}"
    }

    formatted_messages: List[Dict[str, str]] = [system_message]

    # Append up to 6 past conversation turns for follow-up context.
    # To protect the rate limit (tokens per minute), trim older assistant messages if exceptionally long.
    for msg in history[-6:]:
        role = msg.get("role", "user")
        content = msg.get("content", "").strip()
        if content and role in ("user", "assistant"):
            if role == "assistant" and len(content) > 600:
                content = content[:600] + "... [context summary]"
            formatted_messages.append({"role": role, "content": content})

    # Ensure the latest user message is present at the end
    clean_user_message = user_message.strip()
    if not formatted_messages or formatted_messages[-1].get("content") != clean_user_message:
        formatted_messages.append({"role": "user", "content": clean_user_message})

    response_text = await call_grok_api(formatted_messages, temperature=0.7)
    if response_text:
        return {
            "reply": response_text.strip(),
            "source": "grok",
            "is_fallback": False
        }

    # If API call failed or timed out:
    return {
        "reply": "Unable to reach the AI service. Please try again in a few moments.",
        "source": "system",
        "is_fallback": True,
        "notice": "Unable to reach the AI service."
    }

async def extract_timetable_from_text(raw_text: str) -> List[Dict[str, Any]]:
    """
    Parses OCR or PDF extracted timetable text into structured session items.
    Uses Grok with a strict JSON prompt, and falls back to a deterministic regex parser.
    """
    if not raw_text or not raw_text.strip():
        return []

    prompt = f"""You are an expert academic schedule and timetable extraction engine.
Parse the following raw text extracted from a study timetable (e.g., GATE 2027 EEE or college study plan).
Extract EVERY study session, revision, practice block, PYQ session, mock test, break, and error analysis across all dates and weeks.

Rules:
1. Extract ALL sessions spanning multiple days or weeks. Do not omit sessions.
2. For each session provide:
   - "date": string in YYYY-MM-DD format. If only month/day or weekday is given, infer relative to current year (2026/2027).
   - "weekday": full weekday name (e.g. "Monday", "Tuesday").
   - "start_time": string formatted like "05:25 AM" or "16:00".
   - "end_time": string formatted like "06:45 AM" or "17:30".
   - "subject": subject title (e.g. "Network Theory", "Control Systems", "Electrical Machines").
   - "topic": specific chapter or topic (e.g. "KCL, KVL and Nodal Analysis", "Nyquist Plot", "DC Motor Speed Control").
   - "session_type": one of ("study", "pyq", "mock_test", "revision", "break", "analysis").
   - "estimated_minutes": calculated or estimated integer duration in minutes (e.g. 80).
   - "priority": ("high", "medium", "low"). Core concept and mock tests are "high", PYQs and revisions "medium", breaks "low".
   - "notes": additional instructions like question target, formula review, or error logbook.
3. Return STRICTLY a valid JSON array of objects. No markdown backticks, no explanations.

RAW TIMETABLE TEXT:
{raw_text[:6000]}
"""

    messages = [
        {"role": "system", "content": "You are a timetable parser that outputs ONLY valid JSON array."},
        {"role": "user", "content": prompt}
    ]

    response_text = await call_grok_api(messages, temperature=0.1)
    if response_text:
        try:
            cleaned = response_text.strip()
            if cleaned.startswith("```"):
                cleaned = cleaned.split("```")[1]
                if cleaned.startswith("json"):
                    cleaned = cleaned[4:]
            cleaned = cleaned.strip()
            sessions = json.loads(cleaned)
            if isinstance(sessions, list) and len(sessions) > 0:
                logger.info(f"Successfully parsed {len(sessions)} timetable sessions using Grok.")
                return sessions
        except Exception as e:
            logger.warning(f"Failed to parse Grok timetable response: {e}")

    # Deterministic fallback parser using regex heuristics
    import re
    from datetime import datetime, date

    logger.info("Using deterministic timetable fallback parser.")
    fallback_sessions = []
    current_date = date.today().strftime("%Y-%m-%d")
    current_weekday = date.today().strftime("%A")

    lines = raw_text.splitlines()
    for line in lines:
        line_clean = line.strip()
        if not line_clean:
            continue

        # Check for date line: e.g. "Date: 2026-10-27" or "2026-10-27 | Tuesday"
        date_match = re.search(r"(\d{4}[-/]\d{1,2}[-/]\d{1,2})", line_clean)
        if date_match:
            try:
                raw_d = date_match.group(1).replace("/", "-")
                parsed_d = datetime.strptime(raw_d, "%Y-%m-%d").date()
                current_date = parsed_d.strftime("%Y-%m-%d")
                current_weekday = parsed_d.strftime("%A")
            except Exception:
                pass

        weekday_match = re.search(r"\b(Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday)\b", line_clean, re.I)
        if weekday_match:
            current_weekday = weekday_match.group(1).capitalize()

        # Check for time range pattern: e.g. "05:25 AM - 06:45 AM" or "05:25 - 06:45"
        time_match = re.search(r"(\d{1,2}[:.]\d{2}(?:\s*[AaPp][Mm])?)\s*[-–to]+\s*(\d{1,2}[:.]\d{2}(?:\s*[AaPp][Mm])?)", line_clean)
        if time_match:
            start_t = time_match.group(1).strip().replace(".", ":")
            end_t = time_match.group(2).strip().replace(".", ":")
            remainder = line_clean[time_match.end():].strip().lstrip(":- ")
            
            # Extract subject and topic
            subject = "General Study"
            topic = remainder or "Study Session"
            if "-" in remainder:
                parts = remainder.split("-", 1)
                subject = parts[0].strip()
                topic = parts[1].strip()
            elif ":" in remainder:
                parts = remainder.split(":", 1)
                subject = parts[0].strip()
                topic = parts[1].strip()

            lower_line = line_clean.lower()
            if "pyq" in lower_line or "question" in lower_line or "practice" in lower_line:
                stype = "pyq"
                priority = "medium"
            elif "mock" in lower_line or "test" in lower_line:
                stype = "mock_test"
                priority = "high"
            elif "revision" in lower_line or "review" in lower_line:
                stype = "revision"
                priority = "medium"
            elif "break" in lower_line or "rest" in lower_line:
                stype = "break"
                priority = "low"
            elif "error" in lower_line or "analysis" in lower_line:
                stype = "analysis"
                priority = "medium"
            else:
                stype = "study"
                priority = "high"

            fallback_sessions.append({
                "date": current_date,
                "weekday": current_weekday,
                "start_time": start_t,
                "end_time": end_t,
                "subject": subject,
                "topic": topic,
                "session_type": stype,
                "estimated_minutes": 60,
                "priority": priority,
                "notes": line_clean
            })

    return fallback_sessions


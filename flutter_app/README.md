# RISE — Flutter Android Application

**Your Personal Growth System**: An AI Life Coach, Habit Tracker, Focus Planner, and Mountain Expedition Game.

---

## Visual Design System & Aesthetics
- **Dark Gaming Aesthetic**: Midnight Navy (`#080B16`), Secondary Surface (`#11182A`), Elevated Cards (`#171F35`).
- **Signature Mountain Progression Canvas**: Custom-rendered vector mountains with twinkling starfield, atmospheric glows, winding trail, and animated climber beacon.
- **Accents**: Electric Blue (`#4F8CFF`), Violet Accent (`#8B5CF6`), Cyan Highlight (`#42D9F5`), Soft Mint (`#10B981`), Warm Amber (`#F59E0B`).
- **Typography**: Google Fonts Outfit hierarchy.

---

## Screen Architecture
1. **Onboarding Flow**:
   - `WelcomeScreen`: Atmospheric brand entrance with mountain backdrop.
   - `OnboardingFlowScreen`: Questions capturing display name, priorities, daily study time, reminder time, and planning philosophy.
   - `AuthScreen`: Secure registration, login, JWT token persistence, and error handling.
2. **Main Application Shell (`MainNavigationShell`)**:
   - Bottom navigation bar with 5 destinations.
3. **Home Screen**:
   - Header with local-time greeting, user name, date, avatar, and AI daily quote badge.
   - Signature Mountain Journey Hero Card (opens Journey screen).
   - Daily progress overview (circular progress ring, completed vs total tasks, XP earned, streak).
   - Today's Main Focus (featured key lever task).
   - Today's Schedule (Morning Focus, Main Priorities, Evening Review).
   - Quick Actions (AI Coach, Add Task, Focus Flow, Journal).
   - Daily Reflection Preview.
4. **Goals Screen**:
   - Categories (GATE 2027, Coding Independence, Career & Work, Personal Well-being).
   - Goal cards with progress percentage and milestone checklist.
   - AI Plan Generator calling Grok to break goals into daily action items.
5. **AI Coach Screen**:
   - Real-time conversation powered by Grok xAI via backend.
   - Starter prompts for planning, habit friction, and engineering debugging.
6. **Journey Screen**:
   - Fullscreen mountain expedition with 10 ascending stages.
   - Trail milestones list with reached/current state.
   - Expedition achievement badges.
   - Transparent XP rules ledger.
7. **Focus Session**:
   - 25-minute Pomodoro flow timer with start, pause, resume, reset.
   - Completion celebration awarding 10 XP with backend sync.
8. **Daily Journal**:
   - Date picker, mood chips (focused, grateful, motivated, calm, tired).
   - Reflection prompts and history log. Awards 5 XP for self-reflection.
9. **Analytics Screen**:
   - 7-day consistency bar chart.
   - Completion rate, total focus minutes, active streak, and goal breakdown.
10. **Profile Screen**:
    - Display name editing, study time slider, planning style selector, local notification test button, and sign out.

---

## How to Run Locally

### 1. Start the Python Backend
In a separate terminal:
```bash
cd backend
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

### 2. Run Flutter App
```bash
cd flutter_app
flutter pub get
```

#### Android Emulator (pointing to local backend)
```bash
flutter run
```
*(Android emulator automatically uses `http://10.0.2.2:8000/api` by default).*

#### Physical Android Device or Custom Host
```bash
flutter run --dart-define=API_BASE_URL=http://<YOUR_LOCAL_IP>:8000/api
```

#### Pointing to Render Production Backend
```bash
flutter run --dart-define=API_BASE_URL=https://rise-api.onrender.com/api
```

### 3. Build Production APK
```bash
flutter build apk --release --dart-define=API_BASE_URL=https://rise-api.onrender.com/api
```
The resulting APK will be located at:
`build/app/outputs/flutter-apk/app-release.apk`

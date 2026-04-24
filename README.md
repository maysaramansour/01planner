# 01-Planner — Feature Memory

Living record of everything implemented in this session, what it does, and where it lives in code. Use this as the canonical reference when asking the assistant to extend or change behavior.

---

## 1. App identity

| Item | Value |
| --- | --- |
| Display name | **01-Planner** |
| Launcher icon | Coral rounded-square with white **01** + accent dot. Adaptive icon uses `#E89F94` background (`android/app/src/main/res/mipmap-*/ic_launcher*.png`, `mipmap-anydpi-v26/ic_launcher*.xml`, `values/colors.xml`) |
| Locales | English (`en`), Arabic (`ar`) — RTL-aware |
| Platform | Flutter 3.7+, Dart, Hive local storage, Material 3 |

---

## 2. Navigation

Bottom tabs in a Structured-style shell ([lib/screens/main_shell.dart](lib/screens/main_shell.dart)):

1. **Inbox** — unscheduled tasks (empty-state with illustration + "New Inbox Task")
2. **Timeline** — day view (hourly grid, time-blocked cards)
3. **AI** — conversational planning assistant
4. **Settings** — hub for all preferences

A floating **+** FAB on every non-AI tab opens the Structured-style **New Task** bottom sheet.

---

## 3. Data models (Hive)

Persisted locally with Hive. Type IDs claimed: `0 Task, 1 Event, 2 Habit, 3 HabitCompletion, 4 Goal, 5 AIMessage, 6 ChatSession`.

- **Task** ([lib/models/task.dart](lib/models/task.dart)) — fields 0–18: id, title, description, dueAt, priority (0..2), reminder + lead minutes, completed + timestamp, goalId, createdAt, notificationId, **scheduledStart**, **durationMinutes**, **iconKey**, **colorValue**, **subtasks** (`"[x] …" / "[ ] …"` inline encoding), **notes**, **recurrence** (0 none / 1 daily / 2 weekly / 3 monthly).
- **Event** — id, title, location, startAt, endAt, reminderLeadMinutes, recurrence, createdAt, notificationId.
- **Habit** — id, name, frequencyType (0 daily / 1 specific-days), weekdays `[1..7]`, reminderHour/Minute.
- **HabitCompletion** — habitId, dateIso, completedAt.
- **Goal** ([lib/models/goal.dart](lib/models/goal.dart)) — id, title, description, targetDate, archived.
- **AIMessage** ([lib/models/ai_message.dart](lib/models/ai_message.dart)) — id, role (user/assistant/system), text, createdAt, sessionId.
- **ChatSession** ([lib/models/chat_session.dart](lib/models/chat_session.dart)) — id, title, createdAt, updatedAt.

Inbox semantics: a Task with `scheduledStart == null && dueAt == null` is in the Inbox. No separate box or flag.

---

## 4. Timeline (Today screen) — [lib/screens/today_screen.dart](lib/screens/today_screen.dart)

- Large header month + year in the app's primary color.
- **Day strip** — horizontal scrollable list of 60 days (centered around today). Each cell shows weekday + date + **colored dots**: primary dot when the day has scheduled tasks, tertiary dot when it has events.
- **Timeline view** ([lib/widgets/timeline_view.dart](lib/widgets/timeline_view.dart)) — 24 hourly rows (60 dp each), 56 dp gutter with hour labels, RTL-aware. Cards positioned absolutely from `scheduledStart + durationMinutes`. Periodic (30 s) red "now" line with a gutter dot. Auto-scrolls to current hour on first open.
- **Timeline card** ([lib/widgets/timeline_card.dart](lib/widgets/timeline_card.dart)) — colored rounded card with leading icon chip, title, time range, optional subtitle, strike-through when completed.
- Renders three item types:
  - **Events** — tertiary color, `event` icon.
  - **Scheduled tasks** — user-chosen color + icon.
  - **Habits** — purple "🔁 name" card at the habit's reminder time; tap shows mark done / open detail / etc.
- Long-press on a task → reschedule, toggle complete, move to Inbox, delete.
- Tap on the month-year header or the calendar icon → date picker.
- "Due today" footer strip for tasks with only `dueAt` (no scheduled time).

---

## 5. Inbox — [lib/screens/inbox_screen.dart](lib/screens/inbox_screen.dart)

- Empty state matches Structured's screenshot: big coral inbox tile, "Your Unstructured Thoughts" headline, description, big pill "New Inbox Task" button → opens New Task sheet.
- Populated state: list of tiles with icon chip, title, optional notes, completion checkbox.
- Long-press → delete confirmation.

---

## 6. New Task bottom sheet — [lib/widgets/new_task_sheet.dart](lib/widgets/new_task_sheet.dart)

Structured-style two-step modal:

- **Step 1** — "What?" with icon-color chip on the left (opens icon/color picker) and an underlined text field on the right. Four quick-template cards below (Answer Emails, Watch a Movie, Meet with Friends, Go for a Run). Continue button.
- **Step 2** — "When?" with a combined date+time tile (full date picker range: 2 years back to 2 years forward) and a duration dropdown (15/30/45/60/90/120/180 min).
- Save creates a Task with reminder auto-enabled when a start time is set.

---

## 7. Task editing — [lib/screens/task_edit_screen.dart](lib/screens/task_edit_screen.dart)

Full editor for an existing task with:

- Icon + color picker chip (header).
- Title, description, start time (date+time), due date (date+time), duration (when scheduled), priority (low/med/high segmented), recurrence, reminder toggle + lead minutes dropdown, subtasks editor, notes field, link-to-goal dropdown.

---

## 8. Icon + color picker — [lib/widgets/icon_picker_sheet.dart](lib/widgets/icon_picker_sheet.dart)

Modal sheet with:

- 12 curated Material icons ([lib/widgets/task_icons.dart](lib/widgets/task_icons.dart)) — work, gym, call, home, shop, study, food, travel, health, meet, read, idea.
- 12-color palette (shared `kPaletteColors` in [lib/services/ai_service.dart](lib/services/ai_service.dart)).
- Returns `(iconKey, colorValue)`.

---

## 9. AI Assistant

### 9.1 Connection — [lib/services/ai_service.dart](lib/services/ai_service.dart), [lib/services/ai_config.dart](lib/services/ai_config.dart)

- OpenAI-compatible client talking to LM Studio / Ollama / any /v1/chat/completions endpoint.
- **Base URL** and **Model** configurable in Settings → AI Assistant. Defaults: `http://192.168.117.131:9999` and `qwen/qwen2.5-vl-7b`.
- `/v1` auto-appended if the base URL has no `/v\d+` path.
- **Test connection** button probes `/v1/models` (GET) and `/v1/chat/completions` (POST) and surfaces the exact HTTP error in the UI when it fails.
- Android release manifest has `INTERNET` permission + cleartext HTTP allowed (`network_security_config.xml`).
- USB reverse-tunnel supported — base URL `http://127.0.0.1:9999` works via `adb reverse tcp:9999 tcp:9999`.

### 9.2 Conversation flow — [lib/screens/ai_screen.dart](lib/screens/ai_screen.dart)

- Structured-style chat with greeting + suggestion chips when empty.
- Bubbles: user (coral), assistant (white), system (coral-tint + checkmark "confirmation" pills).
- **Quick-reply options** — when the assistant asks a question, it emits an `options` array; the UI renders tap chips instead of forcing the user to type. Chips can be plain text or `{label, picker: "date"|"time"|"duration"}` — picker variants open native pickers and send the formatted value back.
- **Multi-select options** — supported when the assistant sets `multiSelect: true`; a Submit button sends the union.
- **Mic button** — speech-to-text via `speech_to_text` ([lib/services/speech_service.dart](lib/services/speech_service.dart)) with Arabic (`ar-SA`) or English (`en-US`) based on current locale. Live partial transcript fills the input field.
- **Markdown rendering** in assistant bubbles (via `flutter_markdown`).

### 9.3 State snapshot sent to the model

Every turn, the AI receives a JSON snapshot of: `inbox`, `todayScheduled`, `todayEvents`, `habits`, `goals`, with IDs — so it can reference existing items.

### 9.4 Actions the AI can emit

Enum `AIActionKind` ([lib/services/ai_service.dart](lib/services/ai_service.dart)):

| Action | Notes |
| --- | --- |
| `createTask / updateTask / deleteTask / toggleTask` | Full CRUD on tasks, including linking to an existing goal via `goalId`. |
| `createEvent / updateEvent / deleteEvent` | Full CRUD on events. |
| `createHabit / updateHabit / deleteHabit / toggleHabit` | Full CRUD on habits; toggle marks done/undone for a date. |
| `createGoal / updateGoal / deleteGoal / archiveGoal` | Full CRUD on goals. |
| `plan` | Batch action: `{goals:[], habits:[], tasks:[], targetGoalId?}`. Tasks are automatically linked to the first new goal (or `targetGoalId` if supplied). |
| `done` | Friendly close. |
| `none` | Still gathering info; ask the next question with `options`. |

System prompt enforces:
- **≤ 2 clarifying turns** before committing to an action.
- **Unique task titles** — never duplicate.
- **Max 15 tasks** per plan.
- **Conflict-aware scheduling** — every plan call injects a `BUSY` JSON of upcoming events + scheduled tasks; the model is told to avoid those windows.
- **Use real ISO 8601** — no `<tomorrow 19:00 ISO>` placeholder tokens.

### 9.5 Convert chat to plan — [lib/services/ai_service.dart](lib/services/ai_service.dart) `extractPlan`

A dedicated button above the chat input fires a focused JSON-only extraction pass over the full conversation, with higher `max_tokens` (8192). The raw result is run through:

1. **Tolerant JSON parser** — strips markdown fences, extracts the first `{…}`, and **repairs truncated JSON** (closes still-open `[` and `{` when the output hits the token cap).
2. **Dedupe by normalized title** — caps at 15 unique tasks.

### 9.6 Plan preview sheet — [lib/widgets/plan_preview_sheet.dart](lib/widgets/plan_preview_sheet.dart)

95 %-height modal that sits between extraction and commit:

- Header shows plan summary (`N goals · N habits · N tasks`).
- Three sections with per-row checkboxes + inline edit chips (date/time/duration for tasks, reminder time for habits, target date for goals).
- Footer: **Cancel** + **Commit N items** — only checked drafts get written.
- Launched from:
  - **Convert chat to plan** button in AIScreen.
  - **✨ Generate with AI** button on each Goal detail screen (see § 10.3).

### 9.7 Sessions drawer

ChatGPT-style sessions ([lib/services/ai_chat_service.dart](lib/services/ai_chat_service.dart)):

- **AIMessage** and **ChatSession** Hive boxes.
- Active session stored in SharedPreferences.
- Drawer (left-side `Scaffold.drawer`) lists all sessions (most-recent first); tap to switch, popup menu to rename / delete, "New chat" button at top.
- First user message auto-titles the session.
- Clear-chat button in the app bar wipes only the active session.

### 9.8 Daily planner — [lib/screens/daily_planner_screen.dart](lib/screens/daily_planner_screen.dart)

Takes all inbox tasks + user-selected wake / sleep window and asks the model to propose conflict-free time slots. Shows a diff list; user accepts to apply or rejects.

---

## 10. Goals

### 10.1 Goals screen — [lib/screens/goals_screen.dart](lib/screens/goals_screen.dart)

List of active goals with progress bars.

### 10.2 Goal edit — [lib/screens/goal_edit_screen.dart](lib/screens/goal_edit_screen.dart)

Standard title / description / target date / archived form.

### 10.3 Goal detail — [lib/screens/goal_detail_screen.dart](lib/screens/goal_detail_screen.dart)

- Description, target date, progress bar (linked-task completion %).
- Sub-tasks section with manual "Add sub-task" button (opens TaskEditScreen pre-filled with `goalId`).
- **✨ Generate with AI** — fires `AIService.extractTasksForGoal(goal)` which builds a goal-specific prompt (goal title, description, days-until-target), runs extraction with the same busy-window + dedupe pipeline, then opens the plan preview sheet. Committed tasks are stamped with this goal's `goalId`.
- **Link existing** — bottom-sheet picker of all unlinked, incomplete tasks; user selects some and they're attached to this goal in one batch.
- Tasks with this `goalId` are listed below via `TaskService().tasksForGoal(goal.id)`.

---

## 11. Habits

- **Habits screen** ([lib/screens/habits_screen.dart](lib/screens/habits_screen.dart)) — list with streak badges.
- **Habit edit** ([lib/screens/habit_edit_screen.dart](lib/screens/habit_edit_screen.dart)) — name, frequency (daily vs specific weekdays), reminder time.
- **Habit detail** ([lib/screens/habit_detail_screen.dart](lib/screens/habit_detail_screen.dart)) — completion calendar, streak.
- Habits appear on the timeline at their reminder time (purple card). Tap → mark done/undone, open detail, etc.

---

## 12. Events

Standard calendar events ([lib/services/event_service.dart](lib/services/event_service.dart) + [lib/screens/calendar_screen.dart](lib/screens/calendar_screen.dart) + [lib/screens/event_edit_screen.dart](lib/screens/event_edit_screen.dart)):

- Title, optional location, start + end, reminder lead minutes, recurrence (none / daily / weekly / monthly), local notifications.
- Rendered on the timeline and inside the Calendar screen's month view (accessed from Settings → Calendar).

---

## 13. Notifications — [lib/services/notification_service.dart](lib/services/notification_service.dart)

- `flutter_local_notifications` + `timezone`; 3 channels (tasks / events / habits).
- Tasks: fire at `(scheduledStart ?? dueAt) − leadMinutes`. Respect per-task `recurrence` via `DateTimeComponents`.
- Events: fire at `startAt − leadMinutes` with matching recurrence.
- Habits: daily or weekday-specific recurring fires.
- Tapping a notification routes to the relevant edit screen via `rootNavigatorKey`.

---

## 14. Settings — [lib/screens/settings_screen.dart](lib/screens/settings_screen.dart)

Hub screen with:

- **Stats row** — Today, Inbox, Done counts.
- **Organize** section — nav tiles for Calendar, Habits, Goals, Daily plan (each with a count badge when relevant).
- **AI Assistant** — link to AI settings (status dot shows connected/disabled).
- **Preferences** — three hub tiles that open sub-pages:
  - **Notifications & Alerts** → [lib/screens/notifications_screen.dart](lib/screens/notifications_screen.dart)
  - **Customization** → [lib/screens/customization_screen.dart](lib/screens/customization_screen.dart)
  - **Advanced** → [lib/screens/advanced_screen.dart](lib/screens/advanced_screen.dart)

### 14.1 Notifications & Alerts

- Intro info card.
- System notifications tile (permission request).
- Alarms tile (informational: points to OS settings).
- **Default alerts** list backed by `AppPrefs().defaultAlerts` (list of minutes-before). Each row: bell + "At start" / "15m before" / "1h before", with × to remove. "+ Add new alert" bottom-sheet of 7 presets (0/5/15/30/60/120/1440 min).

### 14.2 Customization

- **Preview card** — mini timeline mock using the current primary color + layout mode.
- **App color** — 7 circles (coral, orange, yellow, green, blue, teal, red). Tapping writes to `AppPrefs().primaryColor`; entire app repaints instantly via a `ValueListenableBuilder<int>` wrapping `MaterialApp`.
- **Layout** — segmented Full / Simplified / Minimal. Bound to `AppPrefs().layoutMode`.

### 14.3 Advanced

- **First Day of the Week** dropdown → `AppPrefs().firstDayOfWeek`.
- **Language** dropdown (en / ar) → `LocaleService.setLocale()`.
- **Reset App** destructive button — wipes all Hive boxes (tasks/events/habits/completions/goals/AI messages/sessions), resets `AIConfig` + `AIChatService` + `AppPrefs`, and pops back to root.

---

## 15. Preferences service — [lib/services/app_prefs.dart](lib/services/app_prefs.dart)

SharedPreferences-backed singleton. Exposes `ValueNotifier`s:

| Pref | Default | Purpose |
| --- | --- | --- |
| `primaryColor` | `0xFFE89F94` coral | Overrides theme primary / primaryContainer / FAB / etc. |
| `firstDayOfWeek` | `7` (Sat) | Consumed by calendar + day strip week framing. |
| `defaultAlerts` | `[0, 15]` | Applied to new tasks as reminder lead minutes. |
| `layoutMode` | `full` | `full / simplified / minimal`; controls card density on the timeline. |

`AppPrefs().resetAll()` restores all defaults.

---

## 16. Theming — [lib/theme/app_theme.dart](lib/theme/app_theme.dart)

Material 3 light theme with Structured-style coral defaults. `AppTheme.of(locale, primaryColor)` derives `primaryContainer` from HSL lightness and rebuilds the full `ThemeData`. Arabic uses Cairo, English uses Inter (via `google_fonts`); tolerates the network falling back to system font.

---

## 17. Localization

- All strings in [lib/l10n/app_en.arb](lib/l10n/app_en.arb) and [lib/l10n/app_ar.arb](lib/l10n/app_ar.arb) (`generate: true` → `flutter_gen`).
- Plural forms used for task counts, alert durations, etc.
- RTL-aware widgets throughout.

---

## 18. Android platform glue

- `android/app/src/main/AndroidManifest.xml`:
  - `INTERNET` (required for AI endpoint in release builds).
  - `RECORD_AUDIO` (voice input).
  - `usesCleartextTraffic="true"` + `networkSecurityConfig="@xml/network_security_config"` for local LAN / USB LLM endpoints.
  - Speech recognizer query intent.
- Custom adaptive launcher icon + coral background color.

---

## 19. Verified end-to-end flows

1. Connect AI → ping ping.
2. Chat in Arabic → AI suggests plan → tap options → confirm.
3. Convert chat to plan → review sheet → uncheck noise → commit → items appear.
4. Goal detail → Generate with AI → sub-tasks linked to this goal.
5. Pick a color in Customization → UI repaints everywhere.
6. Advanced → Reset App → fresh Inbox.

---

## 20. Explicit non-goals (so far)

- No inline title/text editing inside the plan preview sheet.
- No drag-to-reschedule on the timeline (long-press + time picker instead).
- No Rise-and-Shine / Wind-Down anchor cards or "2h 30m free" gap cards (v1 scope cut).
- No cloud sync — everything is on-device.
- No iOS-specific integrations beyond Flutter defaults; primary target is Android.
- No Azure MAI Transcribe yet — on-device STT only (the hook is the same `SpeechService` swap).

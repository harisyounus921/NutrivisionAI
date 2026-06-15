# Nutrivision AI (ai_diet)

AI-powered diet monitoring app built with Flutter (Android/iOS). Automates
meal logging via on-device food image recognition (TFLite) and barcode
scanning, pulls nutrition data from verified APIs (USDA/Edamam/Nutritionix),
and provides a conversational AI diet coach (GPT/Dialogflow) plus dashboards,
health-app sync, and gamification (streaks/badges).

See [README.md](README.md) for the full spec: scope, functional requirements
(FR-01..FR-16), use cases (UC-01..UC-12), tech stack, architecture, data
model, screen list, testing approach, and build roadmap.

## Build order & status

User-directed build order: **Auth → Profile → Food/Meals → Dashboard → Coach
→ Health → Gamification → Settings**, building "step by step, module by
module."

- [x] Auth (login, register, session persistence, splash auto-login)
- [x] Profile (biometrics, goals, BMR/TDEE/calorie-goal calc)
- [x] Food/Meal logging (manual search + portion logging; photo/barcode are
      placeholder "coming soon" entry points)
- [x] Dashboard (today's calories/macros, 7-day trend — fl_chart)
- [x] AI Coach (chat UI — rule-based responses grounded in profile + today's
      log; stands in for GPT/Dialogflow until a real backend is wired up)
- [x] Health integration (manual activity logging — net calorie balance,
      steps, activity log; Google Fit/Apple Health sync are placeholder
      "coming soon" entry points, same as photo/barcode in Food)
- [x] Gamification (streaks/badges — "Awards" tab; fully derived from meal
      logs, activity logs, and profile, no new persistence)
- [x] Settings (account/profile link, notification preference toggle,
      data export & delete-all per FR-15, log out — reached via AppBar
      action from Home, not a tab)

All modules in the original build order are complete. Future work should be
confirmed with the user (e.g. wiring real Google Fit/Apple Health sync,
real push notifications, photo/barcode recognition, or a real backend).

Run `flutter analyze && flutter test` after each module — both must stay
clean ("No issues found!" / "All tests passed!").

## Required tech choices (do not deviate without asking)

- **State management:** `provider` (ChangeNotifier) only. No Bloc/Riverpod
  has been introduced despite README mentioning them as options.
- **Persistence:** `shared_preferences` everywhere, JSON-encoded for complex
  objects/lists. No real backend yet.
- **Navigation:** plain `Navigator` with `AppPageRoute` (see below) —
  `pushAndRemoveUntil` / `pushReplacement` / `push` / `pop` /
  `popUntil(... isFirst)`. **No named routes, no routing packages**
  (go_router etc.).
- **Charts:** `fl_chart` (added for Dashboard).
- **Typography & animation:** `google_fonts` (Poppins/Nunito, via `AppTheme`)
  + `flutter_animate` (entrance/stagger animations) — added during the UI
  redesign. Don't introduce other typography/animation packages.

## Architecture / established patterns

- **Local-first, swappable backend:** Auth, Profile, and Food/Meal data all
  live in `shared_preferences` via per-feature `*Service` classes. This is
  intentional — UI and Provider public APIs are written so the services can
  be swapped for Firebase (Option A) or a custom Node/Postgres backend
  (Option B) later without touching screens/providers. **Backend choice A
  vs B is still an open decision — confirm with the user before introducing
  a real backend.**
- **Feature folder structure:**
  `lib/features/<feature>/{models,providers,services,screens,data}/` and
  shared helpers in `lib/core/{services,navigation,theme,widgets}/`. Existing
  features: `auth`, `profile`, `food`, `dashboard`, `coach`, `health`,
  `gamification`, `settings`, `home` (contains `MainShell` + Home tab).
- **Shared widgets:** `lib/core/widgets/log_option_card.dart` →
  `LogOptionCard` — tappable option card used by both `LogMealScreen` and
  `LogActivityScreen` entry screens. Takes `icon`, `title`, `subtitle`,
  `onTap`, plus optional `iconColor` (defaults to `colorScheme.primary`) and
  `animationDelay` (default `Duration.zero`, for staggered entrance).
- **Post-auth routing helper:** `lib/core/navigation/post_auth_navigation.dart`
  → `postAuthDestination(context)` returns `ProfileSetupScreen` if no profile
  saved yet, else `MainShell`. Used by splash/login/register after they
  await `AuthProvider` + `ProfileProvider.loadProfile()` +
  `MealLogProvider.loadLogs()`.
- **App shell:** `lib/features/home/screens/main_shell.dart` — bottom
  `NavigationBar` + `IndexedStack` tabs (Home, Dashboard, Coach, Health,
  Awards — 5 tabs, the Material max). `SettingsScreen` is reached via a
  gear `IconButton` in Home's `AppBar` (it replaced the old "Edit profile"/
  "Logout" icons there, both now consolidated into Settings) rather than as
  a 6th tab.
- **Lazy per-tab loading:** providers whose data isn't needed for post-auth
  routing (e.g. `ChatProvider`, `ActivityLogProvider`) load their own data via
  `loadLogs()`/`loadMessages()` in their tab screen's `initState` (using
  `WidgetsBinding.instance.addPostFrameCallback`), rather than in
  `post_auth_navigation.dart`. Since `MainShell` uses `IndexedStack`, all tabs
  mount immediately so this still runs right away.
- **Async + BuildContext:** every `await` that's followed by another
  `context.read<...>()` or `Navigator` call must be preceded by its own
  `if (!mounted) return;` (avoids `use_build_context_synchronously` lint —
  one guard per await-then-context-use, not just one at the end).
- **Local seed data:** `lib/features/food/data/food_database.dart` (15 items)
  stands in for the USDA/Edamam/Nutritionix nutrition API for now.

## UI theme, navigation & animation conventions

- **Design system:** `lib/core/theme/app_theme.dart` → `AppTheme` is the
  single source of styling, built from a "Fresh Mint & Teal" palette —
  `seed` #16A975 (emerald, primary), `secondary` #0E7C66 (deep teal), `accent`
  #FFB74D (warm amber, used for badges/streaks), surface #F4FBF8 (soft
  mint-white). `AppTheme.light` builds the app's `ThemeData` via
  `ColorScheme.fromSeed().copyWith(...)` plus Poppins (headings) + Nunito
  (body) from `google_fonts`, and is wired into `MaterialApp.theme` in
  `main.dart`. **Light theme only** — dark mode is future work, not started.
  Shared constants used across screens: `heroGradient` (emerald→teal, for
  header/hero containers and emphasis blocks like calorie totals),
  `cardRadius` (20) / `fieldRadius` (16), and macro accent colors
  `proteinColor`/`carbsColor`/`fatColor`.
- **Navigation transitions:** `lib/core/navigation/app_page_route.dart` →
  `AppPageRoute<T>` is a `PageRouteBuilder` subclass providing a fade+slide-up
  transition. It's the drop-in replacement for `MaterialPageRoute` for every
  push/replace in `lib/` — still plain `Navigator`, no routing packages.
- **Entrance animations:** `flutter_animate` is applied declaratively, e.g.
  `.animate().fadeIn(delay:, duration:).slideX/slideY(begin:, end:)` or
  `.scale(begin:, end:, curve:)`. Conventions: staggered list items use
  index-based delays (e.g. `(index * 30).ms` for search results, `(100 +
  index * 50).ms` for achievement cards); sections/cards on a screen stack in
  ~50ms increments (0ms, 50ms, 100ms, ...); hero icons/FABs scale in with
  `Curves.easeOutBack`; looping emphasis (typing-indicator dots, streak flame)
  uses `.animate(onPlay: (c) => c.repeat(...))` with `.then(delay:)` chains.
  Progress values (calorie rings, macro/achievement bars, chart entrances) use
  `TweenAnimationBuilder<double>` (~700ms `Curves.easeOutCubic`) since
  `flutter_animate` doesn't animate indicator *values* directly.
- **google_fonts in tests:** `test/widget_test.dart` sets
  `GoogleFonts.config.allowRuntimeFetching = false` inside `setUpAll()` (not
  in `main.dart`) so `flutter test` doesn't hit the network for font files,
  while the real app still loads Poppins/Nunito normally.

## Key providers

- `AuthProvider` (`features/auth/providers/auth_provider.dart`) — login/
  register/logout/tryAutoLogin, always succeeds locally (no real auth
  backend yet).
- `ProfileProvider` (`features/profile/providers/profile_provider.dart`) —
  `UserProfile` with Mifflin-St Jeor BMR → TDEE → `dailyCalorieGoal`.
- `MealLogProvider` (`features/food/providers/meal_log_provider.dart`) —
  `logs`, `todayLogs`, `todayCalories/Protein/Carbs/Fat`,
  `last7DaysCalories` (7-day rolling totals for Dashboard).
- `ChatProvider` (`features/coach/providers/chat_provider.dart`) — `messages`,
  `loadMessages()`, `sendMessage(text, CoachContext)`. Replies come from
  `CoachResponseService` (rule-based, keyword-matched), given a `CoachContext`
  built by the screen from `ProfileProvider` + `MealLogProvider` (today's
  calories/macros vs. goal). Suggests foods from `food_database.dart`,
  filtered by `UserProfile.dietaryPreference`/`allergies`.
- `ActivityLogProvider` (`features/health/providers/activity_log_provider.dart`)
  — `logs`, `todayLogs`, `todayCaloriesBurned`, `todaySteps`. Activities are
  manually logged from `activity_database.dart` (seed list, mirrors
  `food_database.dart`); net calorie balance on the Health tab combines this
  with `MealLogProvider.todayCalories` and `ProfileProvider`'s
  `dailyCalorieGoal`.
- `SettingsProvider` (`features/settings/providers/settings_provider.dart`) —
  `mealRemindersEnabled` (persisted bool, `loadSettings()`/
  `setMealRemindersEnabled()`). The reminder itself is a placeholder
  (FR-13 needs real device notification scheduling).

All six are registered in `MultiProvider` in `lib/main.dart`.

## Gamification (Awards tab)

- `AchievementService` (`features/gamification/services/achievement_service.dart`)
  — stateless; `evaluate({mealLogs, activityLogs, profile})` returns a
  `GamificationSummary` (current/longest logging streaks + per-badge
  `AchievementProgress`). No provider or persistence — computed on each
  build from `MealLogProvider.logs`, `ActivityLogProvider.logs`, and
  `ProfileProvider.profile`.
- Badge definitions live in `features/gamification/data/achievement_database.dart`
  (mirrors `food_database.dart`/`activity_database.dart` seed-list pattern).
  Adding a badge = adding an `Achievement` entry with an `AchievementType`
  (`mealCount`, `activityCount`, `streak`, `goalHit`) and a `target`.

## Settings screen

- `SettingsScreen` (`features/settings/screens/settings_screen.dart`) —
  account row, "Edit profile" (→ `ProfileSetupScreen`), meal-reminder toggle
  (`SettingsProvider`), "Export my data", "Delete all data", "Log out".
- `DataManagementService` (`features/settings/services/data_management_service.dart`,
  FR-15/UC-12):
  - `exportAll()` — reads `ProfileService`/`MealLogService`/
    `ActivityLogService`/`ChatService` and returns one JSON-able map, shown
    in a dialog with copy-to-clipboard (`SelectableText` +
    `Clipboard.setData`, no new package).
  - `deleteAll()` — clears meal logs, activity logs, and chat history via
    each service's `clearLogs()`/`clearMessages()`. The Settings screen then
    separately calls `ProfileProvider.clearProfile()`, reloads the other
    providers (so in-memory state matches the wiped storage — `ChatProvider`
    re-seeds its welcome message), and finally `AuthProvider.logout()` before
    navigating to `LoginScreen`.
- Each `*Service` that holds a list under one shared_preferences key
  (`MealLogService`, `ActivityLogService`, `ChatService`) has a matching
  `clearLogs()`/`clearMessages()` that does `prefs.remove(key)`, mirroring
  `ProfileService.clearProfile()`/`SessionService.clearSession()`.

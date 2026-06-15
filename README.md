# Nutrivision AI — AI Diet Monitoring App

Nutrivision AI is a cross-platform (Android/iOS) mobile app, built with
Flutter, that automates diet tracking using AI-powered food image
recognition, barcode scanning, and a conversational AI diet coach. It reduces
the manual effort of conventional calorie-tracking apps while providing
personalized nutrition feedback.

## Problem & Purpose

Most diet-tracking apps (MyFitnessPal, Lose It!, Lifesum, Cronometer) rely on
manual food entry: users search for items, estimate portions, and confirm
calorie counts. This is slow, error-prone, and especially hard for
home-cooked, cultural, or mixed-plate meals. Feedback is usually limited to
generic calorie totals, without adapting to personal goals, allergies, or
dietary restrictions — so users disengage over time.

**Nutrivision AI's purpose** is to:

- Automate meal logging via AI food recognition and barcode scanning
- Provide accurate nutrition data from verified nutrition APIs
- Offer personalized dietary recommendations and conversational coaching
- Improve long-term engagement via dashboards, reminders, and gamification

**Differentiation:** existing apps cover one or two of (vision-based logging,
verified nutrition data, AI coaching) at most. Nutrivision AI combines all
three into a single app.

## Scope

### Functional Scope

- **User Profiling** — age, gender, height, weight, activity level, goals
  (weight loss / maintenance / muscle gain), dietary preferences (vegetarian,
  halal, gluten-free), allergies/restrictions
- **Meal Logging** — photo-based AI recognition, barcode scanning, manual
  search (fallback)
- **Nutrition Dashboard** — daily/weekly/monthly calories, macros, and goal
  progress via charts
- **AI Recommendations & Coaching** — chatbot for meal suggestions, healthy
  swaps, portion tips, motivational feedback
- **Health Integration** — sync with Google Fit / Apple Health for net
  calorie balance
- **Gamification** — streaks, badges, weekly reports, reminders

### Non-Functional Scope

- Secure authentication and encrypted data storage
- Fast response time for recognition and logging
- Scalable architecture for multiple users
- Offline caching for recent logs and lookups

### Out of Scope

No medical diagnosis or clinical-level nutrition prescriptions. This is a
lifestyle support tool, not a replacement for professional dietitians.

## Tech Stack

### Frontend (Flutter/Dart)

- **State management:** Provider or Riverpod (general state); Bloc for
  complex flows (meal logging, dashboard updates)
- **Networking:** `dio` or `http`
- **Visualization:** `fl_chart` (primary), `syncfusion_flutter_charts` (if
  advanced charts are needed)
- **Camera/scanning:** `camera` for photo capture, `mobile_scanner` or
  `qr_code_scanner` for barcodes
- **Local storage:** `shared_preferences` (tokens/lightweight config), `Hive`
  (offline cache of nutrition lookups & logs)
- **Auth:** `firebase_auth` (email, Google, Apple)

### Backend — open decision (choose one)

- **Option A — Managed (Firebase):** Firestore (DB), Firebase Storage (meal
  images), Firebase Functions (serverless logic/API glue), Firebase Cloud
  Messaging (reminders/notifications)
- **Option B — Custom:** Node.js/Express or Django REST API; PostgreSQL
  (structured data: users, meals, progress); MongoDB (unstructured data: food
  photos); Redis (cache for frequent food lookups); deployed on AWS/GCP/Azure

### AI/ML

- **On-device food recognition:** TensorFlow Lite, pretrained
  MobileNet/EfficientNet fine-tuned on Food-101 / UEC-Food100 (+ regional food
  data later)
- Cloud AI for retraining / more complex classification
- **Conversational coaching:** OpenAI GPT API or Google Dialogflow

### Nutrition Data

- USDA FoodData Central
- Edamam Nutrition Analysis API
- Nutritionix

### Dev Tooling

- Git/GitHub, GitHub Actions (CI/CD), Postman (API testing), Flutter Test
  (unit/widget tests), Android Studio / VS Code

## System Modules

- **Authentication & User Profile** — register/login (email or social),
  biometrics, goals, preferences, dietary restrictions
- **Food Logging** — photo (AI recognition), barcode (scanner + API), manual
  search (verified database)
- **Nutrition Database & API** — food lookup by name/barcode, nutrition
  fetching and normalization, cached results
- **AI Diet Coach** — chat interface, daily guidance based on consumption,
  motivational feedback and reminders
- **Dashboard & Analytics** — daily macro breakdown, weekly trend charts,
  goal-based alerts (e.g. low protein)
- **Health Integration** — imports calories burned/steps/activity, computes
  net calorie balance
- **Notifications & Gamification** — meal reminders, streaks, badges and
  achievements
- **Settings & Privacy** — manage permissions/notifications, export/delete
  user data, consent and transparency

## Functional Requirements

| ID | Requirement |
|----|-------------|
| FR-01 | User Registration |
| FR-02 | Login/Logout |
| FR-03 | Password Reset |
| FR-04 | Profile Setup (age, height, weight, goal) |
| FR-05 | Daily Calorie Goal Calculation |
| FR-06 | Meal Logging via Photo |
| FR-07 | Meal Logging via Barcode |
| FR-08 | Meal Logging via Manual Search |
| FR-09 | Nutrition Summary Update |
| FR-10 | Charts (daily/weekly/monthly) |
| FR-11 | AI Coach chat query and response |
| FR-12 | Health platform sync |
| FR-13 | Reminder notifications |
| FR-14 | Badges and streaks |
| FR-15 | Data export and deletion |
| FR-16 | Offline caching of recent logs |

## Use Cases

- **UC-01** Register Account
- **UC-02** Login
- **UC-03** Create Profile & Goals
- **UC-04** Log Meal using Photo
- **UC-05** Log Meal using Barcode
- **UC-06** Log Meal manually
- **UC-07** View Dashboard & Progress
- **UC-08** Chat with AI Diet Coach
- **UC-09** Sync Health Data
- **UC-10** View Streaks & Achievements
- **UC-11** Manage Settings & Privacy
- **UC-12** Export/Delete Data

## Architecture Overview

- **Mobile Client (Flutter):** captures photos/barcodes/manual logs, renders
  dashboards/charts/chat UI, handles offline caching of recent logs
- **Backend Services:** auth, nutrition lookups, data storage; APIs for
  profiles, progress summaries, AI recommendations (Option A or B above)
- **AI Layer:** on-device TFLite model for fast/offline food recognition;
  cloud AI for retraining/advanced classification; NLP chatbot
  (GPT/Dialogflow) for coaching
- **External Integrations:** nutrition databases (USDA/Edamam/Nutritionix);
  health platforms (Google Fit/Apple HealthKit)

## System Workflow (End-to-End Example)

1. User logs in (Firebase auth)
2. User captures a photo of their meal
3. On-device TFLite model predicts food item(s)
4. App queries a nutrition API for calories/macros
5. User confirms or adjusts portion size
6. Meal is saved to the user's log (Firestore/Postgres)
7. Dashboard recalculates daily calorie balance and macros
8. AI coach gives instant feedback, e.g. *"Your protein intake is low today,
   consider adding eggs or lentils for dinner."*
9. End-of-day notification summarizes progress, e.g. *"You consumed 1800 kcal
   out of 2000. Great job staying within your target!"*

Barcode logging and AI coach chat follow the same pattern, substituting steps
2-4 with a barcode lookup or a direct chat query.

## Data Model (ER Entities)

Main entities: **User**, **Profile**, **MealLog**, **FoodItem**,
**NutritionSummary**, **Achievements**, **ChatHistory**.

Starting schema reference:

**User**

| Field | Type | Description |
|-------|------|-------------|
| user_id | string/uuid | unique identifier |
| email | string | login email |
| created_at | datetime | registration date |

**MealLog**

| Field | Type | Description |
|-------|------|-------------|
| log_id | uuid | meal log id |
| user_id | uuid | FK user |
| meal_time | datetime | timestamp |
| source | string | photo/barcode/manual |
| calories | float | total kcal |
| protein | float | grams |
| carbs | float | grams |
| fat | float | grams |

## App Screens (Planned)

- Login Screen — email/social login
- Profile Setup Screen — age, height, weight, goal, dietary restrictions
- Dashboard Screen — calories consumed/remaining, macro distribution, trends
- Photo Logging Screen — capture image, show predicted foods
- Barcode Scanner Screen — scan barcode, fetch product nutrition
- AI Coach Chat Screen — ask dietary questions, receive guidance

## Testing Approach

- **Black-box testing** — user-facing flows: registration, login (valid &
  invalid), profile setup, manual/barcode/photo meal logging, dashboard
  totals, AI coach queries, notifications
- **White-box testing** — internal logic: token generation, BMR/goal-calc
  formula paths, DB insert success/failure, nutrition API
  success/timeout/fallback, model confidence thresholds (auto-fill vs. ask
  user to confirm), dashboard totals calculation, chatbot prompt builder with
  user restrictions
- **Unit testing** — UI widgets, nutrition calculation functions, data parsing,
  caching logic
- **Integration testing** — login → log meal → dashboard update; photo
  recognition → nutrition fetch → save; barcode scan → API fetch → save
- **System testing** — multiple users, repeated logs, offline/online
  switching, API performance under load

## Project Status / Roadmap

**Current status:** fresh Flutter scaffold (`flutter create` default), no
custom features implemented yet.

**Suggested build order:**

1. Requirements/design finalization (architecture, ER diagram, wireframes)
2. Project setup, choose backend option (A/B), implement auth & profile module
3. Database + nutrition API integration (USDA/Edamam/Nutritionix)
4. Manual search & barcode-scan meal logging
5. Food recognition AI (train/fine-tune model, convert to TFLite, integrate
   camera flow)
6. Nutrition dashboard & visualizations (fl_chart)
7. AI diet coach chatbot & recommendations (GPT/Dialogflow)
8. Health platform integration (Google Fit / Apple Health, net calorie balance)
9. Notifications & gamification (streaks, badges, reminders)
10. Testing & QA (unit/integration/system)
11. Refinement, optimization, and documentation polish

## Future Enhancements

- Portion estimation using depth/AR
- Expanded food dataset for Pakistani/local foods
- Multilingual support (Urdu + English)
- Improved meal segmentation (multiple items in one plate)
- Offline-first model improvements
- Dietitian-reviewed coaching mode

# MealNudge Firebase Structure

This project follows the same broad Firestore layout as Sceniva: shared app
configuration is stored in `config/*`, user-owned data is stored under
`users/{uid}`, and Firebase Storage stores user media under `users/{uid}`.

## Root Collections

- `users`
- `guest_users`
- `config`
- `foods`
- `barcodes`
- `content`
- `notifications`
- `chat_head`
- `refral`

## Config Documents

- `config/api_keys`
  - `openai_api_key`
  - `imagen_api_key`
  - `gpt_enable`
- `config/app_version`
  - `android`
  - `ios`
- `config/mealnudge_limits`
  - `daily_meal_photo_limit`
  - `daily_coach_message_limit`

## User Documents

- `users/{uid}`
  - `name`
  - `email`
  - `createdAt`
  - `updatedAt`
- `users/{uid}/private/profile`
- `users/{uid}/private/settings`
- `users/{uid}/meals/{mealId}`
- `users/{uid}/healthSummaries/{yyyy-mm-dd}`
- `users/{uid}/conversations/{conversationId}`
- `users/{uid}/conversations/{conversationId}/messages/{messageId}`

## Storage

- `users/{uid}/food_photos/{timestamp}_{filename}`

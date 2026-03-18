# Debtly

Debtly is an offline-first Flutter app for tracking personal debts, recurring payments, bills, salary impact, due dates, and reminders.

It is designed as a focused personal finance utility, not a full accounting system.

## What Debtly Does

- create debts, obligations, subscriptions, and one-time expenses
- create recurring plans:
  - one time
  - monthly
  - yearly
  - custom interval
- track payment cycles and payment history
- support partial payments
- show due, upcoming, overdue, completed, and closed items
- track monthly salary and remaining balance
- allow negative projected/remaining balance
- send local reminders with no backend required
- export a local backup file

## Product Direction

Debtly is built to feel like a premium, calm, dark-mode utility app:

- dark-only UI
- selectable accent themes
- local-first data model
- clean reusable Flutter architecture
- no demo records on first launch

## Tech Stack

- Flutter
- Riverpod
- SQLite via `sqflite`
- Local notifications via `flutter_local_notifications`
- Timezone-aware scheduling via `timezone` + `flutter_timezone`

## Architecture

Project structure:

- `lib/src/app`
  - app shell and navigation
- `lib/src/application`
  - controller/providers
- `lib/src/domain/models`
  - entities, enums, app settings
- `lib/src/domain/services`
  - recurrence engine
  - salary summary service
  - notification service
- `lib/src/data/local`
  - SQLite database setup and migrations
- `lib/src/data/repositories`
  - repository abstraction and implementation
- `lib/src/features`
  - Overview
  - Plans
  - Timeline
  - Salary
  - Settings
- `lib/src/core`
  - theme, tokens, reusable widgets, helpers

## Core Data Model

Debtly stores structured local data in SQLite:

- `plans`
- `occurrences`
- `payments`
- `reminders`
- `salary_configs`
- `settings`

This separation matters:

- recurring plans remain intact even after individual cycles are paid
- payment history is preserved
- reminders can be rescheduled after edits
- salary summaries are recalculated from actual data

## Key Behavior

- recurring occurrences are generated safely ahead of time
- due-day edge cases are clamped correctly for short months
- leap-year yearly recurrence is handled safely
- partial payments reduce remaining occurrence balance
- closed/completed items are retained before cleanup
- reminders support due date, 1 day before, first day of month, salary day, and custom offsets

## Notifications

Debtly uses local notifications only.

Implemented:

- notification permission requests
- exact alarm handling on Android
- local scheduled reminders
- notification tap routing back into the app
- hidden debug tools for notification testing

Notes:

- Android support is actively tested
- iOS support is implemented in code, but should still be validated on a real iPhone before relying on it in production

## Running the Project

From the project root:

```bash
flutter pub get
flutter run
```

## Android Release Build

Standard release APK:

```bash
flutter build apk --release
```

Smaller split APKs by CPU architecture:

```bash
flutter build apk --release --split-per-abi
```

App Bundle for Play Store:

```bash
flutter build appbundle --release
```

## iOS

You cannot build iPhone binaries from Linux.

To build for iPhone you need:

- macOS
- Xcode
- Apple signing/provisioning setup

## Local Data / Reset

Debtly stores all data locally on-device.

You can:

- export a backup from Settings
- reset the app from Settings
- clear app data from the OS

## Current Status

What is working:

- offline-first storage
- recurring debt/payment tracking
- payment history
- salary summary
- local notifications on Android
- premium dark UI with accent themes

What still deserves real-device verification:

- iPhone notification behavior
- iOS notification tap routing
- iOS layout pass on different screen sizes

## Contributing / Using This Repo

If you pull this project:

1. run `flutter pub get`
2. run `flutter analyze`
3. run on Android first
4. verify notifications on your own device

If you modify database fields or settings, make sure to add a proper SQLite migration.

## License

This project is licensed under the MIT License.

See [LICENSE](LICENSE) for details.

# Student Task & Expense Tracker

A Flutter learning/portfolio project for organizing student tasks and tracking a monthly personal budget. Data is stored locally on the device.

## Features
- Add tasks with optional due dates.
- Mark tasks as complete and sort unfinished tasks before completed tasks.
- Highlight overdue unfinished tasks.
- Schedule a local reminder 12 hours before a task deadline when the deadline is still in the future.
- Record income and expenses with an optional note.
- Set a monthly allowance and calculate the remaining amount using transactions from the current month only.
- Store tasks and transactions in SQLite; store the monthly allowance in SharedPreferences.
- Unit tests for monthly transaction filtering, budget calculations, and task sorting.

## Tech stack
- Flutter and Dart
- SQLite (`sqflite`)
- SharedPreferences
- Local notifications and timezone support
- `intl` for date formatting

## Run locally
```bash
flutter pub get
flutter run
flutter test
```

## Project structure
- `lib/main.dart` - application UI and reminder scheduling
- `lib/task_db.dart` - SQLite database operations
- `lib/logic.dart` - testable budget and task-sorting logic
- `test/logic_test.dart` - unit tests

## Data and privacy
All task and budget records are stored locally on the device. The app does not connect to a remote service. This is a personal portfolio project; do not enter sensitive financial information.

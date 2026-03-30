# OJT Calendar

A fully offline Flutter app for OJT (On-the-Job Training) trainees to track daily work hours, record time‑in/out, compute allowances, and generate official Daily Time Record (DTR) reports.

## Features

- 📅 **Interactive Calendar** – View your month at a glance with colour‑coded hours (green ≥8h, orange ≥4h, red <4h, red “Abs” for absent, blue “Hol” for holidays, orange “Sun” for Sundays).
- 📝 **Log Panel** – Record time in/out for morning and afternoon sessions, mark absences or holidays.
- 📊 **DTR Table** – All your records in a searchable, editable table. Automatically includes Sundays.
- 📄 **Export Reports** – Generate official DTR reports for any month or custom date range. Export to **Excel** (`.xlsx`) or **PDF** (half‑bond‑paper format).
- ⚙️ **Settings** – Set total required OJT hours, daily allowance, and your name & supervisor’s name (appears on reports).
- 🔍 **Search by Date** – Quickly find a day’s record via a popup dialog.
- 💾 **Offline First** – All data is stored locally using SQLite. No internet required.

## Screenshots

> _Add your own screenshots here after building the app._

## Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.41.0 or later)
- Android Studio / VS Code with Flutter extensions

### Build from source

1. Clone this repository:
   ```bash
   git clone https://github.com/your-username/ojt_calendar.git
   cd ojt_calendar
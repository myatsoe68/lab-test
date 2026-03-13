# Class Check-in and Reflection App (Flutter MVP)

Simple attendance prototype for university classes. Students check in before class and complete class reflection after class.

## Live Demo
- Firebase Hosting URL: https://class-checkin-mfu-20260313.web.app

## Project Description
This app validates class attendance with three signals:
- GPS location capture
- QR code scanning
- Student reflection form input

The app includes three core screens:
- Home Screen
- Check-in Screen (Before Class)
- Finish Class Screen (After Class)

It also includes a built-in `Show Demo QR Codes` screen for testing scan flow without external tools.

## Features
- Before-class check-in:
	- Scan QR code
	- Capture GPS + timestamp
	- Fill previous topic, expected topic, mood score (1-5)
- After-class completion:
	- Scan QR code again
	- Capture GPS + timestamp
	- Fill learned-today and feedback text
- Local data persistence (MVP):
	- Stored on device with `shared_preferences` (local storage style)
- Firebase Hosting deployment for web demo

## Tech Stack
- Flutter (Dart)
- Packages:
	- `geolocator`
	- `mobile_scanner`
	- `shared_preferences`
	- `qr_flutter`
- Firebase Hosting (web deployment)

## Repository Structure
- `../PRD.md` - Product Requirement Document
- `lib/main.dart` - main app logic and UI
- `test/widget_test.dart` - widget test file
- `firebase.json` - Firebase Hosting config
- `.firebaserc` - Firebase project alias
- `test_qr/` - generated PNG QR samples

## Setup Instructions

### 1. Prerequisites
- Flutter SDK installed
- Git installed
- Node.js installed (for Firebase CLI and local static serving)
- Firebase CLI installed (`npm i -g firebase-tools`)

### 2. Install dependencies
From project folder:

```powershell
cd class_checkin_app
flutter pub get
```

If using Puro-managed Flutter environment, replace `flutter` with `puro -e uni flutter`.

## How to Run

### Option A: Run web build locally (recommended in this setup)
```powershell
cd class_checkin_app
flutter build web
npx serve -s build/web -l 8080
```

Open the shown local URL (for example `http://localhost:8080` or another port if 8080 is busy).

### Option B: Run on Android device/emulator
```powershell
cd class_checkin_app
flutter run
```

Requires Android SDK and accepted licenses.

## Firebase Configuration Notes
- Firebase project alias in `.firebaserc`:
	- `default`: `expensetracker-35b03`
- Firebase Hosting site in `firebase.json`:
	- `site`: `class-checkin-mfu-20260313`
- Deploy command:

```powershell
cd class_checkin_app
flutter build web
firebase deploy --only hosting
```

## Data Captured (MVP)
For each record, app saves:
- `phase` (`checkin` or `finish`)
- `timestamp`
- `qrValue`
- `latitude`, `longitude`, `accuracy`
- check-in fields: `previousTopic`, `expectedTopic`, `moodScore`
- finish fields: `learnedToday`, `feedback`

## AI Usage Report (Short)
AI tools were used to:
- Generate initial Flutter screen scaffolding
- Integrate GPS, QR scanning, and local persistence
- Generate Firebase Hosting setup commands and deployment config
- Draft and refine project documentation

Manual work included:
- Adjusting forms and validation logic
- Updating workflow to match assignment requirements
- Resolving environment setup and deployment issues on Windows
- Finalizing app behavior and testing flow

## Notes
- This is an MVP prototype for assignment use.
- Local storage is used instead of cloud database for attendance records.
- Firebase is currently used for hosting the web demo.

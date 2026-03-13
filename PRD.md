# Product Requirements Document

## Product Name
Class Check-in and Reflection App

## Version
MVP Prototype, March 13, 2026

## Problem Statement
Universities need a lightweight way to verify student attendance more reliably than manual roll calls while also encouraging students to reflect on what they are learning. The current process does not prove that a student was physically present in the classroom or meaningfully engaged in the session. This product provides a simple mobile workflow that combines GPS location, QR code verification, and short learning reflections before and after class.

## Target Users
- Primary user: university students attending scheduled classes
- Secondary user: instructors who display the class QR code and review attendance exports if needed
- Operational stakeholder: course administrators who need a usable attendance record for an MVP

## Goals
- Confirm that a student was near the classroom at the time of check-in and class completion
- Confirm participation through short pre-class and post-class reflections
- Keep the workflow fast enough to complete in under 1 minute for each action
- Store records locally for the MVP and support a simple hosted web presence through Firebase Hosting

## Non-Goals
- Full LMS integration
- Strong anti-spoofing guarantees against advanced GPS or QR sharing attacks
- Instructor dashboards, analytics, or role-based administration in the initial MVP
- Real-time cloud sync as a required MVP feature

## Core Features
1. Home screen
   The student can see the app purpose, start check-in, finish class, and view recent saved records.

2. Before-class check-in
   The student presses Check-in, grants location permission, captures GPS location and timestamp, scans the class QR code, and completes a short form with:
   - topic covered in the previous class
   - expected topic for today
   - mood before class on a 1 to 5 scale

3. After-class completion
   The student presses Finish Class, scans the QR code again, captures GPS location and timestamp, and completes a short form with:
   - what they learned today
   - feedback about the class or instructor

4. Local data storage
   The app stores attendance records on-device using SQLite for the MVP. Each class session record links the check-in and finish-class data for the same session where possible.

5. Firebase-hosted component
   At least one web-delivered component is deployed with Firebase Hosting. For MVP, this can be a Flutter Web build or a landing/demo page that explains the product and optionally reads sample data.

## User Flow
1. Student opens the app on arrival.
2. Student selects Check-in from the home screen.
3. App requests location permission if not already granted.
4. App captures GPS coordinates, timestamp, and location accuracy.
5. Student scans the classroom QR code.
6. Student fills the pre-class reflection form and submits.
7. App validates required fields and saves a check-in record locally.
8. At the end of class, student selects Finish Class.
9. App captures GPS again and requires a second QR scan.
10. Student enters what they learned and class feedback.
11. App saves the class completion record locally and marks the session as completed.

## Functional Requirements
- The app must support Android first; iOS support is optional for the prototype.
- The app must request and use device GPS location during both check-in and finish-class flows.
- The app must record timestamp automatically at the time of submission.
- The app must support QR code scanning using the device camera.
- The app must validate mandatory form fields before saving.
- The app must save records locally and allow the user to see whether an action was saved successfully.
- The app should match a finish-class submission to an earlier check-in using the QR/session identifier and date where possible.
- The app should handle no-permission, location unavailable, and camera-denied states with clear error messages.

## Data Fields
### Student session record
- recordId
- studentId or local demo user identifier
- classId or courseCode
- sessionQrValue
- sessionDate
- status: checked_in, completed

### Check-in fields
- checkInTimestamp
- checkInLatitude
- checkInLongitude
- checkInAccuracyMeters
- previousClassTopic
- expectedTodayTopic
- preClassMoodScore (1 to 5)

### Finish-class fields
- finishTimestamp
- finishLatitude
- finishLongitude
- finishAccuracyMeters
- learnedToday
- classFeedback

## Assumptions and Rules
- Each class session provides a QR code that identifies the class and session instance.
- GPS is used as presence evidence, not as an absolute guarantee. For MVP, location is captured and stored; optional validation against a classroom geofence can be added later.
- The same QR code value may be used for both check-in and finish-class in the MVP, or separate phase-specific codes can be introduced later.
- Reflection text fields should be short free-text inputs, with reasonable character limits such as 200 to 500 characters.

## Success Criteria
- A student can complete check-in end to end without a crash.
- A student can complete finish-class end to end without a crash.
- Saved records remain available after the app restarts.
- A Firebase-hosted page or Flutter Web build is publicly reachable.

## Tech Stack
- Frontend: Flutter
- State/form handling: Flutter forms with built-in validation
- Location: geolocator or equivalent Flutter GPS package
- QR scanning: mobile_scanner or equivalent Flutter package
- Local storage: SQLite via sqflite
- Hosting: Firebase Hosting
- Optional Firebase packages: firebase_core for hosted web integration or future expansion

## Risks
- GPS accuracy may be poor indoors.
- QR sharing between students is still possible in the MVP.
- Local-only storage means records are device-bound unless export or sync is added later.

## Future Enhancements
- Instructor dashboard and attendance export
- Geofence validation against classroom coordinates
- Firebase Firestore sync and authentication
- Duplicate submission detection and offline sync recovery
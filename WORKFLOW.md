# Voice Notes App — Full Workflow

This document walks through exactly how the app works end to end, from the
moment it launches to every user action inside it. Use this alongside
`README.md` (which covers setup/running) for a presentation or report.

---

## 1. App launch flow

```
App starts
   │
   ▼
AuthGate (main.dart)
   │  checks shared_preferences for a saved session
   │
   ├── Session found  ──────────────► HomeScreen
   │
   ├── No session     ──────────────► LandingScreen
   │
   └── Error restoring session ─────► Error screen
                                       (shows the reason, e.g. platform
                                       not supported, DB error)
```

`AuthGate` is the very first widget built. It calls
`AuthService.restoreSession()`, which reads a saved `userId` from
`shared_preferences` and looks that user up in the local database. This is
what lets a signed-in user skip the landing page on their next launch.

---

## 2. Account creation (Sign Up) flow

```
LandingScreen → "Create Account"
   │
   ▼
SignUpScreen
   │  user enters: full name, email, password (min 6 chars)
   │  taps "Create Account"
   │
   ▼
AuthService.signUp()
   │  1. Validates input (non-empty, valid email shape, password length)
   │  2. Checks the email isn't already registered
   │  3. Hashes the password (SHA-256 + salt) — never stored in plain text
   │  4. Inserts a new user row with isVerified = false
   │  5. Generates a random 6-digit OTP code, saves it with a 10-minute
   │     expiry
   │  6. Emails the OTP via Gmail SMTP (EmailService.sendOtp)
   │
   ▼
OtpVerificationScreen
   │  user enters the 6-digit code from their email
   │  (or taps "Resend code" if it hasn't arrived — 30s cooldown)
   │
   ▼
AuthService.verifyOtp()
   │  1. Looks up the saved code + expiry for this user
   │  2. Rejects if expired or incorrect
   │  3. On success: marks the account isVerified = true, deletes the
   │     used OTP, saves the session, logs the user in
   │
   ▼
HomeScreen (NotesProvider now scoped to this user's id)
```

**Why email verification matters here:** it confirms the email address
entered is real and belongs to the person signing up — the account is
unusable (can't log in normally) until the OTP is confirmed.

---

## 3. Login flow

```
LandingScreen → "Log In"
   │
   ▼
LoginScreen
   │  user enters email + password, taps "Log In"
   │
   ▼
AuthService.logIn()
   │  1. Looks up the user by email
   │  2. Compares the hashed password
   │  3. If the account was never verified → generates a fresh OTP,
   │     emails it, returns needsVerification = true
   │  4. If verified → saves the session, logs the user in, and fires
   │     off a "new login" notification email in the background
   │     (fire-and-forget — never blocks the login)
   │
   ├── needsVerification = true  ──► OtpVerificationScreen (see above)
   │
   └── needsVerification = false ──► HomeScreen
```

---

## 4. Recording and saving a voice note

```
HomeScreen → tap the mic button
   │
   ▼
SpeechService.startListening()
   │  1. Requests microphone permission (skipped on web — the browser
   │     handles that itself)
   │  2. Initializes the on-device/OS speech engine
   │  3. Starts a CONTINUOUS listening session:
   │       - partial results stream back live as the user talks
   │       - the text field updates on every partial result
   │       - if the engine auto-stops after a pause (which the underlying
   │         plugin does by default), the service detects that and
   │         immediately resumes listening — nothing already said is lost
   │       - everything recognized so far is accumulated, not overwritten
   │
   ▼
User taps the mic button again to Stop
   │
   ▼
SpeechService.stopListening()
   │  returns the full accumulated text, ends the session for good
   │
   ▼
Home screen automatically calls _saveNote()
   │  (no separate "Save" tap needed once you stop recording)
   │
   ▼
NotesProvider.addNote()
   │  writes the note to sqflite, tagged with the current user's id
   │
   ▼
Note appears at the top of the list (newest first)
```

The **Save note** button next to the mic does the same save step manually
— useful if you typed instead of spoke, or want to save mid-recording.

---

## 5. Viewing, editing, and deleting notes

```
HomeScreen note list (ListView, newest first)
   │
   ├── Tap a note        ──► EditNoteScreen
   │                           - edit the text, tap "Save changes"
   │                           - or tap the delete icon (with a confirm
   │                             dialog) to remove it
   │
   ├── Swipe a note left  ──► instantly deletes it (Dismissible)
   │
   └── Tap the trailing delete icon ──► deletes it immediately
```

All reads/writes go through `NotesProvider`, which is scoped to the
currently logged-in user's id — one account can never see another
account's notes.

---

## 6. Downloading note history

```
HomeScreen → tap the download icon (top right)
   │
   ▼
_downloadHistory()
   │  1. Builds a plain-text export of every note (date + text)
   │  2. On mobile/desktop: writes it to a .txt file, opens the native
   │     share sheet so it can be saved or sent anywhere
   │     On web: shares the text directly (no real filesystem there)
   │  3. Sends a "history downloaded" notification email to the
   │     account's email address (fire-and-forget)
```

---

## 7. Logging out

```
HomeScreen → tap the logout icon
   │
   ▼
Confirm dialog ("Log out?")
   │
   ▼
NotesProvider.setUser(null)   — clears notes from memory
AuthService.logOut()          — clears the saved session
   │
   ▼
LandingScreen
```

---

## 8. Data model summary

| Table   | Purpose                                          | Key columns |
|---------|---------------------------------------------------|-------------|
| `users` | One row per account                                | `id`, `email` (unique), `passwordHash`, `isVerified` |
| `notes` | One row per saved note                             | `id`, `userId` (owner), `text`, `createdAt`, `updatedAt` |
| `otps`  | The current OTP code per user (overwritten each resend) | `userId`, `code`, `expiresAt` |

All three tables live in a single local SQLite database
(`voice_notes.db`), whose storage engine is chosen automatically per
platform (native sqflite on Android/iOS, `sqflite_common_ffi` on desktop,
`sqflite_common_ffi_web` — IndexedDB — on web).

---

## 9. Where each requirement lives in the code

| Requirement                          | File(s) |
|----------------------------------------|---------|
| Mic recording + live transcription     | `services/speech_service.dart`, `screens/home_screen.dart` |
| Continuous listening across pauses     | `services/speech_service.dart` (`_scheduleRestart`, `_accumulatedText`) |
| Save / edit / delete notes             | `services/notes_provider.dart`, `screens/edit_note_screen.dart` |
| Local database                         | `services/database_service.dart`, `services/db/*` |
| Login / signup gating notes            | `services/auth_service.dart`, `services/notes_provider.dart` |
| Email OTP verification                 | `services/auth_service.dart`, `services/email_service.dart`, `screens/otp_verification_screen.dart` |
| Login/download email notifications     | `services/email_service.dart` |
| Landing page                           | `screens/landing_screen.dart` |
| App-wide look and feel                 | `theme/app_theme.dart` |

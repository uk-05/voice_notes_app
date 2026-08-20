<div align="center">

# 🎙️ Voice Notes App

**Speak it. Save it. Never lose it.**

A cross-platform Flutter app that turns speech into text in real time and saves it as private, per-account notes — no API keys, no cloud AI, no cost.

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Platforms](https://img.shields.io/badge/Platforms-Android%20%7C%20iOS%20%7C%20Windows%20%7C%20Web-4CAF50)](#-platform-support)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](#-license)

</div>

---

## 📖 Overview

Voice Notes App lets a user speak naturally and see their words transcribed live on screen, then save that text as a note tied to their own account. Every account is protected with hashed passwords and email OTP verification, and every note is scoped strictly to the account that created it — nothing is visible without logging in.

Built as a Flutter learning/portfolio project, it runs on **Android, iOS, Windows, and Web** from a single codebase, using the device's own built-in speech engine instead of any paid transcription API.

## ✨ Features

- 🎤 **Live voice-to-text** — tap the mic and watch your words appear as you speak
- 🔐 **Account system** — sign up / log in with email + password (SHA-256 hashed, stored locally)
- ✅ **Email OTP verification** — a 6-digit code confirms every new account before it can be used
- 📬 **Email notifications** — alerts on new logins and on history downloads
- 🔒 **Private, per-account notes** — nothing is saved or shown without being logged in
- 💾 **Session persistence** — stay logged in across app restarts, until you log out
- 📝 **Full note management** — save, edit, and delete notes; swipe-to-delete supported
- 📤 **Export history** — download all your notes as a text file and share it
- 🎨 **Polished UI** — gradient headers, rounded cards, and a consistent custom theme

## 📱 Platform Support

| Platform | Status | Storage Engine |
|---|---|---|
| Android | ✅ | `sqflite` (native) |
| iOS | ✅ | `sqflite` (native) |
| Windows | ✅ | `sqflite_common_ffi` |
| Web (Chrome/Edge) | ✅ | `sqflite_common_ffi_web` (IndexedDB) |

> 🎧 Voice recognition is most reliable on a physical Android device. Desktop/web accuracy depends on the OS or browser's built-in speech engine.

## 🛠️ Tech Stack

| Purpose | Package |
|---|---|
| Speech-to-text | `speech_to_text` |
| Runtime permissions | `permission_handler` |
| Local database | `sqflite`, `path` |
| Password hashing | `crypto` |
| Session persistence | `shared_preferences` |
| Email (OTP + notifications) | `mailer` |
| File export / sharing | `path_provider`, `share_plus` |
| State management | `provider` |
| Date formatting | `intl` |

## 📂 Project Structure

```
voice_notes_app/
├── lib/
│   ├── main.dart                # App entry point + auth routing
│   ├── config/
│   │   └── email_config.dart    # Gmail SMTP credentials (see Configuration)
│   ├── theme/
│   │   └── app_theme.dart       # Colors, gradients, ThemeData
│   ├── models/
│   │   ├── note.dart            # Note data model
│   │   └── user.dart            # User data model
│   ├── services/
│   │   ├── speech_service.dart      # Wraps speech_to_text
│   │   ├── database_service.dart    # sqflite: users, notes, OTPs
│   │   ├── auth_service.dart        # Signup / OTP / login / logout
│   │   ├── email_service.dart       # Sends OTP + notification emails
│   │   └── notes_provider.dart      # App state, scoped per user
│   └── screens/
│       ├── landing_screen.dart
│       ├── login_screen.dart
│       ├── signup_screen.dart
│       ├── otp_verification_screen.dart
│       ├── home_screen.dart
│       └── edit_note_screen.dart
├── setup_and_run.ps1            # One-shot Windows setup + run script
└── pubspec.yaml
```

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed (`flutter --version` to confirm)
- A physical device is strongly recommended for the voice demo — most emulators/simulators don't expose a working microphone

### Installation

**Windows (PowerShell) — one command:**

```powershell
git clone https://github.com/<your-username>/voice_notes_app.git
cd voice_notes_app
powershell -ExecutionPolicy Bypass -File setup_and_run.ps1
```

This script generates the native `android/`, `ios/`, `windows/`, and `web/` project folders for your installed Flutter SDK, adds the required mic/speech permissions, fetches dependencies, and launches the app.

**macOS / Linux (manual):**

```bash
git clone https://github.com/<your-username>/voice_notes_app.git
cd voice_notes_app
flutter config --enable-web
flutter create --platforms=android,ios,web .
flutter pub get
flutter run
```

Then add the microphone/speech permissions to `AndroidManifest.xml` and `Info.plist` as described in the in-repo setup notes before your first run.

### Configuration — Email Setup (required for signup/login)

OTP codes and notification emails are sent via Gmail SMTP. Before signup/login will fully work:

1. Open `lib/config/email_config.dart`
2. Enable 2-Step Verification on your Google account
3. Generate an [App Password](https://myaccount.google.com/apppasswords)
4. Fill in your credentials:
   ```dart
   static const String senderEmail = 'youraddress@gmail.com';
   static const String senderPassword = 'your16charapppassword';
   ```

Without this, typed notes still work locally, but OTP emails won't be delivered, so account signup can't complete.

## 🔄 How It Works

1. App launches → `AuthGate` checks for a saved session
2. No session → `LandingScreen` (Create Account / Log In)
3. Sign up → password is hashed, a 6-digit OTP is emailed, account starts unverified
4. Correct OTP → account is verified, session is saved, user lands on `HomeScreen`
5. Tap the mic → live transcription streams into the text field as you speak
6. Save → the note is written to `sqflite`, tagged to the logged-in user
7. Notes list is scoped per account — edit, delete, or export at any time
8. Log out → session and in-memory notes are cleared, back to `LandingScreen`

## 📄 Documentation

- [`WORKFLOW.md`](./WORKFLOW.md) — full walkthrough of every user flow with diagrams
- [`PRIVACY_POLICY.md`](./PRIVACY_POLICY.md) — what data is collected and how it's used
- [`TERMS_AND_CONDITIONS.md`](./TERMS_AND_CONDITIONS.md) — usage terms and disclaimers

## 🗺️ Roadmap

- [ ] Search and filter over saved notes
- [ ] Note categories / tags
- [ ] Auto-punctuation and cleanup of transcribed text

## 📝 License

This project is available under the [MIT License](LICENSE).

## 👤 Author

**Usman**
BSCS Student, Barani Institute of Information Technology (BIIT), Rawalpindi

---

<div align="center">
Made with Flutter 💙
</div>

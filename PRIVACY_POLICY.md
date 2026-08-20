# Privacy Policy — Voice Notes App

**Last updated:** [fill in date]

This Privacy Policy explains what data the Voice Notes App collects, how
it's used, and how it's stored. This app was built as an academic/
coursework project and is not a commercially published product — this
policy is written to accurately describe what the app actually does, not
as a substitute for formal legal advice.

## 1. What data we collect

| Data | Why it's collected | Where it's stored |
|------|---------------------|---------------------|
| Full name | Shown in the app, included in emails sent to you | Local device database |
| Email address | Used for login, sending your OTP verification code, and account notifications | Local device database |
| Password | Used to log you in | Local device database, stored as a **SHA-256 hash** — never in plain text |
| Voice recordings | Converted to text in real time on your device | **Not stored anywhere.** Only the resulting text is saved — the audio itself is never recorded to a file or uploaded |
| Notes (text) | The content you create with the app | Local device database |
| Login timestamps | Used to send you a "new login" notification email | Not stored beyond what's needed to generate that one email |

## 2. Where your data lives

All app data (your account, your notes, your OTP codes) is stored
**locally on your own device** in a local SQLite database. There is no
cloud server, no remote database, and no company collecting or hosting
your data. Uninstalling the app deletes this data.

## 3. Email delivery

To verify your email address and send login/download notifications, the
app sends emails through a standard Gmail SMTP account. This means:

- Your email address and the message content pass through Google's Gmail
  servers, as they would with any email sent from a Gmail account.
- We do not use any third-party marketing or analytics email service.
- No email list is built, sold, or shared — emails are sent only in
  direct response to your own actions (signing up, logging in,
  downloading your notes).

## 4. Microphone access

The app requests microphone access solely to convert your speech into
text using your device's (or browser's) built-in speech recognition
engine. Audio is processed for transcription only and is **not recorded,
saved, or transmitted** anywhere by this app.

## 5. Data sharing

We do not sell, rent, or share your data with third parties. The only
data that leaves your device is:
- The OTP code / notification emails sent via Gmail SMTP (see Section 3).
- Speech audio sent to your device's or browser's built-in speech
  recognition engine (Android/Google, iOS/Apple, or your browser's Web
  Speech API) for transcription — governed by that platform's own privacy
  policy, not this app's.

## 6. Your control over your data

- **Notes:** you can edit or delete any note at any time from within the
  app.
- **History export:** you can download a text copy of all your notes at
  any time using the download button.
- **Account deletion:** since all data is stored locally, uninstalling
  the app permanently removes your account and all notes from that
  device.
- **Logging out** clears your active session but does not delete your
  account or notes — logging back in restores access.

## 7. Children's privacy

This app was built as a coursework project and is not intended for use
by children without adult supervision. It does not knowingly collect
data from children.

## 8. Changes to this policy

This policy may be updated as the app changes. Continued use of the app
after changes are made constitutes acceptance of the updated policy.

## 9. Contact

For questions about this policy or the app, contact: [your email here]

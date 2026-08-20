/// Legal text shown inside the app (Privacy Policy, Terms & Conditions).
/// Kept in sync with the standalone PRIVACY_POLICY.md / TERMS_AND_CONDITIONS.md
/// files at the project root — update both places if you change the wording.
library;

const String privacyPolicyText = '''
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

''';

const String termsAndConditionsText = '''
# Terms and Conditions — Voice Notes App

**Last updated:** [fill in date]

Please read these Terms and Conditions ("Terms") before using the Voice
Notes App ("the App"). By creating an account or using the App, you agree
to these Terms. This App was built as an academic/coursework project —
these Terms are written to reasonably govern its use, not as a substitute
for formal legal advice.

## 1. Acceptance of terms

By downloading, installing, or using the App, you agree to be bound by
these Terms. If you do not agree, please do not use the App.

## 2. Description of service

The App allows users to:
- Create an account, verified via a one-time email code (OTP)
- Convert spoken words into text notes using speech recognition
- Save, edit, and delete personal notes
- Download/export their note history
- Receive email notifications for logins and history downloads

## 3. Account responsibilities

- You must provide a valid email address you have access to, since
  account verification and login notifications are sent there.
- You are responsible for keeping your password confidential. The App
  stores only a hashed version of your password and cannot recover a
  forgotten password by "looking it up" — it can only be reset by
  creating a new account or via any reset flow the App may add in future.
- You are responsible for all activity that occurs under your account.

## 4. Acceptable use

You agree not to:
- Use the App for any unlawful purpose.
- Attempt to access another user's account or notes without authorization.
- Attempt to disrupt, reverse-engineer, or interfere with the App's
  normal operation, including its email or speech-recognition features.
- Use the App to store or transmit content that is illegal, abusive, or
  infringes on others' rights.

## 5. Data and content ownership

- You retain full ownership of the notes and content you create in the
  App.
- Since all data is stored locally on your device, you are responsible
  for backing up your notes (e.g. using the download/export feature)
  before uninstalling the App or switching devices.

## 6. Speech recognition accuracy

Speech-to-text conversion is performed by your device's or browser's
built-in speech recognition engine. Accuracy varies by device, platform,
microphone quality, accent, and background noise, and is **not
guaranteed to be error-free**. You should review transcribed text before
relying on it.

## 7. Email delivery

OTP codes and notification emails are sent via a standard email service
and are **not guaranteed to arrive instantly or at all** — delivery can
be affected by factors outside the App's control (spam filtering,
network issues, provider outages). The App may, at its discretion,
display a verification code on-screen as a fallback if configured to do
so during development/testing.

## 8. No warranty

This App is provided **"as is"**, as an academic/coursework project,
without warranties of any kind, express or implied, including but not
limited to fitness for a particular purpose, uninterrupted operation, or
error-free performance.

## 9. Limitation of liability

To the maximum extent permitted by applicable law, the developer(s) of
this App shall not be liable for any indirect, incidental, or
consequential damages arising from use of the App, including but not
limited to loss of notes, missed notifications, or transcription errors.

## 10. Changes to the service or terms

These Terms, and the App itself, may change over time as it continues to
be developed. Continued use of the App after changes are made
constitutes acceptance of the updated Terms.

## 11. Termination

You may stop using the App at any time by uninstalling it, which removes
your local account and data. We reserve the right to discontinue the App
or any of its features at any time.

## 12. Governing law

These Terms are governed by the laws of [fill in your jurisdiction],
without regard to its conflict of law provisions.

## 13. Contact

For questions about these Terms, contact: [your email here]

''';

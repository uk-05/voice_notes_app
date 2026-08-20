/// SMTP configuration for sending real emails (OTP codes + notifications).
///
/// ⚠️ YOU MUST FILL THESE IN before signup/login/download emails will work.
///
/// How to get a Gmail "App Password" (takes ~2 minutes, free):
///   1. Go to https://myaccount.google.com/security
///   2. Turn on "2-Step Verification" if it isn't already on
///   3. Go to https://myaccount.google.com/apppasswords
///   4. Create an app password (name it e.g. "Voice Notes App")
///   5. Google gives you a 16-character code like "abcd efgh ijkl mnop"
///   6. Paste it below as senderPassword (remove the spaces)
///
/// Do NOT use your real Gmail login password here — use the App Password.
/// This sends from your own Gmail account, so the recipient (the user
/// signing up) will see emails arrive "from" this address.
class EmailConfig {
  static const String senderEmail = 'usmankhanaps@gmail.com';
  static const String senderPassword = 'reeocaxchputbmbd';
  static const String senderName = 'Voice Notes App';
}

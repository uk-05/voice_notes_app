/// Fallback for platforms without dart:io (web). The home screen never
/// actually calls this on web — it shares the text directly instead — but
/// conditional imports require every branch to exist.
Future<String> writeTextFile(String filename, String content) async {
  throw UnsupportedError('writeTextFile is not supported on this platform.');
}

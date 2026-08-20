import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Writes [content] to a text file named [filename] in the app's documents
/// directory and returns the full file path. Only compiled on platforms
/// that have dart:io (Android, iOS, desktop) — never on web.
Future<String> writeTextFile(String filename, String content) async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/$filename');
  await file.writeAsString(content);
  return file.path;
}

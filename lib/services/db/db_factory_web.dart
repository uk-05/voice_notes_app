import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// Compiled only for web builds. Stores data in the browser's IndexedDB.
void configureDatabaseFactory() {
  databaseFactory = databaseFactoryFfiWeb;
}

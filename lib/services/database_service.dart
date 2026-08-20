import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'db/db_factory_stub.dart'
    if (dart.library.io) 'db/db_factory_io.dart'
    if (dart.library.html) 'db/db_factory_web.dart';

import '../models/note.dart';
import '../models/user.dart';

/// Handles all local persistence (users + notes + OTP codes) using sqflite.
/// Singleton so the whole app shares a single DB connection.
///
/// sqflite's default engine only works on Android/iOS. To let the exact
/// same code also run on Windows desktop and in a web browser, we swap in
/// the matching `databaseFactory` implementation before opening the
/// database, via a CONDITIONAL IMPORT (see the import block above) —
/// `sqflite_common_ffi` uses `dart:ffi` (not available on web) and
/// `sqflite_common_ffi_web` uses browser-only APIs (not available on
/// mobile/desktop), so each platform only ever compiles the code it can
/// actually run.
class DatabaseService {
  DatabaseService._internal();
  static final DatabaseService instance = DatabaseService._internal();

  static Database? _database;
  static bool _factoryConfigured = false;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  void _configureDatabaseFactory() {
    if (_factoryConfigured) return;
    _factoryConfigured = true;
    configureDatabaseFactory();
  }

  Future<Database> _initDatabase() async {
    _configureDatabaseFactory();

    // On web there's no real filesystem — the "path" is just an IndexedDB
    // store name, so we skip getDatabasesPath()/join() there.
    final path = kIsWeb
        ? 'voice_notes.db'
        : join(await getDatabasesPath(), 'voice_notes.db');

    return openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            email TEXT NOT NULL UNIQUE,
            passwordHash TEXT NOT NULL,
            isVerified INTEGER NOT NULL DEFAULT 0,
            createdAt TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE notes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            userId INTEGER NOT NULL,
            text TEXT NOT NULL,
            createdAt TEXT NOT NULL,
            updatedAt TEXT NOT NULL,
            FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE otps (
            userId INTEGER PRIMARY KEY,
            code TEXT NOT NULL,
            expiresAt TEXT NOT NULL,
            FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
          )
        ''');
      },
    );
  }

  // ---------------- Users ----------------

  Future<AppUser> insertUser(AppUser user) async {
    final db = await database;
    final id = await db.insert(
      'users',
      user.toMap()..remove('id'),
    );
    return user.copyWith(id: id);
  }

  Future<AppUser?> getUserByEmail(String email) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email.trim().toLowerCase()],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return AppUser.fromMap(result.first);
  }

  Future<AppUser?> getUserById(int id) async {
    final db = await database;
    final result = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return AppUser.fromMap(result.first);
  }

  Future<void> markUserVerified(int userId) async {
    final db = await database;
    await db.update(
      'users',
      {'isVerified': 1},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // ---------------- OTPs ----------------

  Future<void> saveOtp(int userId, String code, DateTime expiresAt) async {
    final db = await database;
    await db.insert(
      'otps',
      {
        'userId': userId,
        'code': code,
        'expiresAt': expiresAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getOtp(int userId) async {
    final db = await database;
    final result = await db.query(
      'otps',
      where: 'userId = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return result.first;
  }

  Future<void> deleteOtp(int userId) async {
    final db = await database;
    await db.delete('otps', where: 'userId = ?', whereArgs: [userId]);
  }

  // ---------------- Notes ----------------

  Future<Note> insertNote(Note note) async {
    final db = await database;
    final id = await db.insert(
      'notes',
      note.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return note.copyWith(id: id);
  }

  Future<List<Note>> getNotesForUser(int userId) async {
    final db = await database;
    final result = await db.query(
      'notes',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );
    return result.map((map) => Note.fromMap(map)).toList();
  }

  Future<int> updateNote(Note note) async {
    final db = await database;
    return db.update(
      'notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<int> deleteNote(int id) async {
    final db = await database;
    return db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }
}

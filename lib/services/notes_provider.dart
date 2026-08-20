import 'package:flutter/foundation.dart';

import '../models/note.dart';
import 'database_service.dart';

/// Holds the in-memory list of notes for the CURRENTLY LOGGED-IN user and
/// syncs changes to the database. Without a logged-in user, no notes can
/// be loaded or saved — this is what makes history "login-only".
class NotesProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;

  List<Note> _notes = [];
  bool _isLoading = false;
  int? _userId;

  List<Note> get notes => _notes;
  bool get isLoading => _isLoading;

  /// Call this whenever the logged-in user changes (login, logout, switch
  /// account) to scope notes to that user and clear any stale data.
  Future<void> setUser(int? userId) async {
    _userId = userId;
    if (userId == null) {
      _notes = [];
      notifyListeners();
      return;
    }
    await loadNotes();
  }

  Future<void> loadNotes() async {
    if (_userId == null) return;
    _isLoading = true;
    notifyListeners();

    _notes = await _db.getNotesForUser(_userId!);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addNote(String text) async {
    if (_userId == null || text.trim().isEmpty) return;
    final now = DateTime.now();
    final note = Note(
      userId: _userId!,
      text: text.trim(),
      createdAt: now,
      updatedAt: now,
    );
    final saved = await _db.insertNote(note);
    _notes.insert(0, saved);
    notifyListeners();
  }

  Future<void> updateNote(Note note, String newText) async {
    if (newText.trim().isEmpty) return;
    final updated = note.copyWith(
      text: newText.trim(),
      updatedAt: DateTime.now(),
    );
    await _db.updateNote(updated);
    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index != -1) {
      _notes[index] = updated;
      notifyListeners();
    }
  }

  Future<void> deleteNote(Note note) async {
    if (note.id == null) return;
    await _db.deleteNote(note.id!);
    _notes.removeWhere((n) => n.id == note.id);
    notifyListeners();
  }
}

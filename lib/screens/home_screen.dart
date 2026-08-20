import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/note.dart';
import '../services/auth_service.dart';
import '../services/email_service.dart';
import '../services/file_writer/file_writer_stub.dart'
    if (dart.library.io) '../services/file_writer/file_writer_io.dart';
import '../services/notes_provider.dart';
import '../theme/app_theme.dart';
import '../services/speech_service.dart';
import 'edit_note_screen.dart';
import 'landing_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SpeechService _speechService = SpeechService();
  final TextEditingController _liveTextController = TextEditingController();

  bool _isListening = false;
  bool _speechAvailable = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotesProvider>().loadNotes();
    });
    _checkSpeechAvailability();
  }

  Future<void> _checkSpeechAvailability() async {
    final ok = await _speechService.initialize();
    if (mounted) setState(() => _speechAvailable = ok);
  }

  Future<void> _toggleListening() async {
    if (!_speechAvailable) {
      _showSnackBar(
        'Microphone permission or speech recognition is unavailable on this device.',
      );
      return;
    }

    if (_isListening) {
      final finalText = await _speechService.stopListening();
      setState(() {
        _isListening = false;
        _liveTextController.text = finalText;
        _liveTextController.selection = TextSelection.fromPosition(
          TextPosition(offset: _liveTextController.text.length),
        );
      });
      // Requirement: once the user taps Stop, whatever was recorded
      // saves automatically — no separate Save tap needed.
      await _saveNote();
      return;
    }

    setState(() => _isListening = true);
    await _speechService.startListening(
      onUpdate: (fullText, isListening) {
        if (!mounted) return;
        setState(() {
          _liveTextController.text = fullText;
          _liveTextController.selection = TextSelection.fromPosition(
            TextPosition(offset: _liveTextController.text.length),
          );
          _isListening = isListening;
        });
      },
    );
  }

  Future<void> _saveNote() async {
    final text = _liveTextController.text.trim();
    if (text.isEmpty) {
      _showSnackBar('Say something or type a note before saving.');
      return;
    }
    await context.read<NotesProvider>().addNote(text);
    _liveTextController.clear();
    _showSnackBar('Note saved.');
  }

  Future<void> _logOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Log out?'),
        content: const Text(
            'You\'ll need to log in again to see your saved notes.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: AppTheme.dangerButtonStyle,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await context.read<NotesProvider>().setUser(null);
    await context.read<AuthService>().logOut();

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LandingScreen()),
      (route) => false,
    );
  }

  Future<void> _downloadHistory() async {
    final notesProvider = context.read<NotesProvider>();
    final auth = context.read<AuthService>();
    final notes = notesProvider.notes;
    final user = auth.currentUser;

    if (notes.isEmpty) {
      _showSnackBar('No notes to download yet.');
      return;
    }

    final buffer = StringBuffer('Voice Notes — exported history\n\n');
    for (final note in notes) {
      final date = DateFormat('MMM d, yyyy • h:mm a').format(note.createdAt);
      buffer.writeln('[$date]');
      buffer.writeln(note.text);
      buffer.writeln('---');
    }

    try {
      if (kIsWeb) {
        // On web there's no real filesystem — share the text directly.
        await SharePlus.instance.share(
          ShareParams(text: buffer.toString(), subject: 'Voice Notes history'),
        );
      } else {
        final path = await writeTextFile(
          'voice_notes_history_${DateTime.now().millisecondsSinceEpoch}.txt',
          buffer.toString(),
        );
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(path)],
            subject: 'Voice Notes history',
          ),
        );
      }

      if (user != null) {
        // Fire-and-forget — don't block the UI on the email send.
        EmailService.sendHistoryDownloadNotification(
          toEmail: user.email,
          name: user.name,
          noteCount: notes.length,
        );
      }

      _showSnackBar('History downloaded — a notification email was sent.');
    } catch (e) {
      _showSnackBar('Could not download history: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  void dispose() {
    _liveTextController.dispose();
    _speechService.cancelListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(user?.name ?? ''),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildRecordingCard(),
                    const SizedBox(height: 8),
                    _buildNotesList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String name) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 24),
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Voice Notes',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (name.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Hi, $name 👋',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: _downloadHistory,
            icon: const Icon(Icons.download_rounded, color: Colors.white),
            tooltip: 'Download history',
          ),
          IconButton(
            onPressed: _logOut,
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            tooltip: 'Log out',
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _liveTextController,
            maxLines: 4,
            minLines: 2,
            decoration: InputDecoration(
              hintText: _isListening
                  ? 'Listening... start speaking'
                  : 'Tap the mic and start speaking, or type here',
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _MicButton(
                isListening: _isListening,
                onPressed: _toggleListening,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _saveNote,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save note'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotesList() {
    return Consumer<NotesProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Padding(
            padding: EdgeInsets.all(40.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (provider.notes.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              children: [
                Icon(Icons.mic_none_rounded,
                    size: 56, color: AppColors.textMuted.withValues(alpha: 0.5)),
                const SizedBox(height: 12),
                const Text(
                  'No notes yet',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Record your first voice note above',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: provider.notes.length,
          itemBuilder: (context, index) {
            final note = provider.notes[index];
            return _NoteTile(
              note: note,
              accentIndex: index,
              onDelete: () => provider.deleteNote(note),
              onTap: () => _openEditScreen(note),
            );
          },
        );
      },
    );
  }

  Future<void> _openEditScreen(Note note) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EditNoteScreen(note: note)),
    );
  }
}

class _MicButton extends StatelessWidget {
  final bool isListening;
  final VoidCallback onPressed;

  const _MicButton({required this.isListening, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isListening ? AppColors.danger : AppColors.primary,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Icon(
            isListening ? Icons.stop_rounded : Icons.mic_rounded,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _NoteTile extends StatelessWidget {
  final Note note;
  final int accentIndex;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _NoteTile({
    required this.note,
    required this.accentIndex,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final formattedDate =
        DateFormat('MMM d, yyyy • h:mm a').format(note.createdAt);

    return Dismissible(
      key: ValueKey(note.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: Card(
        child: ListTile(
          onTap: onTap,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: AppTheme.tileAccentGradient(accentIndex),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.notes_rounded,
                color: Colors.white, size: 20),
          ),
          title: Text(
            note.text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(formattedDate,
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.textMuted),
            onPressed: onDelete,
          ),
        ),
      ),
    );
  }
}

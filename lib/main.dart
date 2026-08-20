import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text_windows/speech_to_text_windows.dart';

import 'screens/home_screen.dart';
import 'screens/landing_screen.dart';
import 'services/auth_service.dart';
import 'services/notes_provider.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Register Windows speech recognition implementation.
  if (defaultTargetPlatform == TargetPlatform.windows) {
    SpeechToTextWindows.registerWith();
  }

  runApp(const VoiceNotesApp());
}

class VoiceNotesApp extends StatelessWidget {
  const VoiceNotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthService(),
        ),
        ChangeNotifierProvider(
          create: (_) => NotesProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'Voice Notes',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restore();
    });
  }

  Future<void> _restore() async {
    final auth = context.read<AuthService>();

    await auth.restoreSession();

    if (!mounted) return;

    if (auth.isLoggedIn && auth.currentUser != null) {
      await context.read<NotesProvider>().setUser(auth.currentUser!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, auth, _) {
        if (auth.isRestoringSession) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (auth.sessionRestoreError != null) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 40,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Could not start the app.',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      auth.sessionRestoreError!,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return auth.isLoggedIn ? const HomeScreen() : const LandingScreen();
      },
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';

class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _isInitialized = false;
  bool _manualStop = true;

  String _accumulatedText = '';
  String _currentText = '';

  void Function(String fullText, bool isListening)? _onUpdate;

  bool get isListening => _speech.isListening;

  bool get isInitialized => _isInitialized;

  // ==========================================================
  // INITIALIZE SPEECH
  // ==========================================================

  Future<bool> initialize() async {
    try {
      debugPrint('====================================');
      debugPrint('Initializing speech recognition...');
      debugPrint('Platform: $defaultTargetPlatform');
      debugPrint('====================================');

      // Android / iOS
      //
      // Windows does NOT use permission_handler here.
      // Windows handles microphone permission through Windows settings.
      if (!kIsWeb && defaultTargetPlatform != TargetPlatform.windows) {
        final permission = await Permission.microphone.request();

        debugPrint(
          'Microphone permission: $permission',
        );

        if (!permission.isGranted) {
          debugPrint(
            'Microphone permission was denied.',
          );

          return false;
        }
      }

      _isInitialized = await _speech.initialize(
        debugLogging: true,
        onStatus: (status) {
          debugPrint(
            'Speech status: $status',
          );

          if (!_manualStop && (status == 'notListening' || status == 'done')) {
            _scheduleRestart();
          }
        },
        onError: (error) {
          debugPrint(
            'Speech ERROR: ${error.errorMsg}',
          );
        },
      );

      debugPrint(
        'Speech initialized: $_isInitialized',
      );

      return _isInitialized;
    } catch (e, stack) {
      debugPrint(
        'Speech initialization exception: $e',
      );

      debugPrint(
        stack.toString(),
      );

      return false;
    }
  }

  // ==========================================================
  // START LISTENING
  // ==========================================================

  Future<void> startListening({
    required void Function(
      String fullText,
      bool isListening,
    ) onUpdate,
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();

      if (!initialized) {
        onUpdate('', false);
        return;
      }
    }

    _manualStop = false;

    _accumulatedText = '';
    _currentText = '';

    _onUpdate = onUpdate;

    await _startSession();
  }

  // ==========================================================
  // START ONE SPEECH SESSION
  // ==========================================================

  Future<void> _startSession() async {
    if (_manualStop) return;

    try {
      debugPrint('Starting speech session...');

      await _speech.listen(
        onResult: (
          SpeechRecognitionResult result,
        ) {
          final recognized = result.recognizedWords.trim();

          if (recognized.isEmpty) {
            return;
          }

          _currentText = recognized;

          String fullText;

          if (_accumulatedText.isEmpty) {
            fullText = _currentText;
          } else {
            fullText = '$_accumulatedText $_currentText';
          }

          fullText = fullText.trim();

          debugPrint(
            'Recognized: "$recognized"',
          );

          debugPrint(
            'Full text: "$fullText"',
          );

          // LIVE TEXT
          _onUpdate?.call(
            fullText,
            _speech.isListening,
          );

          // Save finalized segment.
          if (result.finalResult) {
            _accumulatedText = fullText;
            _currentText = '';
          }
        },
        partialResults: true,
        listenFor: const Duration(minutes: 30),
        pauseFor: const Duration(seconds: 8),
        cancelOnError: false,
        listenMode: stt.ListenMode.dictation,
      );
    } catch (e) {
      debugPrint(
        'Speech start error: $e',
      );
    }
  }

  // ==========================================================
  // AUTOMATIC RESTART
  // ==========================================================

  void _scheduleRestart() {
    Future.delayed(
      const Duration(milliseconds: 700),
      () {
        if (!_manualStop) {
          debugPrint(
            'Restarting speech recognition...',
          );

          _startSession();
        }
      },
    );
  }

  // ==========================================================
  // STOP
  // ==========================================================

  Future<String> stopListening() async {
    _manualStop = true;

    await _speech.stop();

    String finalText;

    if (_currentText.isNotEmpty) {
      if (_accumulatedText.isEmpty) {
        finalText = _currentText;
      } else {
        finalText = '$_accumulatedText $_currentText';
      }
    } else {
      finalText = _accumulatedText;
    }

    finalText = finalText.trim();

    _accumulatedText = finalText;
    _currentText = '';

    _onUpdate?.call(
      finalText,
      false,
    );

    debugPrint(
      'FINAL SPEECH TEXT: "$finalText"',
    );

    return finalText;
  }

  // ==========================================================
  // CANCEL
  // ==========================================================

  Future<void> cancelListening() async {
    _manualStop = true;

    await _speech.cancel();

    _accumulatedText = '';
    _currentText = '';

    _onUpdate?.call(
      '',
      false,
    );
  }
}

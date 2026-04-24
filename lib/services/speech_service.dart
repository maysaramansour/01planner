import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Thin wrapper around the device's native speech recognizer (Google/Samsung
/// on Android, SFSpeechRecognizer on iOS). Supports Arabic and English.
class SpeechService {
  SpeechService._internal();
  static final SpeechService _instance = SpeechService._internal();
  factory SpeechService() => _instance;

  final stt.SpeechToText _stt = stt.SpeechToText();
  bool _initialized = false;

  final ValueNotifier<bool> available = ValueNotifier(false);
  final ValueNotifier<bool> listening = ValueNotifier(false);

  Future<bool> ensureAvailable() async {
    if (_initialized) return available.value;
    try {
      final micStatus = await Permission.microphone.request();
      if (!micStatus.isGranted) {
        available.value = false;
        _initialized = true;
        return false;
      }
      final ok = await _stt.initialize(
        onStatus: (s) {
          if (s == 'done' || s == 'notListening') listening.value = false;
          if (s == 'listening') listening.value = true;
        },
        onError: (e) {
          debugPrint('SpeechService error: ${e.errorMsg}');
          listening.value = false;
        },
      );
      available.value = ok;
      _initialized = true;
      return ok;
    } catch (e) {
      debugPrint('SpeechService init failed: $e');
      available.value = false;
      _initialized = true;
      return false;
    }
  }

  /// Start listening. `onResult` is fired continuously with partial results;
  /// `onFinal` receives the final recognized text.
  Future<bool> start({
    required String localeId,
    required void Function(String partial) onPartial,
    required void Function(String finalText) onFinal,
  }) async {
    final ok = await ensureAvailable();
    if (!ok) return false;
    listening.value = true;
    await _stt.listen(
      localeId: localeId,
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.dictation,
        partialResults: true,
        cancelOnError: true,
        onDevice: true,
      ),
      onResult: (r) {
        if (r.finalResult) {
          onFinal(r.recognizedWords);
        } else {
          onPartial(r.recognizedWords);
        }
      },
      pauseFor: const Duration(seconds: 3),
      listenFor: const Duration(seconds: 60),
    );
    return true;
  }

  Future<void> stop() async {
    try {
      await _stt.stop();
    } catch (_) {}
    listening.value = false;
  }

  Future<void> cancel() async {
    try {
      await _stt.cancel();
    } catch (_) {}
    listening.value = false;
  }
}

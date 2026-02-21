import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'database_service.dart';
import 'gemini_service.dart';

enum PetMood { happy, curious, sleepy, excited }

class AppState extends ChangeNotifier {
  static const _apiKeyStorageKey = 'gemini_api_key';
  final _secureStorage = const FlutterSecureStorage();

  String _apiKey = '';
  int _dayCount = 1;
  String _greeting = '';
  PetMood _mood = PetMood.happy;
  bool _isReady = false;
  int _chatCount = 0;

  // Getters
  String get apiKey => _apiKey;
  int get dayCount => _dayCount;
  String get greeting => _greeting;
  PetMood get mood => _mood;
  bool get isReady => _isReady;

  String get moodEmoji {
    switch (_mood) {
      case PetMood.happy:
        return '🐣';
      case PetMood.curious:
        return '🐥';
      case PetMood.sleepy:
        return '😴';
      case PetMood.excited:
        return '✨';
    }
  }

  String get moodLabel {
    switch (_mood) {
      case PetMood.happy:
        return 'Happy';
      case PetMood.curious:
        return 'Curious';
      case PetMood.sleepy:
        return 'Sleepy';
      case PetMood.excited:
        return 'Excited';
    }
  }

  // ── Initialization ────────────────────────────────────────

  Future<void> init() async {
    try {
      // Init database
      await DatabaseService.database;

      // Load day count
      _dayCount = await DatabaseService.getDayCount();

      // Load API key
      _apiKey = await _secureStorage.read(key: _apiKeyStorageKey) ?? '';

      // Update last session
      await DatabaseService.updateLastSession();

      _isReady = true;
      notifyListeners();

      // Fetch greeting
      _greeting = await GeminiService.getGreeting(_apiKey);
      notifyListeners();
    } catch (e) {
      debugPrint('Init error: $e');
      _isReady = true;
      notifyListeners();
    }
  }

  // ── API Key ───────────────────────────────────────────────

  Future<void> setApiKey(String key) async {
    final trimmed = key.trim();
    _apiKey = trimmed;
    if (trimmed.isNotEmpty) {
      await _secureStorage.write(key: _apiKeyStorageKey, value: trimmed);
    } else {
      await _secureStorage.delete(key: _apiKeyStorageKey);
    }
    notifyListeners();

    // Refresh greeting with new key
    _greeting = await GeminiService.getGreeting(_apiKey);
    notifyListeners();
  }

  // ── Mood ──────────────────────────────────────────────────

  void incrementChat() {
    _chatCount++;
    if (_chatCount == 0) {
      _mood = PetMood.sleepy;
    } else if (_chatCount < 3) {
      _mood = PetMood.happy;
    } else if (_chatCount < 7) {
      _mood = PetMood.excited;
    } else {
      _mood = PetMood.curious;
    }
    notifyListeners();
  }
}

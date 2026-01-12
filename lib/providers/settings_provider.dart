import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  String _userName = '';

  // Consistency emoji settings (low to high intensity)
  String _consistencyEmojiLow = '💧';
  String _consistencyEmojiMedium = '🔥';
  String _consistencyEmojiHigh = '⚡';

  ThemeMode get themeMode => _themeMode;
  String get userName => _userName;

  // Gender settings
  String _gender = 'Prefer not to say';
  bool _onboardingCompleted = false;

  String get gender => _gender;
  bool get onboardingCompleted => _onboardingCompleted;

  // Consistency emoji getters
  String get consistencyEmojiLow => _consistencyEmojiLow;
  String get consistencyEmojiMedium => _consistencyEmojiMedium;
  String get consistencyEmojiHigh => _consistencyEmojiHigh;

  // Get emoji for intensity level (0=none, 1=low, 2=medium, 3=high)
  String getConsistencyEmoji(int intensity) {
    switch (intensity) {
      case 1:
        return _consistencyEmojiLow;
      case 2:
        return _consistencyEmojiMedium;
      case 3:
        return _consistencyEmojiHigh;
      default:
        return '';
    }
  }

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('themeMode') ?? 0; // Default to system (0)
    // Validate index range
    if (themeIndex >= 0 && themeIndex < ThemeMode.values.length) {
      _themeMode = ThemeMode.values[themeIndex];
    }
    _userName = prefs.getString('userName') ?? '';
    _gender = prefs.getString('gender') ?? 'Prefer not to say';
    _onboardingCompleted = prefs.getBool('onboardingCompleted') ?? false;

    // Load consistency emojis
    _consistencyEmojiLow = prefs.getString('consistencyEmojiLow') ?? '💧';
    _consistencyEmojiMedium = prefs.getString('consistencyEmojiMedium') ?? '🔥';
    _consistencyEmojiHigh = prefs.getString('consistencyEmojiHigh') ?? '⚡';

    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', mode.index);
  }

  Future<void> setUserName(String name) async {
    _userName = name;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', name);
  }

  Future<void> setGender(String gender) async {
    _gender = gender;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gender', gender);
  }

  Future<void> completeOnboarding() async {
    _onboardingCompleted = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboardingCompleted', true);
  }

  // Set consistency emojis
  Future<void> setConsistencyEmojis({
    String? low,
    String? medium,
    String? high,
  }) async {
    if (low != null) _consistencyEmojiLow = low;
    if (medium != null) _consistencyEmojiMedium = medium;
    if (high != null) _consistencyEmojiHigh = high;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('consistencyEmojiLow', _consistencyEmojiLow);
    await prefs.setString('consistencyEmojiMedium', _consistencyEmojiMedium);
    await prefs.setString('consistencyEmojiHigh', _consistencyEmojiHigh);
  }

  // Reset all settings
  Future<void> resetSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    _themeMode = ThemeMode.system;
    _userName = '';
    _gender = 'Prefer not to say';
    _onboardingCompleted = false;
    _consistencyEmojiLow = '💧';
    _consistencyEmojiMedium = '🔥';
    _consistencyEmojiHigh = '⚡';

    notifyListeners();
  }

  // Helper to get greeting with user's name
  String getGreeting() {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Good morning';
    } else if (hour < 17) {
      greeting = 'Good afternoon';
    } else {
      greeting = 'Good evening';
    }

    if (_userName.isNotEmpty) {
      return '$greeting, $_userName!';
    }
    return '$greeting!';
  }

  // Get motivational message (with or without name)
  String getMotivationalMessage() {
    final messages = _userName.isNotEmpty
        ? [
            'Keep going, $_userName! You\'re doing great!',
            '$_userName, every habit counts!',
            'Stay consistent, $_userName!',
            'You\'ve got this, $_userName!',
            '$_userName, small steps lead to big changes!',
          ]
        : [
            'Keep going! You\'re doing great!',
            'Every habit counts!',
            'Stay consistent!',
            'You\'ve got this!',
            'Small steps lead to big changes!',
          ];

    return messages[DateTime.now().second % messages.length];
  }
}

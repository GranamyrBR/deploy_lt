import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shared_preferences/shared_preferences.dart';
import '../services/high_contrast_service.dart';

final accessibilityProvider = StateNotifierProvider<AccessibilityNotifier, bool>((ref) {
  return AccessibilityNotifier()..init();
});

class AccessibilityNotifier extends StateNotifier<bool> {
  AccessibilityNotifier() : super(false);
  static const _prefKey = 'high_contrast_enabled';

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool(_prefKey) ?? false;
    state = saved;
    HighContrastService.apply(state);
  }

  Future<void> toggle() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, state);
    HighContrastService.apply(state);
  }
}


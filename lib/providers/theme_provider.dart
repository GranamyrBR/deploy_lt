import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:state_notifier/state_notifier.dart';


// Provider para gerenciar o tema da aplicação
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.light) {
    print('ThemeNotifier initialized with: ${state}');
  }

  void toggleTheme() {
    print('Toggle theme called. Current: ${state}');
    switch (state) {
      case ThemeMode.light:
        state = ThemeMode.dark;
        print('Switched to dark mode');
        break;
      case ThemeMode.dark:
        state = ThemeMode.light;
        print('Switched to light mode');
        break;
      case ThemeMode.system:
        // Se estiver no modo sistema, vai para light
        state = ThemeMode.light;
        print('Switched from system to light mode');
        break;
    }
  }

  void setTheme(ThemeMode themeMode) {
    print('Set theme called: ${themeMode}');
    state = themeMode;
  }

  bool get isDarkMode {
    return state == ThemeMode.dark;
  }

  bool get isLightMode {
    return state == ThemeMode.light;
  }

  bool get isSystemMode {
    return state == ThemeMode.system;
  }
} 

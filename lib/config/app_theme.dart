import 'package:flutter/material.dart';
import 'dart:ui';

class AppTheme {
  // Ordem correta: fonte principal primeiro, depois fallbacks
  static const List<String> _fontFallbacks = [
    'NotoSans',     // Fonte principal para texto
    'NotoEmoji',    // Para emojis e símbolos especiais
    'Roboto',       // Fallback robusto
    'NotoSerif',    // Para caracteres adicionais
    // Fontes do sistema como última opção
    'Arial',
    'Helvetica',
    'sans-serif',
  ];
  // Colors based on Lecotour brand (Blue theme)
  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color secondaryBlue = Color(0xFF3B82F6);
  static const Color accentBlue = Color(0xFF06B6D4);
  static const Color backgroundLight = Color(0xFFF8F9FA);
  static const Color backgroundDark = Color(0xFF1A1A1A);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF2D2D2D);
  static const Color textPrimary = Color(0xFF2D3436);
  static const Color textSecondary = Color(0xFF636E72);
  static const Color textLight = Color(0xFFFFFFFF);
  
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primarySwatch: MaterialColor(0xFF1E3A8A, {
      50: Color(0xFFE8F2FF),
      100: Color(0xFFC5D9FF),
      200: Color(0xFF9FBFFF),
      300: Color(0xFF79A5FF),
      400: Color(0xFF5C91FF),
      500: Color(0xFF1E3A8A),
      600: Color(0xFF1A337D),
      700: Color(0xFF162B6B),
      800: Color(0xFF122359),
      900: Color(0xFF0E1A47),
    }),
    scaffoldBackgroundColor: backgroundLight,
    cardColor: cardLight,
    appBarTheme: const AppBarTheme(
      backgroundColor: backgroundLight,
      elevation: 0,
      iconTheme: IconThemeData(color: textPrimary),
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    colorScheme: const ColorScheme.light(
      primary: primaryBlue,
      secondary: secondaryBlue,
      tertiary: accentBlue,
      surface: cardLight,
      background: backgroundLight,
      onPrimary: textLight,
      onSecondary: textLight,
      onSurface: textPrimary,
      onBackground: textPrimary,
      error: Color(0xFFE74C3C),
      onError: textLight,
      outline: Color(0xFFE0E0E0),
      outlineVariant: Color(0xFFF0F0F0),
      shadow: Color(0x1A000000),
      scrim: Color(0x52000000),
      inverseSurface: textPrimary,
      onInverseSurface: backgroundLight,
      inversePrimary: primaryBlue,
      surfaceTint: primaryBlue,
    ),
    textTheme: TextTheme(
      displayLarge: TextStyle(color: textPrimary, fontFamily: 'NotoSans', fontFamilyFallback: _fontFallbacks, fontFeatures: [FontFeature.tabularFigures()]),
      displayMedium: TextStyle(color: textPrimary, fontFamily: 'NotoSans', fontFamilyFallback: _fontFallbacks, fontFeatures: [FontFeature.tabularFigures()]),
      displaySmall: TextStyle(color: textPrimary, fontFamily: 'NotoSans', fontFamilyFallback: _fontFallbacks, fontFeatures: [FontFeature.tabularFigures()]),
      headlineLarge: TextStyle(color: textPrimary, fontFamily: 'NotoSans', fontFamilyFallback: _fontFallbacks, fontFeatures: [FontFeature.tabularFigures()]),
      headlineMedium: TextStyle(color: textPrimary, fontFamily: 'NotoSans', fontFamilyFallback: _fontFallbacks, fontFeatures: [FontFeature.tabularFigures()]),
      headlineSmall: TextStyle(color: textPrimary, fontFamily: 'NotoSans', fontFamilyFallback: _fontFallbacks, fontFeatures: [FontFeature.tabularFigures()]),
      titleLarge: TextStyle(color: textPrimary, fontFamily: 'NotoSans', fontFamilyFallback: _fontFallbacks, fontFeatures: [FontFeature.tabularFigures()]),
      titleMedium: TextStyle(color: textPrimary, fontFamily: 'NotoSans', fontFamilyFallback: _fontFallbacks, fontFeatures: [FontFeature.tabularFigures()]),
      titleSmall: TextStyle(color: textPrimary, fontFamily: 'NotoSans', fontFamilyFallback: _fontFallbacks, fontFeatures: [FontFeature.tabularFigures()]),
      bodyLarge: TextStyle(color: textPrimary, fontFamily: 'NotoSans', fontFamilyFallback: _fontFallbacks, fontFeatures: [FontFeature.tabularFigures()]),
      bodyMedium: TextStyle(color: textPrimary, fontFamily: 'NotoSans', fontFamilyFallback: _fontFallbacks, fontFeatures: [FontFeature.tabularFigures()]),
      bodySmall: TextStyle(color: textSecondary, fontFamily: 'NotoSans', fontFamilyFallback: _fontFallbacks, fontFeatures: [FontFeature.tabularFigures()]),
      labelLarge: TextStyle(color: textPrimary, fontFamily: 'NotoSans', fontFamilyFallback: _fontFallbacks, fontFeatures: [FontFeature.tabularFigures()]),
      labelMedium: TextStyle(color: textPrimary, fontFamily: 'NotoSans', fontFamilyFallback: _fontFallbacks, fontFeatures: [FontFeature.tabularFigures()]),
      labelSmall: TextStyle(color: textSecondary, fontFamily: 'NotoSans', fontFamilyFallback: _fontFallbacks, fontFeatures: [FontFeature.tabularFigures()]),
    ),
    iconTheme: const IconThemeData(
      color: textPrimary,
    ),
    cardTheme: const CardThemeData(
      color: cardLight,
      elevation: 2,
      shadowColor: Color(0x1A000000),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: textLight,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryBlue,
        side: const BorderSide(color: primaryBlue),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryBlue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return primaryBlue;
        }
        return Colors.grey;
      }),
      trackColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return primaryBlue.withValues(alpha: 0.5);
        }
        return Colors.grey.withValues(alpha: 0.5);
      }),
    ),
  );
  
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primarySwatch: MaterialColor(0xFF1E3A8A, {
      50: Color(0xFFE8F2FF),
      100: Color(0xFFC5D9FF),
      200: Color(0xFF9FBFFF),
      300: Color(0xFF79A5FF),
      400: Color(0xFF5C91FF),
      500: Color(0xFF1E3A8A),
      600: Color(0xFF1A337D),
      700: Color(0xFF162B6B),
      800: Color(0xFF122359),
      900: Color(0xFF0E1A47),
    }),
    scaffoldBackgroundColor: backgroundDark,
    cardColor: cardDark,
    appBarTheme: const AppBarTheme(
      backgroundColor: backgroundDark,
      elevation: 0,
      iconTheme: IconThemeData(color: textLight),
      titleTextStyle: TextStyle(
        color: textLight,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    colorScheme: const ColorScheme.dark(
      primary: primaryBlue,
      secondary: secondaryBlue,
      tertiary: accentBlue,
      surface: cardDark,
      background: backgroundDark,
      onPrimary: textLight,
      onSecondary: textLight,
      onSurface: textLight,
      onBackground: textLight,
      error: Color(0xFFE74C3C),
      onError: textLight,
      outline: Color(0xFF404040),
      outlineVariant: Color(0xFF303030),
      shadow: Color(0x40000000),
      scrim: Color(0x52000000),
      inverseSurface: textLight,
      onInverseSurface: backgroundDark,
      inversePrimary: primaryBlue,
      surfaceTint: primaryBlue,
    ),
    textTheme: TextTheme(
      displayLarge: TextStyle(color: textLight, fontFamily: 'NotoSans', fontFamilyFallback: _fontFallbacks, fontFeatures: [FontFeature.tabularFigures()]),
      displayMedium: TextStyle(color: textLight, fontFamily: 'NotoSans', fontFamilyFallback: _fontFallbacks, fontFeatures: [FontFeature.tabularFigures()]),
      displaySmall: TextStyle(color: textLight, fontFamily: 'NotoSans', fontFamilyFallback: _fontFallbacks, fontFeatures: [FontFeature.tabularFigures()]),
      headlineLarge: TextStyle(color: textLight, fontFamily: 'NotoSans', fontFamilyFallback: _fontFallbacks, fontFeatures: [FontFeature.tabularFigures()]),
      headlineMedium: TextStyle(color: textLight, fontFamily: 'NotoSans', fontFamilyFallback: _fontFallbacks, fontFeatures: [FontFeature.tabularFigures()]),
      headlineSmall: TextStyle(color: textLight, fontFamily: 'NotoSans', fontFamilyFallback: _fontFallbacks, fontFeatures: [FontFeature.tabularFigures()]),
      titleLarge: TextStyle(color: textLight, fontFamily: 'NotoSans', fontFamilyFallback: _fontFallbacks, fontFeatures: [FontFeature.tabularFigures()]),
      titleMedium: TextStyle(color: textLight, fontFamily: 'NotoSans', fontFamilyFallback: _fontFallbacks, fontFeatures: [FontFeature.tabularFigures()]),
      titleSmall: TextStyle(color: textLight, fontFamily: 'NotoSans', fontFamilyFallback: _fontFallbacks, fontFeatures: [FontFeature.tabularFigures()]),
      bodyLarge: TextStyle(color: textLight, fontFamily: 'NotoSans', fontFamilyFallback: _fontFallbacks, fontFeatures: [FontFeature.tabularFigures()]),
      bodyMedium: TextStyle(color: textLight, fontFamily: 'NotoSans', fontFamilyFallback: _fontFallbacks, fontFeatures: [FontFeature.tabularFigures()]),
      bodySmall: TextStyle(color: textLight, fontFamily: 'NotoSans', fontFamilyFallback: _fontFallbacks, fontFeatures: [FontFeature.tabularFigures()]),
      labelLarge: TextStyle(color: textLight, fontFamily: 'NotoSans', fontFamilyFallback: _fontFallbacks, fontFeatures: [FontFeature.tabularFigures()]),
      labelMedium: TextStyle(color: textLight, fontFamily: 'NotoSans', fontFamilyFallback: _fontFallbacks, fontFeatures: [FontFeature.tabularFigures()]),
      labelSmall: TextStyle(color: textLight, fontFamily: 'NotoSans', fontFamilyFallback: _fontFallbacks, fontFeatures: [FontFeature.tabularFigures()]),
    ),
    iconTheme: const IconThemeData(
      color: textLight,
    ),
    cardTheme: const CardThemeData(
      color: cardDark,
      elevation: 2,
      shadowColor: Color(0x40000000),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: textLight,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryBlue,
        side: const BorderSide(color: primaryBlue),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryBlue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return primaryBlue;
        }
        return Colors.grey;
      }),
      trackColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return primaryBlue.withValues(alpha: 0.5);
        }
        return Colors.grey.withValues(alpha: 0.5);
      }),
    ),
  );
}


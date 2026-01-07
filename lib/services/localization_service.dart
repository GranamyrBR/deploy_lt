import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart' as flutter;
import 'package:shared_preferences/shared_preferences.dart';

class LocalizationService {
  static const String _languageKey = 'selected_language';
  static const String _defaultLanguage = 'pt';
  
  // Idiomas suportados
  static const Map<String, String> supportedLanguages = {
    'en': 'English',
    'pt': 'Português',
    'es': 'Español',
  };

  // Locales suportados
  static const List<flutter.Locale> supportedLocales = [
    flutter.Locale('en', 'US'),
    flutter.Locale('pt', 'BR'),
    flutter.Locale('es', 'ES'),
  ];

  // Obter idioma atual
  static Future<String> getCurrentLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageKey) ?? _defaultLanguage;
  }

  // Definir idioma
  static Future<void> setLanguage(flutter.BuildContext context, String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);
    
    // Aplicar o idioma no contexto
    await context.setLocale(flutter.Locale(languageCode));
  }

  // Obter locale do idioma
  static flutter.Locale getLocaleFromLanguage(String languageCode) {
    switch (languageCode) {
      case 'en':
        return const flutter.Locale('en', 'US');
      case 'pt':
        return const flutter.Locale('pt', 'BR');
      case 'es':
        return const flutter.Locale('es', 'ES');
      default:
        return const flutter.Locale('pt', 'BR');
    }
  }

  // Obter nome do idioma
  static String getLanguageName(String languageCode) {
    return supportedLanguages[languageCode] ?? 'Unknown';
  }

  // Verificar se o idioma é suportado
  static bool isLanguageSupported(String languageCode) {
    return supportedLanguages.containsKey(languageCode);
  }

  // Obter idioma padrão do sistema
  static String getSystemLanguage() {
    final locale = flutter.WidgetsBinding.instance.window.locale;
    final languageCode = locale.languageCode;
    
    if (isLanguageSupported(languageCode)) {
      return languageCode;
    }
    
    return _defaultLanguage;
  }

  // Inicializar localização
  static Future<void> initializeLocalization(flutter.BuildContext context) async {
    final currentLanguage = await getCurrentLanguage();
    final locale = getLocaleFromLanguage(currentLanguage);
    
    if (context.locale != locale) {
      await context.setLocale(locale);
    }
  }

  // Obter lista de idiomas para seleção
  static List<Map<String, String>> getLanguageOptions() {
    return supportedLanguages.entries.map((entry) => {
      'code': entry.key,
      'name': entry.value,
    }).toList();
  }

  // Traduzir texto com parâmetros
  static String translate(String key, {Map<String, String>? args}) {
    if (args != null) {
      return key.tr(namedArgs: args);
    }
    return key.tr();
  }

  // Traduzir texto plural
  static String translatePlural(String key, int count) {
    return key.tr(namedArgs: {'count': count.toString()});
  }

  // Obter direção do texto (LTR/RTL)
  static flutter.TextDirection getTextDirection(String languageCode) {
    // Por enquanto, todos os idiomas suportados são LTR
    return flutter.TextDirection.ltr;
  }

  // Formatar data de acordo com o idioma
  static String formatDate(DateTime date, String languageCode) {
    final locale = getLocaleFromLanguage(languageCode);
    return DateFormat.yMMMd(locale.languageCode).format(date);
  }

  // Formatar hora de acordo com o idioma
  static String formatTime(DateTime time, String languageCode) {
    final locale = getLocaleFromLanguage(languageCode);
    return DateFormat.Hm(locale.languageCode).format(time);
  }

  // Formatar número de acordo com o idioma
  static String formatNumber(double number, String languageCode) {
    final locale = getLocaleFromLanguage(languageCode);
    return NumberFormat.decimalPattern(locale.languageCode).format(number);
  }

  // Formatar moeda de acordo com o idioma
  static String formatCurrency(double amount, String currencyCode, String languageCode) {
    final locale = getLocaleFromLanguage(languageCode);
    return NumberFormat.currency(
      locale: locale.languageCode,
      symbol: currencyCode,
    ).format(amount);
  }
} 

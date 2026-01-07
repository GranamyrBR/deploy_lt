import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:intl/intl.dart';

class TimezoneUtils {
  static bool _initialized = false;

  /// Inicializa os dados de timezone (deve ser chamado uma vez no início da aplicação)
  static void initialize() {
    if (!_initialized) {
      tz.initializeTimeZones();
      _initialized = true;
    }
  }

  /// Converte um DateTime UTC para o timezone de São Paulo
  static DateTime convertToSaoPaulo(DateTime utcDateTime) {
    initialize();
    final saoPauloLocation = tz.getLocation('America/Sao_Paulo');
    final tzDateTime = tz.TZDateTime.from(utcDateTime, tz.UTC);
    return tz.TZDateTime.from(tzDateTime, saoPauloLocation);
  }

  /// Converte um DateTime UTC para o timezone de Nova York
  static DateTime convertToNewYork(DateTime utcDateTime) {
    initialize();
    final newYorkLocation = tz.getLocation('America/New_York');
    final tzDateTime = tz.TZDateTime.from(utcDateTime, tz.UTC);
    return tz.TZDateTime.from(tzDateTime, newYorkLocation);
  }

  /// Converte um DateTime de São Paulo para Nova York
  static DateTime convertSaoPauloToNewYork(DateTime saoPauloDateTime) {
    initialize();
    final saoPauloLocation = tz.getLocation('America/Sao_Paulo');
    final newYorkLocation = tz.getLocation('America/New_York');
    
    // Criar TZDateTime para São Paulo
    final saoPauloTz = tz.TZDateTime(
      saoPauloLocation,
      saoPauloDateTime.year,
      saoPauloDateTime.month,
      saoPauloDateTime.day,
      saoPauloDateTime.hour,
      saoPauloDateTime.minute,
      saoPauloDateTime.second,
    );
    
    // Converter para Nova York
    return tz.TZDateTime.from(saoPauloTz, newYorkLocation);
  }

  /// Converte um DateTime de Nova York para São Paulo
  static DateTime convertNewYorkToSaoPaulo(DateTime newYorkDateTime) {
    initialize();
    final saoPauloLocation = tz.getLocation('America/Sao_Paulo');
    final newYorkLocation = tz.getLocation('America/New_York');
    
    // Criar TZDateTime para Nova York
    final newYorkTz = tz.TZDateTime(
      newYorkLocation,
      newYorkDateTime.year,
      newYorkDateTime.month,
      newYorkDateTime.day,
      newYorkDateTime.hour,
      newYorkDateTime.minute,
      newYorkDateTime.second,
    );
    
    // Converter para São Paulo
    return tz.TZDateTime.from(newYorkTz, saoPauloLocation);
  }

  /// Retorna a hora atual em São Paulo
  static DateTime getCurrentTimeSaoPaulo() {
    initialize();
    final saoPauloLocation = tz.getLocation('America/Sao_Paulo');
    return tz.TZDateTime.now(saoPauloLocation);
  }

  /// Retorna a hora atual em Nova York
  static DateTime getCurrentTimeNewYork() {
    initialize();
    final newYorkLocation = tz.getLocation('America/New_York');
    return tz.TZDateTime.now(newYorkLocation);
  }

  /// Formata um DateTime para exibição com timezone
  static String formatWithTimezone(DateTime dateTime, String timezone) {
    final formatter = DateFormat('dd/MM/yy HH:mm');
    return '${formatter.format(dateTime)} ($timezone)';
  }

  /// Formata apenas a hora com timezone
  static String formatTimeWithTimezone(DateTime dateTime, String timezone) {
    final formatter = DateFormat('HH:mm');
    return '${formatter.format(dateTime)} ($timezone)';
  }

  /// Retorna informações de timezone formatadas para exibição
  static Map<String, String> getTimezoneInfo() {
    final saoPauloTime = getCurrentTimeSaoPaulo();
    final newYorkTime = getCurrentTimeNewYork();
    
    return {
      'saoPaulo': formatWithTimezone(saoPauloTime, 'BR'),
      'newYork': formatWithTimezone(newYorkTime, 'NYC'),
      'saoPauloTime': formatTimeWithTimezone(saoPauloTime, 'BR'),
      'newYorkTime': formatTimeWithTimezone(newYorkTime, 'NYC'),
    };
  }
}
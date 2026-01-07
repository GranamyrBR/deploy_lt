import 'package:intl/intl.dart';

class DateTimeUtils {
  /// Converte UTC para horário brasileiro usando timezone dinâmico
  /// Considera automaticamente horário de verão (UTC-2) e padrão (UTC-3)
  static DateTime convertUtcToBrazilTime(DateTime utcDateTime) {
    return utcDateTime.toLocal();
  }

  /// Formata um horário de voo para exibição legível
  /// Converte formatos como "2025-07-03T14:55:00Z" para "14:55"
  static String formatFlightTime(String? timeString) {
    if (timeString == null || timeString.isEmpty) {
      return 'N/A';
    }

    try {
      // Tentar diferentes formatos de data/hora
      DateTime? dateTime;
      
      // Formato ISO 8601 (2025-07-03T14:55:00Z)
      if (timeString.contains('T')) {
        dateTime = DateTime.tryParse(timeString);
      }
      // Formato apenas hora (14:55:00)
      else if (timeString.contains(':')) {
        final parts = timeString.split(':');
        if (parts.length >= 2) {
          final now = DateTime.now();
          dateTime = DateTime(now.year, now.month, now.day, 
                            int.parse(parts[0]), int.parse(parts[1]));
        }
      }
      
      if (dateTime != null) {
        return DateFormat('HH:mm').format(dateTime);
      }
      
      return timeString;
    } catch (e) {
      return timeString;
    }
  }

  /// Formata uma data completa para exibição legível
  /// Converte formatos como "2025-07-03T14:55:00Z" para "03/07/2025 14:55"
  static String formatFlightDateTime(String? dateTimeString) {
    if (dateTimeString == null || dateTimeString.isEmpty) {
      return 'N/A';
    }

    try {
      final dateTime = DateTime.tryParse(dateTimeString);
      if (dateTime != null) {
        return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
      }
      return dateTimeString;
    } catch (e) {
      return dateTimeString;
    }
  }

  /// Formata apenas a data para exibição legível
  /// Converte formatos como "2025-07-03" para "03/07/2025"
  static String formatFlightDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return 'N/A';
    }

    try {
      final date = DateTime.tryParse(dateString);
      if (date != null) {
        return DateFormat('dd/MM/yyyy').format(date);
      }
      return dateString;
    } catch (e) {
      return dateString;
    }
  }

  /// Formata horário com fuso horário local
  /// Converte UTC para horário local brasileiro
  static String formatLocalTime(String? timeString) {
    if (timeString == null || timeString.isEmpty) {
      return 'N/A';
    }

    try {
      final utcDateTime = DateTime.tryParse(timeString);
      if (utcDateTime != null) {
        // Converter para horário local (Brasil - timezone dinâmico)
        final localDateTime = utcDateTime.toLocal();
        return DateFormat('HH:mm').format(localDateTime);
      }
      return timeString;
    } catch (e) {
      return timeString;
    }
  }

  /// Formata data e hora com fuso horário local
  static String formatLocalDateTime(String? dateTimeString) {
    if (dateTimeString == null || dateTimeString.isEmpty) {
      return 'N/A';
    }

    try {
      final utcDateTime = DateTime.tryParse(dateTimeString);
      if (utcDateTime != null) {
        final localDateTime = utcDateTime.toLocal();
        return DateFormat('dd/MM/yyyy HH:mm').format(localDateTime);
      }
      return dateTimeString;
    } catch (e) {
      return dateTimeString;
    }
  }

  /// Formata DateTime UTC para horário brasileiro
  /// Versão específica para quando o banco está em UTC
  static String formatUtcToBrazil(DateTime? utcDateTime) {
    if (utcDateTime == null) return 'Data N/A';
    
    final brazilTime = convertUtcToBrazilTime(utcDateTime);
    return DateFormat('dd/MM/yy HH:mm').format(brazilTime);
  }

  /// Calcula a diferença entre dois horários e retorna em formato legível
  static String formatDuration(String? departureTime, String? arrivalTime) {
    if (departureTime == null || arrivalTime == null) {
      return 'N/A';
    }

    try {
      final departure = DateTime.tryParse(departureTime);
      final arrival = DateTime.tryParse(arrivalTime);
      
      if (departure != null && arrival != null) {
        final duration = arrival.difference(departure);
        final hours = duration.inHours;
        final minutes = duration.inMinutes % 60;
        
        if (hours > 0) {
          return '${hours}h ${minutes}min';
        } else {
          return '${minutes}min';
        }
      }
      
      return 'N/A';
    } catch (e) {
      return 'N/A';
    }
  }

  /// Verifica se um voo está atrasado comparando horário programado vs real
  static String getDelayStatus(String? scheduledTime, String? actualTime) {
    if (scheduledTime == null || actualTime == null) {
      return 'N/A';
    }

    try {
      final scheduled = DateTime.tryParse(scheduledTime);
      final actual = DateTime.tryParse(actualTime);
      
      if (scheduled != null && actual != null) {
        final delay = actual.difference(scheduled);
        
        if (delay.inMinutes > 15) {
          return 'Atrasado ${delay.inMinutes}min';
        } else if (delay.inMinutes < -15) {
          return 'Adiantado ${delay.inMinutes.abs()}min';
        } else {
          return 'No horário';
        }
      }
      
      return 'N/A';
    } catch (e) {
      return 'N/A';
    }
  }
}

import '../models/lead_tintim.dart';
import '../models/response_time_metrics.dart';

/// Serviço para calcular métricas de tempo de resposta
class ResponseTimeCalculator {
  /// Calcula as métricas de tempo de resposta a partir de uma lista de mensagens
  static ResponseTimeMetrics calculateMetrics(List<LeadTintim> messages) {
    if (messages.isEmpty) {
      return ResponseTimeMetrics.empty();
    }

    // Ordenar mensagens por data
    final sortedMessages = List<LeadTintim>.from(messages)
      ..sort((a, b) {
        final aDate = a.datelast ?? a.createdAt ?? DateTime.now();
        final bDate = b.datelast ?? b.createdAt ?? DateTime.now();
        return aDate.compareTo(bDate);
      });

    // Encontrar pares de mensagens (cliente -> atendente)
    final List<ResponseTimeEntry> entries = [];
    LeadTintim? lastCustomerMessage;

    for (final message in sortedMessages) {
      final isFromAgent = message.fromMe == true;
      final messageTime = message.datelast ?? message.createdAt;

      if (messageTime == null) continue;

      if (!isFromAgent) {
        // Mensagem do cliente - armazenar para calcular tempo depois
        lastCustomerMessage = message;
      } else if (lastCustomerMessage != null) {
        // Mensagem do atendente - calcular tempo de resposta
        final customerTime = lastCustomerMessage.datelast ?? lastCustomerMessage.createdAt;
        
        if (customerTime != null) {
          final responseTime = messageTime.difference(customerTime);
          
          // Só considerar se o tempo for positivo (resposta após mensagem do cliente)
          if (responseTime.inSeconds > 0) {
            entries.add(ResponseTimeEntry(
              customerMessageTime: customerTime,
              agentResponseTime: messageTime,
              responseTime: responseTime,
              customerMessage: lastCustomerMessage.message,
              agentMessage: message.message,
            ));
          }
        }
        
        // Reset para próximo par
        lastCustomerMessage = null;
      }
    }

    // Se não houver entradas, retornar métricas vazias
    if (entries.isEmpty) {
      return ResponseTimeMetrics.empty();
    }

    // Calcular estatísticas
    final totalResponses = entries.length;
    final totalDuration = entries.fold<Duration>(
      Duration.zero,
      (sum, entry) => sum + entry.responseTime,
    );

    final averageResponseTime = totalDuration ~/ totalResponses;

    final sortedByDuration = List<ResponseTimeEntry>.from(entries)
      ..sort((a, b) => a.responseTime.compareTo(b.responseTime));

    final minResponseTime = sortedByDuration.first.responseTime;
    final maxResponseTime = sortedByDuration.last.responseTime;

    // Contar por categoria
    int fastResponses = 0; // < 5 min
    int goodResponses = 0; // 5-15 min
    int adequateResponses = 0; // 15-30 min
    int slowResponses = 0; // > 30 min

    for (final entry in entries) {
      final minutes = entry.responseTime.inMinutes;
      if (minutes < 5) {
        fastResponses++;
      } else if (minutes < 15) {
        goodResponses++;
      } else if (minutes < 30) {
        adequateResponses++;
      } else {
        slowResponses++;
      }
    }

    final fastResponseRate = (fastResponses / totalResponses * 100);

    return ResponseTimeMetrics(
      averageResponseTime: averageResponseTime,
      minResponseTime: minResponseTime,
      maxResponseTime: maxResponseTime,
      totalResponses: totalResponses,
      fastResponses: fastResponses,
      goodResponses: goodResponses,
      adequateResponses: adequateResponses,
      slowResponses: slowResponses,
      fastResponseRate: fastResponseRate,
      entries: entries,
    );
  }

  /// Calcula a performance de uma resposta específica
  static ResponsePerformance getResponsePerformance(Duration responseTime) {
    if (responseTime.inMinutes < 5) return ResponsePerformance.excellent;
    if (responseTime.inMinutes < 15) return ResponsePerformance.good;
    if (responseTime.inMinutes < 30) return ResponsePerformance.adequate;
    return ResponsePerformance.needsImprovement;
  }

  /// Formata a duração de forma legível
  static String formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}min';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}min';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  /// Retorna a cor Flutter para uma performance
  static int getPerformanceColorValue(ResponsePerformanceColor color) {
    switch (color) {
      case ResponsePerformanceColor.green:
        return 0xFF4CAF50; // Verde
      case ResponsePerformanceColor.yellow:
        return 0xFFFFEB3B; // Amarelo
      case ResponsePerformanceColor.orange:
        return 0xFFFF9800; // Laranja
      case ResponsePerformanceColor.red:
        return 0xFFF44336; // Vermelho
    }
  }
}

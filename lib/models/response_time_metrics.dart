/// Modelo para métricas de tempo de resposta do atendente
class ResponseTimeMetrics {
  final Duration averageResponseTime;
  final Duration minResponseTime;
  final Duration maxResponseTime;
  final int totalResponses;
  final int fastResponses; // < 5 minutos
  final int goodResponses; // 5-15 minutos
  final int adequateResponses; // 15-30 minutos
  final int slowResponses; // > 30 minutos
  final double fastResponseRate; // Porcentagem de respostas rápidas
  final List<ResponseTimeEntry> entries; // Histórico de respostas

  ResponseTimeMetrics({
    required this.averageResponseTime,
    required this.minResponseTime,
    required this.maxResponseTime,
    required this.totalResponses,
    required this.fastResponses,
    required this.goodResponses,
    required this.adequateResponses,
    required this.slowResponses,
    required this.fastResponseRate,
    required this.entries,
  });

  /// Retorna a performance geral (Excelente, Bom, Adequado, Precisa Melhorar)
  ResponsePerformance get overallPerformance {
    if (fastResponseRate >= 70) return ResponsePerformance.excellent;
    if (fastResponseRate >= 50) return ResponsePerformance.good;
    if (fastResponseRate >= 30) return ResponsePerformance.adequate;
    return ResponsePerformance.needsImprovement;
  }

  /// Retorna a cor associada à performance
  ResponsePerformanceColor get performanceColor {
    switch (overallPerformance) {
      case ResponsePerformance.excellent:
        return ResponsePerformanceColor.green;
      case ResponsePerformance.good:
        return ResponsePerformanceColor.yellow;
      case ResponsePerformance.adequate:
        return ResponsePerformanceColor.orange;
      case ResponsePerformance.needsImprovement:
        return ResponsePerformanceColor.red;
    }
  }

  /// Formata o tempo médio de resposta para exibição
  String get formattedAverageTime => _formatDuration(averageResponseTime);

  /// Formata o tempo mínimo para exibição
  String get formattedMinTime => _formatDuration(minResponseTime);

  /// Formata o tempo máximo para exibição
  String get formattedMaxTime => _formatDuration(maxResponseTime);

  String _formatDuration(Duration duration) {
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

  /// Cria métricas vazias (para quando não há dados)
  factory ResponseTimeMetrics.empty() {
    return ResponseTimeMetrics(
      averageResponseTime: Duration.zero,
      minResponseTime: Duration.zero,
      maxResponseTime: Duration.zero,
      totalResponses: 0,
      fastResponses: 0,
      goodResponses: 0,
      adequateResponses: 0,
      slowResponses: 0,
      fastResponseRate: 0,
      entries: [],
    );
  }
}

/// Entrada individual de tempo de resposta
class ResponseTimeEntry {
  final DateTime customerMessageTime;
  final DateTime agentResponseTime;
  final Duration responseTime;
  final String? customerMessage;
  final String? agentMessage;

  ResponseTimeEntry({
    required this.customerMessageTime,
    required this.agentResponseTime,
    required this.responseTime,
    this.customerMessage,
    this.agentMessage,
  });

  /// Retorna a categoria de performance desta resposta
  ResponsePerformance get performance {
    if (responseTime.inMinutes < 5) return ResponsePerformance.excellent;
    if (responseTime.inMinutes < 15) return ResponsePerformance.good;
    if (responseTime.inMinutes < 30) return ResponsePerformance.adequate;
    return ResponsePerformance.needsImprovement;
  }

  /// Retorna a cor associada à performance
  ResponsePerformanceColor get performanceColor {
    switch (performance) {
      case ResponsePerformance.excellent:
        return ResponsePerformanceColor.green;
      case ResponsePerformance.good:
        return ResponsePerformanceColor.yellow;
      case ResponsePerformance.adequate:
        return ResponsePerformanceColor.orange;
      case ResponsePerformance.needsImprovement:
        return ResponsePerformanceColor.red;
    }
  }

  /// Formata o tempo de resposta para exibição
  String get formattedResponseTime {
    if (responseTime.inDays > 0) {
      return '${responseTime.inDays}d ${responseTime.inHours % 24}h';
    } else if (responseTime.inHours > 0) {
      return '${responseTime.inHours}h ${responseTime.inMinutes % 60}min';
    } else if (responseTime.inMinutes > 0) {
      return '${responseTime.inMinutes}min';
    } else {
      return '${responseTime.inSeconds}s';
    }
  }
}

/// Enum para níveis de performance
enum ResponsePerformance {
  excellent, // < 5 min
  good, // 5-15 min
  adequate, // 15-30 min
  needsImprovement, // > 30 min
}

/// Enum para cores de performance
enum ResponsePerformanceColor {
  green,
  yellow,
  orange,
  red,
}

/// Extensão para obter descrições legíveis
extension ResponsePerformanceExtension on ResponsePerformance {
  String get label {
    switch (this) {
      case ResponsePerformance.excellent:
        return 'Excelente';
      case ResponsePerformance.good:
        return 'Bom';
      case ResponsePerformance.adequate:
        return 'Adequado';
      case ResponsePerformance.needsImprovement:
        return 'Precisa Melhorar';
    }
  }

  String get emoji {
    switch (this) {
      case ResponsePerformance.excellent:
        return '🚀';
      case ResponsePerformance.good:
        return '👍';
      case ResponsePerformance.adequate:
        return '⚠️';
      case ResponsePerformance.needsImprovement:
        return '⏰';
    }
  }

  String get description {
    switch (this) {
      case ResponsePerformance.excellent:
        return 'Tempo de resposta excelente! Continue assim!';
      case ResponsePerformance.good:
        return 'Bom tempo de resposta. Mantenha o ritmo!';
      case ResponsePerformance.adequate:
        return 'Tempo adequado, mas há espaço para melhorar.';
      case ResponsePerformance.needsImprovement:
        return 'Tente responder mais rápido para melhorar a experiência.';
    }
  }
}

import 'package:flutter/material.dart';
import '../models/response_time_metrics.dart';
import '../services/response_time_calculator.dart';

/// Badge que mostra o tempo de resposta ao lado da mensagem do atendente
class ResponseTimeBadge extends StatelessWidget {
  final Duration responseTime;
  final bool compact;

  const ResponseTimeBadge({
    super.key,
    required this.responseTime,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final performance = ResponseTimeCalculator.getResponsePerformance(responseTime);
    final color = _getColor(performance);
    final emoji = _getEmoji(performance);
    final formattedTime = ResponseTimeCalculator.formatDuration(responseTime);

    if (compact) {
      return _buildCompactBadge(context, color, emoji, formattedTime);
    } else {
      return _buildFullBadge(context, color, emoji, formattedTime, performance);
    }
  }

  Widget _buildCompactBadge(BuildContext context, Color color, String emoji, String formattedTime) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 10)),
          const SizedBox(width: 3),
          Text(
            formattedTime,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullBadge(BuildContext context, Color color, String emoji, String formattedTime, ResponsePerformance performance) {
    return Tooltip(
      message: performance.description,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.6), width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  formattedTime,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  performance.label,
                  style: TextStyle(
                    fontSize: 9,
                    color: color.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getColor(ResponsePerformance performance) {
    switch (performance) {
      case ResponsePerformance.excellent:
        return Colors.green;
      case ResponsePerformance.good:
        return Colors.amber;
      case ResponsePerformance.adequate:
        return Colors.orange;
      case ResponsePerformance.needsImprovement:
        return Colors.red;
    }
  }

  String _getEmoji(ResponsePerformance performance) {
    switch (performance) {
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
}

/// Badge animado que chama atenção para respostas lentas
class AnimatedResponseTimeBadge extends StatefulWidget {
  final Duration responseTime;

  const AnimatedResponseTimeBadge({
    super.key,
    required this.responseTime,
  });

  @override
  State<AnimatedResponseTimeBadge> createState() => _AnimatedResponseTimeBadgeState();
}

class _AnimatedResponseTimeBadgeState extends State<AnimatedResponseTimeBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // Animar apenas se for resposta lenta
    final performance = ResponseTimeCalculator.getResponsePerformance(widget.responseTime);
    if (performance == ResponsePerformance.needsImprovement) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: ResponseTimeBadge(responseTime: widget.responseTime),
    );
  }
}

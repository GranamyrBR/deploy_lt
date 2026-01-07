import 'package:flutter/material.dart';
import '../models/response_time_metrics.dart';

/// Card que mostra os KPIs de tempo de resposta
class ResponseTimeKPICard extends StatelessWidget {
  final ResponseTimeMetrics metrics;
  final VoidCallback? onViewDetails;

  const ResponseTimeKPICard({
    super.key,
    required this.metrics,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    if (metrics.totalResponses == 0) {
      return const SizedBox.shrink(); // Não mostra nada se não houver dados
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.2),
              Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.2),
            ],
          ),
        ),
        child: Column(
          children: [
            _buildCompactHeader(context),
            const SizedBox(height: 8),
            _buildCompactMetrics(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _getPerformanceColor(context, metrics.overallPerformance).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            Icons.timer,
            color: _getPerformanceColor(context, metrics.overallPerformance),
            size: 16,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tempo de Resposta',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
              ),
              Text(
                '${metrics.totalResponses} resposta${metrics.totalResponses != 1 ? "s" : ""}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
              ),
            ],
          ),
        ),
        Text(
          metrics.overallPerformance.emoji,
          style: const TextStyle(fontSize: 20),
        ),
        const SizedBox(width: 4),
        Text(
          metrics.overallPerformance.label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 11,
                color: _getPerformanceColor(context, metrics.overallPerformance),
              ),
        ),
      ],
    );
  }

  Widget _buildCompactMetrics(BuildContext context) {
    return Row(
      children: [
        _buildCompactMetricBox(
          context,
          'Média',
          metrics.formattedAverageTime,
          _getPerformanceColor(context, metrics.overallPerformance),
        ),
        const SizedBox(width: 8),
        _buildCompactMetricBox(
          context,
          'Min',
          metrics.formattedMinTime,
          Colors.green,
        ),
        const SizedBox(width: 8),
        _buildCompactMetricBox(
          context,
          'Max',
          metrics.formattedMaxTime,
          Colors.orange,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildCompactPerformanceBar(context),
        ),
      ],
    );
  }

  Widget _buildCompactMetricBox(BuildContext context, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 9,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactPerformanceBar(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${metrics.fastResponseRate.toStringAsFixed(0)}% rápidas',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 2),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: metrics.fastResponseRate / 100,
            minHeight: 6,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              _getPerformanceColor(context, metrics.overallPerformance),
            ),
          ),
        ),
      ],
    );
  }


  Color _getPerformanceColor(BuildContext context, ResponsePerformance performance) {
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
}

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/financial_metric.dart';

class FinancialKPICard extends StatefulWidget {
  final FinancialMetric metric;
  final Map<String, dynamic>? chartData;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showChart;
  final bool isLoading;

  const FinancialKPICard({
    Key? key,
    required this.metric,
    this.chartData,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.showChart = true,
    this.isLoading = false,
  }) : super(key: key);

  @override
  State<FinancialKPICard> createState() => _FinancialKPICardState();
}

class _FinancialKPICardState extends State<FinancialKPICard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final metric = widget.metric;
    final hasAlert = metric.hasAlert;
    final isPositiveVariation = metric.isPositiveVariation;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Card(
        elevation: _isHovered ? 8 : 2,
        shadowColor: hasAlert 
          ? Colors.red.withValues(alpha: 0.3)
          : isPositiveVariation
            ? Colors.green.withValues(alpha: 0.3)
            : Colors.grey.withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: hasAlert
              ? Colors.red.withValues(alpha: 0.5)
              : Colors.transparent,
            width: 2,
          ),
        ),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                  isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFF8F9FA),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header com título e ações
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            metric.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode ? Colors.white70 : Colors.grey[700],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            metric.description,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDarkMode ? Colors.white54 : Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (widget.onEdit != null || widget.onDelete != null)
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit' && widget.onEdit != null) {
                            widget.onEdit!();
                          } else if (value == 'delete' && widget.onDelete != null) {
                            widget.onDelete!();
                          }
                        },
                        itemBuilder: (context) => [
                          if (widget.onEdit != null)
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 16),
                                  SizedBox(width: 8),
                                  Text('Editar'),
                                ],
                              ),
                            ),
                          if (widget.onDelete != null)
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, size: 16, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Excluir', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                        ],
                        child: Icon(
                          Icons.more_vert,
                          color: isDarkMode ? Colors.white54 : Colors.grey[600],
                          size: 16,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Valor principal
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      _formatValue(metric.currentValue, metric.unit),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: hasAlert ? Colors.red : (isDarkMode ? Colors.white : Colors.black87),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      metric.unit,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.white54 : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                
                // Variação
                if (metric.variationPercentage != 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Icon(
                          isPositiveVariation ? Icons.trending_up : Icons.trending_down,
                          size: 16,
                          color: isPositiveVariation ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${metric.variationPercentage.abs().toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isPositiveVariation ? Colors.green : Colors.red,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'vs. período anterior',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDarkMode ? Colors.white38 : Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Alerta
                if (hasAlert)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning_amber_rounded, size: 12, color: Colors.red[700]),
                        const SizedBox(width: 4),
                        Text(
                          'Abaixo do esperado',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.red[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Gráfico mini
                if (widget.showChart && widget.chartData != null)
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    height: 60,
                    child: _buildMiniChart(),
                  ),
                
                // Loading
                if (widget.isLoading)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: LinearProgressIndicator(minHeight: 2),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniChart() {
    if (widget.chartData == null) return const SizedBox.shrink();
    
    final labels = widget.chartData!['labels'] as List<dynamic>;
    final values = widget.chartData!['values'] as List<dynamic>;
    
    if (labels.isEmpty || values.isEmpty) return const SizedBox.shrink();
    
    final spots = values.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      final value = (entry.value as num).toDouble();
      return FlSpot(index, value);
    }).toList();
    
    final isPositive = widget.metric.isPositiveVariation;
    final color = isPositive ? Colors.green : Colors.red;
    
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        minX: 0,
        maxX: spots.length.toDouble() - 1,
        minY: 0,
        maxY: values.map((v) => (v as num).toDouble()).reduce((a, b) => a > b ? a : b) * 1.1,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color.withValues(alpha: 0.7),
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: color.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }

  String _formatValue(double value, String unit) {
    if (unit == '%') {
      return value.toStringAsFixed(1);
    } else if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    } else {
      return value.toStringAsFixed(0);
    }
  }
}

// Widget para grupo de KPIs
class FinancialKPIGroup extends StatelessWidget {
  final String title;
  final List<FinancialMetric> metrics;
  final Map<String, dynamic>? chartData;
  final Function(FinancialMetric)? onEdit;
  final Function(FinancialMetric)? onDelete;
  final bool showCharts;
  final bool isLoading;

  const FinancialKPIGroup({
    Key? key,
    required this.title,
    required this.metrics,
    this.chartData,
    this.onEdit,
    this.onDelete,
    this.showCharts = true,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
        ),
        if (metrics.isEmpty)
          Container(
            height: 120,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDarkMode ? Colors.white24 : Colors.grey[300]!,
                style: BorderStyle.solid,
                width: 1,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bar_chart,
                    size: 32,
                    color: isDarkMode ? Colors.white38 : Colors.grey[400],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Nenhuma métrica disponível',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white54 : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          )
        else ...[
          if (metrics.length <= 3)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  for (var i = 0; i < metrics.length; i++) ...[
                    Expanded(
                      child: FinancialKPICard(
                        metric: metrics[i],
                        chartData: chartData,
                        onEdit: onEdit != null ? () => onEdit!(metrics[i]) : null,
                        onDelete: onDelete != null ? () => onDelete!(metrics[i]) : null,
                        showChart: showCharts,
                        isLoading: isLoading,
                      ),
                    ),
                    if (i != metrics.length - 1) const SizedBox(width: 12),
                  ]
                ],
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.0,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: metrics.length,
              itemBuilder: (context, index) {
                final metric = metrics[index];
                return FinancialKPICard(
                  metric: metric,
                  chartData: chartData,
                  onEdit: onEdit != null ? () => onEdit!(metric) : null,
                  onDelete: onDelete != null ? () => onDelete!(metric) : null,
                  showChart: showCharts,
                  isLoading: isLoading,
                );
              },
            ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}
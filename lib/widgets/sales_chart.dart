import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../design/design_tokens.dart';
import '../utils/responsive_utils.dart';
import '../providers/monthly_sales_provider.dart';
import '../utils/currency_utils.dart';

class SalesChart extends ConsumerWidget {
  const SalesChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final monthlyData = ref.watch(monthlySalesProvider);
    
    if (monthlyData.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (monthlyData.errorMessage != null) {
      return Center(
        child: Column(
          children: [
            Icon(Icons.error, color: Colors.red, size: 32),
            const SizedBox(height: 8),
            Text(
              'Erro ao carregar vendas',
              style: DesignTokens.bodySmall,
            ),
          ],
        ),
      );
    }

    // Preparar dados para o gráfico
    final revenueSpots2024 = <FlSpot>[];
    final revenueSpots2025 = <FlSpot>[];
    double maxValue = 0;

    // Dados de 2024
    for (final month in monthlyData.monthlySales2024) {
      revenueSpots2024.add(FlSpot(month.month.toDouble(), month.revenue));
      if (month.revenue > maxValue) maxValue = month.revenue;
    }

    // Dados de 2025
    for (final month in monthlyData.monthlySales2025) {
      revenueSpots2025.add(FlSpot(month.month.toDouble(), month.revenue));
      if (month.revenue > maxValue) maxValue = month.revenue;
    }

    // Se não há dados, usar valores padrão
    if (revenueSpots2024.isEmpty && revenueSpots2025.isEmpty) {
      revenueSpots2024.addAll([
        const FlSpot(1, 0),
        const FlSpot(2, 0),
        const FlSpot(3, 0),
        const FlSpot(4, 0),
        const FlSpot(5, 0),
      ]);
      maxValue = 1000;
    }

    // Calcular crescimento percentual (2025 vs 2024)
    double growthPercentage = 0.0;
    if (monthlyData.totalRevenue2024 > 0) {
      growthPercentage = ((monthlyData.totalRevenue2025 - monthlyData.totalRevenue2024) / monthlyData.totalRevenue2024) * 100;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header responsivo
        if (isMobile) ...[
          // Layout mobile - empilhado
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'COMPARAÇÃO 2024 vs 2025',
                style: DesignTokens.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: DesignTokens.spacing8),
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4ECDC4),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: DesignTokens.spacing8),
                  Text(
                    '2024',
                    style: DesignTokens.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(width: DesignTokens.spacing16),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Color(0xFF6C5CE7),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: DesignTokens.spacing8),
                  Text(
                    '2025',
                    style: DesignTokens.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DesignTokens.spacing8),
              Row(
                children: [
                  Text(
                    '${growthPercentage.toStringAsFixed(1)}%',
                    style: DesignTokens.titleLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: growthPercentage >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                  const SizedBox(width: DesignTokens.spacing4),
                  Icon(
                    growthPercentage >= 0 ? Icons.trending_up : Icons.trending_down,
                    color: growthPercentage >= 0 ? Colors.green : Colors.red,
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ] else ...[
          // Layout desktop - lado a lado
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'COMPARAÇÃO 2024 vs 2025',
                      style: DesignTokens.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.spacing4),
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Color(0xFF4ECDC4),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: DesignTokens.spacing8),
                        Text(
                          '2024',
                          style: DesignTokens.bodySmall.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(width: DesignTokens.spacing16),
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Color(0xFF6C5CE7),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: DesignTokens.spacing8),
                        Text(
                          '2025',
                          style: DesignTokens.bodySmall.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Text(
                    '${growthPercentage.toStringAsFixed(1)}%',
                    style: DesignTokens.titleLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: growthPercentage >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                  const SizedBox(width: DesignTokens.spacing4),
                  Icon(
                    growthPercentage >= 0 ? Icons.trending_up : Icons.trending_down,
                    color: growthPercentage >= 0 ? Colors.green : Colors.red,
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ],
        const SizedBox(height: DesignTokens.spacing24),
        Expanded(
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxValue / 4,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                    strokeWidth: 1,
                  );
                },
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: 1,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      const style = TextStyle(
                        color: Color(0xff68737d),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      );
                      Widget text;
                      switch (value.toInt()) {
                        case 1:
                          text = const Text('Jan', style: style);
                          break;
                        case 2:
                          text = const Text('Feb', style: style);
                          break;
                        case 3:
                          text = const Text('Mar', style: style);
                          break;
                        case 4:
                          text = const Text('Apr', style: style);
                          break;
                        case 5:
                          text = const Text('May', style: style);
                          break;
                        case 6:
                          text = const Text('Jun', style: style);
                          break;
                        case 7:
                          text = const Text('Jul', style: style);
                          break;
                        case 8:
                          text = const Text('Aug', style: style);
                          break;
                        case 9:
                          text = const Text('Sep', style: style);
                          break;
                        case 10:
                          text = const Text('Oct', style: style);
                          break;
                        case 11:
                          text = const Text('Nov', style: style);
                          break;
                        case 12:
                          text = const Text('Dec', style: style);
                          break;
                        default:
                          text = const Text('', style: style);
                          break;
                      }
                      return SideTitleWidget(
                        meta: meta,
                        space: 4,
                        child: text,
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: maxValue / 4,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Text(
                          CurrencyUtils.formatCompactCurrency(value),
                          style: const TextStyle(
                            color: Color(0xff68737d),
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      );
                    },
                    reservedSize: 80,
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: 1,
              maxX: 12,
              minY: 0,
              maxY: maxValue * 1.1,
              lineBarsData: [
                // Linha 2024
                LineChartBarData(
                  spots: revenueSpots2024,
                  isCurved: true,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF4ECDC4).withValues(alpha: 0.8),
                      const Color(0xFF4ECDC4).withValues(alpha: 0.3),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF4ECDC4).withValues(alpha: 0.3),
                        const Color(0xFF4ECDC4).withValues(alpha: 0.1),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                // Linha 2025
                LineChartBarData(
                  spots: revenueSpots2025,
                  isCurved: true,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF6C5CE7).withValues(alpha: 0.8),
                      const Color(0xFF6C5CE7).withValues(alpha: 0.3),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF6C5CE7).withValues(alpha: 0.3),
                        const Color(0xFF6C5CE7).withValues(alpha: 0.1),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}


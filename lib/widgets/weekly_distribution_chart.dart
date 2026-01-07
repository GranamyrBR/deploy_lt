import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/weekly_distribution_provider.dart';
import '../utils/currency_utils.dart';

class WeeklyDistributionChart extends ConsumerWidget {
  const WeeklyDistributionChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weeklyData = ref.watch(weeklyDistributionProvider);
    
    // Obter dados semanais
    final weeklyRevenue = weeklyData.weeklyData;
    final bestDay = weeklyData.bestDay;
    
    // Calcular valores para o chart (normalizar para porcentagem)
    final maxRevenue = weeklyRevenue.values.isNotEmpty ? weeklyRevenue.values.reduce((a, b) => a > b ? a : b) : 0.0;
    final chartData = [
      weeklyRevenue['Segunda'] ?? 0.0,
      weeklyRevenue['Terça'] ?? 0.0,
      weeklyRevenue['Quarta'] ?? 0.0,
      weeklyRevenue['Quinta'] ?? 0.0,
      weeklyRevenue['Sexta'] ?? 0.0,
      weeklyRevenue['Sábado'] ?? 0.0,
      weeklyRevenue['Domingo'] ?? 0.0,
    ];
    
    // Normalizar para porcentagem (0-100)
    final normalizedData = maxRevenue > 0 
        ? chartData.map((value) => (value / maxRevenue) * 100).toList()
        : List.filled(7, 0.0);

    final hasData = weeklyData.weeklyData.values.any((v) => v > 0);
    return weeklyData.isLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Total: ${CurrencyUtils.formatCompactCurrency(weeklyData.totalRevenue)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4ECDC4).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Média: ${CurrencyUtils.formatCompactCurrency(weeklyData.averageRevenue)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF4ECDC4),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (weeklyData.bestDay.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Melhor: ${weeklyData.bestDay}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (weeklyData.worstDay.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Pior: ${weeklyData.worstDay}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ClipRect(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: hasData
                        ? BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: 100,
                            minY: 0,
                            gridData: const FlGridData(show: false),
                          barTouchData: BarTouchData(
                            enabled: true,
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipColor: (group) => Theme.of(context).colorScheme.surface,
                              tooltipBorder: BorderSide(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                final dayNames = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
                                final actualValue = chartData[group.x];
                                return BarTooltipItem(
                                  '${dayNames[group.x]}\n${CurrencyUtils.formatCompactCurrency(actualValue)}',
                                  TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              },
                            ),
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 26,
                                getTitlesWidget: (double value, TitleMeta meta) {
                                  const style = TextStyle(
                                    color: Color(0xff68737d),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10,
                                  );
                                  Widget text;
                                  switch (value.toInt()) {
                                    case 0:
                                      text = const Text('Seg', style: style);
                                      break;
                                    case 1:
                                      text = const Text('Ter', style: style);
                                      break;
                                    case 2:
                                      text = const Text('Qua', style: style);
                                      break;
                                    case 3:
                                      text = const Text('Qui', style: style);
                                      break;
                                    case 4:
                                      text = const Text('Sex', style: style);
                                      break;
                                    case 5:
                                      text = const Text('Sáb', style: style);
                                      break;
                                    case 6:
                                      text = const Text('Dom', style: style);
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
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: List.generate(7, (index) {
                            final value = normalizedData[index];
                            final isBestDay = index == _getDayIndex(bestDay);
                            return BarChartGroupData(
                              x: index,
                              barRods: [
                                BarChartRodData(
                                  toY: value.isNaN ? 0.0 : value,
                                  color: isBestDay 
                                      ? const Color(0xFF4ECDC4)
                                      : const Color(0xFF6C5CE7).withValues(alpha: 0.7),
                                  width: 16,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ],
                            );
                          }),
                        ),
                      )
                        : Center(
                            child: Text(
                              'Sem dados semanais',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ),
                  ),
                ),
              ),
            ],
          );
  }

  int _getDayIndex(String dayName) {
    switch (dayName) {
      case 'Segunda':
        return 0;
      case 'Terça':
        return 1;
      case 'Quarta':
        return 2;
      case 'Quinta':
        return 3;
      case 'Sexta':
        return 4;
      case 'Sábado':
        return 5;
      case 'Domingo':
        return 6;
      default:
        return 0;
    }
  }
}


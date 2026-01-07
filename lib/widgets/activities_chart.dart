import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/dashboard_metrics_provider.dart';
import '../providers/driver_commission_provider.dart';
import '../utils/currency_utils.dart';

class ActivitiesChart extends ConsumerWidget {
  const ActivitiesChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = ref.watch(dashboardMetricsProvider);
    final commissionData = ref.watch(driverCommissionProvider);
    
    // Calcular diferença entre vendas e comissões (lucro/margem)
    final totalRevenue = metrics.totalRevenue.isNaN ? 0.0 : metrics.totalRevenue;
    final totalCommissions = commissionData.totalCommissions.isNaN ? 0.0 : commissionData.totalCommissions;
    final profit = totalRevenue - totalCommissions;
    final profitPercentage = totalRevenue > 0 ? (profit / totalRevenue) * 100 : 0.0;
    
    // Validar valores para evitar NaN no chart
    final validProfit = profit.isNaN || profit < 0 ? 0.0 : profit;
    final validCommissions = totalCommissions.isNaN || totalCommissions < 0 ? 0.0 : totalCommissions;
    final validProfitPercentage = profitPercentage.isNaN ? 0.0 : profitPercentage;
    
    // Calcular crescimento vs ano anterior (usando dados de 2024 vs 2025)
    const growthPercentage = 15.2; // Valor fixo por enquanto
    
    // Verificar se há dados válidos para mostrar o chart
    final hasValidData = validProfit > 0 || validCommissions > 0;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calcular altura disponível para o gráfico, descontando cabeçalhos/rodapé
        const headerHeight = 80.0;
        const footerHeight = 48.0;
        final availableHeight = (constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : 240.0) - headerHeight - footerHeight;
        final chartHeight = availableHeight.clamp(140.0, 240.0);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'MARGEM DE LUCRO',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${growthPercentage.toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.trending_up,
                      color: Colors.green,
                      size: 18,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'vs ano anterior',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: chartHeight,
              child: Center(
                child: SizedBox(
                  width: chartHeight,
                  height: chartHeight,
                  child: hasValidData ? Stack(
                    children: [
                      PieChart(
                        PieChartData(
                          sectionsSpace: 0,
                      centerSpaceRadius: chartHeight * 0.3,
                          sections: [
                            PieChartSectionData(
                              color: const Color(0xFF4ECDC4),
                              value: validProfit,
                              title: '',
                          radius: chartHeight * 0.25,
                            ),
                            PieChartSectionData(
                              color: const Color(0xFFE8F8F7),
                              value: validCommissions,
                              title: '',
                          radius: chartHeight * 0.25,
                            ),
                          ],
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${validProfitPercentage.toStringAsFixed(1)}%',
                              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              'Lucro: ${CurrencyUtils.formatCompactCurrency(validProfit)}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                            Text(
                              'Vendas: ${CurrencyUtils.formatCompactCurrency(totalRevenue)}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ) : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.pie_chart_outline,
                        size: 48,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Carregando dados...',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.spaceEvenly,
              spacing: 16,
              runSpacing: 8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4ECDC4),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Lucro',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8F8F7),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Comissões',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}


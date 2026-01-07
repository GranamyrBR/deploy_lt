import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../design/design_tokens.dart';
import '../utils/currency_utils.dart';
import '../utils/responsive_utils.dart';
import '../widgets/base_components.dart';
import '../widgets/metric_card.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import '../providers/seller_mock_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/digital_clock_widget.dart';
import '../providers/exchange_rate_provider.dart';
import '../widgets/seller_dashboard_content_drag.dart';
import '../widgets/seller_negotiation_timeline.dart';

class SellerDashboardScreen extends ConsumerWidget {
  const SellerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mock = ref.watch(sellerMockProvider);
    final period = ref.watch(sellerPeriodProvider);
    final needsCompact = ResponsiveUtils.needsCompactLayout(context);
    final padding =
        needsCompact ? const EdgeInsets.all(12) : const EdgeInsets.all(16);
    return SingleChildScrollView(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, mock, ref),
          const SizedBox(height: 12),
          _buildToolbar(context, ref, period),
          const SizedBox(height: 12),
          _buildKpiChips(context, mock, period),
          const SizedBox(height: 12),
          const DigitalClockWidget(compact: true),
          _buildMetricCards(context, mock),
          const SizedBox(height: 12),
          _buildCharts(context, mock, period),
          const SizedBox(height: 12),
          _buildFunnel(context, mock),
          const SizedBox(height: 12),
          _buildNegotiationTimeline(context, mock),
          const SizedBox(height: 12),
          _buildRankings(context, mock, period),
        ],
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, SellerMockData mock, WidgetRef ref) {
    final rate = ref.watch(tourismDollarRateProvider);
    final authState = ref.watch(authProvider);
    final displayName = authState.user?.name ?? mock.sellerName;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: DesignTokens.primaryBlue,
              child: Text(
                _initialsFromName(displayName),
                style: DesignTokens.titleMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dashboard do Vendedor',
                  style: DesignTokens.headlineLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      displayName,
                      style: DesignTokens.bodyLarge.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.attach_money,
                              size: 16, color: Color(0xFF10B981)),
                          const SizedBox(width: 4),
                          Text(
                            'USD/BRL: ${CurrencyUtils.formatCompactCurrency(rate)}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        Row(
          children: [
            ModernButton(
              text: 'Atualizar',
              onPressed: () {
                ref.invalidate(exchangeRateProvider);
                ref.invalidate(sellerMockProvider);
              },
              variant: ButtonVariant.secondary,
              size: ButtonSize.medium,
              icon: Icons.refresh,
            ),
          ],
        ),
      ],
    );
  }

  String _initialsFromName(String name) {
    final parts = name.trim().split(RegExp(r"\s+"));
    if (parts.isEmpty) return 'VD';
    final first = parts.first.isNotEmpty ? parts.first[0] : '';
    final second = parts.length > 1 && parts[1].isNotEmpty ? parts[1][0] : '';
    final initials = (first + second).toUpperCase();
    return initials.isNotEmpty ? initials : 'VD';
  }

  Widget _buildMetricCards(BuildContext context, SellerMockData mock) {
    final isMobile = ResponsiveUtils.isMobile(context);
    
    if (isMobile) {
      // Mobile: Layout vertical para evitar overflow
      return Column(
        children: [
          MetricCard(
            title: 'Receita Total',
            value: CurrencyUtils.formatCurrency(mock.totalRevenueUsd),
            percentage: 'Descontos: ${CurrencyUtils.formatCompactCurrency(mock.totalDiscountUsd)}',
            isPositive: true,
            color: const Color(0xFF10B981),
            icon: Icons.payments,
            numericValue: mock.totalRevenueUsd,
          ),
          const SizedBox(height: 16),
          MetricCard(
            title: 'Operações',
            value: '${mock.operationsCount}',
            percentage: 'Pendentes: ${mock.pendingOperationsCount}',
            isPositive: true,
            color: const Color(0xFF3B82F6),
            icon: Icons.work,
            numericValue: mock.operationsCount.toDouble(),
          ),
          const SizedBox(height: 16),
          MetricCard(
            title: 'WhatsApp',
            value: '${mock.whatsappConvertedContacts}',
            percentage: 'Comissões: ${CurrencyUtils.formatCompactCurrency(mock.driversCommissionUsd)}',
            isPositive: true,
            color: const Color(0xFF8B5CF6),
            icon: Icons.chat_bubble,
            numericValue: mock.whatsappConvertedContacts.toDouble(),
          ),
        ],
      );
    }
    
    // Desktop/Tablet: Layout responsivo otimizado para MacBook 13"
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        
        // Para telas pequenas (MacBook 13", etc.) - layout em 2 linhas
        if (screenWidth < 1000) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: MetricCard(
                      title: 'Receita Total',
                      value: CurrencyUtils.formatCurrency(mock.totalRevenueUsd),
                      percentage: 'Descontos: ${CurrencyUtils.formatCompactCurrency(mock.totalDiscountUsd)}',
                      isPositive: true,
                      color: const Color(0xFF10B981),
                      icon: Icons.payments,
                      numericValue: mock.totalRevenueUsd,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: MetricCard(
                      title: 'Operações',
                      value: '${mock.operationsCount}',
                      percentage: 'Pendentes: ${mock.pendingOperationsCount}',
                      isPositive: true,
                      color: const Color(0xFF3B82F6),
                      icon: Icons.work,
                      numericValue: mock.operationsCount.toDouble(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: MetricCard(
                      title: 'WhatsApp',
                      value: '${mock.whatsappConvertedContacts}',
                      percentage: 'Comissões: ${CurrencyUtils.formatCompactCurrency(mock.driversCommissionUsd)}',
                      isPositive: true,
                      color: const Color(0xFF8B5CF6),
                      icon: Icons.chat_bubble,
                      numericValue: mock.whatsappConvertedContacts.toDouble(),
                    ),
                  ),
                ],
              ),
            ],
          );
        }
        
        // Para telas maiores - 3 colunas lado a lado
        return Row(
          children: [
            Expanded(
              child: MetricCard(
                title: 'Receita Total',
                value: CurrencyUtils.formatCurrency(mock.totalRevenueUsd),
                percentage: 'Descontos: ${CurrencyUtils.formatCompactCurrency(mock.totalDiscountUsd)}',
                isPositive: true,
                color: const Color(0xFF10B981),
                icon: Icons.payments,
                numericValue: mock.totalRevenueUsd,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: MetricCard(
                title: 'Operações',
                value: '${mock.operationsCount}',
                percentage: 'Pendentes: ${mock.pendingOperationsCount}',
                isPositive: true,
                color: const Color(0xFF3B82F6),
                icon: Icons.work,
                numericValue: mock.operationsCount.toDouble(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: MetricCard(
                title: 'WhatsApp',
                value: '${mock.whatsappConvertedContacts}',
                percentage: 'Comissões: ${CurrencyUtils.formatCompactCurrency(mock.driversCommissionUsd)}',
                isPositive: true,
                color: const Color(0xFF8B5CF6),
                icon: Icons.chat_bubble,
                numericValue: mock.whatsappConvertedContacts.toDouble(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildKpiChips(
      BuildContext context, SellerMockData mock, String period) {
    final revenueTotal = _filterSeries(mock.monthlyRevenue, period)
        .fold<double>(0.0, (sum, p) => sum + p.value);
    final discountTotal = _filterSeries(mock.discountBreakdown, period)
        .fold<double>(0.0, (sum, p) => sum + p.value);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
        children: [
          _chip(
              context,
              Icons.payments,
              'Receita',
              CurrencyUtils.formatCompactCurrency(
                  revenueTotal > 0 ? revenueTotal : mock.totalRevenueUsd),
              const Color(0xFF10B981)),
          _chip(
              context,
              Icons.local_offer,
              'Descontos',
              CurrencyUtils.formatCompactCurrency(
                  discountTotal > 0 ? discountTotal : mock.totalDiscountUsd),
              const Color(0xFFFF9F1C)),
          _chip(context, Icons.work, 'Operações', '${mock.operationsCount}',
              const Color(0xFF3B82F6)),
          _chip(context, Icons.pending_actions, 'Pendentes',
              '${mock.pendingOperationsCount}', const Color(0xFFEF4444)),
          _chip(context, Icons.chat_bubble, 'Conversões WhatsApp',
              '${mock.whatsappConvertedContacts}', const Color(0xFF8B5CF6)),
          _chip(
              context,
              Icons.directions_car,
              'Comissões Motoristas',
              CurrencyUtils.formatCompactCurrency(mock.driversCommissionUsd),
              const Color(0xFF6C5CE7)),
          const SizedBox(width: 8),
        ],
      );
    }

  Widget _chip(BuildContext context, IconData icon, String label, String value,
      Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            '$label:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return const SizedBox.shrink();
  }

  List<SellerMetricPoint> _filterSeries(
      List<SellerMetricPoint> series, String period) {
    if (period == '30D') {
      return series.isNotEmpty ? [series.last] : [];
    } else if (period == '90D') {
      final count = series.length;
      final start = count >= 3 ? count - 3 : 0;
      return series.sublist(start);
    }
    return series;
  }

  Widget _buildPeriodSelector(
      BuildContext context, WidgetRef ref, String period) {
    final options = ['30D', '90D', 'YTD'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...options.map((opt) {
            final selected = period == opt;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(opt),
                selected: selected,
                onSelected: (_) =>
                    ref.read(sellerPeriodProvider.notifier).state = opt,
              ),
            );
          }).toList(),
          const SizedBox(width: 12),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              avatar: const Icon(Icons.add, size: 16),
              label: const Text('Nova Venda'),
              onPressed: () {},
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              avatar: const Icon(Icons.upload, size: 16),
              label: const Text('Importar Leads'),
              onPressed: () {},
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              avatar: const Icon(Icons.chat_bubble, size: 16),
              label: const Text('Enviar WhatsApp'),
              onPressed: () {},
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              avatar: const Icon(Icons.dashboard, size: 16),
              label: const Text('Kanban/To-do'),
              onPressed: () => Navigator.of(context).pushNamed('/seller-kanban'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(BuildContext context, WidgetRef ref, String period) {
    return _buildActionsMenu(context, ref, period);
  }
  
  Widget _buildActionsMenu(BuildContext context, WidgetRef ref, String period) {
    return Align(
      alignment: Alignment.centerRight,
      child: PopupMenuButton<String>(
        icon: const Icon(Icons.menu),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        itemBuilder: (context) => [
          const PopupMenuItem<String>(
            value: 'period_30D',
            child: Text('Período: 30D'),
          ),
          const PopupMenuItem<String>(
            value: 'period_90D',
            child: Text('Período: 90D'),
          ),
          const PopupMenuItem<String>(
            value: 'period_YTD',
            child: Text('Período: YTD'),
          ),
          const PopupMenuDivider(),
          const PopupMenuItem<String>(
            value: 'new_sale',
            child: Text('Nova Venda'),
          ),
          const PopupMenuItem<String>(
            value: 'import_leads',
            child: Text('Importar Leads'),
          ),
          const PopupMenuItem<String>(
            value: 'send_whatsapp',
            child: Text('Enviar WhatsApp'),
          ),
          const PopupMenuItem<String>(
            value: 'kanban_todo',
            child: Text('Kanban/To-do'),
          ),
        ],
        onSelected: (value) {
          switch (value) {
            case 'period_30D':
              ref.read(sellerPeriodProvider.notifier).state = '30D';
              break;
            case 'period_90D':
              ref.read(sellerPeriodProvider.notifier).state = '90D';
              break;
            case 'period_YTD':
              ref.read(sellerPeriodProvider.notifier).state = 'YTD';
              break;
            case 'new_sale':
              break;
            case 'import_leads':
              break;
            case 'send_whatsapp':
              break;
            case 'kanban_todo':
              Navigator.of(context).pushNamed('/seller-kanban');
              break;
          }
        },
      ),
    );
  }

  Widget _buildCharts(
      BuildContext context, SellerMockData mock, String period) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: ModernCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Receita Mensal',
                    style: DesignTokens.titleLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 320,
                    child: SfCartesianChart(
                      primaryXAxis: CategoryAxis(),
                      primaryYAxis: NumericAxis(),
                      tooltipBehavior: TooltipBehavior(enable: true),
                      series: <ColumnSeries<SellerMetricPoint, String>>[
                        ColumnSeries<SellerMetricPoint, String>(
                          dataSource:
                              _filterSeries(mock.monthlyRevenue, period),
                          xValueMapper: (p, _) => p.label,
                          yValueMapper: (p, _) => p.value,
                          color: const Color(0xFF10B981),
                          borderRadius:
                              const BorderRadius.all(Radius.circular(6)),
                          dataLabelSettings: const DataLabelSettings(
                            isVisible: true,
                            labelPosition: ChartDataLabelPosition.outside,
                            textStyle: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                          width: 0.6,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 1,
          child: ModernCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Descontos',
                    style: DesignTokens.titleLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 260,
                    child: SfCircularChart(
                      legend: const Legend(
                        isVisible: true,
                        position: LegendPosition.bottom,
                        overflowMode: LegendItemOverflowMode.wrap,
                      ),
                      annotations: <CircularChartAnnotation>[
                        CircularChartAnnotation(
                          widget: Builder(
                            builder: (context) {
                              final filtered =
                                  _filterSeries(mock.discountBreakdown, period);
                              final total = filtered.fold<double>(
                                  0.0, (sum, p) => sum + p.value);
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Descontos',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall),
                                  Text(
                                    CurrencyUtils.formatCompactCurrency(total),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                      series: <DoughnutSeries<SellerMetricPoint, String>>[
                        DoughnutSeries<SellerMetricPoint, String>(
                          dataSource:
                              _filterSeries(mock.discountBreakdown, period),
                          xValueMapper: (p, _) => p.label,
                          yValueMapper: (p, _) => p.value,
                          dataLabelMapper: (p, _) =>
                              '${p.label}: ${CurrencyUtils.formatCompactCurrency(p.value)}',
                          dataLabelSettings: const DataLabelSettings(
                            isVisible: true,
                            labelPosition: ChartDataLabelPosition.outside,
                            connectorLineSettings:
                                ConnectorLineSettings(width: 1.5),
                            textStyle: TextStyle(fontSize: 11),
                          ),
                          radius: '85%',
                          innerRadius: '50%',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFunnel(BuildContext context, SellerMockData mock) {
    final palette = const [
      Color(0xFF10B981),
      Color(0xFF3B82F6),
      Color(0xFFFF9F1C),
      Color(0xFF8B5CF6),
    ];
    return ModernCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Funil de Conversão (WhatsApp → Venda)',
              style: DesignTokens.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 260,
              child: SfFunnelChart(
                series: FunnelSeries<SellerMetricPoint, String>(
                  dataSource: mock.conversionFunnel,
                  xValueMapper: (p, _) => p.label,
                  yValueMapper: (p, _) => p.value,
                  dataLabelSettings: const DataLabelSettings(isVisible: true),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<SellerMetricPoint> _filterTop(
      List<SellerMetricPoint> series, String period) {
    if (period == '30D') {
      return series.take(3).toList();
    } else if (period == '90D') {
      return series.take(4).toList();
    }
    return series;
  }

  Widget _buildRankings(
      BuildContext context, SellerMockData mock, String period) {
    final topCustomers = _filterTop(mock.topCustomers, period);
    final topProducts = _filterTop(mock.topProducts, period);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ModernCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Top Clientes',
                    style: DesignTokens.titleLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 240,
                    child: SfCartesianChart(
                      primaryXAxis: CategoryAxis(),
                      primaryYAxis: NumericAxis(isVisible: false),
                      series: <BarSeries<SellerMetricPoint, String>>[
                        BarSeries<SellerMetricPoint, String>(
                          dataSource: topCustomers,
                          xValueMapper: (p, _) => p.label,
                          yValueMapper: (p, _) => p.value,
                          dataLabelMapper: (p, _) =>
                              CurrencyUtils.formatCompactCurrency(p.value),
                          dataLabelSettings:
                              const DataLabelSettings(isVisible: true),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ModernCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Top Produtos',
                    style: DesignTokens.titleLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 240,
                    child: SfCartesianChart(
                      primaryXAxis: CategoryAxis(),
                      primaryYAxis: NumericAxis(isVisible: false),
                      series: <BarSeries<SellerMetricPoint, String>>[
                        BarSeries<SellerMetricPoint, String>(
                          dataSource: topProducts,
                          xValueMapper: (p, _) => p.label,
                          yValueMapper: (p, _) => p.value,
                          dataLabelMapper: (p, _) =>
                              CurrencyUtils.formatCompactCurrency(p.value),
                          dataLabelSettings:
                              const DataLabelSettings(isVisible: true),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNegotiationTimeline(BuildContext context, SellerMockData mock) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 0),
      child: Container(
        height: 400, // Altura fixa para evitar overflow
        child: SellerNegotiationTimeline(
          sellerId: mock.sellerId,
        ),
      ),
    );
  }
}

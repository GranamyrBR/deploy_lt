import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../design/design_tokens.dart';
import '../utils/responsive_utils.dart';
import '../utils/currency_utils.dart';
import 'base_components.dart';
import 'metric_card.dart';
import 'sales_chart.dart';
import 'activities_chart.dart';
import 'resource_distribution_table.dart';
import 'weekly_distribution_chart.dart';
import '../providers/dashboard_metrics_provider.dart';
import '../providers/driver_commission_provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';


class DashboardContent extends ConsumerWidget {
  const DashboardContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final isTablet = ResponsiveUtils.isTablet(context);
    final needsCompact = ResponsiveUtils.needsCompactLayout(context);
    
    // Ajusta espaçamentos baseado no layout compacto
    final padding = needsCompact ? const EdgeInsets.all(12) : const EdgeInsets.all(16);
    final spacing = needsCompact ? 16.0 : 32.0;
    
    return SingleChildScrollView(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(context, isMobile, ref),
          SizedBox(height: spacing),

          // Metric Cards
          _buildMetricCards(context, isMobile, isTablet, ref),
          SizedBox(height: spacing),

          // Charts Section
          _buildChartsSection(context, isMobile, isTablet),
          SizedBox(height: spacing),

          // Bottom Section
          _buildBottomSection(context, isMobile, isTablet),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isMobile, WidgetRef ref) {
    return ResponsiveWidget(
      mobile: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: DesignTokens.primaryBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'web/icons/lecotour.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.directions_car,
                        color: Colors.white,
                        size: 24,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dashboard Lecotour',
                      style: DesignTokens.headlineMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Visão Geral dos Serviços',
                      style: DesignTokens.bodyMedium.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ModernButton(
                  text: 'Atualizar',
                  onPressed: () {
                    ref.read(dashboardMetricsProvider.notifier).fetchMetrics();
                    ref.read(driverCommissionProvider.notifier).fetchCommissionData();
                  },
                  variant: ButtonVariant.secondary,
                  size: ButtonSize.medium,
                  icon: Icons.refresh,
                ),
              ),
              const SizedBox(width: 12),
              ModernButton(
                text: 'Mais',
                onPressed: () {},
                variant: ButtonVariant.ghost,
                size: ButtonSize.medium,
                icon: Icons.more_vert,
              ),
            ],
          ),
        ],
      ),
      desktop: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: DesignTokens.primaryBlue,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'web/icons/lecotour.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.directions_car,
                        color: Colors.white,
                        size: 28,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dashboard Lecotour',
                    style: DesignTokens.headlineLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    'Visão Geral dos Serviços',
                    style: DesignTokens.bodyLarge.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
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
                  ref.read(dashboardMetricsProvider.notifier).fetchMetrics();
                  ref.read(driverCommissionProvider.notifier).fetchCommissionData();
                },
                variant: ButtonVariant.secondary,
                size: ButtonSize.medium,
                icon: Icons.refresh,
              ),
              const SizedBox(width: 12),
              ModernButton(
                text: 'Mais',
                onPressed: () {},
                variant: ButtonVariant.ghost,
                size: ButtonSize.medium,
                icon: Icons.more_vert,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCards(BuildContext context, bool isMobile, bool isTablet, WidgetRef ref) {
    final metrics = ref.watch(dashboardMetricsProvider);
    final commissionData = ref.watch(driverCommissionProvider);
    
    if (metrics.isLoading || commissionData.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (metrics.errorMessage != null) {
      return Center(
        child: Column(
          children: [
            Icon(Icons.error, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Erro ao carregar métricas',
              style: DesignTokens.titleMedium,
            ),
            Text(
              metrics.errorMessage!,
              style: DesignTokens.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ModernButton(
              text: 'Tentar Novamente',
              onPressed: () => ref.read(dashboardMetricsProvider.notifier).fetchMetrics(),
              variant: ButtonVariant.primary,
            ),
          ],
        ),
      );
    }

    if (isMobile) {
      // Em mobile, mostrar cards em Column para evitar overflow
      return Column(
        children: [
          MetricCard(
            title: 'Receita Total',
            value: CurrencyUtils.formatCurrency(metrics.totalRevenue),
            percentage: '${metrics.totalSales} vendas concluídas',
            isPositive: true,
            color: const Color(0xFF10B981),
            icon: Icons.trending_up,
            numericValue: metrics.totalRevenue,
          ),
          const SizedBox(height: 20),
          MetricCard(
            title: 'Comissões Motoristas',
            value: CurrencyUtils.formatCurrency(commissionData.totalCommissions),
            percentage: '${commissionData.driversWithCommissions} motoristas ativos',
            isPositive: true,
            color: const Color(0xFF8B5CF6),
            icon: Icons.attach_money,
            numericValue: commissionData.totalCommissions,
          ),
          const SizedBox(height: 20),
          MetricCard(
            title: 'Operações Realizadas',
            value: '${metrics.totalOperations}',
            percentage: '${metrics.totalContacts} contatos efetivos',
            isPositive: true,
            color: const Color(0xFFF59E0B),
            icon: Icons.business_center,
            numericValue: metrics.totalOperations.toDouble(),
          ),
        ],
      );
    } else {
      // Layout otimizado para MacBook 13" e telas pequenas
      return LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          
          // Para telas pequenas (MacBook 13", tablets, etc.)
          if (screenWidth < 1200) {
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: MetricCard(
                        title: 'Receita Total',
                        value: CurrencyUtils.formatCurrency(metrics.totalRevenue),
                        percentage: '${metrics.totalSales} vendas concluídas',
                        isPositive: true,
                        color: const Color(0xFF10B981),
                        icon: Icons.trending_up,
                        numericValue: metrics.totalRevenue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: MetricCard(
                        title: 'Comissões Motoristas',
                        value: CurrencyUtils.formatCurrency(commissionData.totalCommissions),
                        percentage: '${commissionData.driversWithCommissions} motoristas ativos',
                        isPositive: true,
                        color: const Color(0xFF8B5CF6),
                        icon: Icons.attach_money,
                        numericValue: commissionData.totalCommissions,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: MetricCard(
                        title: 'Operações Realizadas',
                        value: '${metrics.totalOperations}',
                        percentage: '${metrics.totalContacts} contatos efetivos',
                        isPositive: true,
                        color: const Color(0xFFF59E0B),
                        icon: Icons.business_center,
                        numericValue: metrics.totalOperations.toDouble(),
                      ),
                    ),
                  ],
                ),
              ],
            );
          }
          
          // Para telas maiores (desktops)
          return Row(
            children: [
              Expanded(
                child: MetricCard(
                  title: 'Receita Total',
                  value: CurrencyUtils.formatCurrency(metrics.totalRevenue),
                  percentage: '${metrics.totalSales} vendas concluídas',
                  isPositive: true,
                  color: const Color(0xFF10B981),
                  icon: Icons.trending_up,
                  numericValue: metrics.totalRevenue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: MetricCard(
                  title: 'Comissões Motoristas',
                  value: CurrencyUtils.formatCurrency(commissionData.totalCommissions),
                  percentage: '${commissionData.driversWithCommissions} motoristas ativos',
                  isPositive: true,
                  color: const Color(0xFF8B5CF6),
                  icon: Icons.attach_money,
                  numericValue: commissionData.totalCommissions,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: MetricCard(
                  title: 'Operações Realizadas',
                  value: '${metrics.totalOperations}',
                  percentage: '${metrics.totalContacts} contatos efetivos',
                  isPositive: true,
                  color: const Color(0xFFF59E0B),
                  icon: Icons.business_center,
                  numericValue: metrics.totalOperations.toDouble(),
                ),
              ),
            ],
          );
        },
      );
    }
  }

  Widget _buildChartsSection(BuildContext context, bool isMobile, bool isTablet) {
    if (isMobile) {
      return Column(
        children: [
          _buildSalesChart(context),
          const SizedBox(height: 24),
          _buildActivitiesChart(context),
        ],
      );
    } else {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: _buildSalesChart(context),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 1,
            child: _buildActivitiesChart(context),
          ),
        ],
      );
    }
  }

  Widget _buildSalesChart(BuildContext context) {
    return ModernCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'COMPARAÇÃO 2024 vs 2025',
              style: DesignTokens.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: ResponsiveUtils.getContainerHeight(
                context,
                mobile: 300,
                tablet: 350,
                desktop: 450,
              ),
              child: const SalesChart(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitiesChart(BuildContext context) {
    return ModernCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MARGEM DE LUCRO',
              style: DesignTokens.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: ResponsiveUtils.getContainerHeight(
                context,
                mobile: 300,
                tablet: 350,
                desktop: 450,
              ),
              child: const ActivitiesChart(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSection(BuildContext context, bool isMobile, bool isTablet) {
    if (isMobile) {
      return Column(
        children: [
          _buildResourceDistribution(context),
          const SizedBox(height: DesignTokens.spacing24),
          _buildWeeklyDistribution(context),
        ],
      );
    } else {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: _buildResourceDistribution(context),
          ),
          const SizedBox(width: DesignTokens.spacing24),
          Expanded(
            flex: 1,
            child: _buildWeeklyDistribution(context),
          ),
        ],
      );
    }
  }

  Widget _buildResourceDistribution(BuildContext context) {
    final bottomContentHeight = ResponsiveUtils.getContainerHeight(
      context,
      mobile: 300,
      tablet: 350,
      desktop: 400,
    );
    return ModernCard(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'COMISSÕES DOS MOTORISTAS',
              style: DesignTokens.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: bottomContentHeight,
              child: Consumer(
                builder: (context, ref, child) {
                  final commissionData = ref.watch(driverCommissionProvider);
                  
                  if (commissionData.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (commissionData.errorMessage != null) {
                    return Center(
                      child: Column(
                        children: [
                          Icon(Icons.error, color: Colors.red, size: 32),
                          const SizedBox(height: 8),
                          Text(
                            'Erro ao carregar comissões',
                            style: DesignTokens.bodySmall,
                          ),
                        ],
                      ),
                    );
                  }
                  
                  final topDrivers = commissionData.topDrivers.take(5).toList();
                  final palette = [
                    const Color(0xFF6C5CE7),
                    const Color(0xFF4ECDC4),
                    const Color(0xFFFF9F1C),
                    const Color(0xFF10B981),
                    const Color(0xFFEF4444),
                  ];
                  return Column(
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
                              'Total: ${CurrencyUtils.formatCompactCurrency(commissionData.totalCommissions)}',
                              style: DesignTokens.bodySmall.copyWith(
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
                              'Média: ${CurrencyUtils.formatCompactCurrency(commissionData.averageCommission)}',
                              style: DesignTokens.bodySmall.copyWith(
                                color: const Color(0xFF4ECDC4),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6C5CE7).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Comissão ativa: ${commissionData.driversWithCommissions}',
                              style: DesignTokens.bodySmall.copyWith(
                                color: const Color(0xFF6C5CE7),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 180,
                        child: SfCartesianChart(
                          primaryXAxis: CategoryAxis(
                            isVisible: true,
                            labelRotation: 15,
                          ),
                          primaryYAxis: NumericAxis(isVisible: false),
                          tooltipBehavior: TooltipBehavior(enable: true),
                          series: <ColumnSeries<dynamic, String>>[
                            ColumnSeries<dynamic, String>(
                              dataSource: topDrivers,
                              xValueMapper: (d, _) => d.driverName,
                              yValueMapper: (d, _) => d.commission * 4,
                              pointColorMapper: (d, i) => palette[(i ?? 0) % palette.length].withValues(alpha: 0.9),
                              dataLabelMapper: (d, _) => CurrencyUtils.formatCompactCurrency(d.commission),
                              dataLabelSettings: const DataLabelSettings(
                                isVisible: true,
                                labelPosition: ChartDataLabelPosition.outside,
                                textStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                              width: 0.6,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 160,
                        child: SfCircularChart(
                          legend: const Legend(
                            isVisible: true,
                            position: LegendPosition.bottom,
                            overflowMode: LegendItemOverflowMode.wrap,
                          ),
                          tooltipBehavior: TooltipBehavior(enable: true),
                          series: <DoughnutSeries<dynamic, String>>[
                            DoughnutSeries<dynamic, String>(
                              dataSource: topDrivers,
                              xValueMapper: (d, _) => d.driverName,
                              yValueMapper: (d, _) => d.commission,
                              pointColorMapper: (d, i) => palette[(i ?? 0) % palette.length].withValues(alpha: 0.85),
                              dataLabelMapper: (d, _) => '${d.driverName}: ${CurrencyUtils.formatCompactCurrency(d.commission)}',
                              dataLabelSettings: const DataLabelSettings(
                                isVisible: true,
                                labelPosition: ChartDataLabelPosition.outside,
                                connectorLineSettings: ConnectorLineSettings(width: 1.5),
                                textStyle: TextStyle(fontSize: 11),
                              ),
                              radius: '85%',
                              innerRadius: '40%',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          primary: false,
                          child: _buildCommissionTable(context, commissionData.topDrivers),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommissionTable(BuildContext context, List<DriverCommission> drivers) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(2),
          1: FlexColumnWidth(1),
          2: FlexColumnWidth(1),
          3: FlexColumnWidth(1),
        },
        children: [
          TableRow(
            children: [
              _buildHeaderCell(context, 'MOTORISTA'),
              _buildHeaderCell(context, 'VIAGENS'),
              _buildHeaderCell(context, 'RECEITA'),
              _buildHeaderCell(context, 'COMISSÃO'),
            ],
          ),
          ...drivers.take(5).map((driver) => _buildCommissionRow(context, driver)),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Text(
        text,
        style: DesignTokens.bodySmall.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  TableRow _buildCommissionRow(BuildContext context, DriverCommission driver) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Text(
            driver.driverName,
            style: DesignTokens.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Text(
            '${driver.trips}',
            style: DesignTokens.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Text(
            CurrencyUtils.formatCurrency(driver.totalRevenue),
            style: DesignTokens.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Text(
            CurrencyUtils.formatCurrency(driver.commission),
            style: DesignTokens.bodyMedium.copyWith(
              color: const Color(0xFF8B5CF6),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyDistribution(BuildContext context) {
    final bottomContentHeight = ResponsiveUtils.getContainerHeight(
      context,
      mobile: 300,
      tablet: 350,
      desktop: 400,
    );
    return ModernCard(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'DISTRIBUIÇÃO SEMANAL',
              style: DesignTokens.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: bottomContentHeight,
              child: const WeeklyDistributionChart(),
            ),
          ],
        ),
      ),
    );
  }
}

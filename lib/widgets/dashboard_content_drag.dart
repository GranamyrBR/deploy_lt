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
import '../providers/auth_provider.dart';

class DashboardContentDrag extends ConsumerStatefulWidget {
  const DashboardContentDrag({super.key});

  @override
  ConsumerState<DashboardContentDrag> createState() =>
      _DashboardContentDragState();
}

class _DashboardContentDragState extends ConsumerState<DashboardContentDrag> {
  // Ordem inicial dos cards
  List<String> cardOrder = [
    'revenue',
    'commissions',
    'operations',
    'salesChart',
    'activitiesChart',
    'resourceDistribution',
    'weeklyDistribution'
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final isTablet = ResponsiveUtils.isTablet(context);
    final needsCompact = ResponsiveUtils.needsCompactLayout(context);

    // Ajusta espaçamentos baseado no layout compacto
    final padding =
        needsCompact ? const EdgeInsets.all(12) : const EdgeInsets.all(16);
    final spacing = needsCompact ? 16.0 : 24.0;

    return SingleChildScrollView(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header fixo (não arrastável)
          _buildHeader(context, isMobile, ref),
          SizedBox(height: spacing),

          // Área drag and drop dos cards
          _buildDragDropArea(context, isMobile, isTablet, spacing),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isMobile, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final userName = authState.user?.name ?? 'Usuário';
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
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                      ),
                    ),
                    Text(
                      'Usuário: $userName',
                      style: DesignTokens.labelMedium.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600,
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
                    ref
                        .read(driverCommissionProvider.notifier)
                        .fetchCommissionData();
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
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                ),
              ),
              Text(
                'Usuário: $userName',
                style: DesignTokens.titleSmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w600,
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
                  ref
                      .read(driverCommissionProvider.notifier)
                      .fetchCommissionData();
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

  Widget _buildDragDropArea(
      BuildContext context, bool isMobile, bool isTablet, double spacing) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Layout responsivo baseado na largura disponível
        final crossAxisCount = isMobile ? 1 : (isTablet ? 2 : 3);
        final childAspectRatio = isMobile ? 2.0 : (isTablet ? 1.8 : 1.6);

        return DragTarget<String>(
          onWillAcceptWithDetails: (details) => true,
          onAcceptWithDetails: (details) {
            final draggedCardId = details.data;
            final dropPosition = _getDropPosition(
                details.offset, constraints, crossAxisCount, childAspectRatio);

            setState(() {
              // Reorganizar cards baseado na posição de drop
              final draggedIndex = cardOrder.indexOf(draggedCardId);
              final targetIndex = dropPosition.clamp(0, cardOrder.length - 1);

              if (draggedIndex != -1 && draggedIndex != targetIndex) {
                final draggedCard = cardOrder.removeAt(draggedIndex);
                cardOrder.insert(targetIndex, draggedCard);
              }
            });
          },
          builder: (context, candidateData, rejectedData) {
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: cardOrder.map((cardId) {
                return DraggableCard(
                  cardId: cardId,
                  constraints: constraints,
                  aspectRatio: childAspectRatio,
                  onDragCompleted: () {},
                );
              }).toList(),
            );
          },
        );
      },
    );
  }

  int _getDropPosition(Offset offset, BoxConstraints constraints,
      int crossAxisCount, double childAspectRatio) {
    final cardWidth =
        (constraints.maxWidth - (crossAxisCount - 1) * 16) / crossAxisCount;
    final cardHeight = cardWidth / childAspectRatio;

    final column = (offset.dx / (cardWidth + 16)).floor();
    final row = (offset.dy / (cardHeight + 16)).floor();

    return row * crossAxisCount + column;
  }
}

class DraggableCard extends ConsumerWidget {
  final String cardId;
  final BoxConstraints constraints;
  final double aspectRatio;
  final VoidCallback onDragCompleted;

  const DraggableCard({
    super.key,
    required this.cardId,
    required this.constraints,
    required this.aspectRatio,
    required this.onDragCompleted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = ref.watch(dashboardMetricsProvider);
    final commissionData = ref.watch(driverCommissionProvider);

    return Draggable<String>(
      data: cardId,
      feedback: _buildCardFeedback(context, metrics, commissionData),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: _buildCardContent(context, metrics, commissionData),
      ),
      child: _buildCardContent(context, metrics, commissionData),
    );
  }

  Widget _buildCardContent(BuildContext context, DashboardMetrics metrics,
      DriverCommissionData commissionData) {
    switch (cardId) {
      case 'revenue':
        return MetricCard(
          title: 'Receita Total',
          value: CurrencyUtils.formatCurrency(metrics.totalRevenue),
          percentage: '${metrics.totalSales} vendas concluídas',
          isPositive: true,
          color: const Color(0xFF10B981),
          icon: Icons.trending_up,
          numericValue: metrics.totalRevenue,
        );

      case 'commissions':
        return MetricCard(
          title: 'Comissões Motoristas',
          value: CurrencyUtils.formatCurrency(commissionData.totalCommissions),
          percentage:
              '${commissionData.driversWithCommissions} motoristas ativos',
          isPositive: true,
          color: const Color(0xFF8B5CF6),
          icon: Icons.attach_money,
          numericValue: commissionData.totalCommissions,
        );

      case 'operations':
        return MetricCard(
          title: 'Operações Realizadas',
          value: '${metrics.totalOperations}',
          percentage: '${metrics.totalContacts} contatos efetivos',
          isPositive: true,
          color: const Color(0xFFF59E0B),
          icon: Icons.business_center,
          numericValue: metrics.totalOperations.toDouble(),
        );

      case 'salesChart':
        return SizedBox(
          height: 400,
          child: ModernCard(
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
                  const Expanded(
                    child: SalesChart(),
                  ),
                ],
              ),
            ),
          ),
        );

      case 'activitiesChart':
        return SizedBox(
          height: 400,
          child: ModernCard(
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
                  const Expanded(
                    child: ActivitiesChart(),
                  ),
                ],
              ),
            ),
          ),
        );

      case 'resourceDistribution':
        return SizedBox(
          height: 500,
          child: ModernCard(
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
                  const Expanded(
                    child: ResourceDistributionTable(),
                  ),
                ],
              ),
            ),
          ),
        );

      case 'weeklyDistribution':
        return SizedBox(
          height: 400,
          child: ModernCard(
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
                  const Expanded(
                    child: WeeklyDistributionChart(),
                  ),
                ],
              ),
            ),
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildCardFeedback(BuildContext context, DashboardMetrics metrics,
      DriverCommissionData commissionData) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 200,
        height: 120,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: _buildCardContent(context, metrics, commissionData),
      ),
    );
  }
}
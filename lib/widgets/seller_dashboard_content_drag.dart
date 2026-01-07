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
import '../providers/seller_mock_provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class SellerDashboardContentDrag extends ConsumerStatefulWidget {
  const SellerDashboardContentDrag({super.key});

  @override
  ConsumerState<SellerDashboardContentDrag> createState() => _SellerDashboardContentDragState();
}

class _SellerDashboardContentDragState extends ConsumerState<SellerDashboardContentDrag> {
  // Ordem inicial dos cards do vendedor
  List<String> cardOrder = ['totalRevenue', 'whatsappConversions', 'totalOperations', 'salesChart', 'topSellers', 'recentSales'];
  
  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final isTablet = ResponsiveUtils.isTablet(context);
    final needsCompact = ResponsiveUtils.needsCompactLayout(context);
    
    // Ajusta espaçamentos baseado no layout compacto
    final padding = needsCompact ? const EdgeInsets.all(12) : const EdgeInsets.all(16);
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
                child: const Icon(
                  Icons.person_outline,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dashboard do Vendedor',
                      style: DesignTokens.headlineMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Performance de Vendas',
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
                    // Recarregar dados do mock
                  },
                  variant: ButtonVariant.secondary,
                  size: ButtonSize.medium,
                  icon: Icons.refresh,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ModernButton(
                  text: 'Kanban/To-do',
                  onPressed: () {
                    // Navegar para kanban
                  },
                  variant: ButtonVariant.primary,
                  size: ButtonSize.medium,
                  icon: Icons.table_chart,
                ),
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
                child: const Icon(
                  Icons.person_outline,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 20),
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
                  Text(
                    'Performance de Vendas',
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
                text: 'Enviar WhatsApp',
                onPressed: () {
                  // Ação WhatsApp
                },
                variant: ButtonVariant.secondary,
                size: ButtonSize.medium,
                icon: Icons.chat,
              ),
              const SizedBox(width: 12),
              ModernButton(
                text: 'Kanban/To-do',
                onPressed: () {
                  // Navegar para kanban
                },
                variant: ButtonVariant.primary,
                size: ButtonSize.medium,
                icon: Icons.table_chart,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDragDropArea(BuildContext context, bool isMobile, bool isTablet, double spacing) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Layout responsivo baseado na largura disponível
        final crossAxisCount = isMobile ? 1 : (isTablet ? 2 : 3);
        final childAspectRatio = isMobile ? 2.0 : (isTablet ? 1.8 : 1.6);
        
        return DragTarget<String>(
          onWillAcceptWithDetails: (details) => true,
          onAcceptWithDetails: (details) {
            final draggedCardId = details.data;
            final dropPosition = _getDropPosition(details.offset, constraints, crossAxisCount, childAspectRatio);
            
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
                return DraggableSellerCard(
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

  int _getDropPosition(Offset offset, BoxConstraints constraints, int crossAxisCount, double childAspectRatio) {
    final cardWidth = (constraints.maxWidth - (crossAxisCount - 1) * 16) / crossAxisCount;
    final cardHeight = cardWidth / childAspectRatio;
    
    final column = (offset.dx / (cardWidth + 16)).floor();
    final row = (offset.dy / (cardHeight + 16)).floor();
    
    return row * crossAxisCount + column;
  }
}

class DraggableSellerCard extends ConsumerWidget {
  final String cardId;
  final BoxConstraints constraints;
  final double aspectRatio;
  final VoidCallback onDragCompleted;

  const DraggableSellerCard({
    super.key,
    required this.cardId,
    required this.constraints,
    required this.aspectRatio,
    required this.onDragCompleted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sellerData = ref.watch(sellerMockProvider);
    
    return Draggable<String>(
      data: cardId,
      feedback: _buildCardFeedback(context, sellerData),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: _buildCardContent(context, sellerData),
      ),
      child: _buildCardContent(context, sellerData),
    );
  }

  Widget _buildCardContent(BuildContext context, SellerMockData sellerData) {
    switch (cardId) {
      case 'totalRevenue':
        return MetricCard(
          title: 'Receita Total',
          value: CurrencyUtils.formatCurrency(sellerData.totalRevenueUsd),
          percentage: '${sellerData.operationsCount} vendas realizadas',
          isPositive: true,
          color: const Color(0xFF10B981),
          icon: Icons.trending_up,
          numericValue: sellerData.totalRevenueUsd,
        );
      
      case 'whatsappConversions':
        return MetricCard(
          title: 'Conversões WhatsApp',
          value: '${sellerData.whatsappConvertedContacts}',
          percentage: '${sellerData.operationsCount} operações realizadas',
          isPositive: true,
          color: const Color(0xFF25D366),
          icon: Icons.chat_bubble,
          numericValue: sellerData.whatsappConvertedContacts.toDouble(),
        );
      
      case 'totalOperations':
        return MetricCard(
          title: 'Total de Operações',
          value: '${sellerData.operationsCount}',
          percentage: '${sellerData.pendingOperationsCount} pendentes',
          isPositive: true,
          color: const Color(0xFF8B5CF6),
          icon: Icons.business_center,
          numericValue: sellerData.operationsCount.toDouble(),
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
                    'VENDAS POR MÊS',
                    style: DesignTokens.titleLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: SalesChart(),
                  ),
                ],
              ),
            ),
          ),
        );
      
      case 'topSellers':
        return SizedBox(
          height: 300,
          child: ModernCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DESEMPENHO MENSAL',
                    style: DesignTokens.titleLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _buildMonthlyChart(sellerData.monthlyRevenue),
                  ),
                ],
              ),
            ),
          ),
        );
      
      case 'recentSales':
        return SizedBox(
          height: 300,
          child: ModernCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOP PRODUTOS',
                    style: DesignTokens.titleLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _buildTopProductsList(sellerData.topProducts),
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

  Widget _buildMonthlyChart(List<SellerMetricPoint> monthlyData) {
    return SfCartesianChart(
      primaryXAxis: CategoryAxis(
        isVisible: true,
        labelRotation: -45,
      ),
      primaryYAxis: NumericAxis(isVisible: false),
      tooltipBehavior: TooltipBehavior(enable: true),
      series: <ColumnSeries<SellerMetricPoint, String>>[
        ColumnSeries<SellerMetricPoint, String>(
          dataSource: monthlyData,
          xValueMapper: (SellerMetricPoint point, _) => point.label,
          yValueMapper: (SellerMetricPoint point, _) => point.value,
          color: const Color(0xFF8B5CF6).withValues(alpha: 0.8),
          dataLabelSettings: const DataLabelSettings(
            isVisible: true,
            textStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
          width: 0.6,
        ),
      ],
    );
  }

  Widget _buildTopProductsList(List<SellerMetricPoint> products) {
    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.1),
            child: Icon(
              Icons.star,
              color: const Color(0xFF10B981),
              size: 20,
            ),
          ),
          title: Text(
            product.label,
            style: DesignTokens.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          trailing: Text(
            CurrencyUtils.formatCurrency(product.value),
            style: DesignTokens.bodyMedium.copyWith(
              color: const Color(0xFF10B981),
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardFeedback(BuildContext context, SellerMockData sellerData) {
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
        child: _buildCardContent(context, sellerData),
      ),
    );
  }
}
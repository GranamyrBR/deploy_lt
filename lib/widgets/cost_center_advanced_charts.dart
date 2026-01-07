import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/cost_center.dart';

class CostCenterAdvancedCharts extends StatelessWidget {
  final List<CostCenter> costCenters;

  const CostCenterAdvancedCharts({
    super.key,
    required this.costCenters,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(context, 'Análise Avançada com Gráficos Especializados'),
          const SizedBox(height: 24),
          
          _buildRadarChartSection(context),
          const SizedBox(height: 32),
          
          _buildFunnelChartSection(context),
          const SizedBox(height: 32),
          
          _buildGaugeChartSection(context),
          const SizedBox(height: 32),
          
          _buildTreeMapChartSection(context),
          const SizedBox(height: 32),
          
          _build3DScatterPlotSection(context),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).primaryColor,
      ),
    );
  }

  // Radar Chart para análise multidimensional
  Widget _buildRadarChartSection(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Análise Multidimensional - Radar Chart',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Comparação de desempenho entre centros de custo',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 400,
              child: RadarChart(
                RadarChartData(
                  radarShape: RadarShape.polygon,
                  dataSets: _buildRadarDataSets(),
                  radarBackgroundColor: Colors.transparent,
                  borderData: FlBorderData(show: false),
                  radarBorderData: const BorderSide(color: Colors.grey),
                  titlePositionPercentageOffset: 0.2,
                  titleTextStyle: Theme.of(context).textTheme.bodySmall,
                  tickCount: 5,
                  ticksTextStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                  tickBorderData: const BorderSide(color: Colors.grey),
                  gridBorderData: const BorderSide(color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<RadarDataSet> _buildRadarDataSets() {
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
    ];

    return costCenters.take(5).map((center) {
      final utilizationRate = center.utilizationRate;
      final fixedExpenseRatio = center.budget > 0 ? center.fixedExpenses / center.budget : 0;
      final variableExpenseRatio = center.budget > 0 ? center.variableExpenses / center.budget : 0;
      final efficiency = center.budget > 0 ? (center.budget - center.utilized) / center.budget : 0;
      final approvalRate = center.expenses.isNotEmpty 
          ? center.expenses.where((e) => e.type == ExpenseType.FIXED).length / center.expenses.length 
          : 0;

      return RadarDataSet(
        fillColor: colors[costCenters.indexOf(center) % colors.length].withValues(alpha: 0.3),
        borderColor: colors[costCenters.indexOf(center) % colors.length],
        borderWidth: 2,
        dataEntries: [
          RadarEntry(value: utilizationRate * 100),
          RadarEntry(value: fixedExpenseRatio * 100),
          RadarEntry(value: variableExpenseRatio * 100),
          RadarEntry(value: efficiency * 100),
          RadarEntry(value: approvalRate * 100),
        ],
        entryRadius: 4,
      );
    }).toList();
  }

  // Funnel Chart para análise de conversão de orçamento
  Widget _buildFunnelChartSection(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Análise de Conversão - Funnel Chart',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Fluxo de orçamento desde aprovação até utilização',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: _buildFunnelChart(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFunnelChart() {
    final totalBudget = costCenters.fold(0.0, (sum, center) => sum + center.budget);
    final totalUtilized = costCenters.fold(0.0, (sum, center) => sum + center.utilized);
    final totalFixed = costCenters.fold(0.0, (sum, center) => sum + center.fixedExpenses);
    final totalVariable = costCenters.fold(0.0, (sum, center) => sum + center.variableExpenses);

    final funnelData = [
      {'stage': 'Orçamento Total', 'value': totalBudget, 'color': Colors.blue},
      {'stage': 'Orçamento Aprovado', 'value': totalBudget * 0.9, 'color': Colors.green},
      {'stage': 'Despesas Fixas', 'value': totalFixed, 'color': Colors.orange},
      {'stage': 'Despesas Variáveis', 'value': totalVariable, 'color': Colors.red},
      {'stage': 'Total Utilizado', 'value': totalUtilized, 'color': Colors.purple},
    ];

    return Column(
      children: funnelData.map((data) {
        final percentage = totalBudget > 0 ? (data['value'] as double) / totalBudget : 0;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(data['stage'] as String),
                  Text('R\$ ${(data['value'] as double).toStringAsFixed(2)}'),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                height: 40,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: (data['color'] as Color).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Container(
                      height: 40,
                      width: MediaQueryData.fromView(WidgetsBinding.instance.platformDispatcher.implicitView!).size.width * percentage,
                      decoration: BoxDecoration(
                        color: data['color'] as Color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '${(percentage * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Gauge Chart para KPIs
  Widget _buildGaugeChartSection(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Indicadores de Performance - Gauge Chart',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Métricas-chave de desempenho dos centros de custo',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.2,
              children: [
                _buildGaugeCard('Taxa de Utilização', _calculateAverageUtilization(), Colors.blue),
                _buildGaugeCard('Eficiência de Orçamento', _calculateBudgetEfficiency(), Colors.green),
                _buildGaugeCard('Taxa de Aprovação', _calculateApprovalRate(), Colors.orange),
                _buildGaugeCard('Performance Geral', _calculateOverallPerformance(), Colors.purple),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGaugeCard(String title, double value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 80,
              child: PieChart(
                PieChartData(
                  startDegreeOffset: 270,
                  sectionsSpace: 2,
                  centerSpaceRadius: 30,
                  sections: [
                    PieChartSectionData(
                      color: color.withValues(alpha: 0.3),
                      value: 100 - value,
                      radius: 15,
                      title: '',
                    ),
                    PieChartSectionData(
                      color: color,
                      value: value,
                      radius: 15,
                      title: '',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${value.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // TreeMap Chart para análise hierárquica
  Widget _buildTreeMapChartSection(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Análise Hierárquica - TreeMap Chart',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Distribuição visual do orçamento por centro de custo',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 400,
              child: _buildTreeMapChart(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTreeMapChart() {
    final totalBudget = costCenters.fold(0.0, (sum, center) => sum + center.budget);
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: costCenters.map((center) {
            final percentage = center.budget / totalBudget;
            final area = constraints.maxWidth * constraints.maxHeight * percentage;
            final width = sqrt(area * 1.5);
            final height = area / width;
            
            final index = costCenters.indexOf(center);
            final row = index ~/ 2;
            final col = index % 2;
            
            return Positioned(
              left: col * (constraints.maxWidth / 2),
              top: row * (constraints.maxHeight / ((costCenters.length + 1) ~/ 2)),
              width: constraints.maxWidth / 2 - 4,
              height: (constraints.maxHeight / ((costCenters.length + 1) ~/ 2)) - 4,
              child: Container(
                decoration: BoxDecoration(
                  color: _getColorForIndex(index).withValues(alpha: 0.7),
                  border: Border.all(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      center.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'R\$ ${center.budget.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      '${(percentage * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // 3D Scatter Plot simulado
  Widget _build3DScatterPlotSection(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Análise Tridimensional - 3D Scatter Plot',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Relação entre orçamento, utilização e eficiência',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 400,
              child: _build3DScatterPlot(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _build3DScatterPlot() {
    return ScatterChart(
      ScatterChartData(
        scatterSpots: costCenters.map((center) {
          final x = center.budget / 1000; // Orçamento em milhares
          final y = center.utilized / 1000; // Utilizado em milhares
          final z = center.utilizationRate; // Taxa de utilização como tamanho
          
          return ScatterSpot(
            x,
            y,
            dotPainter: FlDotCirclePainter(
              color: _getColorForPerformance(center.utilizationRate),
              radius: 4 + (z / 20), // Tamanho baseado na taxa de utilização
            ),
          );
        }).toList(),
        minX: 0,
        maxX: costCenters.map((c) => c.budget).reduce((a, b) => a > b ? a : b) / 1000,
        minY: 0,
        maxY: costCenters.map((c) => c.utilized).reduce((a, b) => a > b ? a : b) / 1000,
        borderData: FlBorderData(show: true),
        gridData: const FlGridData(show: true),
        titlesData: const FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: 10,
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: 10,
            ),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
      ),
    );
  }

  // Métodos auxiliares
  double _calculateAverageUtilization() {
    if (costCenters.isEmpty) return 0;
    final total = costCenters.fold(0.0, (sum, center) => sum + center.utilizationRate);
    return (total / costCenters.length) * 100;
  }

  double _calculateBudgetEfficiency() {
    if (costCenters.isEmpty) return 0;
    final totalBudget = costCenters.fold(0.0, (sum, center) => sum + center.budget);
    final totalUtilized = costCenters.fold(0.0, (sum, center) => sum + center.utilized);
    return totalBudget > 0 ? ((totalBudget - totalUtilized) / totalBudget) * 100 : 0;
  }

  double _calculateApprovalRate() {
    if (costCenters.isEmpty) return 0;
    int totalExpenses = 0;
    int approvedExpenses = 0;
    
    for (final center in costCenters) {
      totalExpenses += center.expenses.length;
      approvedExpenses += center.expenses.where((e) => e.type == ExpenseType.FIXED).length;
    }
    
    return totalExpenses > 0 ? (approvedExpenses / totalExpenses) * 100 : 0;
  }

  double _calculateOverallPerformance() {
    final utilization = _calculateAverageUtilization();
    final efficiency = _calculateBudgetEfficiency();
    final approval = _calculateApprovalRate();
    
    return (utilization + efficiency + approval) / 3;
  }

  Color _getColorForIndex(int index) {
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.cyan,
      Colors.amber,
      Colors.brown,
    ];
    return colors[index % colors.length];
  }

  Color _getColorForPerformance(double performance) {
    if (performance >= 80) return Colors.green;
    if (performance >= 60) return Colors.orange;
    return Colors.red;
  }
}
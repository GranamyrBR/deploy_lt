import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/cost_center.dart';

class CostCenterKpiDashboard extends StatelessWidget {
  final List<CostCenter> costCenters;
  
  const CostCenterKpiDashboard({
    super.key,
    required this.costCenters,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard de KPIs - Centros de Custo',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
            const SizedBox(height: 24),
            
            // Cards de KPIs Principais
            _buildKpiCards(context),
            const SizedBox(height: 24),
            
            // Gráficos
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: _buildFixedVariableChart(context)),
                const SizedBox(width: 16),
                Expanded(flex: 1, child: _buildCategoryDistributionChart(context)),
              ],
            ),
            const SizedBox(height: 24),
            
            // Gráfico de Utilização por Centro
            _buildUtilizationChart(context),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCards(BuildContext context) {
    final totalBudget = costCenters.fold(0.0, (sum, cc) => sum + cc.budget);
    final totalUtilized = costCenters.fold(0.0, (sum, cc) => sum + cc.utilized);
    final totalFixed = costCenters.fold(0.0, (sum, cc) => sum + cc.fixedExpenses);
    final totalVariable = costCenters.fold(0.0, (sum, cc) => sum + cc.variableExpenses);

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      childAspectRatio: 1.5,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _buildKpiCard(
          context,
          'Total Orçamento',
          'R\$ ${totalBudget.toStringAsFixed(2)}',
          Icons.account_balance_wallet,
          Colors.green,
        ),
        _buildKpiCard(
          context,
          'Total Utilizado',
          'R\$ ${totalUtilized.toStringAsFixed(2)}',
          Icons.money_off,
          Colors.orange,
        ),
        _buildKpiCard(
          context,
          'Despesas Fixas',
          'R\$ ${totalFixed.toStringAsFixed(2)}',
          Icons.schedule,
          Colors.blue,
        ),
        _buildKpiCard(
          context,
          'Despesas Variáveis',
          'R\$ ${totalVariable.toStringAsFixed(2)}',
          Icons.trending_up,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildKpiCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color.withValues(alpha: 0.8),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFixedVariableChart(BuildContext context) {
    final totalFixed = costCenters.fold(0.0, (sum, cc) => sum + cc.fixedExpenses);
    final totalVariable = costCenters.fold(0.0, (sum, cc) => sum + cc.variableExpenses);
    final total = totalFixed + totalVariable;

    if (total == 0) {
      return _buildEmptyChart(context, 'Sem dados de despesas');
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Distribuição: Fixas vs Variáveis',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      color: Colors.blue,
                      value: (totalFixed / total) * 100,
                      title: 'Fixas\n${((totalFixed / total) * 100).toStringAsFixed(1)}%',
                      radius: 80,
                      titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    PieChartSectionData(
                      color: Colors.orange,
                      value: (totalVariable / total) * 100,
                      title: 'Variáveis\n${((totalVariable / total) * 100).toStringAsFixed(1)}%',
                      radius: 80,
                      titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(Colors.blue, 'Despesas Fixas'),
                const SizedBox(width: 16),
                _buildLegendItem(Colors.orange, 'Despesas Variáveis'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryDistributionChart(BuildContext context) {
    final categoryTotals = <String, double>{};
    
    for (final cc in costCenters) {
      for (final expense in cc.expenses) {
        categoryTotals.update(
          expense.category,
          (value) => value + expense.amount,
          ifAbsent: () => expense.amount,
        );
      }
    }

    if (categoryTotals.isEmpty) {
      return _buildEmptyChart(context, 'Sem categorias');
    }

    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Categorias',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: ListView.builder(
                itemCount: sortedCategories.length.clamp(0, 5),
                itemBuilder: (context, index) {
                  final category = sortedCategories[index];
                  final total = categoryTotals.values.fold(0.0, (sum, value) => sum + value);
                  final percentage = (category.value / total) * 100;
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          color: _getCategoryColor(index),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            category.key,
                            style: Theme.of(context).textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${percentage.toStringAsFixed(1)}%',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUtilizationChart(BuildContext context) {
    if (costCenters.isEmpty) {
      return _buildEmptyChart(context, 'Sem centros de custo');
    }

    final sortedCenters = List<CostCenter>.from(costCenters)
      ..sort((a, b) => b.utilizationPercentage.compareTo(a.utilizationPercentage));

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Utilização do Orçamento por Centro',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < sortedCenters.length) {
                            return Text(
                              sortedCenters[index].name.length > 10
                                  ? '${sortedCenters[index].name.substring(0, 10)}...'
                                  : sortedCenters[index].name,
                              style: Theme.of(context).textTheme.bodySmall,
                            );
                          }
                          return const Text('');
                        },
                        reservedSize: 42,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 20,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) {
                          return Text('${value.toInt()}%');
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: sortedCenters.take(8).toList().asMap().entries.map((entry) {
                    final index = entry.key;
                    final center = entry.value;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: center.utilizationPercentage.clamp(0, 100),
                          color: center.isOverBudget 
                              ? Colors.red 
                              : center.utilizationPercentage > 80
                                  ? Colors.orange
                                  : Colors.green,
                          width: 20,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyChart(BuildContext context, String message) {
    return Card(
      elevation: 2,
      child: Container(
        height: 200,
        alignment: Alignment.center,
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Color _getCategoryColor(int index) {
    final colors = [
      Colors.blue,
      Colors.orange,
      Colors.green,
      Colors.red,
      Colors.purple,
      Colors.teal,
      Colors.amber,
      Colors.indigo,
    ];
    return colors[index % colors.length];
  }
}
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/cost_center.dart';

class CostCenterTemporalDashboard extends StatelessWidget {
  final List<CostCenter> costCenters;

  const CostCenterTemporalDashboard({
    Key? key,
    required this.costCenters,
  }) : super(key: key);



  // Generate budget vs actual comparison data
  List<BarChartGroupData> _generateBudgetVsActualData() {
    return costCenters.asMap().entries.map((entry) {
      final index = entry.key;
      final costCenter = entry.value;
      
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: costCenter.budget,
            color: Colors.blue,
            width: 16,
            borderRadius: BorderRadius.circular(2),
          ),
          BarChartRodData(
            toY: costCenter.utilized,
            color: costCenter.isOverBudget ? Colors.red : Colors.green,
            width: 16,
            borderRadius: BorderRadius.circular(2),
          ),
        ],
      );
    }).toList();
  }

  // Generate expense type distribution over time
  List<LineChartBarData> _generateExpenseTypeTrends() {
    final now = DateTime.now();
    
    // Fixed expenses trend
    final fixedSpots = <FlSpot>[];
    for (int i = 11; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final fixedExpenses = costCenters.expand((cc) => cc.expenses)
          .where((expense) => 
              expense.type == ExpenseType.FIXED &&
              expense.date.year == date.year && 
              expense.date.month == date.month)
          .fold(0.0, (sum, expense) => sum + expense.amount);
      
      fixedSpots.add(FlSpot((11 - i).toDouble(), fixedExpenses));
    }

    // Variable expenses trend
    final variableSpots = <FlSpot>[];
    for (int i = 11; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final variableExpenses = costCenters.expand((cc) => cc.expenses)
          .where((expense) => 
              expense.type == ExpenseType.VARIABLE &&
              expense.date.year == date.year && 
              expense.date.month == date.month)
          .fold(0.0, (sum, expense) => sum + expense.amount);
      
      variableSpots.add(FlSpot((11 - i).toDouble(), variableExpenses));
    }

    return [
      LineChartBarData(
        spots: fixedSpots,
        isCurved: true,
        color: Colors.blue,
        barWidth: 3,
        dotData: FlDotData(show: true),
        belowBarData: BarAreaData(show: true, color: Colors.blue.withValues(alpha: 0.1)),
      ),
      LineChartBarData(
        spots: variableSpots,
        isCurved: true,
        color: Colors.orange,
        barWidth: 3,
        dotData: FlDotData(show: true),
        belowBarData: BarAreaData(show: true, color: Colors.orange.withValues(alpha: 0.1)),
      ),
    ];
  }

  // Generate radar chart data for department performance
  List<RadarDataSet> _generateDepartmentRadarData() {
    final departments = costCenters.map((cc) => cc.department).toSet().toList();
    final departmentData = departments.map((dept) {
      final deptCostCenters = costCenters.where((cc) => cc.department == dept);
      final totalBudget = deptCostCenters.fold(0.0, (sum, cc) => sum + cc.budget);
      final totalUtilized = deptCostCenters.fold(0.0, (sum, cc) => sum + cc.utilized);
      final efficiency = totalBudget > 0 ? (totalUtilized / totalBudget) * 100 : 0.0;
      
      return RadarEntry(value: efficiency);
    }).toList();

    return [
      RadarDataSet(
        dataEntries: departmentData,
        borderColor: Colors.purple,
        borderWidth: 2,
        fillColor: Colors.purple.withValues(alpha: 0.2),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final totalBudget = costCenters.fold(0.0, (sum, cc) => sum + cc.budget);
    final totalUtilized = costCenters.fold(0.0, (sum, cc) => sum + cc.utilized);
    final totalFixed = costCenters.expand((cc) => cc.expenses)
        .where((e) => e.type == ExpenseType.FIXED)
        .fold(0.0, (sum, e) => sum + e.amount);
    final totalVariable = costCenters.expand((cc) => cc.expenses)
        .where((e) => e.type == ExpenseType.VARIABLE)
        .fold(0.0, (sum, e) => sum + e.amount);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Orçamento Total',
                  'R\$ ${totalBudget.toStringAsFixed(2)}',
                  Colors.blue,
                  Icons.account_balance_wallet,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'Total Utilizado',
                  'R\$ ${totalUtilized.toStringAsFixed(2)}',
                  totalUtilized > totalBudget ? Colors.red : Colors.green,
                  Icons.monetization_on,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'Taxa de Utilização',
                  '${((totalUtilized / totalBudget) * 100).toStringAsFixed(1)}%',
                  Colors.orange,
                  Icons.percent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Temporal Expense Trends
          _buildChartCard(
            'Tendências de Despesas por Mês',
            'Evolução das despesas ao longo do tempo',
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text('R\$ ${value.toStringAsFixed(0)}');
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final months = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
                          final monthIndex = value.toInt();
                          if (monthIndex >= 0 && monthIndex < 12) {
                            return Text(months[monthIndex]);
                          }
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: _generateExpenseTypeTrends(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Budget vs Actual Comparison
          _buildChartCard(
            'Comparativo Orçamento vs Realizado',
            'Comparação entre orçamento planejado e gastos reais por centro de custo',
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text('R\$ ${(value / 1000).toStringAsFixed(0)}k');
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < costCenters.length) {
                            return Text(
                              costCenters[index].name.length > 10
                                  ? costCenters[index].name.substring(0, 10) + '...'
                                  : costCenters[index].name,
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  barGroups: _generateBudgetVsActualData(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Department Performance Radar
          _buildChartCard(
            'Desempenho por Departamento',
            'Eficiência de utilização de orçamento por departamento',
            SizedBox(
              height: 350,
              child: RadarChart(
                RadarChartData(
                  dataSets: _generateDepartmentRadarData(),
                  radarShape: RadarShape.polygon,
                  ticksTextStyle: const TextStyle(fontSize: 12),
                  tickCount: 5,
                  titlePositionPercentageOffset: 0.2,
                  titleTextStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  getTitle: (index, angle) {
                    final departments = costCenters.map((cc) => cc.department).toSet().toList();
                    if (index >= 0 && index < departments.length) {
                      return RadarChartTitle(text: departments[index]);
                    }
                    return const RadarChartTitle(text: '');
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Expense Type Distribution
          Row(
            children: [
              Expanded(
                child: _buildChartCard(
                  'Distribuição por Tipo',
                  'Proporção entre despesas fixas e variáveis',
                  SizedBox(
                    height: 250,
                    child: PieChart(
                      PieChartData(
                        sections: [
                          PieChartSectionData(
                            color: Colors.blue,
                            value: totalFixed,
                            title: 'Fixas\nR\$ ${totalFixed.toStringAsFixed(0)}',
                            radius: 80,
                            titleStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          PieChartSectionData(
                            color: Colors.orange,
                            value: totalVariable,
                            title: 'Variáveis\nR\$ ${totalVariable.toStringAsFixed(0)}',
                            radius: 80,
                            titleStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildChartCard(
                  'Eficiência por Centro',
                  'Percentual de utilização do orçamento',
                  SizedBox(
                    height: 250,
                    child: ListView.builder(
                      itemCount: costCenters.length,
                      itemBuilder: (context, index) {
                        final cc = costCenters[index];
                        final utilization = cc.utilizationPercentage;
                        
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: utilization > 90
                                ? Colors.red
                                : utilization > 70
                                    ? Colors.orange
                                    : Colors.green,
                            child: Text('${utilization.toStringAsFixed(0)}%'),
                          ),
                          title: Text(cc.name),
                          subtitle: Text(cc.department),
                          trailing: Text('R\$ ${cc.utilized.toStringAsFixed(0)}'),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color, IconData icon) {
    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard(String title, String subtitle, Widget chart) {
    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: const LinearGradient(
            colors: [Colors.white, Color(0xFFF8F9FA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            chart,
          ],
        ),
      ),
    );
  }
}
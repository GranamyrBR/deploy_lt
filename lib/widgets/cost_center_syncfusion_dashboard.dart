import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:intl/intl.dart';
import '../models/cost_center.dart';

// Remove CornerStyle import conflict

class CostCenterSyncfusionDashboard extends StatelessWidget {
  final List<CostCenter> costCenters;

  const CostCenterSyncfusionDashboard({
    Key? key,
    required this.costCenters,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
              context, 'Dashboard Empresarial - Centros de Custo'),
          const SizedBox(height: 24),
          _buildKPICards(context),
          const SizedBox(height: 32),
          _buildBudgetOverviewChart(context),
          const SizedBox(height: 32),
          _buildExpenseDistributionChart(context),
          const SizedBox(height: 32),
          _buildFixedVariableChart(context),
          const SizedBox(height: 32),
          _buildUtilizationGauges(context),
          const SizedBox(height: 32),
          _buildDepartmentComparisonChart(context),
          const SizedBox(height: 32),
          _buildTrendAnalysisChart(context),
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

  // KPI Cards com Gauge Radial - Layout responsivo para evitar overflow
  Widget _buildKPICards(BuildContext context) {
    final totalBudget = costCenters.fold(0.0, (sum, c) => sum + c.budget);
    final totalUtilized = costCenters.fold(0.0, (sum, c) => sum + c.utilized);
    final totalFixed = costCenters.fold(0.0, (sum, c) => sum + c.fixedExpenses);
    final totalVariable =
        costCenters.fold(0.0, (sum, c) => sum + c.variableExpenses);
    final utilizationRate = totalBudget > 0
        ? ((totalUtilized / totalBudget) * 100).toDouble()
        : 0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final crossAxisCount = isMobile ? 2 : 4;
        final childAspectRatio = isMobile ? 0.9 : 1.2;
        
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: [
            _buildKPIGauge('Taxa de Utilização', utilizationRate, Colors.blue),
            _buildKPIGauge(
                'Despesas Fixas', (totalFixed / totalBudget) * 100, Colors.green),
            _buildKPIGauge('Despesas Variáveis',
                (totalVariable / totalBudget) * 100, Colors.orange),
            _buildKPIGauge('Eficiência', 100 - utilizationRate, Colors.red),
          ],
        );
      },
    );
  }

  Widget _buildKPIGauge(String title, double value, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 120, // Altura fixa para o gauge
              child: SfRadialGauge(
                axes: <RadialAxis>[
                  RadialAxis(
                    minimum: 0,
                    maximum: 100,
                    showLabels: false,
                    showTicks: false,
                    axisLineStyle: AxisLineStyle(
                      thickness: 0.2,
                      color: Colors.grey[300],
                      thicknessUnit: GaugeSizeUnit.factor,
                    ),
                    pointers: <GaugePointer>[
                      RangePointer(
                        value: value,
                        width: 0.2,
                        sizeUnit: GaugeSizeUnit.factor,
                        color: color,
                      ),
                      MarkerPointer(
                        value: value,
                        markerType: MarkerType.circle,
                        color: color,
                        markerWidth: 12,
                        markerHeight: 12,
                      ),
                    ],
                    annotations: <GaugeAnnotation>[
                      GaugeAnnotation(
                        positionFactor: 0.1,
                        angle: 90,
                        widget: Text(
                          '${value.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Gráfico de Pizza - Visão Geral do Orçamento
  Widget _buildBudgetOverviewChart(BuildContext context) {
    final data = costCenters.map((center) {
      return ChartData(
        center.name,
        center.budget,
        _getColorForDepartment(center.department),
      );
    }).toList();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Distribuição do Orçamento por Centro de Custo',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: SfCircularChart(
                title: ChartTitle(text: 'Orçamento Total por Centro'),
                legend:
                    Legend(isVisible: true, position: LegendPosition.bottom),
                series: <CircularSeries>[
                  PieSeries<ChartData, String>(
                    dataSource: data,
                    xValueMapper: (ChartData data, _) => data.category,
                    yValueMapper: (ChartData data, _) => data.value,
                    pointColorMapper: (ChartData data, _) => data.color,
                    dataLabelSettings: const DataLabelSettings(
                      isVisible: true,
                      labelPosition: ChartDataLabelPosition.outside,
                    ),
                    enableTooltip: true,
                    radius: '80%',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Gráfico de Barras - Distribuição de Despesas
  Widget _buildExpenseDistributionChart(BuildContext context) {
    final data = costCenters.map((center) {
      return ExpenseData(
        center.name,
        center.fixedExpenses,
        center.variableExpenses,
        center.utilized,
      );
    }).toList();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Análise de Despesas por Centro de Custo',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 350,
              child: SfCartesianChart(
                primaryXAxis: CategoryAxis(
                  title: AxisTitle(text: 'Centros de Custo'),
                  labelRotation: -45,
                ),
                primaryYAxis: NumericAxis(
                  title: AxisTitle(text: 'Valor (R\$)'),
                  numberFormat:
                      NumberFormat.currency(symbol: 'R\$', decimalDigits: 0),
                ),
                legend:
                    Legend(isVisible: true, position: LegendPosition.bottom),
                tooltipBehavior: TooltipBehavior(enable: true),
                series: <StackedColumnSeries<ExpenseData, String>>[
                  StackedColumnSeries<ExpenseData, String>(
                    dataSource: data,
                    xValueMapper: (ExpenseData data, _) => data.category,
                    yValueMapper: (ExpenseData data, _) => data.fixed,
                    name: 'Despesas Fixas',
                    color: Colors.blue,
                  ),
                  StackedColumnSeries<ExpenseData, String>(
                    dataSource: data,
                    xValueMapper: (ExpenseData data, _) => data.category,
                    yValueMapper: (ExpenseData data, _) => data.variable,
                    name: 'Despesas Variáveis',
                    color: Colors.orange,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Gráfico de Rosca - Fixas vs Variáveis
  Widget _buildFixedVariableChart(BuildContext context) {
    final totalFixed = costCenters.fold(0.0, (sum, c) => sum + c.fixedExpenses);
    final totalVariable =
        costCenters.fold(0.0, (sum, c) => sum + c.variableExpenses);
    final total = totalFixed + totalVariable;

    final data = [
      ChartData('Despesas Fixas', totalFixed, Colors.blue),
      ChartData('Despesas Variáveis', totalVariable, Colors.orange),
    ];

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Proporção: Despesas Fixas vs Variáveis',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: SfCircularChart(
                      series: <CircularSeries>[
                        DoughnutSeries<ChartData, String>(
                          dataSource: data,
                          xValueMapper: (ChartData data, _) => data.category,
                          yValueMapper: (ChartData data, _) => data.value,
                          pointColorMapper: (ChartData data, _) => data.color,
                          dataLabelSettings: const DataLabelSettings(
                            isVisible: true,
                          ),
                          innerRadius: '60%',
                          radius: '100%',
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLegendItem(
                            'Fixas', totalFixed, Colors.blue, total),
                        const SizedBox(height: 16),
                        _buildLegendItem(
                            'Variáveis', totalVariable, Colors.orange, total),
                        const SizedBox(height: 16),
                        Divider(),
                        Text(
                          'Total: R\$ ${total.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Medidores de Utilização por Departamento
  Widget _buildUtilizationGauges(BuildContext context) {
    final departments = <String, List<CostCenter>>{};
    for (final center in costCenters) {
      departments.putIfAbsent(center.department, () => []).add(center);
    }

    final departmentData = departments.entries.map((entry) {
      final totalBudget = entry.value.fold(0.0, (sum, c) => sum + c.budget);
      final totalUtilized = entry.value.fold(0.0, (sum, c) => sum + c.utilized);
      final utilization = totalBudget > 0
          ? ((totalUtilized / totalBudget) * 100).toDouble()
          : 0.0;
      return DepartmentData(
          entry.key, utilization, _getColorForDepartment(entry.key));
    }).toList();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Utilização por Departamento',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: departmentData.map((dept) {
                return _buildDepartmentGauge(
                    dept.name, dept.utilization, dept.color);
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDepartmentGauge(
      String department, double utilization, Color color) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
        color: color.withValues(alpha: 0.1),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            department,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 100, // Altura fixa para o gauge
            child: SfRadialGauge(
              axes: <RadialAxis>[
                RadialAxis(
                  minimum: 0,
                  maximum: 100,
                  showLabels: false,
                  showTicks: false,
                  axisLineStyle: AxisLineStyle(
                    thickness: 0.15,
                    color: Colors.grey[300],
                    thicknessUnit: GaugeSizeUnit.factor,
                  ),
                  pointers: <GaugePointer>[
                    RangePointer(
                      value: utilization,
                      width: 0.15,
                      sizeUnit: GaugeSizeUnit.factor,
                      color: color,
                    ),
                  ],
                  annotations: <GaugeAnnotation>[
                    GaugeAnnotation(
                      positionFactor: 0.1,
                      angle: 90,
                      widget: Text(
                        '${utilization.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Gráfico de Comparação entre Departamentos
  Widget _buildDepartmentComparisonChart(BuildContext context) {
    final departments = <String, List<CostCenter>>{};
    for (final center in costCenters) {
      departments.putIfAbsent(center.department, () => []).add(center);
    }

    final data = departments.entries.map((entry) {
      final totalBudget = entry.value.fold(0.0, (sum, c) => sum + c.budget);
      final totalUtilized = entry.value.fold(0.0, (sum, c) => sum + c.utilized);
      final avgUtilization = totalBudget > 0
          ? ((totalUtilized / totalBudget) * 100).toDouble()
          : 0.0;
      return DepartmentComparisonData(
        entry.key,
        totalBudget,
        totalUtilized,
        avgUtilization,
        _getColorForDepartment(entry.key),
      );
    }).toList();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comparação entre Departamentos',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: SfCartesianChart(
                primaryXAxis: CategoryAxis(
                  title: AxisTitle(text: 'Departamentos'),
                ),
                primaryYAxis: NumericAxis(
                  title: AxisTitle(text: 'Valor (R\$)'),
                  numberFormat:
                      NumberFormat.currency(symbol: 'R\$', decimalDigits: 0),
                ),
                legend:
                    Legend(isVisible: true, position: LegendPosition.bottom),
                tooltipBehavior: TooltipBehavior(enable: true),
                series: <ColumnSeries<DepartmentComparisonData, String>>[
                  ColumnSeries<DepartmentComparisonData, String>(
                    dataSource: data,
                    xValueMapper: (DepartmentComparisonData data, _) =>
                        data.department,
                    yValueMapper: (DepartmentComparisonData data, _) =>
                        data.budget,
                    name: 'Orçamento',
                    color: Colors.blue.withValues(alpha: 0.7),
                  ),
                  ColumnSeries<DepartmentComparisonData, String>(
                    dataSource: data,
                    xValueMapper: (DepartmentComparisonData data, _) =>
                        data.department,
                    yValueMapper: (DepartmentComparisonData data, _) =>
                        data.utilized,
                    name: 'Utilizado',
                    color: Colors.red.withValues(alpha: 0.7),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Gráfico de Linhas - Análise de Tendências
  Widget _buildTrendAnalysisChart(BuildContext context) {
    // Simulação de dados históricos para análise de tendências
    final months = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun'];
    final data = months.map((month) {
      final monthIndex = months.indexOf(month);
      final baseValue = 50000;
      final variation = (monthIndex * 5000) + (monthIndex % 3) * 2000;
      final utilized = baseValue + variation - (monthIndex * 3000);
      return TrendData(
        month,
        baseValue + variation.toDouble(),
        utilized.toDouble(),
      );
    }).toList();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Análise de Tendências - 6 Meses',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: SfCartesianChart(
                primaryXAxis: CategoryAxis(
                  title: AxisTitle(text: 'Meses'),
                ),
                primaryYAxis: NumericAxis(
                  title: AxisTitle(text: 'Valor (R\$)'),
                  numberFormat:
                      NumberFormat.currency(symbol: 'R\$', decimalDigits: 0),
                ),
                legend:
                    Legend(isVisible: true, position: LegendPosition.bottom),
                tooltipBehavior: TooltipBehavior(enable: true),
                series: <LineSeries<TrendData, String>>[
                  LineSeries<TrendData, String>(
                    dataSource: data,
                    xValueMapper: (TrendData data, _) => data.month,
                    yValueMapper: (TrendData data, _) => data.budget,
                    name: 'Orçamento',
                    color: Colors.blue,
                    markerSettings: const MarkerSettings(isVisible: true),
                  ),
                  LineSeries<TrendData, String>(
                    dataSource: data,
                    xValueMapper: (TrendData data, _) => data.month,
                    yValueMapper: (TrendData data, _) => data.utilized,
                    name: 'Utilizado',
                    color: Colors.red,
                    markerSettings: const MarkerSettings(isVisible: true),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget Auxiliares
  Widget _buildLegendItem(
      String label, double value, Color color, double total) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          color: color,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12)),
              Text(
                'R\$ ${value.toStringAsFixed(0)} (${((value / total) * 100).toStringAsFixed(1)}%)',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getColorForDepartment(String department) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.amber,
    ];
    return colors[department.hashCode % colors.length];
  }
}

// Classes de Dados para os Gráficos
class ChartData {
  final String category;
  final double value;
  final Color color;

  ChartData(this.category, this.value, this.color);
}

class ExpenseData {
  final String category;
  final double fixed;
  final double variable;
  final double total;

  ExpenseData(this.category, this.fixed, this.variable, this.total);
}

class DepartmentData {
  final String name;
  final double utilization;
  final Color color;

  DepartmentData(this.name, this.utilization, this.color);
}

class DepartmentComparisonData {
  final String department;
  final double budget;
  final double utilized;
  final double utilization;
  final Color color;

  DepartmentComparisonData(
    this.department,
    this.budget,
    this.utilized,
    this.utilization,
    this.color,
  );
}

class TrendData {
  final String month;
  final double budget;
  final double utilized;

  TrendData(this.month, this.budget, this.utilized);
}

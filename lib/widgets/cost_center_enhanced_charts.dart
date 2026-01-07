import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/cost_center.dart';

class CostCenterEnhancedCharts extends StatelessWidget {
  final List<CostCenter> costCenters;

  const CostCenterEnhancedCharts({
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
          _buildSectionTitle(
              context, 'Dashboard Aprimorado - Análises Multidimensionais'),
          const SizedBox(height: 24),
          _build3DEnhancedScatterPlotSection(context),
          const SizedBox(height: 32),
          _buildMultiDimensionalAnalysisSection(context),
          const SizedBox(height: 32),
          _buildNetworkAnalysisSection(context),
          const SizedBox(height: 32),
          _buildClusteringAnalysisSection(context),
          const SizedBox(height: 32),
          _buildRegressionAnalysisSection(context),
          const SizedBox(height: 32),
          _buildAnomalyDetectionSection(context),
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

  // 3D Enhanced Scatter Plot com simulação realista
  Widget _build3DEnhancedScatterPlotSection(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Análise Tridimensional Aprimorada - 3D Scatter Plot',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Relação multidimensional: Orçamento × Utilização × Eficiência × Performance',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 450,
              child: _buildEnhanced3DScatterPlot(),
            ),
            const SizedBox(height: 16),
            _build3DLegend(context),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhanced3DScatterPlot() {
    return Stack(
      children: [
        // Plano de fundo 3D simulado
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.grey[100]!,
                Colors.grey[200]!,
                Colors.grey[300]!,
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
        ),

        // Grid 3D simulado
        CustomPaint(
          size: const Size(double.infinity, double.infinity),
          painter: Grid3DPainter(),
        ),

        // Scatter plot com profundidade
        ScatterChart(
          ScatterChartData(
            scatterSpots: costCenters.map((center) {
              final x = center.budget / 1000; // Orçamento em milhares (X)
              final y = center.utilized / 1000; // Utilizado em milhares (Y)
              final z =
                  center.utilizationRate; // Taxa de utilização (Z - tamanho)
              final w = center.budget > 0
                  ? (center.budget - center.utilized) / center.budget
                  : 0; // Eficiência (cor)

              return ScatterSpot(
                x,
                y,
              );
            }).toList(),
            minX: 0,
            maxX: costCenters
                    .map((c) => c.budget)
                    .reduce((a, b) => a > b ? a : b) /
                1000,
            minY: 0,
            maxY: costCenters
                    .map((c) => c.utilized)
                    .reduce((a, b) => a > b ? a : b) /
                1000,
            borderData: FlBorderData(show: false),
            gridData: const FlGridData(show: true),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 50,
                  interval: 10,
                  getTitlesWidget: (value, meta) {
                    return Text('R\$ ${value.toInt()}k');
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 50,
                  interval: 10,
                  getTitlesWidget: (value, meta) {
                    return Text('R\$ ${value.toInt()}k');
                  },
                ),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            scatterTouchData: ScatterTouchData(
              enabled: true,
              touchTooltipData: ScatterTouchTooltipData(
                getTooltipColor: (spot) => Colors.black.withValues(alpha: 0.8),
                getTooltipItems: (ScatterSpot spot) {
                  // Handle single spot tooltip
                  final centerIndex = costCenters.indexWhere((c) =>
                      (c.budget / 1000).toStringAsFixed(1) ==
                          spot.x.toStringAsFixed(1) &&
                      (c.utilized / 1000).toStringAsFixed(1) ==
                          spot.y.toStringAsFixed(1));
                  final center = centerIndex >= 0
                      ? costCenters[centerIndex]
                      : costCenters.first;
                  return ScatterTooltipItem(
                    '${center.name}\n'
                    'Orçamento: R\$ ${center.budget.toStringAsFixed(0)}\n'
                    'Utilizado: R\$ ${center.utilized.toStringAsFixed(0)}\n'
                    'Taxa: ${(center.utilizationRate * 100).toStringAsFixed(1)}%',
                  );
                },
              ),
            ),
          ),
        ),

        // Eixo Z simulado (profundidade)
        Positioned(
          right: 20,
          top: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Profundidade: Taxa de Utilização',
                  style: TextStyle(fontSize: 10, color: Colors.grey[600])),
              const SizedBox(height: 4),
              Container(
                width: 100,
                height: 10,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.withValues(alpha: 0.3),
                      Colors.red.withValues(alpha: 1.0)
                    ],
                  ),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              const SizedBox(height: 2),
              Text('0% → 100%',
                  style: TextStyle(fontSize: 8, color: Colors.grey[600])),
            ],
          ),
        ),
      ],
    );
  }

  // Multi-Dimensional Analysis com múltiplas perspectivas
  Widget _buildMultiDimensionalAnalysisSection(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Análise Multidimensional - Múltiplas Perspectivas',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Visualização de dados em múltiplas dimensões simultaneamente',
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
                _buildDimensionCard(
                    'Dimensão Financeira', _buildFinancialDimension()),
                _buildDimensionCard(
                    'Dimensão Temporal', _buildTemporalDimension()),
                _buildDimensionCard(
                    'Dimensão de Performance', _buildPerformanceDimension()),
                _buildDimensionCard('Dimensão de Risco', _buildRiskDimension()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDimensionCard(String title, Widget chart) {
    return Card(
      elevation: 2,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(child: chart),
        ],
      ),
    );
  }

  Widget _buildFinancialDimension() {
    return PieChart(
      PieChartData(
        sections: costCenters.map((center) {
          final percentage =
              costCenters.fold(0.0, (sum, c) => sum + c.budget) > 0
                  ? center.budget /
                      costCenters.fold(0.0, (sum, c) => sum + c.budget)
                  : 0;

          return PieChartSectionData(
            color: _getColorForIndex(costCenters.indexOf(center)),
            value: percentage * 100,
            title: '${(percentage * 100).toStringAsFixed(1)}%',
            titleStyle:
                const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          );
        }).toList(),
        sectionsSpace: 2,
        centerSpaceRadius: 20,
      ),
    );
  }

  Widget _buildTemporalDimension() {
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
                12, (i) => FlSpot(i.toDouble(), 50 + (i * 5) + (i % 3) * 10)),
            isCurved: true,
            color: Colors.blue,
            barWidth: 2,
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceDimension() {
    return RadarChart(
      RadarChartData(
        radarShape: RadarShape.polygon,
        dataSets: [
          RadarDataSet(
            fillColor: Colors.green.withValues(alpha: 0.3),
            borderColor: Colors.green,
            borderWidth: 1,
            dataEntries: [
              const RadarEntry(value: 80),
              const RadarEntry(value: 65),
              const RadarEntry(value: 70),
              const RadarEntry(value: 85),
              const RadarEntry(value: 75),
            ],
            entryRadius: 2,
          ),
        ],
        titleTextStyle: const TextStyle(fontSize: 8),
        tickCount: 3,
        titlePositionPercentageOffset: 0.1,
      ),
    );
  }

  Widget _buildRiskDimension() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 100,
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(5, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: 20 + (i * 15).toDouble(),
                color:
                    i < 2 ? Colors.green : (i < 4 ? Colors.orange : Colors.red),
                width: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }),
      ),
    );
  }

  // Network Analysis para análise de relacionamentos
  Widget _buildNetworkAnalysisSection(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Análise de Rede - Network Analysis',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Relacionamentos e dependências entre centros de custo',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 400,
              child: _buildNetworkChart(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkChart() {
    return CustomPaint(
      size: const Size(double.infinity, double.infinity),
      painter: NetworkChartPainter(costCenters: costCenters),
    );
  }

  // Clustering Analysis para agrupamento inteligente
  Widget _buildClusteringAnalysisSection(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Análise de Agrupamento - Clustering Analysis',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Centros de custo agrupados por similaridade de performance',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 350,
              child: _buildClusteringChart(),
            ),
            const SizedBox(height: 16),
            _buildClusteringLegend(context),
          ],
        ),
      ),
    );
  }

  Widget _buildClusteringChart() {
    return ScatterChart(
      ScatterChartData(
        scatterSpots: _generateClusteringData(),
        minX: 0,
        maxX: 100,
        minY: 0,
        maxY: 100,
        borderData: FlBorderData(show: true),
        gridData: const FlGridData(show: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: 20,
              getTitlesWidget: (value, meta) {
                final intValue = value.toInt();
                return Text('$intValue%');
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: 20,
              getTitlesWidget: (value, meta) {
                return Text('${value.toInt()}%');
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        scatterTouchData: ScatterTouchData(
          enabled: true,
          touchTooltipData: const ScatterTouchTooltipData(),
        ),
      ),
    );
  }

  List<ScatterSpot> _generateClusteringData() {
    final spots = <ScatterSpot>[];

    // Cluster 1: Alto orçamento, alta utilização
    for (int i = 0; i < costCenters.length ~/ 2; i++) {
      final x = 60 + (i * 5) + (i % 3) * 3; // Budget score
      final y = 70 + (i * 2) + (i % 4) * 5; // Performance score

      spots.add(ScatterSpot(
        x.toDouble(),
        y.toDouble(),
      ));
    }

    // Cluster 2: Baixo orçamento, baixa utilização
    for (int i = costCenters.length ~/ 2; i < costCenters.length; i++) {
      final x = 20 + (i * 3) + (i % 3) * 2;
      final y = 30 + (i * 1) + (i % 3) * 3;

      spots.add(ScatterSpot(
        x.toDouble(),
        y.toDouble(),
      ));
    }

    return spots;
  }

  Widget _buildClusteringLegend(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(Colors.blue, 'Cluster A: Alto Performance'),
        const SizedBox(width: 16),
        _buildLegendItem(Colors.red, 'Cluster B: Baixo Performance'),
      ],
    );
  }

  // Regression Analysis para tendências preditivas
  Widget _buildRegressionAnalysisSection(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Análise de Regressão - Regression Analysis',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tendências preditivas e projeções futuras',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 350,
              child: _buildRegressionChart(),
            ),
            const SizedBox(height: 16),
            _buildRegressionLegend(context),
          ],
        ),
      ),
    );
  }

  Widget _buildRegressionChart() {
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: 10000,
              getTitlesWidget: (value, meta) {
                return Text('R\$ ${(value / 1000).toInt()}k');
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final months = [
                  'Jan',
                  'Fev',
                  'Mar',
                  'Abr',
                  'Mai',
                  'Jun',
                  'Jul',
                  'Ago',
                  'Set'
                ];
                return Text(months[value.toInt() % months.length]);
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          // Dados históricos
          LineChartBarData(
            spots: List.generate(
                6,
                (i) =>
                    FlSpot(i.toDouble(), 30000 + (i * 5000) + (i % 2) * 2000)),
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            dotData: const FlDotData(show: true),
          ),
          // Linha de regressão
          LineChartBarData(
            spots: List.generate(
                9, (i) => FlSpot(i.toDouble(), 28000 + (i * 5500))),
            isCurved: false,
            color: Colors.red,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            dashArray: [5, 5],
          ),
          // Projeção futura
          LineChartBarData(
            spots: List.generate(
                9, (i) => FlSpot(i.toDouble(), 28000 + (i * 5500))).sublist(6),
            isCurved: true,
            color: Colors.green.withValues(alpha: 0.7),
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.green.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }

  // Anomaly Detection para detecção de anomalias
  Widget _buildAnomalyDetectionSection(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detecção de Anomalias - Anomaly Detection',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Identificação automática de comportamentos fora do padrão',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 350,
              child: _buildAnomalyChart(),
            ),
            const SizedBox(height: 16),
            _buildAnomalyLegend(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAnomalyChart() {
    return ScatterChart(
      ScatterChartData(
        scatterSpots: _generateAnomalyData(),
        minX: 0,
        maxX: 100,
        minY: 0,
        maxY: 100,
        borderData: FlBorderData(show: true),
        gridData: const FlGridData(show: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: 25,
              getTitlesWidget: (value, meta) {
                final intValue = value.toInt();
                return Text('$intValue%');
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: 25,
              getTitlesWidget: (value, meta) {
                final intValue = value.toInt();
                return Text('$intValue%');
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        scatterTouchData: ScatterTouchData(
          enabled: true,
          touchTooltipData: ScatterTouchTooltipData(
            getTooltipColor: (spot) => Colors.black.withValues(alpha: 0.8),
          ),
          touchCallback: (event, response) {
            // Handle touch events if needed
          },
        ),
      ),
    );
  }

  List<ScatterSpot> _generateAnomalyData() {
    final spots = <ScatterSpot>[];

    // Dados normais
    for (int i = 0; i < 30; i++) {
      final x = 30 + (i % 40) + (i % 3) * 5;
      final y = 40 + (i % 30) + (i % 4) * 3;

      spots.add(ScatterSpot(
        x.toDouble(),
        y.toDouble(),
      ));
    }

    // Anomalias
    for (int i = 0; i < 5; i++) {
      final x = i < 3 ? 85 + i * 3 : 20 + i * 5;
      final y = i < 2 ? 10 + i * 2 : 85 + i * 2;

      spots.add(ScatterSpot(
        x.toDouble(),
        y.toDouble(),
      ));
    }

    return spots;
  }

  // Métodos auxiliares
  Color _getColorFor4DValue(double value) {
    if (value >= 0.8) return Colors.green;
    if (value >= 0.6) return Colors.yellow;
    if (value >= 0.4) return Colors.orange;
    return Colors.red;
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

  Widget _build3DLegend(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Legenda 4D:',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildLegendItem(Colors.green, 'Alta Eficiência (≥80%)'),
            const SizedBox(width: 8),
            _buildLegendItem(Colors.yellow, 'Média Eficiência (60-80%)'),
            const SizedBox(width: 8),
            _buildLegendItem(Colors.orange, 'Baixa Eficiência (40-60%)'),
            const SizedBox(width: 8),
            _buildLegendItem(Colors.red, 'Crítico (<40%)'),
          ],
        ),
        const SizedBox(height: 4),
        Text('Tamanho dos pontos: Taxa de Utilização',
            style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }

  Widget _buildRegressionLegend(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(Colors.blue, 'Dados Históricos'),
        const SizedBox(width: 8),
        _buildLegendItem(Colors.red, 'Linha de Regressão'),
        const SizedBox(width: 8),
        _buildLegendItem(
            Colors.green.withValues(alpha: 0.7), 'Projeção Futura'),
      ],
    );
  }

  Widget _buildAnomalyLegend(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(Colors.blue.withValues(alpha: 0.6), 'Dados Normais'),
        const SizedBox(width: 8),
        _buildLegendItem(Colors.red, 'Anomalias Detectadas'),
      ],
    );
  }
}

// Custom Painter para Grid 3D
class Grid3DPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.3)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Grid horizontal
    for (int i = 0; i <= 10; i++) {
      final y = (size.height / 10) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Grid vertical
    for (int i = 0; i <= 10; i++) {
      final x = (size.width / 10) * i;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Linhas de profundidade simuladas
    final depthPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.2)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 5; i++) {
      final offset = (i + 1) * 10.0;
      canvas.drawLine(
        Offset(size.width - offset, 0),
        Offset(size.width, offset),
        depthPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom Painter para Network Chart
class NetworkChartPainter extends CustomPainter {
  final List<CostCenter> costCenters;

  NetworkChartPainter({required this.costCenters});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
    ];

    // Desenhar nós (centros de custo)
    final nodes = <Offset>[];
    for (int i = 0; i < costCenters.length; i++) {
      final angle = (i * 2 * 3.14159) / costCenters.length;
      final radius = size.width * 0.3;
      final centerX = size.width / 2;
      final centerY = size.height / 2;

      final x = centerX + radius * cos(angle);
      final y = centerY + radius * sin(angle);

      nodes.add(Offset(x, y));

      // Desenhar nó
      paint.color = colors[i % colors.length];
      canvas.drawCircle(Offset(x, y), 20, paint);

      // Desenhar texto do nó
      final textPainter = TextPainter(
        text: TextSpan(
          text: costCenters[i].name.split(' ').first,
          style: const TextStyle(color: Colors.white, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas,
          Offset(x - textPainter.width / 2, y - textPainter.height / 2));
    }

    // Desenhar conexões
    final connectionPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < nodes.length; i++) {
      for (int j = i + 1; j < nodes.length; j++) {
        // Simular força de conexão baseada na similaridade de orçamento
        final budgetDiff =
            (costCenters[i].budget - costCenters[j].budget).abs();
        final maxBudget =
            costCenters.map((c) => c.budget).reduce((a, b) => a > b ? a : b);
        final connectionStrength = 1 - (budgetDiff / maxBudget);

        if (connectionStrength > 0.6) {
          connectionPaint.strokeWidth = connectionStrength * 3;
          connectionPaint.color =
              Colors.blue.withValues(alpha: connectionStrength);
          canvas.drawLine(nodes[i], nodes[j], connectionPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Extensão para cálculos trigonométricos
double cos(double angle) {
  // Implementação simplificada para ângulos comuns
  if (angle < 0) return cos(-angle);
  angle = angle % (2 * 3.14159);

  if (angle < 1.5708) {
    return (1 - (angle * angle) / 2 + (angle * angle * angle * angle) / 24);
  }
  if (angle < 3.1416) return -cos(3.1416 - angle);
  if (angle < 4.7124) return -cos(angle - 3.1416);
  return cos(6.2832 - angle);
}

double sin(double angle) {
  return cos(1.5708 - angle);
}

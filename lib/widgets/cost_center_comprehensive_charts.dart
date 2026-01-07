import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/cost_center.dart';

class CostCenterComprehensiveCharts extends StatelessWidget {
  final List<CostCenter> costCenters;

  const CostCenterComprehensiveCharts({
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
              context, 'Dashboard Compreensivo - Todas as Visualizações'),
          const SizedBox(height: 24),
          _buildCandlestickChartSection(context),
          const SizedBox(height: 32),
          _buildSankeyChartSection(context),
          const SizedBox(height: 32),
          _buildMultiSeriesTemporalSection(context),
          const SizedBox(height: 32),
          _buildHeatmapChartSection(context),
          const SizedBox(height: 32),
          _buildPolarChartSection(context),
          const SizedBox(height: 32),
          _buildWaterfallChartSection(context),
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

  // Candlestick Chart para análise de volatilidade
  Widget _buildCandlestickChartSection(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Análise de Volatilidade - Candlestick Chart',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Variação de despesas ao longo do tempo',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: _buildCandlestickChart(),
            ),
            const SizedBox(height: 16),
            _buildLegend(context, [
              {'color': Colors.green, 'label': 'Baixa Volatilidade'},
              {'color': Colors.orange, 'label': 'Média Volatilidade'},
              {'color': Colors.red, 'label': 'Alta Volatilidade'},
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildCandlestickChart() {
    // Simula dados de candlestick baseados na variação de despesas
    final candleData = _generateCandlestickData();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 100,
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: 20,
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                final months = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun'];
                final index = value.toInt();
                if (index >= 0 && index < months.length) {
                  return Text(months[index]);
                }
                return Text('');
              },
            ),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: true),
        barGroups: candleData.map((data) {
          return BarChartGroupData(
            x: data['x'] as int,
            barRods: [
              BarChartRodData(
                toY: data['high'] as double,
                fromY: data['low'] as double,
                color: data['color'] as Color,
                width: 16,
                borderRadius: BorderRadius.circular(2),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  List<Map<String, dynamic>> _generateCandlestickData() {
    return List.generate(6, (index) {
      final baseValue = 20 + (index * 10);
      final variation = (index % 3) * 15;
      return {
        'x': index,
        'open': baseValue.toDouble(),
        'close': (baseValue + variation).toDouble(),
        'high': (baseValue + variation + 10).toDouble(),
        'low': (baseValue - 5).toDouble(),
        'color': index % 3 == 0
            ? Colors.green
            : (index % 3 == 1 ? Colors.orange : Colors.red),
      };
    });
  }

  // Sankey Chart para fluxo de orçamento
  Widget _buildSankeyChartSection(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fluxo de Orçamento - Sankey Chart',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Distribuição de recursos entre centros de custo',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 400,
              child: _buildSankeyChart(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSankeyChart() {
    final totalBudget =
        costCenters.fold(0.0, (sum, center) => sum + center.budget);

    return CustomPaint(
      size: const Size(double.infinity, 400),
      painter: SankeyChartPainter(
        costCenters: costCenters,
        totalBudget: totalBudget,
      ),
    );
  }

  // Multi-Series Temporal Analysis
  Widget _buildMultiSeriesTemporalSection(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Análise Temporal Multi-Séries',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Evolução temporal de múltiplas métricas',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 350,
              child: LineChart(
                _buildMultiSeriesData(),
              ),
            ),
            const SizedBox(height: 16),
            _buildLegend(context, [
              {'color': Colors.blue, 'label': 'Orçamento'},
              {'color': Colors.red, 'label': 'Utilizado'},
              {'color': Colors.green, 'label': 'Disponível'},
              {'color': Colors.orange, 'label': 'Fixas'},
              {'color': Colors.purple, 'label': 'Variáveis'},
            ]),
          ],
        ),
      ),
    );
  }

  LineChartData _buildMultiSeriesData() {
    return LineChartData(
      gridData: const FlGridData(show: true),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            interval: 10000,
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) {
              final months = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun'];
              final index = value.toInt();
              if (index >= 0 && index < months.length) {
                return Text(months[index]);
              }
              return Text('');
            },
          ),
        ),
        rightTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      borderData: FlBorderData(show: true),
      lineBarsData: [
        _buildLineChartBarData(Colors.blue, _generateBudgetData()),
        _buildLineChartBarData(Colors.red, _generateUtilizedData()),
        _buildLineChartBarData(Colors.green, _generateAvailableData()),
        _buildLineChartBarData(Colors.orange, _generateFixedData()),
        _buildLineChartBarData(Colors.purple, _generateVariableData()),
      ],
    );
  }

  LineChartBarData _buildLineChartBarData(Color color, List<FlSpot> spots) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: true),
      belowBarData: BarAreaData(
        show: true,
        color: color.withValues(alpha: 0.1),
      ),
    );
  }

  List<FlSpot> _generateBudgetData() =>
      List.generate(6, (i) => FlSpot(i.toDouble(), 45000 + (i * 5000)));
  List<FlSpot> _generateUtilizedData() =>
      List.generate(6, (i) => FlSpot(i.toDouble(), 30000 + (i * 3000)));
  List<FlSpot> _generateAvailableData() =>
      List.generate(6, (i) => FlSpot(i.toDouble(), 15000 + (i * 2000)));
  List<FlSpot> _generateFixedData() =>
      List.generate(6, (i) => FlSpot(i.toDouble(), 20000 + (i * 1000)));
  List<FlSpot> _generateVariableData() =>
      List.generate(6, (i) => FlSpot(i.toDouble(), 10000 + (i * 2000)));

  // Heatmap Chart para análise de densidade
  Widget _buildHeatmapChartSection(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Análise de Densidade - Heatmap Chart',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Concentração de despesas por período e categoria',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: _buildHeatmapChart(),
            ),
            const SizedBox(height: 16),
            _buildHeatmapLegend(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeatmapChart() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.5,
      ),
      itemCount: 42, // 6 weeks * 7 days
      itemBuilder: (context, index) {
        final intensity = (index % 5) * 0.2;
        final color = _getHeatmapColor(intensity);

        return Container(
          margin: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
          child: Center(
            child: Text(
              '${(intensity * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                color: intensity > 0.5 ? Colors.white : Colors.black,
                fontSize: 10,
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getHeatmapColor(double intensity) {
    if (intensity < 0.2) return Colors.blue.withValues(alpha: 0.3);
    if (intensity < 0.4) return Colors.green.withValues(alpha: 0.5);
    if (intensity < 0.6) return Colors.orange.withValues(alpha: 0.7);
    if (intensity < 0.8) return Colors.red.withValues(alpha: 0.8);
    return Colors.red.withValues(alpha: 1.0);
  }

  Widget _buildHeatmapLegend(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Menos', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(width: 8),
        ...[0.2, 0.4, 0.6, 0.8, 1.0]
            .map((intensity) => Container(
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: _getHeatmapColor(intensity),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ))
            .toList(),
        const SizedBox(width: 8),
        Text('Mais', style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  // Polar Chart para análise cíclica
  Widget _buildPolarChartSection(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Análise Cíclica - Polar Chart',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Padrões sazonais de despesas',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 350,
              child: _buildPolarChart(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPolarChart() {
    return RadarChart(
      RadarChartData(
        radarShape: RadarShape.circle,
        dataSets: [
          RadarDataSet(
            fillColor: Colors.blue.withValues(alpha: 0.3),
            borderColor: Colors.blue,
            borderWidth: 2,
            dataEntries: [
              RadarEntry(value: 80),
              RadarEntry(value: 65),
              RadarEntry(value: 45),
              RadarEntry(value: 30),
              RadarEntry(value: 55),
              RadarEntry(value: 70),
              RadarEntry(value: 85),
              RadarEntry(value: 90),
              RadarEntry(value: 75),
              RadarEntry(value: 60),
              RadarEntry(value: 40),
              RadarEntry(value: 50),
            ],
            entryRadius: 3,
          ),
          RadarDataSet(
            fillColor: Colors.red.withValues(alpha: 0.3),
            borderColor: Colors.red,
            borderWidth: 2,
            dataEntries: [
              RadarEntry(value: 60),
              RadarEntry(value: 70),
              RadarEntry(value: 80),
              RadarEntry(value: 85),
              RadarEntry(value: 65),
              RadarEntry(value: 50),
              RadarEntry(value: 45),
              RadarEntry(value: 55),
              RadarEntry(value: 70),
              RadarEntry(value: 80),
              RadarEntry(value: 85),
              RadarEntry(value: 75),
            ],
            entryRadius: 3,
          ),
        ],
        titleTextStyle: const TextStyle(fontSize: 12),
        tickCount: 4,
        ticksTextStyle: const TextStyle(fontSize: 10),
        titlePositionPercentageOffset: 0.2,
      ),
    );
  }

  // Waterfall Chart para análise de contribuição
  Widget _buildWaterfallChartSection(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Análise de Contribuição - Waterfall Chart',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Impacto incremental de cada centro de custo',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: _buildWaterfallChart(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaterfallChart() {
    final waterfallData = _generateWaterfallData();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 100,
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: 20,
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              getTitlesWidget: (value, meta) {
                final labels = ['Início', 'MKT', 'Vendas', 'RH', 'TI', 'Final'];
                final index = value.toInt();
                if (index >= 0 && index < labels.length) {
                  return RotatedBox(
                    quarterTurns: 3,
                    child: Text(labels[index]),
                  );
                }
                return RotatedBox(
                  quarterTurns: 3,
                  child: Text(''),
                );
              },
            ),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: true),
        barGroups: waterfallData.map((data) {
          return BarChartGroupData(
            x: data['x'] as int,
            barRods: [
              BarChartRodData(
                toY: data['y'] as double,
                color: data['color'] as Color,
                width: 30,
                borderRadius: BorderRadius.circular(2),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  List<Map<String, dynamic>> _generateWaterfallData() {
    return [
      {'x': 0, 'y': 20.0, 'color': Colors.blue},
      {'x': 1, 'y': 15.0, 'color': Colors.green},
      {'x': 2, 'y': 25.0, 'color': Colors.orange},
      {'x': 3, 'y': -10.0, 'color': Colors.red},
      {'x': 4, 'y': 20.0, 'color': Colors.purple},
      {'x': 5, 'y': 70.0, 'color': Colors.teal},
    ];
  }

  // Métodos auxiliares
  Widget _buildLegend(BuildContext context, List<Map<String, dynamic>> items) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: items.map((item) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: item['color'] as Color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              item['label'] as String,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        );
      }).toList(),
    );
  }
}

// Custom Painter para Sankey Chart
class SankeyChartPainter extends CustomPainter {
  final List<CostCenter> costCenters;
  final double totalBudget;

  SankeyChartPainter({
    required this.costCenters,
    required this.totalBudget,
  });

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

    // Desenhar nós de origem (orçamento total)
    final sourceRect = Rect.fromLTWH(50, size.height / 2 - 50, 100, 100);
    paint.color = Colors.blue;
    canvas.drawRRect(
      RRect.fromRectAndRadius(sourceRect, const Radius.circular(8)),
      paint,
    );

    // Desenhar texto do nó de origem
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'Orçamento\nTotal',
        style: TextStyle(color: Colors.white, fontSize: 12),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
        canvas,
        Offset(sourceRect.center.dx - textPainter.width / 2,
            sourceRect.center.dy - textPainter.height / 2));

    // Desenhar centros de custo como nós de destino
    final nodeWidth = 80.0;
    final nodeHeight = 60.0;
    final nodeSpacing = 20.0;

    for (int i = 0; i < costCenters.length; i++) {
      final center = costCenters[i];
      final percentage = center.budget / totalBudget;
      final nodeHeight =
          30 + (percentage * 200); // Altura proporcional ao orçamento

      final x = size.width - 200;
      final y = 50 + (i * (nodeHeight + nodeSpacing));

      final targetRect = Rect.fromLTWH(x, y, nodeWidth, nodeHeight);
      paint.color = colors[i % colors.length];

      canvas.drawRRect(
        RRect.fromRectAndRadius(targetRect, const Radius.circular(6)),
        paint,
      );

      // Desenhar texto do centro de custo
      final centerTextPainter = TextPainter(
        text: TextSpan(
          text: '${center.name}\nR\$ ${center.budget.toStringAsFixed(0)}',
          style: const TextStyle(color: Colors.white, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      );
      centerTextPainter.layout(maxWidth: nodeWidth - 8);
      centerTextPainter.paint(
        canvas,
        Offset(targetRect.left + 4,
            targetRect.center.dy - centerTextPainter.height / 2),
      );

      // Desenhar conexão (fluxo)
      final path = Path();
      path.moveTo(sourceRect.right, sourceRect.center.dy);
      path.cubicTo(
        sourceRect.right +
            (size.width - sourceRect.right - targetRect.left) / 2,
        sourceRect.center.dy,
        sourceRect.right +
            (size.width - sourceRect.right - targetRect.left) / 2,
        targetRect.center.dy,
        targetRect.left,
        targetRect.center.dy,
      );

      final connectionPaint = Paint()
        ..color = colors[i % colors.length].withValues(alpha: 0.6)
        ..strokeWidth = 8 + (percentage * 20) // Largura proporcional ao fluxo
        ..style = PaintingStyle.stroke;

      canvas.drawPath(path, connectionPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/financial_metric.dart';
import '../providers/financial_metrics_provider.dart';
import '../widgets/financial_kpi_card.dart';
import '../widgets/financial_metric_modal.dart';

class FinancialDashboardScreen extends ConsumerStatefulWidget {
  const FinancialDashboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<FinancialDashboardScreen> createState() => _FinancialDashboardScreenState();
}

class _FinancialDashboardScreenState extends ConsumerState<FinancialDashboardScreen> {
  String _selectedTimeRange = 'month';
  String _selectedCategory = 'all';
  DateTime _selectedDate = DateTime.now();
  bool _showCharts = true;
  
  final List<Map<String, String>> _timeRanges = [
    {'value': 'day', 'label': 'Dia'},
    {'value': 'week', 'label': 'Semana'},
    {'value': 'month', 'label': 'Mês'},
    {'value': 'quarter', 'label': 'Trimestre'},
    {'value': 'year', 'label': 'Ano'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(financialMetricsProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final provider = ref.watch(financialMetricsProvider);
    
    return Scaffold(
      body: Consumer(
        builder: (context, widgetRef, child) {
          final provider = widgetRef.watch(financialMetricsProvider);
          final metrics = provider.metrics;
          final keyMetrics = provider.keyMetrics;
          final alerts = provider.alerts;
          final categories = provider.categories;
          
          return RefreshIndicator(
            onRefresh: () => provider.loadMetrics(),
            child: CustomScrollView(
              slivers: [
                // Header
                SliverAppBar(
                  floating: true,
                  pinned: true,
                  elevation: 0,
                  flexibleSpace: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDarkMode 
                            ? [Colors.blue.shade900, Colors.purple.shade900]
                            : [Colors.blue.shade600, Colors.purple.shade600],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  title: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.attach_money, size: 18),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Dashboard Financeiro', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text('Análise Financeira e Métricas', style: TextStyle(fontSize: 10, color: Colors.white70)),
                        ],
                      ),
                    ],
                  ),
                  actions: [
                    // Botão de gráficos
                    IconButton(
                      icon: Icon(_showCharts ? Icons.bar_chart : Icons.bar_chart_outlined),
                      onPressed: () => setState(() => _showCharts = !_showCharts),
                      tooltip: _showCharts ? 'Ocultar gráficos' : 'Mostrar gráficos',
                    ),
                    // Botão adicionar métrica
                    IconButton(
                      icon: const Icon(Icons.add_chart),
                      onPressed: () => _showAddMetricModal(context),
                      tooltip: 'Adicionar métrica',
                    ),
                  ],
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(120),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Filtros principais
                          Row(
                            children: [
                              // Filtro de período
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _selectedTimeRange,
                                  decoration: const InputDecoration(
                                    labelText: 'Período',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.calendar_today),
                                  ),
                                  items: _timeRanges.map((range) {
                                    return DropdownMenuItem<String>(
                                      value: range['value'],
                                      child: Text(range['label']!),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() => _selectedTimeRange = value);
                                      ref.read(financialMetricsProvider.notifier).setTimeRange(value);
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              
                              // Filtro de categoria
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _selectedCategory,
                                  decoration: const InputDecoration(
                                    labelText: 'Categoria',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.category),
                                  ),
                                  items: categories.map((category) {
                                    return DropdownMenuItem<String>(
                                      value: category,
                                      child: Text(_getCategoryLabel(category)),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() => _selectedCategory = value);
                                      ref.read(financialMetricsProvider.notifier).setCategory(value);
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              
                              // Seletor de data
                              IconButton(
                                icon: const Icon(Icons.date_range),
                                onPressed: () => _selectDate(context),
                                tooltip: 'Selecionar data',
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Cards de métricas principais (mantidos no topo, horizontais)
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildMainMetricCard(
                                  'Receita Total',
                                  keyMetrics['revenue'] ?? 0,
                                  'R\$',
                                  Icons.trending_up,
                                  Colors.green,
                                ),
                                const SizedBox(width: 12),
                                _buildMainMetricCard(
                                  'Despesas',
                                  keyMetrics['expenses'] ?? 0,
                                  'R\$',
                                  Icons.trending_down,
                                  Colors.red,
                                ),
                                const SizedBox(width: 12),
                                _buildMainMetricCard(
                                  'Lucro',
                                  keyMetrics['profit'] ?? 0,
                                  'R\$',
                                  Icons.account_balance,
                                  Colors.blue,
                                ),
                                const SizedBox(width: 12),
                                _buildMainMetricCard(
                                  'Margem',
                                  keyMetrics['profit_margin'] ?? 0,
                                  '%',
                                  Icons.percent,
                                  Colors.purple,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Conteúdo principal
                if (provider.isLoading)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (provider.error != null)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Erro ao carregar dados',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            provider.error!,
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => ref.read(financialMetricsProvider.notifier).loadMetrics(),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Tentar novamente'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ..._buildContent(provider, isDarkMode),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildContent(FinancialMetricsProvider provider, bool isDarkMode) {
    final metricsByCategory = provider.metricsByCategory;
    final alerts = provider.alerts;
    
    return [
      // Alertas
      if (alerts.isNotEmpty)
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.red[700]),
                    const SizedBox(width: 8),
                    Text(
                      'Alertas (${alerts.length})',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...alerts.take(3).map((alert) => Padding(
                  padding: const EdgeInsets.only(left: 32, bottom: 4),
                  child: Text(
                    '• ${alert.name}: ${alert.currentValue.toStringAsFixed(2)}${alert.unit}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red[700],
                    ),
                  ),
                )),
                if (alerts.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(left: 32, top: 4),
                    child: Text(
                      'e mais ${alerts.length - 3} alertas...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      
      // Gráfico principal
      if (_showCharts)
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.all(16),
            child: _buildMainChart(provider),
          ),
        ),
      
      // Métricas por categoria
      ...metricsByCategory.entries.map((entry) {
        final category = entry.key;
        final metrics = entry.value;
        
        return SliverToBoxAdapter(
          child: FinancialKPIGroup(
            title: _getCategoryLabel(category),
            metrics: metrics,
            showCharts: _showCharts,
            onEdit: (metric) => _showEditMetricModal(context, metric),
            onDelete: (metric) => _showDeleteMetricDialog(context, metric),
          ),
        );
      }),
      
      const SliverToBoxAdapter(child: SizedBox(height: 32)),
    ];
  }

  Widget _buildMainMetricCard(
    String title,
    double value,
    String unit,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: color.withOpacity(0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _formatValue(value, unit),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainChart(FinancialMetricsProvider provider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        height: 300,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Evolução Financeira',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    _buildChartLegend(Colors.green, 'Receita'),
                    const SizedBox(width: 16),
                    _buildChartLegend(Colors.red, 'Despesas'),
                    const SizedBox(width: 16),
                    _buildChartLegend(Colors.blue, 'Lucro'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _buildLineChart(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartLegend(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildLineChart() {
    // Dados de exemplo para o gráfico principal
    final revenueData = [100, 120, 150, 180, 200, 220, 250, 280, 300, 320, 350, 380];
    final expenseData = [60, 70, 85, 90, 100, 110, 120, 130, 140, 150, 160, 170];
    final profitData = revenueData.map((r) => r - expenseData[revenueData.indexOf(r)]).toList();
    
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 50,
          verticalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.2),
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.2),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                const months = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 
                               'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
                if (value.toInt() >= 0 && value.toInt() < months.length) {
                  return Text(
                    months[value.toInt()],
                    style: const TextStyle(fontSize: 10),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 50,
              reservedSize: 42,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}K',
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        minX: 0,
        maxX: 11,
        minY: 0,
        maxY: 400,
        lineBarsData: [
          LineChartBarData(
            spots: revenueData.asMap().entries.map((e) => 
              FlSpot(e.key.toDouble(), e.value.toDouble())).toList(),
            isCurved: true,
            gradient: LinearGradient(
              colors: [Colors.green[300]!, Colors.green[700]!],
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [Colors.green.withOpacity(0.1), Colors.green.withOpacity(0.3)],
              ),
            ),
          ),
          LineChartBarData(
            spots: expenseData.asMap().entries.map((e) => 
              FlSpot(e.key.toDouble(), e.value.toDouble())).toList(),
            isCurved: true,
            gradient: LinearGradient(
              colors: [Colors.red[300]!, Colors.red[700]!],
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [Colors.red.withOpacity(0.1), Colors.red.withOpacity(0.3)],
              ),
            ),
          ),
          LineChartBarData(
            spots: profitData.asMap().entries.map((e) => 
              FlSpot(e.key.toDouble(), e.value.toDouble())).toList(),
            isCurved: true,
            gradient: LinearGradient(
              colors: [Colors.blue[300]!, Colors.blue[700]!],
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [Colors.blue.withOpacity(0.1), Colors.blue.withOpacity(0.3)],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddMetricModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => FinancialMetricModal(
        onSave: (metric) {
          ref.read(financialMetricsProvider.notifier).addMetric(metric);
        },
      ),
    );
  }

  void _showEditMetricModal(BuildContext context, FinancialMetric metric) {
    showDialog(
      context: context,
      builder: (context) => FinancialMetricModal(
        metric: metric,
        onSave: (updatedMetric) {
          ref.read(financialMetricsProvider.notifier).updateMetric(updatedMetric);
        },
      ),
    );
  }

  void _showDeleteMetricDialog(BuildContext context, FinancialMetric metric) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir métrica'),
        content: Text('Tem certeza que deseja excluir a métrica "${metric.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(financialMetricsProvider.notifier).deleteMetric(metric.id);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      ref.read(financialMetricsProvider.notifier).setDate(picked);
    }
  }

  String _formatValue(double value, String unit) {
    if (unit == '%') {
      return '${value.toStringAsFixed(1)}%';
    } else if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    } else {
      return '${value.toStringAsFixed(0)}';
    }
  }

  String _getCategoryLabel(String category) {
    final labels = {
      'all': 'Todas',
      'revenue': 'Receita',
      'expense': 'Despesa',
      'profit': 'Lucro',
      'cash_flow': 'Fluxo de Caixa',
      'cost': 'Custo',
      'investment': 'Investimento',
      'debt': 'Dívida',
      'tax': 'Imposto',
      'commission': 'Comissão',
      'other': 'Outro',
    };
    return labels[category] ?? category;
  }
}
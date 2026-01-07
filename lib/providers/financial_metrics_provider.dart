import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/financial_metric.dart';
import '../services/financial_service.dart';

class FinancialMetricsProvider extends ChangeNotifier {
  final FinancialService _financialService = FinancialService();
  
  List<FinancialMetric> _metrics = [];
  List<FinancialMetric> _filteredMetrics = [];
  String _selectedCategory = 'all';
  String _selectedTimeRange = 'month';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  String? _error;

  // Getters
  List<FinancialMetric> get metrics => _filteredMetrics;
  List<FinancialMetric> get allMetrics => _metrics;
  String get selectedCategory => _selectedCategory;
  String get selectedTimeRange => _selectedTimeRange;
  DateTime get selectedDate => _selectedDate;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Categorias disponíveis
  List<String> get categories {
    final uniqueCategories = _metrics.map((m) => m.category).toSet().toList();
    return ['all', ...uniqueCategories];
  }

  // Métricas por categoria
  Map<String, List<FinancialMetric>> get metricsByCategory {
    final Map<String, List<FinancialMetric>> grouped = {};
    for (final metric in _filteredMetrics) {
      grouped.putIfAbsent(metric.category, () => []);
      grouped[metric.category]!.add(metric);
    }
    return grouped;
  }

  // Métricas principais calculadas
  Map<String, double> get keyMetrics {
    final revenue = _getMetricValue('revenue');
    final expenses = _getMetricValue('expense');
    final profit = revenue - expenses;
    final profitMargin = revenue > 0 ? (profit / revenue) * 100 : 0.0;
    
    return {
      'revenue': revenue,
      'expenses': expenses,
      'profit': profit,
      'profit_margin': profitMargin.toDouble(),
      'cash_flow': _getMetricValue('cash_flow'),
      'roi': _getMetricValue('roi'),
    };
  }

  double _getMetricValue(String category) {
    final categoryMetrics = _filteredMetrics.where((m) => m.category == category).toList();
    if (categoryMetrics.isEmpty) return 0.0;
    return categoryMetrics.map((m) => m.currentValue).reduce((a, b) => a + b);
  }

  // Tendências e variações
  Map<String, double> get trends {
    final Map<String, double> trends = {};
    for (final metric in _filteredMetrics) {
      trends[metric.name] = metric.variationPercentage;
    }
    return trends;
  }

  // Alertas
  List<FinancialMetric> get alerts {
    return _filteredMetrics.where((m) => m.hasAlert).toList();
  }

  // Inicialização
  Future<void> initialize() async {
    await loadMetrics();
  }

  // Carregar métricas
  Future<void> loadMetrics() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _metrics = await _financialService.getFinancialMetrics();
      _applyFilters();
    } catch (e) {
      _error = 'Erro ao carregar métricas: $e';
      _metrics = _getDefaultMetrics(); // Dados de exemplo
      _applyFilters();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Aplicar filtros
  void _applyFilters() {
    _filteredMetrics = _metrics.where((metric) {
      // Filtro por categoria
      if (_selectedCategory != 'all' && metric.category != _selectedCategory) {
        return false;
      }
      
      // Filtro por status ativo
      if (!metric.isActive) return false;
      
      return true;
    }).toList();
  }

  // Alterar categoria
  void setCategory(String category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  // Alterar período de tempo
  void setTimeRange(String timeRange) {
    _selectedTimeRange = timeRange;
    _updateMetricsForTimeRange();
    notifyListeners();
  }

  // Alterar data
  void setDate(DateTime date) {
    _selectedDate = date;
    _updateMetricsForTimeRange();
    notifyListeners();
  }

  // Atualizar métricas para o período selecionado
  void _updateMetricsForTimeRange() {
    // Simular dados baseados no período selecionado
    // Em produção, isso buscaria dados reais do backend
    for (int i = 0; i < _metrics.length; i++) {
      final baseValue = _metrics[i].currentValue;
      final variation = _getTimeVariation();
      _metrics[i] = _metrics[i].copyWith(
        currentValue: baseValue * variation,
        previousValue: baseValue,
      );
    }
    _applyFilters();
  }

  double _getTimeVariation() {
    switch (_selectedTimeRange) {
      case 'day':
        return 1.0; // Sem variação para dia
      case 'week':
        return 1.05; // +5% para semana
      case 'month':
        return 1.15; // +15% para mês
      case 'quarter':
        return 1.35; // +35% para trimestre
      case 'year':
        return 1.80; // +80% para ano
      default:
        return 1.0;
    }
  }

  // Adicionar nova métrica
  Future<void> addMetric(FinancialMetric metric) async {
    try {
      final newMetric = await _financialService.createFinancialMetric(metric);
      _metrics.add(newMetric);
      _applyFilters();
      notifyListeners();
    } catch (e) {
      _error = 'Erro ao adicionar métrica: $e';
      notifyListeners();
    }
  }

  // Atualizar métrica
  Future<void> updateMetric(FinancialMetric metric) async {
    try {
      final updatedMetric = await _financialService.updateFinancialMetric(metric);
      final index = _metrics.indexWhere((m) => m.id == metric.id);
      if (index != -1) {
        _metrics[index] = updatedMetric;
        _applyFilters();
        notifyListeners();
      }
    } catch (e) {
      _error = 'Erro ao atualizar métrica: $e';
      notifyListeners();
    }
  }

  // Excluir métrica
  Future<void> deleteMetric(String id) async {
    try {
      await _financialService.deleteFinancialMetric(id);
      _metrics.removeWhere((m) => m.id == id);
      _applyFilters();
      notifyListeners();
    } catch (e) {
      _error = 'Erro ao excluir métrica: $e';
      notifyListeners();
    }
  }

  // Dados de exemplo para desenvolvimento
  List<FinancialMetric> _getDefaultMetrics() {
    return [
      FinancialMetric(
        id: '1',
        name: 'Receita Total',
        description: 'Receita total do período',
        currentValue: 150000.0,
        previousValue: 120000.0,
        unit: 'R\$',
        category: 'revenue',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
        targetValue: '200000',
      ),
      FinancialMetric(
        id: '2',
        name: 'Despesas Operacionais',
        description: 'Total de despesas operacionais',
        currentValue: 85000.0,
        previousValue: 75000.0,
        unit: 'R\$',
        category: 'expense',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
        alertThreshold: '90000',
      ),
      FinancialMetric(
        id: '3',
        name: 'Lucro Bruto',
        description: 'Lucro antes de impostos',
        currentValue: 65000.0,
        previousValue: 45000.0,
        unit: 'R\$',
        category: 'profit',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
        targetValue: '80000',
      ),
      FinancialMetric(
        id: '4',
        name: 'Fluxo de Caixa',
        description: 'Fluxo de caixa operacional',
        currentValue: 45000.0,
        previousValue: 30000.0,
        unit: 'R\$',
        category: 'cash_flow',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
      ),
      FinancialMetric(
        id: '5',
        name: 'ROI',
        description: 'Retorno sobre investimento',
        currentValue: 15.5,
        previousValue: 12.3,
        unit: '%',
        category: 'investment',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
        targetValue: '20',
      ),
    ];
  }

  // Limpar erro
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

// Provider Riverpod
final financialMetricsProvider = ChangeNotifierProvider<FinancialMetricsProvider>((ref) {
  return FinancialMetricsProvider();
});
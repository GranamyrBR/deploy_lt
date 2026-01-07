import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/financial_metric.dart';

class FinancialService {
  static const String baseUrl = 'https://your-api-url.com/api';
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Buscar todas as métricas financeiras
  Future<List<FinancialMetric>> getFinancialMetrics() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/financial-metrics'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => FinancialMetric.fromJson(json)).toList();
      } else {
        throw Exception('Falha ao carregar métricas: ${response.statusCode}');
      }
    } catch (e) {
      // Retornar dados de exemplo se houver erro
      return _getDefaultMetrics();
    }
  }

  // Buscar métrica por ID
  Future<FinancialMetric> getFinancialMetricById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/financial-metrics/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return FinancialMetric.fromJson(json.decode(response.body));
      } else {
        throw Exception('Falha ao carregar métrica: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao buscar métrica: $e');
    }
  }

  // Criar nova métrica
  Future<FinancialMetric> createFinancialMetric(FinancialMetric metric) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/financial-metrics'),
        headers: headers,
        body: json.encode(metric.toJson()),
      );

      if (response.statusCode == 201) {
        return FinancialMetric.fromJson(json.decode(response.body));
      } else {
        throw Exception('Falha ao criar métrica: ${response.statusCode}');
      }
    } catch (e) {
      // Retornar a métrica original se houver erro
      return metric;
    }
  }

  // Atualizar métrica
  Future<FinancialMetric> updateFinancialMetric(FinancialMetric metric) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/financial-metrics/${metric.id}'),
        headers: headers,
        body: json.encode(metric.toJson()),
      );

      if (response.statusCode == 200) {
        return FinancialMetric.fromJson(json.decode(response.body));
      } else {
        throw Exception('Falha ao atualizar métrica: ${response.statusCode}');
      }
    } catch (e) {
      // Retornar a métrica original se houver erro
      return metric;
    }
  }

  // Excluir métrica
  Future<void> deleteFinancialMetric(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/financial-metrics/$id'),
        headers: headers,
      );

      if (response.statusCode != 204) {
        throw Exception('Falha ao excluir métrica: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao excluir métrica: $e');
    }
  }

  // Buscar métricas por período
  Future<List<FinancialMetric>> getFinancialMetricsByPeriod({
    required DateTime startDate,
    required DateTime endDate,
    String? category,
  }) async {
    try {
      final params = {
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        if (category != null) 'category': category,
      };

      final uri = Uri.parse('$baseUrl/financial-metrics/by-period')
          .replace(queryParameters: params);

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => FinancialMetric.fromJson(json)).toList();
      } else {
        throw Exception('Falha ao carregar métricas por período: ${response.statusCode}');
      }
    } catch (e) {
      return _getDefaultMetrics();
    }
  }

  // Buscar dados para gráficos
  Future<Map<String, dynamic>> getChartData({
    required String metricType,
    required String timeRange,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final params = {
        'metric_type': metricType,
        'time_range': timeRange,
        if (startDate != null) 'start_date': startDate.toIso8601String(),
        if (endDate != null) 'end_date': endDate.toIso8601String(),
      };

      final uri = Uri.parse('$baseUrl/financial-metrics/chart-data')
          .replace(queryParameters: params);

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Falha ao carregar dados do gráfico: ${response.statusCode}');
      }
    } catch (e) {
      // Retornar dados de exemplo para gráficos
      return _getDefaultChartData(metricType, timeRange);
    }
  }

  // Buscar resumo financeiro
  Future<Map<String, double>> getFinancialSummary({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final params = {
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
      };

      final uri = Uri.parse('$baseUrl/financial-metrics/summary')
          .replace(queryParameters: params);

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data.map((key, value) => MapEntry(key, value.toDouble()));
      } else {
        throw Exception('Falha ao carregar resumo financeiro: ${response.statusCode}');
      }
    } catch (e) {
      return _getDefaultSummary();
    }
  }

  // Dados de exemplo
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
    ];
  }

  Map<String, dynamic> _getDefaultChartData(String metricType, String timeRange) {
    final now = DateTime.now();
    final dataPoints = _generateTimeSeriesData(metricType, timeRange);
    
    return {
      'labels': dataPoints.map((p) => p['label']).toList(),
      'values': dataPoints.map((p) => p['value']).toList(),
      'metric_type': metricType,
      'time_range': timeRange,
      'generated_at': now.toIso8601String(),
    };
  }

  List<Map<String, dynamic>> _generateTimeSeriesData(String metricType, String timeRange) {
    final data = <Map<String, dynamic>>[];
    final now = DateTime.now();
    int points = 12;
    
    switch (timeRange) {
      case 'day':
        points = 24; // 24 horas
        for (int i = 0; i < points; i++) {
          data.add({
            'label': '${i}h',
            'value': _generateRandomValue(metricType, i),
          });
        }
        break;
      case 'week':
        points = 7; // 7 dias
        for (int i = 0; i < points; i++) {
          data.add({
            'label': _getWeekDay(i),
            'value': _generateRandomValue(metricType, i),
          });
        }
        break;
      case 'month':
        points = 30; // 30 dias
        for (int i = 1; i <= points; i++) {
          data.add({
            'label': '$i',
            'value': _generateRandomValue(metricType, i),
          });
        }
        break;
      case 'quarter':
        points = 12; // 12 semanas
        for (int i = 1; i <= points; i++) {
          data.add({
            'label': 'S$i',
            'value': _generateRandomValue(metricType, i),
          });
        }
        break;
      case 'year':
        points = 12; // 12 meses
        for (int i = 0; i < points; i++) {
          data.add({
            'label': _getMonthName(i),
            'value': _generateRandomValue(metricType, i),
          });
        }
        break;
      default:
        points = 12;
        for (int i = 0; i < points; i++) {
          data.add({
            'label': 'P${i + 1}',
            'value': _generateRandomValue(metricType, i),
          });
        }
    }
    
    return data;
  }

  double _generateRandomValue(String metricType, int index) {
    final baseValues = {
      'revenue': 100000.0,
      'expense': 60000.0,
      'profit': 40000.0,
      'cash_flow': 30000.0,
      'roi': 15.0,
    };
    
    final base = baseValues[metricType] ?? 50000.0;
    final variation = (index * 0.05) + (DateTime.now().millisecond % 20) * 0.01;
    return base + (base * variation);
  }

  String _getWeekDay(int index) {
    final days = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
    return days[index % days.length];
  }

  String _getMonthName(int index) {
    final months = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 
                   'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
    return months[index % months.length];
  }

  Map<String, double> _getDefaultSummary() {
    return {
      'revenue': 150000.0,
      'expenses': 85000.0,
      'profit': 65000.0,
      'profit_margin': 43.33,
      'cash_flow': 45000.0,
      'roi': 15.5,
    };
  }
}
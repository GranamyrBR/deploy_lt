import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:state_notifier/state_notifier.dart';

import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class WeeklyDistributionData {
  final Map<String, double> weeklyData;
  final double totalRevenue;
  final double averageRevenue;
  final String bestDay;
  final String worstDay;
  final bool isLoading;
  final String? errorMessage;

  WeeklyDistributionData({
    required this.weeklyData,
    required this.totalRevenue,
    required this.averageRevenue,
    required this.bestDay,
    required this.worstDay,
    this.isLoading = false,
    this.errorMessage,
  });

  WeeklyDistributionData copyWith({
    Map<String, double>? weeklyData,
    double? totalRevenue,
    double? averageRevenue,
    String? bestDay,
    String? worstDay,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return WeeklyDistributionData(
      weeklyData: weeklyData ?? this.weeklyData,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      averageRevenue: averageRevenue ?? this.averageRevenue,
      bestDay: bestDay ?? this.bestDay,
      worstDay: worstDay ?? this.worstDay,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class WeeklyDistributionNotifier extends StateNotifier<WeeklyDistributionData> {
  WeeklyDistributionNotifier()
      : super(WeeklyDistributionData(
          weeklyData: {},
          totalRevenue: 0.0,
          averageRevenue: 0.0,
          bestDay: '',
          worstDay: '',
        )) {
    fetchWeeklyData();
  }

  Future<void> fetchWeeklyData() async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      final weeklyData = await _calculateWeeklyDistribution();
      
      state = state.copyWith(
        weeklyData: weeklyData['weeklyData'] ?? {},
        totalRevenue: weeklyData['totalRevenue'] ?? 0.0,
        averageRevenue: weeklyData['averageRevenue'] ?? 0.0,
        bestDay: weeklyData['bestDay'] ?? '',
        worstDay: weeklyData['worstDay'] ?? '',
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Erro ao buscar dados semanais: $e',
      );
    }
  }

  Future<Map<String, dynamic>> _calculateWeeklyDistribution() async {
    try {
      // Carregar dados do JSON
      final jsonString = await rootBundle.loadString('assets/commission_data.json');
      final List<dynamic> rawData = json.decode(jsonString);
      
      print('DEBUG: Calculando distribuição semanal de ${rawData.length} registros');

      // Mapear dias da semana
      final Map<String, double> weeklyRevenue = {
        'Segunda': 0.0,
        'Terça': 0.0,
        'Quarta': 0.0,
        'Quinta': 0.0,
        'Sexta': 0.0,
        'Sábado': 0.0,
        'Domingo': 0.0,
      };

      double totalRevenue = 0.0;
      int totalRecords = 0;

      for (final record in rawData) {
        final valorCobrado = _parseDouble(record['Valor Cobrado']);
        final dataStr = record['Data do Serviço']?.toString();
        
        print('DEBUG: Processando registro - Data: $dataStr, Valor: $valorCobrado');
        
        if (dataStr != null && dataStr != 'nan' && valorCobrado > 0) {
          try {
            // Tentar diferentes formatos de data
            DateTime? data;
            
            // Formato: YYYY-MM-DD HH:MM:SS
            if (dataStr.contains('-') && dataStr.contains(':')) {
              data = DateTime.parse(dataStr);
            }
            // Formato: DD/MM/YYYY
            else if (dataStr.contains('/')) {
              final parts = dataStr.split('/');
              if (parts.length == 3) {
                data = DateTime(
                  int.parse(parts[2]),
                  int.parse(parts[1]),
                  int.parse(parts[0]),
                );
              }
            }
            // Formato: YYYY-MM-DD
            else if (dataStr.contains('-')) {
              data = DateTime.parse(dataStr);
            }
            
            if (data != null) {
              final dayOfWeek = _getDayOfWeek(data.weekday);
              weeklyRevenue[dayOfWeek] = (weeklyRevenue[dayOfWeek] ?? 0.0) + valorCobrado;
              totalRevenue += valorCobrado;
              totalRecords++;
              
              print('DEBUG: Data processada: ${data.toString()} -> $dayOfWeek, Valor: $valorCobrado');
            } else {
              print('DEBUG: Não foi possível processar a data: $dataStr');
            }
          } catch (e) {
            print('Erro ao processar data: $dataStr - $e');
          }
        }
      }

      print('DEBUG: Distribuição semanal calculada:');
      weeklyRevenue.forEach((day, revenue) {
        print('  $day: \$${revenue.toStringAsFixed(2)}');
      });

      // Encontrar melhor e pior dia
      String bestDay = '';
      String worstDay = '';
      double maxRevenue = 0.0;
      double minRevenue = double.infinity;

      weeklyRevenue.forEach((day, revenue) {
        if (revenue > maxRevenue) {
          maxRevenue = revenue;
          bestDay = day;
        }
        if (revenue < minRevenue && revenue > 0) {
          minRevenue = revenue;
          worstDay = day;
        }
      });

      final averageRevenue = totalRecords > 0 ? totalRevenue / totalRecords : 0.0;

      return {
        'weeklyData': weeklyRevenue,
        'totalRevenue': totalRevenue,
        'averageRevenue': averageRevenue,
        'bestDay': bestDay,
        'worstDay': worstDay,
      };
    } catch (e) {
      print('Erro ao calcular distribuição semanal: $e');
      return {
        'weeklyData': {},
        'totalRevenue': 0.0,
        'averageRevenue': 0.0,
        'bestDay': '',
        'worstDay': '',
      };
    }
  }

  String _getDayOfWeek(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Segunda';
      case DateTime.tuesday:
        return 'Terça';
      case DateTime.wednesday:
        return 'Quarta';
      case DateTime.thursday:
        return 'Quinta';
      case DateTime.friday:
        return 'Sexta';
      case DateTime.saturday:
        return 'Sábado';
      case DateTime.sunday:
        return 'Domingo';
      default:
        return 'Segunda';
    }
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value.replaceAll(',', '.').replaceAll('\$', '').trim());
      } catch (e) {
        return 0.0;
      }
    }
    return 0.0;
  }
}

final weeklyDistributionProvider = StateNotifierProvider<WeeklyDistributionNotifier, WeeklyDistributionData>((ref) {
  return WeeklyDistributionNotifier();
}); 

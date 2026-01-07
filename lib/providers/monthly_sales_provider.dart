import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:state_notifier/state_notifier.dart';

import 'package:flutter/services.dart';
import 'dart:convert';

class MonthlySalesData {
  final List<MonthlySales> monthlySales2024;
  final List<MonthlySales> monthlySales2025;
  final double totalRevenue2024;
  final double totalRevenue2025;
  final double totalCommissions2024;
  final double totalCommissions2025;
  final bool isLoading;
  final String? errorMessage;

  MonthlySalesData({
    required this.monthlySales2024,
    required this.monthlySales2025,
    required this.totalRevenue2024,
    required this.totalRevenue2025,
    required this.totalCommissions2024,
    required this.totalCommissions2025,
    this.isLoading = false,
    this.errorMessage,
  });

  MonthlySalesData copyWith({
    List<MonthlySales>? monthlySales2024,
    List<MonthlySales>? monthlySales2025,
    double? totalRevenue2024,
    double? totalRevenue2025,
    double? totalCommissions2024,
    double? totalCommissions2025,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return MonthlySalesData(
      monthlySales2024: monthlySales2024 ?? this.monthlySales2024,
      monthlySales2025: monthlySales2025 ?? this.monthlySales2025,
      totalRevenue2024: totalRevenue2024 ?? this.totalRevenue2024,
      totalRevenue2025: totalRevenue2025 ?? this.totalRevenue2025,
      totalCommissions2024: totalCommissions2024 ?? this.totalCommissions2024,
      totalCommissions2025: totalCommissions2025 ?? this.totalCommissions2025,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class MonthlySales {
  final int month;
  final double revenue;
  final double commissions;
  final int operations;

  MonthlySales({
    required this.month,
    required this.revenue,
    required this.commissions,
    required this.operations,
  });
}

class MonthlySalesNotifier extends StateNotifier<MonthlySalesData> {
  MonthlySalesNotifier()
      : super(MonthlySalesData(
          monthlySales2024: [],
          monthlySales2025: [],
          totalRevenue2024: 0.0,
          totalRevenue2025: 0.0,
          totalCommissions2024: 0.0,
          totalCommissions2025: 0.0,
        )) {
    fetchMonthlySales();
  }

  Future<void> fetchMonthlySales() async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      // Carregar dados do JSON da planilha
      final jsonString = await rootBundle.loadString('assets/commission_data.json');
      final List<dynamic> rawData = json.decode(jsonString);
      
      print('DEBUG: Carregando vendas mensais de ${rawData.length} registros');

      // Processar dados por ano e mês
      final Map<int, Map<int, Map<String, dynamic>>> yearlyStats = {};
      
      for (final record in rawData) {
        final dataServico = record['Data do Serviço']?.toString();
        if (dataServico != null && dataServico != 'null' && dataServico != 'ID Fatura') {
          try {
            final date = DateTime.parse(dataServico);
            final year = date.year;
            final month = date.month;
            final valorCobrado = _parseDouble(record['Valor Cobrado']);
            final repasse = _parseDouble(record['Repasse \$']);
            
            if (!yearlyStats.containsKey(year)) {
              yearlyStats[year] = {};
            }
            if (!yearlyStats[year]!.containsKey(month)) {
              yearlyStats[year]![month] = {
                'revenue': 0.0,
                'commissions': 0.0,
                'operations': 0,
              };
            }
            
            final stats = yearlyStats[year]![month]!;
            stats['revenue'] = (stats['revenue'] as double) + valorCobrado;
            stats['commissions'] = (stats['commissions'] as double) + repasse;
            stats['operations'] = (stats['operations'] as int) + 1;
          } catch (e) {
            print('Erro ao processar data: $dataServico - $e');
          }
        }
      }

      // Mostrar distribuição por ano
      print('DEBUG: Distribuição por ano:');
      for (final year in yearlyStats.keys) {
        final yearData = yearlyStats[year]!;
        final totalOps = yearData.values.fold(0, (sum, stats) => sum + (stats['operations'] as int));
        final totalRev = yearData.values.fold(0.0, (sum, stats) => sum + (stats['revenue'] as double));
        print('  $year: $totalOps operações, \$${totalRev.toStringAsFixed(2)} receita em ${yearData.length} meses');
      }

      // Processar dados de 2024
      final monthlyStats2024 = yearlyStats[2024] ?? {};
      final monthlySales2024 = monthlyStats2024.entries.map((entry) {
        final stats = entry.value;
        return MonthlySales(
          month: entry.key,
          revenue: stats['revenue'] as double,
          commissions: stats['commissions'] as double,
          operations: stats['operations'] as int,
        );
      }).toList();
      monthlySales2024.sort((a, b) => a.month.compareTo(b.month));

      // Processar dados de 2025
      final monthlyStats2025 = yearlyStats[2025] ?? {};
      final monthlySales2025 = monthlyStats2025.entries.map((entry) {
        final stats = entry.value;
        return MonthlySales(
          month: entry.key,
          revenue: stats['revenue'] as double,
          commissions: stats['commissions'] as double,
          operations: stats['operations'] as int,
        );
      }).toList();
      monthlySales2025.sort((a, b) => a.month.compareTo(b.month));

      // Calcular totais
      final totalRevenue2024 = monthlySales2024.fold(0.0, (sum, month) => sum + month.revenue);
      final totalRevenue2025 = monthlySales2025.fold(0.0, (sum, month) => sum + month.revenue);
      final totalCommissions2024 = monthlySales2024.fold(0.0, (sum, month) => sum + month.commissions);
      final totalCommissions2025 = monthlySales2025.fold(0.0, (sum, month) => sum + month.commissions);

      print('DEBUG: Comparação 2024 vs 2025:');
      print('  2024: \$${totalRevenue2024.toStringAsFixed(2)} receita, \$${totalCommissions2024.toStringAsFixed(2)} comissões');
      print('  2025: \$${totalRevenue2025.toStringAsFixed(2)} receita, \$${totalCommissions2025.toStringAsFixed(2)} comissões');

      state = state.copyWith(
        monthlySales2024: monthlySales2024,
        monthlySales2025: monthlySales2025,
        totalRevenue2024: totalRevenue2024,
        totalRevenue2025: totalRevenue2025,
        totalCommissions2024: totalCommissions2024,
        totalCommissions2025: totalCommissions2025,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Erro ao carregar vendas mensais: $e',
      );
    }
  }

  double _parseDouble(dynamic value) {
    if (value == null || value == 'nan' || value == '') return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) {
      final cleaned = value.replaceAll(RegExp(r'[^\d.-]'), '');
      return double.tryParse(cleaned) ?? 0.0;
    }
    return 0.0;
  }
}

final monthlySalesProvider = StateNotifierProvider<MonthlySalesNotifier, MonthlySalesData>((ref) {
  return MonthlySalesNotifier();
}); 

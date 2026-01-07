import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:state_notifier/state_notifier.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

class DriverCommissionData {
  final int totalDrivers;
  final double totalCommissions;
  final double averageCommission;
  final int driversWithCommissions;
  final List<DriverCommission> topDrivers;
  final bool isLoading;
  final String? errorMessage;

  DriverCommissionData({
    required this.totalDrivers,
    required this.totalCommissions,
    required this.averageCommission,
    required this.driversWithCommissions,
    required this.topDrivers,
    this.isLoading = false,
    this.errorMessage,
  });

  DriverCommissionData copyWith({
    int? totalDrivers,
    double? totalCommissions,
    double? averageCommission,
    int? driversWithCommissions,
    List<DriverCommission>? topDrivers,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DriverCommissionData(
      totalDrivers: totalDrivers ?? this.totalDrivers,
      totalCommissions: totalCommissions ?? this.totalCommissions,
      averageCommission: averageCommission ?? this.averageCommission,
      driversWithCommissions: driversWithCommissions ?? this.driversWithCommissions,
      topDrivers: topDrivers ?? this.topDrivers,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class DriverCommission {
  final int driverId;
  final String driverName;
  final double commission;
  final int trips;
  final double totalRevenue;
  final String? paymentMethod;
  final bool isArtist;

  DriverCommission({
    required this.driverId,
    required this.driverName,
    required this.commission,
    required this.trips,
    required this.totalRevenue,
    this.paymentMethod,
    this.isArtist = false,
  });
}

class DriverCommissionNotifier extends StateNotifier<DriverCommissionData> {
  final SupabaseClient _supabase;

  DriverCommissionNotifier(this._supabase)
      : super(DriverCommissionData(
          totalDrivers: 0,
          totalCommissions: 0.0,
          averageCommission: 0.0,
          driversWithCommissions: 0,
          topDrivers: [],
        )) {
    fetchCommissionData();
  }

  Future<void> fetchCommissionData() async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      // Buscar dados reais da planilha
      final commissionData = await _getRealCommissionData();
      
      state = state.copyWith(
        totalDrivers: commissionData['totalDrivers'] ?? 0,
        totalCommissions: commissionData['totalCommissions'] ?? 0.0,
        averageCommission: commissionData['averageCommission'] ?? 0.0,
        driversWithCommissions: commissionData['driversWithCommissions'] ?? 0,
        topDrivers: commissionData['topDrivers'] ?? [],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Erro ao buscar dados de comissões: $e',
      );
    }
  }

  Future<Map<String, dynamic>> _getRealCommissionData() async {
    try {
      // Carregar dados do JSON dos assets
      final jsonString = await rootBundle.loadString('assets/commission_data.json');
      final List<dynamic> rawData = json.decode(jsonString);
      
      print('DEBUG: Carregados ${rawData.length} registros do JSON');

      // Processar dados dos motoristas
      final Map<String, Map<String, dynamic>> driverStats = {};
      
      for (final record in rawData) {
        final driverName = record['Motoristas']?.toString() ?? 'Sem Motorista';
        final valorCobrado = _parseDouble(record['Valor Cobrado']);
        final repasse = _parseDouble(record['Repasse \$']);
        final formaPagamento = record['FormaPagamento']?.toString();
        final servicoPago = record['Serviço Pago']?.toString();
        
        if (!driverStats.containsKey(driverName)) {
          driverStats[driverName] = {
            'trips': 0,
            'totalRevenue': 0.0,
            'totalCommission': 0.0,
            'paymentMethods': <String>{},
            'paidServices': 0,
            'unpaidServices': 0,
          };
        }
        
        final stats = driverStats[driverName]!;
        stats['trips'] = (stats['trips'] as int) + 1;
        stats['totalRevenue'] = (stats['totalRevenue'] as double) + valorCobrado;
        stats['totalCommission'] = (stats['totalCommission'] as double) + repasse;
        
        if (formaPagamento != null && formaPagamento != 'nan') {
          (stats['paymentMethods'] as Set<String>).add(formaPagamento);
        }
        
        if (servicoPago == 'SIM') {
          stats['paidServices'] = (stats['paidServices'] as int) + 1;
        } else {
          stats['unpaidServices'] = (stats['unpaidServices'] as int) + 1;
        }
      }

      print('DEBUG: Processados ${driverStats.length} motoristas únicos');
      print('DEBUG: Motoristas encontrados: ${driverStats.keys.toList()}');

      // Converter para lista de DriverCommission
      final topDrivers = driverStats.entries.map((entry) {
        final stats = entry.value;
        final paymentMethod = (stats['paymentMethods'] as Set<String>).isNotEmpty 
            ? (stats['paymentMethods'] as Set<String>).first 
            : null;
        
        return DriverCommission(
          driverId: entry.key.hashCode,
          driverName: entry.key,
          commission: stats['totalCommission'] as double,
          trips: stats['trips'] as int,
          totalRevenue: stats['totalRevenue'] as double,
          paymentMethod: paymentMethod,
          isArtist: _isArtist(entry.key),
        );
      }).toList();

      // Ordenar por comissão (maior primeiro)
      topDrivers.sort((a, b) => b.commission.compareTo(a.commission));

      print('DEBUG: Top 5 motoristas por comissão:');
      for (int i = 0; i < topDrivers.take(5).length; i++) {
        final driver = topDrivers[i];
        print('  ${i+1}. ${driver.driverName}: \$${driver.commission.toStringAsFixed(2)} (${driver.trips} viagens)');
      }

      // Log específico para Leco Campos
      final lecoCampos = topDrivers.where((d) => d.driverName == 'Leco Campos').firstOrNull;
      if (lecoCampos != null) {
        print('DEBUG: Leco Campos encontrado: \$${lecoCampos.commission.toStringAsFixed(2)} (${lecoCampos.trips} viagens)');
      } else {
        print('DEBUG: Leco Campos NÃO encontrado na lista de topDrivers');
      }

      // Mostrar todos os motoristas com comissão > 0
      final driversWithCommission = topDrivers.where((d) => d.commission > 0).toList();
      print('DEBUG: Motoristas com comissão > 0: ${driversWithCommission.length}');
      print('DEBUG: Primeiros 10 com comissão:');
      for (int i = 0; i < driversWithCommission.take(10).length; i++) {
        final driver = driversWithCommission[i];
        print('  ${i+1}. ${driver.driverName}: \$${driver.commission.toStringAsFixed(2)}');
      }

      // Calcular totais
      final totalCommissions = topDrivers.fold(0.0, (sum, driver) => sum + driver.commission);
      final averageCommission = topDrivers.isNotEmpty ? totalCommissions / topDrivers.length : 0.0;

      return {
        'totalDrivers': topDrivers.length,
        'totalCommissions': totalCommissions,
        'averageCommission': averageCommission,
        'driversWithCommissions': topDrivers.where((d) => d.commission > 0).length,
        'topDrivers': topDrivers.take(10).toList(), // Top 10 motoristas
      };
    } catch (e) {
      print('Erro ao carregar dados reais: $e');
      return {
        'totalDrivers': 0,
        'totalCommissions': 0.0,
        'averageCommission': 0.0,
        'driversWithCommissions': 0,
        'topDrivers': [],
      };
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

  bool _isArtist(String driverName) {
    final artists = [
      'Preta Gil', 'Endy Lisboa', 'Willian de Campos', 'Stanley', 
      'Gabriel Enrico', 'Claudia Varela', 'Vitor Belfort', 'Gisela Gueiros',
      'Murilo Linhares', 'Fabiolla Lima', 'Eduardo Romero'
    ];
    return artists.contains(driverName);
  }

  Future<Map<String, dynamic>> _getCommissionData() async {
    try {
      // Tentar buscar da tabela de comissões se existir
      final response = await _supabase
          .from('driver_commission')
          .select('*')
          .order('commission', ascending: false)
          .order('id', ascending: false).limit(10);
      
      if (response.isNotEmpty) {
        return _processCommissionData(response);
      }
    } catch (e) {
      print('Tabela driver_commission não existe: $e');
    }

    // Se não encontrar dados, retornar vazio
    return {
      'totalDrivers': 0,
      'totalCommissions': 0.0,
      'averageCommission': 0.0,
      'driversWithCommissions': 0,
      'topDrivers': [],
    };
  }

  Future<Map<String, dynamic>> _processCommissionData(List<dynamic> data) async {
    final topDrivers = data.map((item) => DriverCommission(
      driverId: item['driver_id'] ?? 0,
      driverName: item['driver_name'] ?? 'Motorista',
      commission: (item['commission'] ?? 0.0).toDouble(),
      trips: item['trips'] ?? 0,
      totalRevenue: (item['total_revenue'] ?? 0.0).toDouble(),
    )).toList();

    final totalCommissions = topDrivers.fold(0.0, (sum, driver) => sum + driver.commission);
    final averageCommission = topDrivers.isNotEmpty ? totalCommissions / topDrivers.length : 0.0;

    return {
      'totalDrivers': topDrivers.length,
      'totalCommissions': totalCommissions,
      'averageCommission': averageCommission,
      'driversWithCommissions': topDrivers.where((d) => d.commission > 0).length,
      'topDrivers': topDrivers,
    };
  }
}

final driverCommissionProvider = StateNotifierProvider<DriverCommissionNotifier, DriverCommissionData>((ref) {
  final supabase = Supabase.instance.client;
  return DriverCommissionNotifier(supabase);
}); 

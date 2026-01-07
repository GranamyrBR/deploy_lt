import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:state_notifier/state_notifier.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

class DashboardMetrics {
  final int totalLeads;
  final int totalDrivers;
  final int totalContacts;
  final int totalSales;
  final int totalCars;
  final int totalAgencies;
  final int totalUsers;
  final int totalOperations;
  final double totalRevenue;
  final double conversionRate;
  final bool isLoading;
  final String? errorMessage;

  DashboardMetrics({
    required this.totalLeads,
    required this.totalDrivers,
    required this.totalContacts,
    required this.totalSales,
    required this.totalCars,
    required this.totalAgencies,
    required this.totalUsers,
    required this.totalOperations,
    required this.totalRevenue,
    required this.conversionRate,
    this.isLoading = false,
    this.errorMessage,
  });

  DashboardMetrics copyWith({
    int? totalLeads,
    int? totalDrivers,
    int? totalContacts,
    int? totalSales,
    int? totalCars,
    int? totalAgencies,
    int? totalUsers,
    int? totalOperations,
    double? totalRevenue,
    double? conversionRate,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DashboardMetrics(
      totalLeads: totalLeads ?? this.totalLeads,
      totalDrivers: totalDrivers ?? this.totalDrivers,
      totalContacts: totalContacts ?? this.totalContacts,
      totalSales: totalSales ?? this.totalSales,
      totalCars: totalCars ?? this.totalCars,
      totalAgencies: totalAgencies ?? this.totalAgencies,
      totalUsers: totalUsers ?? this.totalUsers,
      totalOperations: totalOperations ?? this.totalOperations,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      conversionRate: conversionRate ?? this.conversionRate,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class DashboardMetricsNotifier extends StateNotifier<DashboardMetrics> {
  final SupabaseClient _supabase;

  DashboardMetricsNotifier(this._supabase)
      : super(DashboardMetrics(
          totalLeads: 0,
          totalDrivers: 0,
          totalContacts: 0,
          totalSales: 0,
          totalCars: 0,
          totalAgencies: 0,
          totalUsers: 0,
          totalOperations: 0,
          totalRevenue: 0.0,
          conversionRate: 0.0,
        )) {
    fetchMetrics();
  }

  Future<void> fetchMetrics() async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      // Carregar dados reais da planilha
      final metrics = await _getRealMetrics();
      
      state = state.copyWith(
        totalLeads: metrics['totalLeads'] ?? 0,
        totalDrivers: metrics['totalDrivers'] ?? 0,
        totalContacts: metrics['totalContacts'] ?? 0,
        totalSales: metrics['totalSales'] ?? 0,
        totalCars: metrics['totalCars'] ?? 0,
        totalAgencies: metrics['totalAgencies'] ?? 0,
        totalUsers: metrics['totalUsers'] ?? 0,
        totalOperations: metrics['totalOperations'] ?? 0,
        totalRevenue: metrics['totalRevenue'] ?? 0.0,
        conversionRate: metrics['conversionRate'] ?? 0.0,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Erro ao buscar métricas: $e',
      );
    }
  }

  Future<Map<String, dynamic>> _getRealMetrics() async {
    try {
      // Carregar dados do JSON da planilha
      final jsonString = await rootBundle.loadString('assets/commission_data.json');
      final List<dynamic> rawData = json.decode(jsonString);
      
      print('DEBUG: Carregando métricas de ${rawData.length} registros da planilha');

      // Calcular métricas reais baseadas na planilha
      double totalRevenue = 0.0;
      Set<String> uniqueDrivers = {};
      Set<String> uniqueVendors = {};
      Set<String> uniqueSources = {};
      int totalOperations = 0;
      int paidServices = 0;
      int unpaidServices = 0;

      for (final record in rawData) {
        final valorCobrado = _parseDouble(record['Valor Cobrado']);
        final driverName = record['Motoristas']?.toString() ?? 'Sem Motorista';
        final vendor = record['Vendedor']?.toString() ?? 'Sem Vendedor';
        final source = record['Fonte']?.toString() ?? 'Sem Fonte';
        final servicoPago = record['Serviço Pago']?.toString();

        totalRevenue += valorCobrado;
        uniqueDrivers.add(driverName);
        uniqueVendors.add(vendor);
        uniqueSources.add(source);
        totalOperations++;

        if (servicoPago == 'SIM') {
          paidServices++;
        } else {
          unpaidServices++;
        }
      }

      // Buscar dados adicionais do Supabase (se disponíveis)
      int totalCars = 0;
      int totalUsers = 0;
      
      try {
        final carsResponse = await _supabase.from('car').select('id');
        totalCars = carsResponse.length;
      } catch (e) {
        print('Tabela car não existe: $e');
      }

      try {
        final usersResponse = await _supabase.from('user').select('id');
        totalUsers = usersResponse.length;
      } catch (e) {
        print('Tabela user não existe: $e');
      }

      print('DEBUG: Métricas calculadas:');
      print('  - Receita total: \$${totalRevenue.toStringAsFixed(2)}');
      print('  - Motoristas únicos: ${uniqueDrivers.length}');
      print('  - Operações totais: $totalOperations');
      print('  - Serviços pagos: $paidServices');
      print('  - Serviços não pagos: $unpaidServices');

      return {
        'totalLeads': uniqueSources.length, // Fontes únicas como leads
        'totalDrivers': uniqueDrivers.length,
        'totalContacts': totalOperations, // Total de operações como contatos
        'totalSales': paidServices, // Serviços pagos como vendas
        'totalCars': totalCars,
        'totalAgencies': uniqueVendors.length, // Vendedores únicos como agências
        'totalUsers': totalUsers,
        'totalOperations': totalOperations,
        'totalRevenue': totalRevenue,
        'conversionRate': totalOperations > 0 ? (paidServices / totalOperations) * 100 : 0.0,
      };
    } catch (e) {
      print('Erro ao carregar métricas reais: $e');
      return {
        'totalLeads': 0,
        'totalDrivers': 0,
        'totalContacts': 0,
        'totalSales': 0,
        'totalCars': 0,
        'totalAgencies': 0,
        'totalUsers': 0,
        'totalOperations': 0,
        'totalRevenue': 0.0,
        'conversionRate': 0.0,
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

  // Métodos antigos mantidos para compatibilidade
  Future<int> _getLeadsCount() async {
    try {
      final response = await _supabase.from('whatsapp_leads').select('id');
      return response.length;
    } catch (e) {
      print('Tabela whatsapp_leads não existe: $e');
      return 0;
    }
  }

  Future<int> _getDriversCount() async {
    try {
      final response = await _supabase.from('driver').select('id');
      return response.length;
    } catch (e) {
      print('Erro ao buscar motoristas: $e');
      return 0;
    }
  }

  Future<int> _getContactsCount() async {
    try {
      final response = await _supabase.from('contact').select('id');
      return response.length;
    } catch (e) {
      print('Erro ao buscar contatos: $e');
      return 0;
    }
  }

  Future<int> _getSalesCount() async {
    try {
      final response = await _supabase.from('sale').select('id');
      return response.length;
    } catch (e) {
      print('Erro ao buscar vendas: $e');
      return 0;
    }
  }

  Future<int> _getCarsCount() async {
    try {
      final response = await _supabase.from('car').select('id');
      return response.length;
    } catch (e) {
      print('Erro ao buscar carros: $e');
      return 0;
    }
  }

  Future<int> _getAgenciesCount() async {
    try {
      final response = await _supabase.from('agency').select('id');
      return response.length;
    } catch (e) {
      print('Tabela agency não existe: $e');
      return 0;
    }
  }

  Future<int> _getUsersCount() async {
    try {
      final response = await _supabase.from('user').select('id');
      return response.length;
    } catch (e) {
      print('Tabela user não existe: $e');
      return 0;
    }
  }

  Future<int> _getOperationsCount() async {
    try {
      final response = await _supabase.from('operation').select('id');
      return response.length;
    } catch (e) {
      print('Tabela operation não existe: $e');
      return 0;
    }
  }

  Future<double> _getTotalRevenue() async {
    try {
      final response = await _supabase.from('sale').select('total_amount');
      
      if (response == null || response.isEmpty) return 0.0;
      
      double total = 0.0;
      for (final sale in response) {
        final amount = sale['total_amount'];
        if (amount != null) {
          double value = (amount is int) ? amount.toDouble() : (amount as double);
          total += value;
        }
      }
      return total;
    } catch (e) {
      print('Erro ao buscar receita total: $e');
      return 0.0;
    }
  }
}

final dashboardMetricsProvider = StateNotifierProvider<DashboardMetricsNotifier, DashboardMetrics>((ref) {
  final supabase = Supabase.instance.client;
  return DashboardMetricsNotifier(supabase);
}); 

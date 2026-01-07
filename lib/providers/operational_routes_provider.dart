import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/operational_route.dart';
import '../services/hybrid_flight_service.dart';
import '../services/real_flight_data_service.dart';
import '../services/database_flight_service.dart';

final hybridFlightServiceProvider = Provider<HybridFlightService>((ref) {
  return HybridFlightService();
});

final realFlightDataServiceProvider = Provider<RealFlightDataService>((ref) {
  return RealFlightDataService();
});

final databaseFlightServiceProvider = Provider<DatabaseFlightService>((ref) {
  return DatabaseFlightService();
});

final operationalRoutesProvider = FutureProvider<List<OperationalRoute>>((ref) async {
  try {
    print('=== CARREGANDO ROTAS OPERACIONAIS ===');
    
    final databaseService = ref.read(databaseFlightServiceProvider);
    
    // Primeiro, tentar buscar do banco de dados
    final dbRoutes = await databaseService.getOperationalRoutes();
    
    if (dbRoutes.isNotEmpty) {
      print('✅ ${dbRoutes.length} rotas carregadas do banco de dados');
      return dbRoutes;
    }
    
    print('⚠️ Nenhuma rota encontrada no banco, tentando API...');
    
    // Fallback para API se banco estiver vazio
    final realFlightService = ref.read(realFlightDataServiceProvider);
    final flights = await realFlightService.getBrazilUsaRoutes();
    
    if (flights.isNotEmpty) {
      // Converter FlightInfo para OperationalRoute
      final routes = flights.map((flight) => OperationalRoute.fromFlightInfo(flight)).toList();
      print('✅ ${routes.length} rotas carregadas da API');
      return routes;
    }
    
    print('⚠️ Nenhuma rota encontrada na API, retornando lista vazia');
    return [];
    
  } catch (e) {
    print('❌ Erro ao carregar rotas operacionais: $e');
    return [];
  }
});

// Provider para listar aeroportos disponíveis
final availableAirportsProvider = FutureProvider<List<String>>((ref) async {
  try {
    final routes = await ref.watch(operationalRoutesProvider.future);
    
    // Extrair aeroportos únicos (origem e destino)
    final airports = <String>{};
    
    for (final route in routes) {
      airports.add(route.origem);
      airports.add(route.destino);
    }
    
    // Ordenar aeroportos
    final sortedAirports = airports.toList()..sort();
    
    print('✅ ${sortedAirports.length} aeroportos disponíveis: $sortedAirports');
    return sortedAirports;
  } catch (e) {
    print('❌ Erro ao listar aeroportos: $e');
    return [];
  }
});

// Provider para listar companhias disponíveis
final availableAirlinesProvider = FutureProvider<List<String>>((ref) async {
  try {
    final routes = await ref.watch(operationalRoutesProvider.future);
    
    // Extrair companhias únicas
    final airlines = routes.map((route) => route.cia).toSet().toList();
    airlines.sort();
    
    print('✅ ${airlines.length} companhias disponíveis: $airlines');
    return airlines;
  } catch (e) {
    print('❌ Erro ao listar companhias: $e');
    return [];
  }
});

// Provider para listar operações disponíveis
final availableOperationsProvider = FutureProvider<List<String>>((ref) async {
  try {
    final routes = await ref.watch(operationalRoutesProvider.future);
    
    // Extrair operações únicas
    final operations = routes.map((route) => route.operacao).toSet().toList();
    operations.sort();
    
    print('✅ ${operations.length} operações disponíveis: $operations');
    return operations;
  } catch (e) {
    print('❌ Erro ao listar operações: $e');
    return [];
  }
});

final filteredOperationalRoutesProvider = Provider.family<AsyncValue<List<OperationalRoute>>, OperationalRouteFilters>((ref, filters) {
  return ref.watch(operationalRoutesProvider).whenData((routes) {
    var filteredRoutes = routes;

    // Filtrar por operação (saída/chegada)
    if (filters.operacao != null) {
      filteredRoutes = filteredRoutes.where((route) => route.operacao == filters.operacao).toList();
    }

    // Filtrar por companhia
    if (filters.companhia != null && filters.companhia!.isNotEmpty) {
      filteredRoutes = filteredRoutes.where((route) => route.cia == filters.companhia).toList();
    }

    // Filtrar por aeroporto (origem OU destino)
    if (filters.aeroportoOrigem != null && filters.aeroportoOrigem!.isNotEmpty) {
      filteredRoutes = filteredRoutes.where((route) => 
        route.origem == filters.aeroportoOrigem || route.destino == filters.aeroportoOrigem
      ).toList();
    }

    // Filtrar por aeroporto de destino específico (se fornecido)
    if (filters.aeroportoDestino != null && filters.aeroportoDestino!.isNotEmpty) {
      filteredRoutes = filteredRoutes.where((route) => route.destino == filters.aeroportoDestino).toList();
    }

    // Busca por texto livre
    if (filters.searchQuery != null && filters.searchQuery!.isNotEmpty) {
      final query = filters.searchQuery!.toLowerCase();
      filteredRoutes = filteredRoutes.where((route) {
        return route.voo.toLowerCase().contains(query) ||
               route.nomeCia.toLowerCase().contains(query) ||
               route.origem.toLowerCase().contains(query) ||
               route.destino.toLowerCase().contains(query) ||
               (route.observacoes?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    print('🔍 Filtros aplicados: ${filters.toString()}');
    print('📊 Resultados: ${filteredRoutes.length} rotas encontradas');
    
    return filteredRoutes;
  });
});

// Provider para buscar rotas com filtros do banco
final databaseFilteredRoutesProvider = FutureProvider.family<List<OperationalRoute>, OperationalRouteFilters>((ref, filters) async {
  final databaseService = ref.read(databaseFlightServiceProvider);
  
  return await databaseService.getOperationalRoutesByFilters(
    operacao: filters.operacao,
    companhia: filters.companhia,
    aeroportoOrigem: filters.aeroportoOrigem,
    aeroportoDestino: filters.aeroportoDestino,
    searchQuery: filters.searchQuery,
  );
});

// Provider para buscar voo específico do banco
final databaseFlightByNumberProvider = FutureProvider.family<OperationalRoute?, String>((ref, flightNumber) async {
  final databaseService = ref.read(databaseFlightServiceProvider);
  return await databaseService.getOperationalRouteByFlightNumber(flightNumber);
});

// Provider para estatísticas do banco
final databaseRouteStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final databaseService = ref.read(databaseFlightServiceProvider);
  return await databaseService.getRouteStats();
});

// Provider para testar conexão com banco
final databaseConnectionTestProvider = FutureProvider<bool>((ref) async {
  final databaseService = ref.read(databaseFlightServiceProvider);
  return await databaseService.testConnection();
});

// Provider para verificar estrutura da tabela
final databaseTableStructureProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final databaseService = ref.read(databaseFlightServiceProvider);
  return await databaseService.checkTableStructure();
});

class OperationalRouteFilters {
  final String? operacao;
  final String? companhia;
  final String? aeroportoOrigem;
  final String? aeroportoDestino;
  final String? searchQuery;

  OperationalRouteFilters({
    this.operacao,
    this.companhia,
    this.aeroportoOrigem,
    this.aeroportoDestino,
    this.searchQuery,
  });

  OperationalRouteFilters copyWith({
    String? operacao,
    String? companhia,
    String? aeroportoOrigem,
    String? aeroportoDestino,
    String? searchQuery,
  }) {
    return OperationalRouteFilters(
      operacao: operacao ?? this.operacao,
      companhia: companhia ?? this.companhia,
      aeroportoOrigem: aeroportoOrigem ?? this.aeroportoOrigem,
      aeroportoDestino: aeroportoDestino ?? this.aeroportoDestino,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  String toString() {
    return 'OperationalRouteFilters(operacao: $operacao, companhia: $companhia, aeroportoOrigem: $aeroportoOrigem, aeroportoDestino: $aeroportoDestino, searchQuery: $searchQuery)';
  }
}

// Provider para estatísticas das rotas (versão melhorada)
final routeStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  try {
    // Tentar usar estatísticas do banco primeiro
    final dbStats = await ref.watch(databaseRouteStatsProvider.future);
    if (dbStats['total_routes'] > 0) {
      return dbStats;
    }
    
    // Fallback para cálculo em memória
    final routes = await ref.watch(operationalRoutesProvider.future);
    
    final stats = <String, dynamic>{};
    
    // Total de rotas
    stats['total_routes'] = routes.length;
    
    // Rotas por operação
    stats['saida_brasil'] = routes.where((r) => r.operacao == 'SAÍDA DO BRASIL').length;
    stats['chegada_brasil'] = routes.where((r) => r.operacao == 'CHEGADA AO BRASIL').length;
    
    // Companhias únicas
    final companhias = routes.map((r) => r.cia).toSet().toList();
    stats['total_companies'] = companhias.length;
    stats['companies'] = companhias;
    
    // Aeroportos brasileiros
    final aeroportosBr = routes.where((r) => r.operacao == 'SAÍDA DO BRASIL').map((r) => r.origem).toSet().toList();
    stats['aeroportos_brasil'] = aeroportosBr;
    
    // Aeroportos americanos
    final aeroportosEua = routes.where((r) => r.operacao == 'SAÍDA DO BRASIL').map((r) => r.destino).toSet().toList();
    stats['aeroportos_eua'] = aeroportosEua;
    
    return stats;
  } catch (e) {
    print('❌ Erro ao calcular estatísticas: $e');
    return {
      'total_routes': 0,
      'saida_brasil': 0,
      'chegada_brasil': 0,
      'total_companies': 0,
      'companies': [],
      'aeroportos_brasil': [],
      'aeroportos_eua': [],
    };
  }
}); 

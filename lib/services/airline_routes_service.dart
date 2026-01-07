import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/airline_route.dart';

class AirlineRoutesService {
  SupabaseClient get _supabase => Supabase.instance.client;

  // Buscar todas as rotas Brasil ↔ EUA
  Future<List<AirlineRoute>> getBrazilUsaRoutes() async {
    try {
      final response = await _supabase
          .from('brazil_usa_routes')
          .select('*')
          .order('airline_name, flight_number');

      return (response as List)
          .map((json) => AirlineRoute.fromJson(json))
          .toList();
    } catch (e) {
      print('Erro ao buscar rotas Brasil-EUA: $e');
      return [];
    }
  }

  // Buscar rotas por direção (Brasil → EUA ou EUA → Brasil)
  Future<List<AirlineRoute>> getRoutesByDirection(String direction) async {
    try {
      final response = await _supabase
          .from('brazil_usa_routes')
          .select('*')
          .eq('direction', direction)
          .order('airline_name, flight_number');

      return (response as List)
          .map((json) => AirlineRoute.fromJson(json))
          .toList();
    } catch (e) {
      print('Erro ao buscar rotas por direção: $e');
      return [];
    }
  }

  // Buscar rotas por companhia aérea
  Future<List<AirlineRoute>> getRoutesByAirline(String airlineIata) async {
    try {
      final response = await _supabase
          .from('brazil_usa_routes')
          .select('*')
          .eq('airline_iata', airlineIata)
          .order('flight_number');

      return (response as List)
          .map((json) => AirlineRoute.fromJson(json))
          .toList();
    } catch (e) {
      print('Erro ao buscar rotas por companhia: $e');
      return [];
    }
  }

  // Buscar rotas por aeroporto de origem
  Future<List<AirlineRoute>> getRoutesByOrigin(String airportIata) async {
    try {
      final response = await _supabase
          .from('brazil_usa_routes')
          .select('*')
          .eq('origin_airport_iata', airportIata)
          .order('airline_name, flight_number');

      return (response as List)
          .map((json) => AirlineRoute.fromJson(json))
          .toList();
    } catch (e) {
      print('Erro ao buscar rotas por origem: $e');
      return [];
    }
  }

  // Buscar rotas por aeroporto de destino
  Future<List<AirlineRoute>> getRoutesByDestination(String airportIata) async {
    try {
      final response = await _supabase
          .from('brazil_usa_routes')
          .select('*')
          .eq('destination_airport_iata', airportIata)
          .order('airline_name, flight_number');

      return (response as List)
          .map((json) => AirlineRoute.fromJson(json))
          .toList();
    } catch (e) {
      print('Erro ao buscar rotas por destino: $e');
      return [];
    }
  }

  // Buscar rotas diretas (sem conexão)
  Future<List<AirlineRoute>> getDirectRoutes() async {
    try {
      final allRoutes = await getBrazilUsaRoutes();
      return allRoutes.where((route) => route.isDirect).toList();
    } catch (e) {
      print('Erro ao buscar rotas diretas: $e');
      return [];
    }
  }

  // Buscar rotas que operam diariamente
  Future<List<AirlineRoute>> getDailyRoutes() async {
    try {
      final response = await _supabase
          .from('brazil_usa_routes')
          .select('*')
          .eq('frequency_per_week', 7)
          .order('airline_name, flight_number');

      return (response as List)
          .map((json) => AirlineRoute.fromJson(json))
          .toList();
    } catch (e) {
      print('Erro ao buscar rotas diárias: $e');
      return [];
    }
  }

  // Buscar estatísticas das rotas
  Future<Map<String, dynamic>> getRoutesStatistics() async {
    try {
      final allRoutes = await getBrazilUsaRoutes();
      
      // Agrupar por companhia aérea
      final airlineStats = <String, int>{};
      final cityPairs = <String, int>{};
      final directRoutes = <AirlineRoute>[];
      final connectionRoutes = <AirlineRoute>[];
      
      for (final route in allRoutes) {
        // Contar por companhia
        airlineStats[route.airlineName] = (airlineStats[route.airlineName] ?? 0) + 1;
        
        // Contar pares de cidades
        final cityPair = '${route.originCity} → ${route.destinationCity}';
        cityPairs[cityPair] = (cityPairs[cityPair] ?? 0) + 1;
        
        // Separar diretas de conexão
        if (route.isDirect) {
          directRoutes.add(route);
        } else {
          connectionRoutes.add(route);
        }
      }

      return {
        'total_routes': allRoutes.length,
        'total_airlines': airlineStats.length,
        'direct_routes': directRoutes.length,
        'connection_routes': connectionRoutes.length,
        'airline_distribution': airlineStats,
        'city_pairs': cityPairs,
        'brasil_to_usa': allRoutes.where((r) => r.direction == 'Brasil → EUA').length,
        'usa_to_brasil': allRoutes.where((r) => r.direction == 'EUA → Brasil').length,
      };
    } catch (e) {
      print('Erro ao calcular estatísticas: $e');
      return {};
    }
  }

  // Buscar aeroportos únicos
  Future<Map<String, List<Map<String, String>>>> getUniqueAirports() async {
    try {
      final allRoutes = await getBrazilUsaRoutes();
      
      final brazilianAirports = <String, Map<String, String>>{};
      final americanAirports = <String, Map<String, String>>{};
      
      for (final route in allRoutes) {
        if (route.originCountry == 'Brasil') {
          brazilianAirports[route.originAirportIata] = {
            'iata': route.originAirportIata,
            'name': route.originAirportName,
            'city': route.originCity,
          };
        }
        
        if (route.destinationCountry == 'EUA') {
          americanAirports[route.destinationAirportIata] = {
            'iata': route.destinationAirportIata,
            'name': route.destinationAirportName,
            'city': route.destinationCity,
          };
        }
        
        if (route.originCountry == 'EUA') {
          americanAirports[route.originAirportIata] = {
            'iata': route.originAirportIata,
            'name': route.originAirportName,
            'city': route.originCity,
          };
        }
        
        if (route.destinationCountry == 'Brasil') {
          brazilianAirports[route.destinationAirportIata] = {
            'iata': route.destinationAirportIata,
            'name': route.destinationAirportName,
            'city': route.destinationCity,
          };
        }
      }
      
      return {
        'brazilian_airports': brazilianAirports.values.toList(),
        'american_airports': americanAirports.values.toList(),
      };
    } catch (e) {
      print('Erro ao buscar aeroportos únicos: $e');
      return {'brazilian_airports': [], 'american_airports': []};
    }
  }

  // Buscar companhias aéreas únicas
  Future<List<Map<String, String>>> getUniqueAirlines() async {
    try {
      final allRoutes = await getBrazilUsaRoutes();
      
      final airlines = <String, Map<String, String>>{};
      
      for (final route in allRoutes) {
        airlines[route.airlineIata] = {
          'iata': route.airlineIata,
          'name': route.airlineName,
        };
      }
      
      return airlines.values.toList()
        ..sort((a, b) => a['name']!.compareTo(b['name']!));
    } catch (e) {
      print('Erro ao buscar companhias únicas: $e');
      return [];
    }
  }
} 

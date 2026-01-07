import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/hybrid_flight_service.dart';
import '../models/flight_info.dart';

// Provider para o serviço de voos
final flightServiceProvider = Provider<HybridFlightService>((ref) {
  return HybridFlightService();
});

// Provider para buscar voo por número (versão simples)
final flightSearchProvider = FutureProvider.family<FlightInfo?, String>((ref, flightNumber) async {
  final flightService = ref.read(flightServiceProvider);
  return await flightService.searchFlightByNumber(flightNumber);
});

// Provider para buscar voo por número com data (versão completa)
final flightByNumberProvider = FutureProvider.family<FlightInfo?, ({String flightNumber, String? date})>((ref, params) async {
  final flightService = ref.read(flightServiceProvider);
  return await flightService.searchFlightByNumber(params.flightNumber, date: params.date);
});

// Provider para buscar voos por aeroporto
final airportFlightsProvider = FutureProvider.family<List<FlightInfo>, Map<String, dynamic>>((ref, params) async {
  final flightService = ref.read(flightServiceProvider);
  return await flightService.getFlightsByAirport(
    arrIata: params['arrIata'],
    depIata: params['depIata'],
    flightDate: params['flightDate'],
    flightStatus: params['flightStatus'] ?? 'scheduled',
    limit: params['limit'] ?? 10,
  );
});

// Provider para buscar voos Brasil-EUA
final brazilUsaFlightsProvider = FutureProvider<List<FlightInfo>>((ref) async {
  final flightService = ref.read(flightServiceProvider);
  return await flightService.getBrazilUsaFlights();
});

// Provider para testar conexão
final connectionTestProvider = FutureProvider<bool>((ref) async {
  final flightService = ref.read(flightServiceProvider);
  return await flightService.testConnection();
});

// Provider para status do serviço
final serviceStatusProvider = Provider<String>((ref) {
  final flightService = ref.read(flightServiceProvider);
  return flightService.getServiceStatus();
});

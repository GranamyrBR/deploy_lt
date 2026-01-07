import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/flight_info.dart';
import '../models/firebase_account.dart';
import 'firebase_account_service.dart';

class FirebaseFlightService {
  final FirebaseAccountService _accountService = FirebaseAccountService.instance;
  
  // URLs padrão das Cloud Functions (fallback)
  static const String _defaultTestConnectionUrl = 'https://testconnection-6jqkhayvia-uc.a.run.app';
  static const String _defaultSearchFlightUrl = 'https://searchflight-6jqkhayvia-uc.a.run.app';
  static const String _defaultGetAirportFlightsUrl = 'https://getairportflights-6jqkhayvia-uc.a.run.app';
  static const String _defaultGetBrazilUsaFlightsUrl = 'https://getbrazilusaflights-6jqkhayvia-uc.a.run.app';
  
  // Obter URLs da conta ativa
  String get _testConnectionUrl {
    final account = _accountService.activeAccount;
    return account?.testConnectionUrl ?? _defaultTestConnectionUrl;
  }
  
  String get _searchFlightUrl {
    final account = _accountService.activeAccount;
    return account?.searchFlightUrl ?? _defaultSearchFlightUrl;
  }
  
  String get _getAirportFlightsUrl {
    final account = _accountService.activeAccount;
    return account?.getAirportFlightsUrl ?? _defaultGetAirportFlightsUrl;
  }
  
  String get _getBrazilUsaFlightsUrl {
    final account = _accountService.activeAccount;
    return account?.getBrazilUsaFlightsUrl ?? _defaultGetBrazilUsaFlightsUrl;
  }
  
  // Buscar voo por número
  Future<FlightInfo?> searchFlightByNumber(String flightNumber, {String? date}) async {
    try {
      final formattedDate = date ?? _formatDateForAPI(DateTime.now());
      final uri = Uri.parse('$_searchFlightUrl?flightNumber=$flightNumber&date=$formattedDate');
      
      print('=== FIREBASE: Buscando voo ===');
      print('Voo: $flightNumber');
      print('Data: $formattedDate');
      print('URL: $uri');

      final response = await http.get(uri);

      print('Status da resposta: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        print('Resposta Firebase: $responseData');
        
        if (responseData['success'] == true && responseData['data'] != null) {
          return _convertFlightAwareToFlightInfo(responseData['data']);
        }
      } else if (response.statusCode == 404) {
        print('Voo não encontrado');
        return null;
      } else {
        print('Erro na requisição Firebase. Status: ${response.statusCode}');
        print('Resposta: ${response.body}');
      }
      
      return null;
    } catch (e) {
      print('Erro ao buscar voo via Firebase: $e');
      return null;
    }
  }

  // Buscar voos por aeroporto
  Future<List<FlightInfo>> getFlightsByAirport({
    String? arrIata,
    String? depIata,
    String? flightDate,
    String flightStatus = 'scheduled',
    int limit = 10,
  }) async {
    try {
      final formattedDate = flightDate ?? _formatDateForAPI(DateTime.now());
      final airport = arrIata ?? depIata ?? 'JFK';
      final type = arrIata != null ? 'arrivals' : 'departures';
      
      final uri = Uri.parse('$_getAirportFlightsUrl?airport=$airport&date=$formattedDate&type=$type&limit=$limit');
      
      print('=== FIREBASE: Buscando voos por aeroporto ===');
      print('Aeroporto: $airport');
      print('Tipo: $type');
      print('Data: $formattedDate');
      print('URL: $uri');

      final response = await http.get(uri);

      print('Status da resposta: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        print('Resposta Firebase: ${responseData.keys}');
        
        if (responseData['success'] == true && responseData['data'] != null) {
          final List<dynamic> flightsData = responseData['data'];
          return flightsData
              .map((flightData) => _convertFlightAwareToFlightInfo(flightData))
              .toList();
        }
      } else {
        print('Erro na requisição Firebase. Status: ${response.statusCode}');
        print('Resposta: ${response.body}');
      }
      
      return [];
    } catch (e) {
      print('Erro ao buscar voos via Firebase: $e');
      return [];
    }
  }

  // Buscar voos Brasil-EUA
  Future<List<FlightInfo>> getBrazilUsaFlights() async {
    try {
      final formattedDate = _formatDateForAPI(DateTime.now());
      final uri = Uri.parse('$_getBrazilUsaFlightsUrl?date=$formattedDate');
      
      print('=== FIREBASE: Buscando voos Brasil-EUA ===');
      print('Data: $formattedDate');
      print('URL: $uri');

      final response = await http.get(uri);

      print('Status da resposta: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        print('Resposta Firebase: ${responseData.keys}');
        
        if (responseData['success'] == true && responseData['data'] != null) {
          final List<dynamic> flightsData = responseData['data'];
          return flightsData
              .map((flightData) => _convertFlightAwareToFlightInfo(flightData))
              .toList();
        }
      } else {
        print('Erro na requisição Firebase. Status: ${response.statusCode}');
        print('Resposta: ${response.body}');
      }
      
      return [];
    } catch (e) {
      print('Erro ao buscar voos Brasil-EUA via Firebase: $e');
      return [];
    }
  }

  // Testar conexão
  Future<bool> testConnection() async {
    try {
      final uri = Uri.parse('$_testConnectionUrl');
      
      final response = await http.get(uri);

      return response.statusCode == 200;
    } catch (e) {
      print('Erro ao testar conexão Firebase: $e');
      return false;
    }
  }

  // Formatar data para API
  String _formatDateForAPI(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Converter dados FlightAware para FlightInfo
  FlightInfo _convertFlightAwareToFlightInfo(Map<String, dynamic> flightData) {
    print('=== CONVERTENDO DADOS FIREBASE ===');
    print('Dados recebidos: ${flightData.keys}');
    
    // Extrair data do scheduled_out se disponível
    String? flightDate;
    if (flightData['scheduled_out'] != null) {
      try {
        final dateStr = flightData['scheduled_out'].toString();
        flightDate = dateStr.substring(0, 10); // YYYY-MM-DD
      } catch (e) {
        flightDate = null;
      }
    }
    
    final flightInfo = FlightInfo(
      flightDate: flightDate,
      flightStatus: _mapFlightStatus(flightData['status']?.toString()),
      departure: DepartureInfo(
        airport: flightData['origin']?['name']?.toString(),
        iata: flightData['origin']?['code_icao']?.toString(),
        scheduled: flightData['scheduled_out']?.toString(),
        estimated: flightData['estimated_out']?.toString(),
        terminal: flightData['terminal_origin']?.toString(),
        gate: flightData['gate_origin']?.toString(),
      ),
      arrival: ArrivalInfo(
        airport: flightData['destination']?['name']?.toString(),
        iata: flightData['destination']?['code_icao']?.toString(),
        scheduled: flightData['scheduled_in']?.toString(),
        estimated: flightData['estimated_in']?.toString(),
        terminal: flightData['terminal_destination']?.toString(),
        gate: flightData['gate_destination']?.toString(),
      ),
      airline: AirlineInfo(
        name: flightData['operator']?.toString(),
        iata: flightData['operator_iata']?.toString(),
      ),
      flight: FlightDetails(
        number: flightData['ident']?.toString(),
        iata: flightData['ident_iata']?.toString(),
      ),
    );
    
    print('FlightInfo criado:');
    print('- Número do voo: ${flightInfo.flight?.number}');
    print('- Companhia: ${flightInfo.airline?.name}');
    print('- Status: ${flightInfo.flightStatus}');
    print('- Partida: ${flightInfo.departure?.airport} (${flightInfo.departure?.iata})');
    print('- Chegada: ${flightInfo.arrival?.airport} (${flightInfo.arrival?.iata})');
    
    return flightInfo;
  }

  // Mapear status da FlightAware para nosso formato
  String _mapFlightStatus(String? status) {
    if (status == null) return 'scheduled';
    
    // Status reais da FlightAware que vimos na resposta
    final statusMap = {
      'Landed / Taxiing': 'landed',
      'Arrived / Gate Arrival': 'landed',
      'En Route / On Time': 'active',
      'En Route / Delayed': 'active',
      'Scheduled': 'scheduled',
      'Cancelled': 'cancelled',
      'Diverted': 'diverted',
      'Unknown': 'unknown',
    };
    
    return statusMap[status] ?? 'scheduled';
  }
}

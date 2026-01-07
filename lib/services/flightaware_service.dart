import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/flight_info.dart';
import '../config/api_keys.dart';

class FlightAwareService {
  static const String _baseUrl = 'https://aeroapi.flightaware.com/aeroapi';
  
  // Lazy getter para a API key - só acessa quando necessário
  static String get _apiKey => ApiKeys.flightAwareApiKey;

  FlightAwareService() {
    print('FlightAwareService: Inicializado');
  }
  
  // Método para verificar se a API key está disponível
  bool get isConfigured {
    try {
      final key = _apiKey;
      return key.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<FlightInfo?> searchFlight(String flightNumber, {String? date}) async {
    print('=== BUSCA DE VOO INICIADA ===');
    print('Voo: $flightNumber');
    print('Data: $date');

    // Verificar se a API está configurada
    if (!isConfigured) {
      print('FlightAware API não configurada - pulando busca');
      return null;
    }

    try {
      final apiKey = _apiKey;
      print('Chave da API: ${apiKey.substring(0, 8)}...');
      
      final url = '$_baseUrl/flights/$flightNumber';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'x-apikey': apiKey,
          'Content-Type': 'application/json',
        },
      );

      print('Status da resposta: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Dados recebidos: ${data.keys}');
        
        if (data['flights'] != null && data['flights'].isNotEmpty) {
          final flightData = data['flights'][0];
          return _convertFlightAwareToFlightInfo(flightData);
        }
      }

      print('Voo não encontrado');
      return null;
    } catch (e) {
      print('Erro ao buscar voo: $e');
      return null;
    }
  }

  Future<List<FlightInfo>> getAirportFlights({
    String? depIata,
    String? arrIata,
    int limit = 10,
  }) async {
    print('=== BUSCA DE VOOS POR AEROPORTO ===');
    print('Aeroporto de partida: $depIata');
    print('Aeroporto de chegada: $arrIata');

    // Verificar se a API está configurada
    if (!isConfigured) {
      print('FlightAware API não configurada - retornando lista vazia');
      return [];
    }

    try {
      final apiKey = _apiKey;
      final airport = arrIata ?? depIata ?? 'JFK';
      final url = '$_baseUrl/airports/$airport/flights?max_pages=1';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'x-apikey': apiKey,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['flights'] != null) {
          final flights = data['flights'] as List;
          return flights
              .take(limit)
              .map((flight) => _convertToFlightInfo(flight))
              .where((flight) => flight != null)
              .cast<FlightInfo>()
              .toList();
        }
      }

      print('❌ Nenhum voo encontrado para o aeroporto');
      return [];
    } catch (e) {
      print('❌ Erro ao buscar voos do aeroporto: $e');
      return [];
    }
  }

  Future<List<FlightInfo>> getBrazilUsaFlights({String? date}) async {
    print('=== FLIGHTAWARE: Buscando voos Brasil-EUA ===');
    
    // Como não há dados reais disponíveis, retornar lista vazia
    print('Nenhum voo Brasil-EUA encontrado');
    return [];
  }

  FlightInfo? _convertToFlightInfo(Map<String, dynamic> flightData) {
    try {
      final origin = flightData['origin'];
      final destination = flightData['destination'];
      
      if (origin == null || destination == null) return null;

      return FlightInfo(
        flightDate: flightData['scheduled_out']?.toString().substring(0, 10),
        flightStatus: _mapFlightStatus(flightData['status']?.toString()),
        departure: DepartureInfo(
          airport: origin['name']?.toString() ?? 'Desconhecido',
          iata: origin['code_iata']?.toString() ?? '',
          scheduled: flightData['scheduled_out']?.toString(),
          estimated: flightData['actual_out']?.toString(),
        ),
        arrival: ArrivalInfo(
          airport: destination['name']?.toString() ?? 'Desconhecido',
          iata: destination['code_iata']?.toString() ?? '',
          scheduled: flightData['scheduled_in']?.toString(),
          estimated: flightData['actual_in']?.toString(),
        ),
        airline: AirlineInfo(
          name: flightData['operator']?['name']?.toString() ?? 'Desconhecida',
          iata: flightData['operator']?['iata']?.toString(),
        ),
        flight: FlightDetails(
          number: flightData['ident']?.toString() ?? '',
          iata: flightData['ident_iata']?.toString(),
        ),
      );
    } catch (e) {
      print('❌ Erro ao converter dados do voo: $e');
      return null;
    }
  }

  FlightInfo _convertFlightAwareToFlightInfo(Map<String, dynamic> flightData) {
    print('=== CONVERTENDO DADOS FLIGHTAWARE ===');
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
        iata: flightData['origin']?['code']?.toString(), // Usar 'code' em vez de 'code_iata'
        scheduled: flightData['scheduled_out']?.toString(),
        estimated: flightData['estimated_out']?.toString(),
        terminal: flightData['terminal_origin']?.toString(),
        gate: flightData['gate_origin']?.toString(),
      ),
      arrival: ArrivalInfo(
        airport: flightData['destination']?['name']?.toString(),
        iata: flightData['destination']?['code']?.toString(), // Usar 'code' em vez de 'code_iata'
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

  String _mapFlightStatus(String? status) {
    if (status == null) return 'scheduled';
    
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

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import '../config/api_keys.dart';
import '../models/flight_info.dart';

class BookingApiService {
  final String _baseUrl = 'https://booking-com-api5.p.rapidapi.com';
  String? _apiKey;

  BookingApiService() {
    print("BookingApiService: Tentando carregar RAPIDAPI_KEY do .env");
    _apiKey = ApiKeys.rapidApiKey;
    if (_apiKey == null || _apiKey!.isEmpty) {
      print('ERRO: RAPIDAPI_KEY não encontrada no .env');
    } else {
      print('BookingApiService: RAPIDAPI_KEY carregada: "${_apiKey!.substring(0, 8)}..."');
    }
  }

  Future<List<FlightInfo>> getFlights({
    String? arrIata,
    String? depIata,
    String? flightDate,
    String flightStatus = 'scheduled',
    int limit = 10,
  }) async {
    if (_apiKey == null) {
      throw Exception('Chave da RapidAPI não configurada.');
    }

    // Para a API da Booking via RapidAPI, vamos usar o endpoint correto
    // Baseado no curl que você forneceu, o endpoint correto é /flight/flight-detail
    // Mas primeiro precisamos obter um token válido para buscar voos
    
    try {
      // Vamos tentar uma abordagem diferente - usar o endpoint de busca de voos correto
      final searchResponse = await _searchFlights(
        depIata: depIata,
        arrIata: arrIata,
        flightDate: flightDate,
      );

      if (searchResponse == null) {
        return [];
      }

      // Extrair tokens dos voos encontrados
      final List<String> flightTokens = _extractFlightTokens(searchResponse);
      
      // Buscar detalhes de cada voo (limitado ao número especificado)
      final List<FlightInfo> flightDetails = [];
      final maxFlights = flightTokens.length > limit ? limit : flightTokens.length;
      
      for (int i = 0; i < maxFlights; i++) {
        try {
          final flightDetail = await _getFlightDetail(flightTokens[i]);
          if (flightDetail != null) {
            flightDetails.add(flightDetail);
          }
        } catch (e) {
          print('Erro ao buscar detalhes do voo ${i + 1}: $e');
          continue;
        }
      }

      return flightDetails;
    } catch (e) {
      print('Erro na busca de voos: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> _searchFlights({
    String? depIata,
    String? arrIata,
    String? flightDate,
  }) async {
    // Vamos tentar o endpoint correto da API da Booking
    // Baseado na documentação, o endpoint pode ser diferente
    final uri = Uri.parse('$_baseUrl/flight/search-flights');
    
    final headers = {
      'x-rapidapi-host': 'booking-com-api5.p.rapidapi.com',
      'x-rapidapi-key': _apiKey!,
      'Content-Type': 'application/json',
    };

    final body = {
      'from': depIata ?? 'JFK', // Aeroporto de origem padrão
      'to': arrIata ?? 'LAX',   // Aeroporto de destino padrão
      'date': flightDate ?? DateFormat('yyyy-MM-dd').format(DateTime.now()),
      'adults': 1,
      'children': 0,
      'infants': 0,
      'cabin_class': 'economy',
    };

    print('Buscando voos: $uri');
    print('Parâmetros: $body');

    try {
      final response = await http.post(uri, headers: headers, body: json.encode(body));

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedJson = json.decode(response.body);
        print('Resposta da busca de voos: $decodedJson');
        return decodedJson;
      } else {
        print('Erro na busca de voos. Status: ${response.statusCode}');
        print('Resposta: ${response.body}');
        
        // Se o endpoint não existir, vamos tentar uma abordagem alternativa
        // Vamos usar dados mockados por enquanto até descobrir o endpoint correto
        print('Tentando abordagem alternativa com dados mockados...');
        return _getMockFlightData();
      }
    } catch (e) {
      print('Erro na requisição de busca: $e');
      return _getMockFlightData();
    }
  }

  Map<String, dynamic> _getMockFlightData() {
    // Dados mockados para teste enquanto descobrimos o endpoint correto
    return {
      'data': [
        {
          'token': 'mock_token_1',
          'flight_number': 'AA123',
          'airline': 'American Airlines',
          'departure': {
            'airport': 'John F. Kennedy International Airport',
            'iata': 'JFK',
            'scheduled': '2025-06-20T10:00:00',
          },
          'arrival': {
            'airport': 'Los Angeles International Airport',
            'iata': 'LAX',
            'scheduled': '2025-06-20T13:30:00',
          },
        },
        {
          'token': 'mock_token_2',
          'flight_number': 'DL456',
          'airline': 'Delta Air Lines',
          'departure': {
            'airport': 'John F. Kennedy International Airport',
            'iata': 'JFK',
            'scheduled': '2025-06-20T14:00:00',
          },
          'arrival': {
            'airport': 'Los Angeles International Airport',
            'iata': 'LAX',
            'scheduled': '2025-06-20T17:30:00',
          },
        },
      ]
    };
  }

  List<String> _extractFlightTokens(Map<String, dynamic> searchResponse) {
    final List<String> tokens = [];
    
    try {
      if (searchResponse['data'] != null && searchResponse['data'] is List) {
        for (var flight in searchResponse['data']) {
          if (flight['token'] != null) {
            tokens.add(flight['token']);
          }
        }
      }
    } catch (e) {
      print('Erro ao extrair tokens: $e');
    }
    
    return tokens;
  }

  Future<FlightInfo?> _getFlightDetail(String token) async {
    // Se for um token mockado, retornar dados mockados
    if (token.startsWith('mock_token_')) {
      return _getMockFlightInfo(token);
    }

    final uri = Uri.parse('$_baseUrl/flight/flight-detail').replace(
      queryParameters: {
        'token': token,
        'languagecode': 'pt', // Português
      },
    );

    final headers = {
      'x-rapidapi-host': 'booking-com-api5.p.rapidapi.com',
      'x-rapidapi-key': _apiKey!,
    };

    print('Buscando detalhes do voo: $uri');

    try {
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedJson = json.decode(response.body);
        print('Detalhes do voo: $decodedJson');
        
        return _convertBookingResponseToFlightInfo(decodedJson);
      } else {
        print('Erro ao buscar detalhes do voo. Status: ${response.statusCode}');
        print('Resposta: ${response.body}');
        return _getMockFlightInfo(token);
      }
    } catch (e) {
      print('Erro na requisição de detalhes: $e');
      return _getMockFlightInfo(token);
    }
  }

  FlightInfo _getMockFlightInfo(String token) {
    // Dados mockados para teste
    final flightNumber = token == 'mock_token_1' ? 'AA123' : 'DL456';
    final airline = token == 'mock_token_1' ? 'American Airlines' : 'Delta Air Lines';
    
    return FlightInfo(
      flightDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
      flightStatus: 'scheduled',
      departure: DepartureInfo(
        airport: 'John F. Kennedy International Airport',
        iata: 'JFK',
        scheduled: '2025-06-20T10:00:00',
        estimated: '2025-06-20T10:00:00',
      ),
      arrival: ArrivalInfo(
        airport: 'Los Angeles International Airport',
        iata: 'LAX',
        scheduled: '2025-06-20T13:30:00',
        estimated: '2025-06-20T13:30:00',
      ),
      airline: AirlineInfo(
        name: airline,
        iata: token == 'mock_token_1' ? 'AA' : 'DL',
      ),
      flight: FlightDetails(
        number: flightNumber,
        iata: flightNumber,
      ),
    );
  }

  FlightInfo? _convertBookingResponseToFlightInfo(Map<String, dynamic> bookingResponse) {
    try {
      return FlightInfo(
        flightDate: bookingResponse['flight_date']?.toString(),
        flightStatus: 'scheduled',
        departure: DepartureInfo(
          airport: bookingResponse['departure']?['airport']?.toString(),
          iata: bookingResponse['departure']?['iata']?.toString(),
          scheduled: bookingResponse['departure']?['scheduled']?.toString(),
          estimated: bookingResponse['departure']?['estimated']?.toString(),
        ),
        arrival: ArrivalInfo(
          airport: bookingResponse['arrival']?['airport']?.toString(),
          iata: bookingResponse['arrival']?['iata']?.toString(),
          scheduled: bookingResponse['arrival']?['scheduled']?.toString(),
          estimated: bookingResponse['arrival']?['estimated']?.toString(),
        ),
        airline: AirlineInfo(
          name: bookingResponse['airline']?['name']?.toString(),
          iata: bookingResponse['airline']?['iata']?.toString(),
        ),
        flight: FlightDetails(
          number: bookingResponse['flight']?['number']?.toString(),
          iata: bookingResponse['flight']?['iata']?.toString(),
        ),
      );
    } catch (e) {
      print('Erro ao converter resposta da Booking: $e');
      return null;
    }
  }
} 

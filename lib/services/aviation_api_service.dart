import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_keys.dart';
import '../models/flight_info.dart';

class AviationApiService {
  final String _baseUrl = 'http://api.aviationstack.com/v1';
  String? _apiKey;

  AviationApiService() {
    print(
        "AviationApiService: Tentando carregar AVIATIONSTACK_API_KEY do .env");
    _apiKey = ApiKeys.aviationStackApiKey;
    if (_apiKey == null || _apiKey!.isEmpty) {
      // Em um app real, você poderia lançar uma exceção ou ter um fallback
      print('ERRO: AVIATIONSTACK_API_KEY não encontrada no .env');
    } else {
      print('AviationApiService: AVIATIONSTACK_API_KEY carregada: "${_apiKey!.substring(0, 8)}..."');
    }
  }

  Future<List<FlightInfo>> getFlights({
    String? arrIata, // Código IATA do aeroporto de chegada (ex: JFK)
    String? depIata, // Código IATA do aeroporto de partida
    String? flightDate, // Formato YYYY-MM-DD que o usuário selecionou na UI
    String flightStatus =
        'scheduled', // Outros: active, landed, cancelled, etc.
    int limit = 10,
  }) async {
    if (_apiKey == null) {
      print('ERRO em getFlights: _apiKey é null. Chave não configurada.');
      throw Exception('Chave da API da AviationStack não configurada.');
    }
    print('getFlights: Usando _apiKey: "$_apiKey"');
    Map<String, String> queryParams = {
      'access_key': _apiKey!,
      'flight_status': flightStatus,
      'limit': limit.toString(),
    };

    // Usa os parâmetros da UI se fornecidos
    if (arrIata != null) queryParams['arr_iata'] = arrIata;
    if (depIata != null) queryParams['dep_iata'] = depIata;
    if (flightDate != null) queryParams['flight_date'] = flightDate;

    // Este exemplo usa /flights, que pode ser mais genérico.
    final uri =
        Uri.parse('$_baseUrl/flights').replace(queryParameters: queryParams);

    print('Chamando API: $uri'); // Para debug

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedJson = json.decode(response.body);
        print(
            'AviationApiService: Resposta JSON decodificada: $decodedJson'); // Log da resposta completa
        final aviationResponse = AviationStackResponse.fromJson(decodedJson);

        if (aviationResponse.data.isEmpty) {
          print(
              'AviationApiService: A API retornou uma lista de voos vazia (aviationResponse.data está vazia).');
        } else {
          print(
              'AviationApiService: Voos processados (${aviationResponse.data.length}): ${aviationResponse.data.map((f) => f.flight?.iata).toList()}');
        }
        return aviationResponse.data; // Retorna os dados diretamente da API
      } else {
        // Tente decodificar a mensagem de erro da API, se houver
        String errorMessage =
            'Falha ao carregar dados dos voos. Status: ${response.statusCode}';
        try {
          final errorBody = json.decode(response.body);
          if (errorBody['error'] != null &&
              errorBody['error']['message'] != null) {
            errorMessage += ' - Mensagem: ${errorBody['error']['message']}';
          } else if (errorBody['message'] != null) {
            errorMessage += ' - Mensagem: ${errorBody['message']}';
          }
        } catch (e) {
          // Ignora se não conseguir parsear o corpo do erro
          errorMessage += ' - Corpo da resposta: ${response.body}';
        }
        print(errorMessage);
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Erro na chamada da API AviationStack: $e');
      rethrow; // Re-lança a exceção para ser tratada pelo chamador
    }
  }
}

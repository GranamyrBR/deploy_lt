import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ExchangeRateService {
  // APIs em ordem de prioridade - BCB é a fonte oficial mais confiável
  static const List<Map<String, String>> _apiEndpoints = [
    {
      'name': 'Banco Central do Brasil (PTAX)',
      'url': 'https://api.bcb.gov.br/dados/serie/bcdata.sgs.1/dados/ultimos/1?formato=json',
      'type': 'bcb'
    },
    {
      'name': 'AwesomeAPI',
      'url': 'https://economia.awesomeapi.com.br/json/last/USD-BRL',
      'type': 'awesomeapi'
    },
    {
      'name': 'Banco Central (Dólar Americano)',
      'url': 'https://api.bcb.gov.br/dados/serie/bcdata.sgs.10813/dados/ultimos/1?formato=json',
      'type': 'bcb_comercial'
    }
  ];
  
  String get _baseUrl => dotenv.env['EXCHANGE_RATE_API_URL'] ?? _apiEndpoints[0]['url']!;
  double get _fallbackBid => double.tryParse(dotenv.env['EXCHANGE_RATE_FALLBACK_BID'] ?? '5.50') ?? 5.50;
  double get _fallbackAsk => double.tryParse(dotenv.env['EXCHANGE_RATE_FALLBACK_ASK'] ?? '5.55') ?? 5.55;
  
  // Validação de valores realistas para USD/BRL (faixa baseada nos dados de 2025)
  static const double _minRealisticRate = 5.0; // Mínimo realista atual
  static const double _maxRealisticRate = 7.0; // Máximo realista atual
  
  bool _isRealisticRate(double rate) {
    return rate >= _minRealisticRate && rate <= _maxRealisticRate;
  }

  Future<Map<String, dynamic>> getExchangeRate() async {
    // Try each API endpoint in order
    for (int i = 0; i < _apiEndpoints.length; i++) {
      final endpoint = _apiEndpoints[i];
      try {
        print('ExchangeRateService: Tentando API ${endpoint['name']} - ${endpoint['url']}');
        
        final response = await http.get(
          Uri.parse(endpoint['url']!),
          headers: {'User-Agent': 'LecotourDashboard/1.0'},
        ).timeout(const Duration(seconds: 10));
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          
          // Parse response based on API type
                     switch (endpoint['type']) {
             case 'bcb':
             case 'bcb_comercial':
               // API do Banco Central do Brasil - fonte oficial PTAX
               if (data is List && data.isNotEmpty) {
                 final bcbData = data[0];
                 final rate = double.tryParse(bcbData['valor'] ?? '0') ?? 0.0;
                 if (rate > 0 && _isRealisticRate(rate)) {
                   // Para BCB, usamos spread muito pequeno pois é a taxa oficial
                   final result = {
                     'bid': rate * 0.999, // Spread mínimo para fonte oficial
                     'ask': rate * 1.001,
                     'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
                     'create_date': bcbData['data'] ?? DateTime.now().toUtc().toIso8601String(),
                     'source': '${endpoint['name']} (Oficial)',
                   };
                   print('ExchangeRateService: ✅ 🏛️ Cotação oficial BCB obtida - Taxa: $rate (Bid: ${result['bid']}, Ask: ${result['ask']})');
                   return result;
                 } else if (rate > 0) {
                   print('ExchangeRateService: ⚠️ Valor BCB fora da faixa esperada: $rate');
                 } else {
                   print('ExchangeRateService: ❌ BCB retornou valor inválido: ${bcbData['valor']}');
                 }
               } else {
                 print('ExchangeRateService: ❌ BCB retornou dados vazios ou formato incorreto');
               }
               break;

              
                         case 'awesomeapi':
               final usdBrl = data['USDBRL'];
               if (usdBrl != null) {
                 final bid = double.tryParse(usdBrl['bid'] ?? '0') ?? 0.0;
                 final ask = double.tryParse(usdBrl['ask'] ?? '0') ?? 0.0;
                 if (bid > 0 && ask > 0) {
                   // Converter timestamp da AwesomeAPI (em segundos) para milissegundos
                   String normalizedTimestamp;
                   try {
                     final originalTimestamp = usdBrl['timestamp'] ?? '';
                     if (originalTimestamp.isNotEmpty) {
                       final timestampInt = int.parse(originalTimestamp);
                       // Se está em segundos (10 dígitos), converter para milissegundos
                       normalizedTimestamp = timestampInt < 9999999999 
                         ? (timestampInt * 1000).toString()
                         : timestampInt.toString();
                     } else {
                       normalizedTimestamp = DateTime.now().millisecondsSinceEpoch.toString();
                     }
                   } catch (e) {
                     normalizedTimestamp = DateTime.now().millisecondsSinceEpoch.toString();
                   }
                   
                   final result = {
                     'bid': bid,
                     'ask': ask,
                     'timestamp': normalizedTimestamp,
                     'create_date': usdBrl['create_date'] ?? DateTime.now().toUtc().toIso8601String(),
                     'source': endpoint['name'],
                   };
                  print('ExchangeRateService: ✅ Cotação obtida via ${endpoint['name']} - Bid: ${result['bid']}, Ask: ${result['ask']}');
                  return result;
                }
              }
              break;
              
            case 'currencyapi':
              final dataRates = data['data'];
              if (dataRates != null && dataRates['BRL'] != null) {
                final rate = double.tryParse(dataRates['BRL']['value'].toString()) ?? 0.0;
                if (rate > 0) {
                  final result = {
                    'bid': rate * 0.98,
                    'ask': rate * 1.02,
                    'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
                    'create_date': DateTime.now().toUtc().toIso8601String(),
                    'source': endpoint['name'],
                  };
                  print('ExchangeRateService: ✅ Cotação obtida via ${endpoint['name']} - Bid: ${result['bid']}, Ask: ${result['ask']}');
                  return result;
                }
              }
              break;
          }
        } else {
          print('ExchangeRateService: ❌ API ${endpoint['name']} retornou status ${response.statusCode}');
        }
      } catch (e) {
        print('ExchangeRateService: ❌ Erro na API ${endpoint['name']}: $e');
        // Continue to next API
      }
    }
    
    // If all APIs fail, return fallback values
    print('ExchangeRateService: ⚠️ Todas as APIs falharam, usando valores de fallback - Bid: $_fallbackBid, Ask: $_fallbackAsk');
    return {
      'bid': _fallbackBid,
      'ask': _fallbackAsk,
      'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
      'create_date': DateTime.now().toUtc().toIso8601String(),
      'source': 'Fallback',
    };
  }

  // Método para obter apenas a cotação de compra (bid)
  Future<double> getBidRate() async {
    final rates = await getExchangeRate();
    return rates['bid'] as double;
  }

  // Método para obter apenas a cotação de venda (ask)
  Future<double> getAskRate() async {
    final rates = await getExchangeRate();
    return rates['ask'] as double;
  }

  // Método para obter a cotação oficial (média entre bid e ask)
  Future<double> getOfficialRate() async {
    final rates = await getExchangeRate();
    final bid = rates['bid'] as double;
    final ask = rates['ask'] as double;
    return (bid + ask) / 2;
  }

  // Método para testar conectividade com todas as APIs
  Future<Map<String, bool>> testApiConnectivity() async {
    final results = <String, bool>{};
    
    for (final endpoint in _apiEndpoints) {
      try {
        final response = await http.get(
          Uri.parse(endpoint['url']!),
          headers: {'User-Agent': 'LecotourDashboard/1.0'},
        ).timeout(const Duration(seconds: 5));
        
        results[endpoint['name']!] = response.statusCode == 200;
      } catch (e) {
        results[endpoint['name']!] = false;
      }
    }
    
    return results;
  }
} 

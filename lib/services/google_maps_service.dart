import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../config/api_keys.dart';

/// Serviço para APIs gratuitas do Google Maps (Fase 1)
/// 
/// APIs implementadas:
/// - Geocoding API: Converter endereços em coordenadas
/// - Directions API: Calcular rotas entre pontos
/// - Distance Matrix API: Calcular distâncias
class GoogleMapsService {
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api';
  
  // Cache para evitar chamadas repetidas
  static final Map<String, dynamic> _cache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheDuration = Duration(hours: 24); // Cache por 24 horas para coordenadas
  
  // Rate limiting
  static final Map<String, DateTime> _lastApiCall = {};
  static const Duration _rateLimitDelay = Duration(milliseconds: 500); // 500ms entre chamadas
  
  // Chave de API
  String? get _apiKey => ApiKeys.googleMapsApiKey;
  
  GoogleMapsService() {
    debugPrint('GoogleMapsService: Inicializado');
    _checkApiKey();
  }
  
  void _checkApiKey() {
    if (_apiKey == null || _apiKey!.isEmpty) {
      debugPrint('⚠️ Google Maps API Key não configurada');
      debugPrint('Configure GOOGLE_MAPS_API_KEY no arquivo .env');
    } else {
      debugPrint('✅ Google Maps API Key configurada');
    }
  }
  
  // =====================================================
  // GEOCODING API (2.500 requisições/dia GRÁTIS)
  // =====================================================
  
  /// Converte um endereço em coordenadas (latitude, longitude)
  Future<Map<String, dynamic>?> getCoordinates(String address) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      debugPrint('❌ Google Maps API Key não configurada para geocoding');
      return null;
    }
    
    final cacheKey = 'geocoding_${address.toLowerCase()}';
    
    // Verificar cache
    final cachedData = _getFromCache<Map<String, dynamic>>(cacheKey);
    if (cachedData != null) {
      return cachedData;
    }
    
    try {
      await _checkRateLimit('geocoding');
      
      final uri = Uri.parse('$_baseUrl/geocode/json').replace(
        queryParameters: {
          'address': address,
          'key': _apiKey!,
          'language': 'pt-BR',
        },
      );
      
      debugPrint('🌍 Geocoding: $address');
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          final result = data['results'][0];
          final location = result['geometry']['location'];
          final coordinates = <String, dynamic>{
            'latitude': location['lat'].toDouble(),
            'longitude': location['lng'].toDouble(),
            'formatted_address': result['formatted_address'],
            'place_id': result['place_id'],
            'types': result['types'],
          };
          
          _saveToCache(cacheKey, coordinates);
          debugPrint('✅ Coordenadas obtidas: ${coordinates['latitude']}, ${coordinates['longitude']}');
          return coordinates;
        } else {
          debugPrint('❌ Geocoding falhou: ${data['status']}');
          return null;
        }
      } else {
        debugPrint('❌ Erro HTTP: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Erro no geocoding: $e');
      return null;
    }
  }
  
  // =====================================================
  // DIRECTIONS API (2.500 requisições/dia GRÁTIS)
  // =====================================================
  
  /// Calcula rota entre dois pontos
  Future<Map<String, dynamic>?> getDirections({
    required String origin,
    required String destination,
    String? mode = 'driving', // driving, walking, bicycling, transit
  }) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      debugPrint('❌ Google Maps API Key não configurada para directions');
      return null;
    }
    
    final cacheKey = 'directions_${origin.toLowerCase()}_${destination.toLowerCase()}_$mode';
    
    // Verificar cache
    final cachedData = _getFromCache<Map<String, dynamic>>(cacheKey);
    if (cachedData != null) {
      return cachedData;
    }
    
    try {
      await _checkRateLimit('directions');
      
      final uri = Uri.parse('$_baseUrl/directions/json').replace(
        queryParameters: {
          'origin': origin,
          'destination': destination,
          'mode': mode,
          'key': _apiKey!,
          'language': 'pt-BR',
          'units': 'metric',
        },
      );
      
      debugPrint('🗺️ Directions: $origin → $destination ($mode)');
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];
          
          final directions = {
            'distance': leg['distance']['text'],
            'duration': leg['duration']['text'],
            'start_address': leg['start_address'],
            'end_address': leg['end_address'],
            'start_location': leg['start_location'],
            'end_location': leg['end_location'],
            'steps': leg['steps'].map((step) => {
              'instruction': step['html_instructions'],
              'distance': step['distance']['text'],
              'duration': step['duration']['text'],
            }).toList(),
            'polyline': route['overview_polyline'],
          };
          
          _saveToCache(cacheKey, directions);
          debugPrint('✅ Rota calculada: ${directions['distance']} em ${directions['duration']}');
          return directions;
        } else {
          debugPrint('❌ Directions falhou: ${data['status']}');
          return null;
        }
      } else {
        debugPrint('❌ Erro HTTP: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Erro no directions: $e');
      return null;
    }
  }
  
  // =====================================================
  // DISTANCE MATRIX API (100 requisições/dia GRÁTIS)
  // =====================================================
  
  /// Calcula distâncias entre múltiplos pontos
  Future<List<Map<String, dynamic>>?> getDistanceMatrix({
    required List<String> origins,
    required List<String> destinations,
    String? mode = 'driving',
  }) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      debugPrint('❌ Google Maps API Key não configurada para distance matrix');
      return null;
    }
    
    final cacheKey = 'distance_matrix_${origins.join('_')}_${destinations.join('_')}_$mode';
    
    // Verificar cache
    final cachedData = _getFromCache<List<Map<String, dynamic>>>(cacheKey);
    if (cachedData != null) {
      return cachedData;
    }
    
    try {
      await _checkRateLimit('distance_matrix');
      
      final uri = Uri.parse('$_baseUrl/distancematrix/json').replace(
        queryParameters: {
          'origins': origins.join('|'),
          'destinations': destinations.join('|'),
          'mode': mode,
          'key': _apiKey!,
          'language': 'pt-BR',
          'units': 'metric',
        },
      );
      
      debugPrint('📏 Distance Matrix: ${origins.length} origens → ${destinations.length} destinos');
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK') {
          final results = <Map<String, dynamic>>[];
          
          for (int i = 0; i < data['rows'].length; i++) {
            final row = data['rows'][i];
            for (int j = 0; j < row['elements'].length; j++) {
              final element = row['elements'][j];
              if (element['status'] == 'OK') {
                results.add({
                  'origin': origins[i],
                  'destination': destinations[j],
                  'distance': element['distance']['text'],
                  'duration': element['duration']['text'],
                  'distance_meters': element['distance']['value'],
                  'duration_seconds': element['duration']['value'],
                });
              }
            }
          }
          
          _saveToCache(cacheKey, results);
          debugPrint('✅ Distance matrix calculada: ${results.length} resultados');
          return results;
        } else {
          debugPrint('❌ Distance matrix falhou: ${data['status']}');
          return null;
        }
      } else {
        debugPrint('❌ Erro HTTP: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Erro no distance matrix: $e');
      return null;
    }
  }
  
  // =====================================================
  // MÉTODOS AUXILIARES
  // =====================================================
  
  /// Verifica se cache é válido
  bool _isCacheValid(String key) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _cacheDuration;
  }
  
  /// Obtém dados do cache
  T? _getFromCache<T>(String key) {
    if (_isCacheValid(key)) {
      debugPrint('📦 Retornando do cache: $key');
      return _cache[key] as T?;
    }
    return null;
  }
  
  /// Salva dados no cache
  void _saveToCache<T>(String key, T data) {
    _cache[key] = data;
    _cacheTimestamps[key] = DateTime.now();
    debugPrint('💾 Salvo no cache: $key');
  }
  
  /// Rate limiting
  Future<void> _checkRateLimit(String apiName) async {
    final lastCall = _lastApiCall[apiName];
    if (lastCall != null) {
      final timeSinceLastCall = DateTime.now().difference(lastCall);
      if (timeSinceLastCall < _rateLimitDelay) {
        final waitTime = _rateLimitDelay - timeSinceLastCall;
        debugPrint('⏱️ Rate limit: aguardando ${waitTime.inMilliseconds}ms para $apiName');
        await Future.delayed(waitTime);
      }
    }
    _lastApiCall[apiName] = DateTime.now();
  }
  
  /// Limpa cache
  void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
    debugPrint('🗑️ Cache limpo');
  }
  
  /// Limpa cache específico
  void clearCacheForKey(String key) {
    _cache.remove(key);
    _cacheTimestamps.remove(key);
    debugPrint('🗑️ Cache limpo para: $key');
  }
  
  /// Obtém estatísticas de uso
  Map<String, dynamic> getUsageStats() {
    return {
      'cache_size': _cache.length,
      'last_calls': _lastApiCall.map((key, value) => MapEntry(key, value.toIso8601String())),
    };
  }
} 

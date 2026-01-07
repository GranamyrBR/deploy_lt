import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/new_york_attraction.dart';
import '../models/new_york_tour_package.dart';
import '../models/new_york_weather.dart';
import '../config/api_keys.dart';
import 'google_maps_service.dart';

class NewYorkService {
  static const String _tripadvisorBaseUrl = 'https://tripadvisor1.p.rapidapi.com';
  static const String _openweatherBaseUrl = 'https://api.openweathermap.org/data/3.0';
  static const String _googlePlacesBaseUrl = 'https://maps.googleapis.com/maps/api/place';
  static const String _viatorBaseUrl = 'https://viator.p.rapidapi.com';

  // Cache para evitar chamadas repetidas
  static final Map<String, dynamic> _cache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheDuration = Duration(minutes: 15); // Cache por 15 minutos
  
  // Rate limiting
  static final Map<String, DateTime> _lastApiCall = {};
  static const Duration _rateLimitDelay = Duration(seconds: 2); // 2 segundos entre chamadas

  // Chaves de API (configurar no .env)
  String? get _tripadvisorApiKey => ApiKeys.tripadvisorApiKey;
  String? get _openweatherApiKey => ApiKeys.openweatherApiKey;
  String? get _googlePlacesApiKey => ApiKeys.googlePlacesApiKey;
  String? get _viatorApiKey => ApiKeys.viatorApiKey;

  // Google Maps Service (APIs gratuitas - Fase 1)
  late final GoogleMapsService _googleMapsService;

  NewYorkService() {
    debugPrint('NewYorkService: Inicializado');
    _googleMapsService = GoogleMapsService();
    _checkApiKeys();
  }

  void _checkApiKeys() {
    debugPrint('Verificando chaves de API:');
    debugPrint('TripAdvisor: ${_tripadvisorApiKey != null ? "✓" : "✗"}');
    debugPrint('OpenWeather: ${_openweatherApiKey != null ? "✓" : "✗"}');
    debugPrint('Google Places: ${_googlePlacesApiKey != null ? "✓" : "✗"}');
    debugPrint('Viator: ${_viatorApiKey != null ? "✓" : "✗"}');
  }



  // Método para verificar cache
  bool _isCacheValid(String key) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _cacheDuration;
  }

  // Método para obter do cache
  T? _getFromCache<T>(String key) {
    if (_isCacheValid(key)) {
      debugPrint('Retornando dados do cache: $key');
      return _cache[key] as T?;
    }
    return null;
  }

  // Método para salvar no cache
  void _saveToCache<T>(String key, T data) {
    _cache[key] = data;
    _cacheTimestamps[key] = DateTime.now();
    debugPrint('Dados salvos no cache: $key');
  }

  // Método para rate limiting
  Future<void> _checkRateLimit(String apiName) async {
    final lastCall = _lastApiCall[apiName];
    if (lastCall != null) {
      final timeSinceLastCall = DateTime.now().difference(lastCall);
      if (timeSinceLastCall < _rateLimitDelay) {
        final waitTime = _rateLimitDelay - timeSinceLastCall;
        debugPrint('Rate limit: aguardando ${waitTime.inMilliseconds}ms para $apiName');
        await Future.delayed(waitTime);
      }
    }
    _lastApiCall[apiName] = DateTime.now();
  }

  // Método para limpar cache
  void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
    debugPrint('Cache limpo');
  }

  // Método para limpar cache específico
  void clearCacheForKey(String key) {
    _cache.remove(key);
    _cacheTimestamps.remove(key);
    debugPrint('Cache limpo para: $key');
  }

  // =====================================================
  // ATRAÇÕES TURÍSTICAS (TripAdvisor + Google Places)
  // =====================================================

  Future<List<NewYorkAttraction>> getAttractions({
    String? category,
    String? neighborhood,
    int limit = 20,
    String? sortBy, // "rating", "popularity", "price"
  }) async {
    // Criar chave única para cache
    final cacheKey = 'attractions_${category ?? 'all'}_${neighborhood ?? 'all'}_$limit';
    
    // Verificar cache primeiro
    final cachedData = _getFromCache<List<NewYorkAttraction>>(cacheKey);
    if (cachedData != null) {
      return cachedData;
    }

    try {
      debugPrint('=== BUSCANDO ATRAÇÕES NYC ===');
      debugPrint('Categoria: $category');
      debugPrint('Bairro: $neighborhood');
      debugPrint('Limite: $limit');

      List<NewYorkAttraction> result;

      // Primeiro tentar TripAdvisor (GRATUITO via RapidAPI)
      if (_tripadvisorApiKey != null) {
        try {
          await _checkRateLimit('tripadvisor');
          result = await _getAttractionsFromTripAdvisor(
            category: category,
            neighborhood: neighborhood,
            limit: limit,
            sortBy: sortBy,
          );
          _saveToCache(cacheKey, result);
          return result;
        } catch (e) {
          debugPrint('Erro TripAdvisor: $e');
        }
      }

      // DESABILITADO: Google Places API (CAUSA COBRANÇAS)
      // Usar apenas dados mockados como fallback
      debugPrint('Google Places API DESABILITADA para evitar cobranças');
      debugPrint('Usando dados mockados como fallback');
      result = _getMockAttractions(category: category, neighborhood: neighborhood);
      _saveToCache(cacheKey, result);
      return result;
    } catch (e) {
      debugPrint('Erro ao buscar atrações: $e');
      final result = _getMockAttractions(category: category, neighborhood: neighborhood);
      _saveToCache(cacheKey, result);
      return result;
    }
  }

  Future<List<NewYorkAttraction>> _getAttractionsFromTripAdvisor({
    String? category,
    String? neighborhood,
    int limit = 20,
    String? sortBy,
  }) async {
    final uri = Uri.parse('$_tripadvisorBaseUrl/attractions/list').replace(
      queryParameters: {
        'location_id': '60763', // NYC location ID
        'currency': 'USD',
        'lang': 'pt-BR',
        'lunit': 'km',
        'limit': limit.toString(),
        if (category != null) 'category': category,
        if (sortBy != null) 'sort': sortBy,
      },
    );

    final response = await http.get(
      uri,
      headers: {
        'x-rapidapi-host': 'tripadvisor1.p.rapidapi.com',
        'x-rapidapi-key': _tripadvisorApiKey!,
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return _parseTripAdvisorAttractions(data, neighborhood);
    } else {
      throw Exception('Erro TripAdvisor: ${response.statusCode}');
    }
  }

  Future<List<NewYorkAttraction>> _getAttractionsFromGooglePlaces({
    String? category,
    String? neighborhood,
  }) async {
    final uri = Uri.parse('$_googlePlacesBaseUrl/nearbysearch/json').replace(
      queryParameters: {
        'location': '40.7128,-74.0060', // NYC coordinates
        'radius': '50000',
        'type': 'tourist_attraction',
        'language': 'pt-BR',
        'key': _googlePlacesApiKey!,
        if (category != null) 'keyword': category,
      },
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return _parseGooglePlacesAttractions(data, neighborhood);
    } else {
      throw Exception('Erro Google Places: ${response.statusCode}');
    }
  }

  List<NewYorkAttraction> _parseTripAdvisorAttractions(Map<String, dynamic> data, String? neighborhood) {
    final attractions = <NewYorkAttraction>[];
    
    if (data['data'] != null) {
      for (final item in data['data']) {
        if (neighborhood == null || 
            item['address_string']?.toLowerCase().contains(neighborhood.toLowerCase()) == true) {
          attractions.add(NewYorkAttraction(
            id: item['location_id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
            name: item['name'] ?? 'Nome não disponível',
            description: item['description'],
            address: item['address_string'],
            latitude: item['latitude']?.toDouble(),
            longitude: item['longitude']?.toDouble(),
            category: item['category']?['name'],
            neighborhood: _extractNeighborhood(item['address_string']),
            rating: item['rating']?.toDouble(),
            reviewCount: item['num_reviews'],
            priceLevel: _convertPriceLevel(item['price_level']),
            openingHours: item['hours']?['week_ranges']?.toString(),
            phone: item['phone'],
            website: item['website'],
            photos: item['photo']?['images']?['large'] != null 
                ? [item['photo']['images']['large']['url']] 
                : null,
            tags: _extractTags(item),
            estimatedDuration: _estimateDuration(item['category']?['name']),
            isWheelchairAccessible: item['wheelchair_accessible'] ?? false,
            isFamilyFriendly: _isFamilyFriendly(item['category']?['name']),
            seasonality: 'year-round',
            crowdLevel: _estimateCrowdLevel(item['rating']),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));
        }
      }
    }
    
    return attractions;
  }

  List<NewYorkAttraction> _parseGooglePlacesAttractions(Map<String, dynamic> data, String? neighborhood) {
    final attractions = <NewYorkAttraction>[];
    
    if (data['results'] != null) {
      for (final item in data['results']) {
        if (neighborhood == null || 
            item['vicinity']?.toLowerCase().contains(neighborhood.toLowerCase()) == true) {
          attractions.add(NewYorkAttraction(
            id: item['place_id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
            name: item['name'] ?? 'Nome não disponível',
            description: item['types']?.join(', '),
            address: item['vicinity'],
            latitude: item['geometry']?['location']?['lat']?.toDouble(),
            longitude: item['geometry']?['location']?['lng']?.toDouble(),
            category: item['types']?.first,
            neighborhood: _extractNeighborhood(item['vicinity']),
            rating: item['rating']?.toDouble(),
            reviewCount: item['user_ratings_total'],
            priceLevel: _convertGooglePriceLevel(item['price_level']),
            openingHours: item['opening_hours']?['open_now']?.toString(),
            photos: item['photos']?.map((p) => 
                'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=${p['photo_reference']}&key=$_googlePlacesApiKey').toList().cast<String>(),
            tags: item['types']?.cast<String>(),
            estimatedDuration: _estimateDuration(item['types']?.first),
            isWheelchairAccessible: item['wheelchair_accessible_entrance'] ?? false,
            isFamilyFriendly: _isFamilyFriendly(item['types']?.first),
            seasonality: 'year-round',
            crowdLevel: _estimateCrowdLevel(item['rating']),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));
        }
      }
    }
    
    return attractions;
  }

  // =====================================================
  // PACOTES DE TOURS (Viator)
  // =====================================================

  Future<List<NewYorkTourPackage>> getTourPackages({
    String? category,
    String? duration,
    double? maxPrice,
    int? groupSize,
    bool? familyFriendly,
  }) async {
    // Criar chave única para cache
    final cacheKey = 'packages_${category ?? 'all'}_${duration ?? 'all'}_${maxPrice ?? 'all'}_${groupSize ?? 'all'}_${familyFriendly ?? 'all'}';
    
    // Verificar cache primeiro
    final cachedData = _getFromCache<List<NewYorkTourPackage>>(cacheKey);
    if (cachedData != null) {
      return cachedData;
    }

    try {
      debugPrint('=== BUSCANDO PACOTES NYC ===');
      debugPrint('Categoria: $category');
      debugPrint('Duração: $duration');
      debugPrint('Preço máximo: $maxPrice');

      List<NewYorkTourPackage> result;

      // DESABILITADO: Viator API (causa loop infinito e erros 429)
      // Usar apenas dados mockados
      debugPrint('Viator API DESABILITADA para evitar loop infinito');

      // Fallback para dados mockados
      debugPrint('Usando dados mockados como fallback');
      result = _getMockTourPackages(
        category: category,
        duration: duration,
        maxPrice: maxPrice,
        groupSize: groupSize,
        familyFriendly: familyFriendly,
      );
      _saveToCache(cacheKey, result);
      return result;
    } catch (e) {
      debugPrint('Erro ao buscar pacotes: $e');
      final result = _getMockTourPackages(
        category: category,
        duration: duration,
        maxPrice: maxPrice,
        groupSize: groupSize,
        familyFriendly: familyFriendly,
      );
      _saveToCache(cacheKey, result);
      return result;
    }
  }

  Future<List<NewYorkTourPackage>> _getTourPackagesFromViator({
    String? category,
    String? duration,
    double? maxPrice,
    int? groupSize,
    bool? familyFriendly,
  }) async {
    final uri = Uri.parse('$_viatorBaseUrl/products').replace(
      queryParameters: {
        'destId': '60763', // NYC destination ID
        'currency': 'USD',
        'lang': 'pt-BR',
        'limit': '50',
        if (category != null) 'catId': _getViatorCategoryId(category),
        if (maxPrice != null) 'maxPrice': maxPrice.toString(),
      },
    );

    final response = await http.get(
      uri,
      headers: {
        'x-rapidapi-host': 'viator.p.rapidapi.com',
        'x-rapidapi-key': _viatorApiKey!,
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return _parseViatorTourPackages(data, duration, groupSize, familyFriendly);
    } else if (response.statusCode == 429) {
      debugPrint('Rate limit atingido para Viator API. Usando dados mockados.');
      throw Exception('Rate limit: ${response.statusCode}');
    } else {
      throw Exception('Erro Viator: ${response.statusCode}');
    }
  }

  List<NewYorkTourPackage> _parseViatorTourPackages(
    Map<String, dynamic> data, 
    String? duration, 
    int? groupSize, 
    bool? familyFriendly
  ) {
    final packages = <NewYorkTourPackage>[];
    
    if (data['products'] != null) {
      for (final item in data['products']) {
        // Filtrar por duração
        if (duration != null && !_matchesDuration(item, duration)) continue;
        
        // Filtrar por tamanho do grupo
        if (groupSize != null && !_matchesGroupSize(item, groupSize)) continue;
        
        // Filtrar por family-friendly
        if (familyFriendly != null && !_matchesFamilyFriendly(item, familyFriendly)) continue;

        packages.add(NewYorkTourPackage(
          id: item['productId']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
          name: item['title'] ?? 'Tour não disponível',
          description: item['shortDescription'],
          shortDescription: item['shortDescription'],
          category: _convertViatorCategory(item['primaryGroupId']),
          duration: _convertViatorDuration(item['duration']),
          estimatedHours: _extractHours(item['duration']),
          price: _extractPrice(item['price']),
          currency: 'USD',
          originalPrice: item['originalPrice']?.toString(),
          discountPercentage: _calculateDiscount(item['price'], item['originalPrice']),
          maxGroupSize: item['maxGroupSize'] ?? 20,
          minGroupSize: item['minGroupSize'] ?? 1,
          includedAttractions: _extractIncludedAttractions(item),
          includedServices: _extractIncludedServices(item),
          excludedServices: _extractExcludedServices(item),
          highlights: _extractHighlights(item),
          meetingPoint: item['meetingPoint'],
          endingPoint: item['endingPoint'],
          transportation: _extractTransportation(item),
          includesGuide: item['includesGuide'] ?? true,
          includesMeals: item['includesMeals'] ?? false,
          includesTickets: item['includesTickets'] ?? true,
          includesTransportation: item['includesTransportation'] ?? false,
          guideLanguage: item['guideLanguage'] ?? 'en',
          difficultyLevel: _extractDifficultyLevel(item),
          isWheelchairAccessible: item['wheelchairAccessible'] ?? false,
          isFamilyFriendly: item['familyFriendly'] ?? false,
          bestTimeToVisit: item['bestTimeToVisit'],
          seasonality: item['seasonality'] ?? 'year-round',
          photos: item['photos']?.map((p) => p['url']).toList().cast<String>(),
          rating: item['rating']?.toDouble(),
          reviewCount: item['reviewCount'],
          tags: _extractTourTags(item),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }
    }
    
    return packages;
  }

  // =====================================================
  // INFORMAÇÕES CLIMÁTICAS (OpenWeather)
  // =====================================================

  Future<NewYorkWeather> getCurrentWeather() async {
    // Criar chave única para cache (clima muda a cada 10 minutos)
    const cacheKey = 'weather_current';
    
    // Verificar cache primeiro
    final cachedData = _getFromCache<NewYorkWeather>(cacheKey);
    if (cachedData != null) {
      return cachedData;
    }

    try {
      debugPrint('=== BUSCANDO CLIMA NYC ===');

      NewYorkWeather result;

      if (_openweatherApiKey != null) {
        try {
          await _checkRateLimit('openweather');
          result = await _getWeatherFromOpenWeather();
          _saveToCache(cacheKey, result);
          return result;
        } catch (e) {
          debugPrint('Erro OpenWeather: $e');
        }
      }

      // Fallback para dados mockados
      debugPrint('Usando dados mockados como fallback');
      result = _getMockWeather();
      _saveToCache(cacheKey, result);
      return result;
    } catch (e) {
      debugPrint('Erro ao buscar clima: $e');
      final result = _getMockWeather();
      _saveToCache(cacheKey, result);
      return result;
    }
  }

  Future<NewYorkWeather> _getWeatherFromOpenWeather() async {
    // Coordenadas de Nova York
    const lat = 40.7128;
    const lon = -74.0060;
    
    final uri = Uri.parse('$_openweatherBaseUrl/onecall').replace(
      queryParameters: {
        'lat': lat.toString(),
        'lon': lon.toString(),
        'appid': _openweatherApiKey!,
        'units': 'metric',
        'lang': 'pt_br',
        'exclude': 'minutely', // Excluir dados de minuto para economizar
      },
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return _parseOpenWeatherOneCallData(data);
    } else {
      throw Exception('Erro OpenWeather: ${response.statusCode}');
    }
  }

  NewYorkWeather _parseOpenWeatherOneCallData(Map<String, dynamic> data) {
    final current = data['current'];
    final daily = data['daily']?[0]; // Previsão de hoje
    final hourly = data['hourly']?.take(24).toList(); // Previsão de 24h
    
    return NewYorkWeather(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.fromMillisecondsSinceEpoch(current['dt'] * 1000),
      temperature: current['temp'].toDouble(),
      feelsLike: current['feels_like'].toDouble(),
      minTemperature: daily?['temp']?['min']?.toDouble() ?? current['temp'].toDouble(),
      maxTemperature: daily?['temp']?['max']?.toDouble() ?? current['temp'].toDouble(),
      humidity: current['humidity'],
      pressure: current['pressure'],
      windSpeed: current['wind_speed'].toDouble(),
      windDirection: _convertWindDirection(current['wind_deg']),
      description: current['weather'][0]['description'],
      icon: current['weather'][0]['icon'],
      visibility: (current['visibility'] ?? 10000) / 1000, // Convert to km
      uvIndex: current['uvi']?.toDouble() ?? 0,
      precipitation: current['pop']?.toDouble() ?? 0, // Probability of precipitation
      precipitationType: _determinePrecipitationType(current['weather'][0]['main']),
      cloudCover: current['clouds'],
      sunrise: _formatTime(daily?['sunrise'] ?? current['dt']),
      sunset: _formatTime(daily?['sunset'] ?? current['dt']),
      moonrise: _formatTime(daily?['moonrise']),
      moonset: _formatTime(daily?['moonset']),
      moonPhase: _getMoonPhase(daily?['moon_phase']),
      hourlyForecast: _parseHourlyForecast(hourly),
      dailyForecast: _parseDailyForecast(data['daily']),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // =====================================================
  // DADOS MOCKADOS (Fallback)
  // =====================================================

  List<NewYorkAttraction> _getMockAttractions({String? category, String? neighborhood}) {
    final allAttractions = [
      NewYorkAttraction(
        id: '1',
        name: 'Estátua da Liberdade',
        description: 'Símbolo icônico da liberdade americana, localizada na Liberty Island.',
        address: 'Liberty Island, New York, NY 10004',
        latitude: 40.6892,
        longitude: -74.0445,
        category: 'landmark',
        neighborhood: 'Manhattan',
        rating: 4.7,
        reviewCount: 45000,
        priceLevel: '\$\$',
        openingHours: '8:30 AM - 4:00 PM',
        phone: '+1 (212) 363-3200',
        website: 'https://www.nps.gov/stli/',
        photos: ['https://example.com/statue-liberty.jpg'],
        tags: ['iconic', 'historical', 'family-friendly'],
        pricing: {'adult': 25.00, 'child': 12.00, 'senior': 20.00},
        bestTimeToVisit: 'Manhã cedo para evitar filas',
        estimatedDuration: 180,
        isWheelchairAccessible: true,
        isFamilyFriendly: true,
        seasonality: 'year-round',
        crowdLevel: 'high',
        nearbyAttractions: ['Ellis Island', 'Battery Park', 'Wall Street'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      NewYorkAttraction(
        id: '2',
        name: 'Central Park',
        description: 'O pulmão verde de Manhattan, com 843 acres de parque urbano.',
        address: 'Central Park, New York, NY',
        latitude: 40.7829,
        longitude: -73.9654,
        category: 'park',
        neighborhood: 'Central Park',
        rating: 4.8,
        reviewCount: 67000,
        priceLevel: '\$',
        openingHours: '6:00 AM - 10:00 PM',
        phone: '+1 (212) 310-6600',
        website: 'https://www.centralparknyc.org/',
        photos: ['https://example.com/central-park.jpg'],
        tags: ['nature', 'recreation', 'family-friendly', 'romantic'],
        pricing: {'entrance': 0.00},
        bestTimeToVisit: 'Primavera e outono para as cores',
        estimatedDuration: 240,
        isWheelchairAccessible: true,
        isFamilyFriendly: true,
        seasonality: 'year-round',
        crowdLevel: 'medium',
        nearbyAttractions: ['Metropolitan Museum', 'Belvedere Castle', 'Bethesda Fountain'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      NewYorkAttraction(
        id: '3',
        name: 'Times Square',
        description: 'O cruzamento mais famoso do mundo, conhecido por suas luzes neon.',
        address: 'Times Square, New York, NY 10036',
        latitude: 40.7580,
        longitude: -73.9855,
        category: 'tourist_attraction',
        neighborhood: 'Times Square',
        rating: 4.3,
        reviewCount: 89000,
        priceLevel: '\$\$',
        openingHours: '24/7',
        phone: '+1 (212) 869-1890',
        website: 'https://www.timessquarenyc.org/',
        photos: ['https://example.com/times-square.jpg'],
        tags: ['iconic', 'nightlife', 'shopping', 'entertainment'],
        pricing: {'entrance': 0.00},
        bestTimeToVisit: 'À noite para ver as luzes',
        estimatedDuration: 120,
        isWheelchairAccessible: true,
        isFamilyFriendly: true,
        seasonality: 'year-round',
        crowdLevel: 'high',
        nearbyAttractions: ['Broadway', 'Madame Tussauds', 'Hershey Store'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      NewYorkAttraction(
        id: '4',
        name: 'Metropolitan Museum of Art',
        description: 'Um dos maiores e mais importantes museus de arte do mundo.',
        address: '1000 5th Ave, New York, NY 10028',
        latitude: 40.7794,
        longitude: -73.9632,
        category: 'museum',
        neighborhood: 'Upper East Side',
        rating: 4.6,
        reviewCount: 56000,
        priceLevel: '\$\$',
        openingHours: '10:00 AM - 5:30 PM',
        phone: '+1 (212) 535-7710',
        website: 'https://www.metmuseum.org/',
        photos: ['https://example.com/met-museum.jpg'],
        tags: ['art', 'cultural', 'educational', 'family-friendly'],
        pricing: {'adult': 25.00, 'student': 12.00, 'senior': 17.00},
        bestTimeToVisit: 'Quartas-feiras à noite (gratuito)',
        estimatedDuration: 300,
        isWheelchairAccessible: true,
        isFamilyFriendly: true,
        seasonality: 'year-round',
        crowdLevel: 'medium',
        nearbyAttractions: ['Central Park', 'Guggenheim Museum', 'Frick Collection'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      NewYorkAttraction(
        id: '5',
        name: 'Empire State Building',
        description: 'Arranha-céu icônico com observatório no 86º andar.',
        address: '20 W 34th St, New York, NY 10001',
        latitude: 40.7484,
        longitude: -73.9857,
        category: 'landmark',
        neighborhood: 'Midtown',
        rating: 4.4,
        reviewCount: 78000,
        priceLevel: '\$\$\$',
        openingHours: '8:00 AM - 2:00 AM',
        phone: '+1 (212) 736-3100',
        website: 'https://www.esbnyc.com/',
        photos: ['https://example.com/empire-state.jpg'],
        tags: ['iconic', 'views', 'romantic', 'nightlife'],
        pricing: {'adult': 44.00, 'child': 38.00, 'senior': 42.00},
        bestTimeToVisit: 'Pôr do sol para vistas espetaculares',
        estimatedDuration: 120,
        isWheelchairAccessible: true,
        isFamilyFriendly: true,
        seasonality: 'year-round',
        crowdLevel: 'high',
        nearbyAttractions: ['Madison Square Garden', 'Herald Square', 'Macy\'s'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    // Filtrar por categoria se especificada
    if (category != null) {
      return allAttractions.where((a) => a.category == category).toList();
    }

    // Filtrar por bairro se especificado
    if (neighborhood != null) {
      return allAttractions.where((a) => 
        a.neighborhood?.toLowerCase().contains(neighborhood.toLowerCase()) == true
      ).toList();
    }

    return allAttractions;
  }

  List<NewYorkTourPackage> _getMockTourPackages({
    String? category,
    String? duration,
    double? maxPrice,
    int? groupSize,
    bool? familyFriendly,
  }) {
    final allPackages = [
      NewYorkTourPackage(
        id: '1',
        name: 'City Tour Clássico de Nova York',
        description: 'Passeio completo pelos principais pontos turísticos da cidade.',
        shortDescription: 'Veja os principais pontos turísticos de NYC em um dia',
        category: 'city_tour',
        duration: 'full_day',
        estimatedHours: 8,
        price: 89.99,
        currency: 'USD',
        originalPrice: '119.99',
        discountPercentage: 25.0,
        maxGroupSize: 15,
        minGroupSize: 1,
        includedAttractions: ['Times Square', 'Central Park', 'Empire State Building', 'Brooklyn Bridge'],
        includedServices: ['Guia profissional', 'Transporte', 'Ingressos', 'Almoço'],
        excludedServices: ['Gorjetas', 'Bebidas', 'Compras pessoais'],
        highlights: ['Vistas panorâmicas', 'Fotos icônicas', 'História da cidade'],
        meetingPoint: 'Times Square, em frente ao Hard Rock Cafe',
        endingPoint: 'Brooklyn Bridge',
        transportation: 'bus',
        includesGuide: true,
        includesMeals: true,
        includesTickets: true,
        includesTransportation: true,
        guideLanguage: 'pt-BR',
        difficultyLevel: 'easy',
        isWheelchairAccessible: true,
        isFamilyFriendly: true,
        bestTimeToVisit: 'Primavera e outono',
        seasonality: 'year-round',
        photos: ['https://example.com/city-tour.jpg'],
        rating: 4.7,
        reviewCount: 1250,
        tags: ['popular', 'family-friendly', 'cultural'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      NewYorkTourPackage(
        id: '2',
        name: 'Tour Gastronômico de Nova York',
        description: 'Explore a cena gastronômica diversificada da cidade.',
        shortDescription: 'Prove as melhores comidas de NYC',
        category: 'food',
        duration: 'half_day',
        estimatedHours: 4,
        price: 65.00,
        currency: 'USD',
        maxGroupSize: 12,
        minGroupSize: 2,
        includedAttractions: ['Little Italy', 'Chinatown', 'Chelsea Market'],
        includedServices: ['Guia especializado', 'Degustações', 'Água'],
        excludedServices: ['Bebidas alcoólicas', 'Gorjetas'],
        highlights: ['Pizza autêntica', 'Dim sum', 'Street food'],
        meetingPoint: 'Little Italy, Mulberry Street',
        endingPoint: 'Chelsea Market',
        transportation: 'walking',
        includesGuide: true,
        includesMeals: true,
        includesTickets: false,
        includesTransportation: false,
        guideLanguage: 'pt-BR',
        difficultyLevel: 'easy',
        isWheelchairAccessible: false,
        isFamilyFriendly: true,
        bestTimeToVisit: 'Almoço ou jantar',
        seasonality: 'year-round',
        photos: ['https://example.com/food-tour.jpg'],
        rating: 4.8,
        reviewCount: 890,
        tags: ['gastronômico', 'cultural', 'popular'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      NewYorkTourPackage(
        id: '3',
        name: 'Tour Romântico de Nova York',
        description: 'Experiência romântica perfeita para casais.',
        shortDescription: 'Momentos românticos nos locais mais charmosos',
        category: 'romantic',
        duration: 'full_day',
        estimatedHours: 6,
        price: 199.99,
        currency: 'USD',
        maxGroupSize: 2,
        minGroupSize: 2,
        includedAttractions: ['Central Park', 'Brooklyn Bridge', 'Top of the Rock'],
        includedServices: ['Guia privativo', 'Limousine', 'Jantar romântico', 'Fotógrafo'],
        excludedServices: ['Flores', 'Joias'],
        highlights: ['Pôr do sol no Brooklyn Bridge', 'Jantar com vista', 'Fotos profissionais'],
        meetingPoint: 'Hotel do cliente',
        endingPoint: 'Restaurante romântico',
        transportation: 'limo',
        includesGuide: true,
        includesMeals: true,
        includesTickets: true,
        includesTransportation: true,
        guideLanguage: 'pt-BR',
        difficultyLevel: 'easy',
        isWheelchairAccessible: true,
        isFamilyFriendly: false,
        bestTimeToVisit: 'Pôr do sol',
        seasonality: 'year-round',
        photos: ['https://example.com/romantic-tour.jpg'],
        rating: 4.9,
        reviewCount: 450,
        tags: ['romântico', 'luxo', 'exclusivo'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    // Aplicar filtros
    var filteredPackages = allPackages;

    if (category != null) {
      filteredPackages = filteredPackages.where((p) => p.category == category).toList();
    }

    if (duration != null) {
      filteredPackages = filteredPackages.where((p) => p.duration == duration).toList();
    }

    if (maxPrice != null) {
      filteredPackages = filteredPackages.where((p) => p.price <= maxPrice).toList();
    }

    if (groupSize != null) {
      filteredPackages = filteredPackages.where((p) => 
        p.minGroupSize <= groupSize && p.maxGroupSize >= groupSize
      ).toList();
    }

    if (familyFriendly != null) {
      filteredPackages = filteredPackages.where((p) => p.isFamilyFriendly == familyFriendly).toList();
    }

    return filteredPackages;
  }

  NewYorkWeather _getMockWeather() {
    return NewYorkWeather(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      temperature: 22.0,
      feelsLike: 24.0,
      minTemperature: 18.0,
      maxTemperature: 26.0,
      humidity: 65,
      pressure: 1013,
      windSpeed: 12.0,
      windDirection: 'SW',
      description: 'scattered clouds',
      icon: '03d',
      visibility: 10.0,
      uvIndex: 6.0,
      precipitation: 0.0,
      precipitationType: 'none',
      cloudCover: 40,
      sunrise: '06:30',
      sunset: '19:45',
      moonrise: '14:20',
      moonset: '02:15',
      moonPhase: 'first_quarter',
      bestTimeToVisit: 'Excelente para turismo!',
      tourismRecommendation: 'Perfeito para atividades ao ar livre e passeios turísticos!',
      activities: ['Central Park', 'Times Square', 'Brooklyn Bridge'],
      clothingRecommendations: ['Jaqueta leve', 'Camisa de manga longa'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // =====================================================
  // MÉTODOS AUXILIARES
  // =====================================================

  String _extractNeighborhood(String? address) {
    if (address == null) return 'Manhattan';
    
    final neighborhoods = [
      'Manhattan', 'Brooklyn', 'Queens', 'Bronx', 'Staten Island',
      'Times Square', 'Central Park', 'Financial District', 'SoHo',
      'Chelsea', 'Greenwich Village', 'Upper East Side', 'Upper West Side',
      'Harlem', 'Williamsburg', 'DUMBO'
    ];
    
    for (final neighborhood in neighborhoods) {
      if (address.toLowerCase().contains(neighborhood.toLowerCase())) {
        return neighborhood;
      }
    }
    
    return 'Manhattan';
  }

  String _convertPriceLevel(String? priceLevel) {
    switch (priceLevel) {
      case '1':
        return '\$';
      case '2':
        return '\$\$';
      case '3':
        return '\$\$\$';
      case '4':
        return '\$\$\$\$';
      default:
        return '\$\$';
    }
  }

  String _convertGooglePriceLevel(int? priceLevel) {
    switch (priceLevel) {
      case 1:
        return '\$';
      case 2:
        return '\$\$';
      case 3:
        return '\$\$\$';
      case 4:
        return '\$\$\$\$';
      default:
        return '\$\$';
    }
  }

  List<String> _extractTags(Map<String, dynamic> item) {
    final tags = <String>[];
    
    if (item['family_friendly'] == true) tags.add('family-friendly');
    if (item['romantic'] == true) tags.add('romantic');
    if (item['cultural'] == true) tags.add('cultural');
    if (item['historical'] == true) tags.add('historical');
    if (item['iconic'] == true) tags.add('iconic');
    
    return tags;
  }

  int _estimateDuration(String? category) {
    switch (category) {
      case 'museum':
        return 180;
      case 'park':
        return 120;
      case 'landmark':
        return 90;
      case 'tourist_attraction':
        return 60;
      default:
        return 60;
    }
  }

  bool _isFamilyFriendly(String? category) {
    final familyFriendlyCategories = ['park', 'museum', 'tourist_attraction'];
    return familyFriendlyCategories.contains(category);
  }

  String _estimateCrowdLevel(double? rating) {
    if (rating == null) return 'medium';
    if (rating >= 4.5) return 'high';
    if (rating >= 4.0) return 'medium';
    return 'low';
  }

  String _getViatorCategoryId(String category) {
    switch (category) {
      case 'city_tour':
        return '1';
      case 'cultural':
        return '2';
      case 'food':
        return '3';
      case 'shopping':
        return '4';
      case 'nightlife':
        return '5';
      default:
        return '1';
    }
  }

  String _convertViatorCategory(String? categoryId) {
    switch (categoryId) {
      case '1':
        return 'city_tour';
      case '2':
        return 'cultural';
      case '3':
        return 'food';
      case '4':
        return 'shopping';
      case '5':
        return 'nightlife';
      default:
        return 'city_tour';
    }
  }

  String _convertViatorDuration(String? duration) {
    if (duration == null) return 'full_day';
    if (duration.contains('half')) return 'half_day';
    if (duration.contains('full')) return 'full_day';
    if (duration.contains('multi')) return 'multi_day';
    return 'full_day';
  }

  int _extractHours(String? duration) {
    if (duration == null) return 8;
    if (duration.contains('half')) return 4;
    if (duration.contains('full')) return 8;
    if (duration.contains('multi')) return 24;
    return 8;
  }

  double _extractPrice(Map<String, dynamic>? price) {
    if (price == null) return 0.0;
    return price['amount']?.toDouble() ?? 0.0;
  }

  double? _calculateDiscount(Map<String, dynamic>? price, Map<String, dynamic>? originalPrice) {
    if (price == null || originalPrice == null) return null;
    final currentPrice = price['amount']?.toDouble() ?? 0.0;
    final original = originalPrice['amount']?.toDouble() ?? 0.0;
    if (original > 0) {
      return ((original - currentPrice) / original) * 100;
    }
    return null;
  }

  List<String> _extractIncludedAttractions(Map<String, dynamic> item) {
    return item['includedAttractions']?.cast<String>() ?? [];
  }

  List<String> _extractIncludedServices(Map<String, dynamic> item) {
    return item['includedServices']?.cast<String>() ?? [];
  }

  List<String> _extractExcludedServices(Map<String, dynamic> item) {
    return item['excludedServices']?.cast<String>() ?? [];
  }

  List<String> _extractHighlights(Map<String, dynamic> item) {
    return item['highlights']?.cast<String>() ?? [];
  }

  String? _extractTransportation(Map<String, dynamic> item) {
    return item['transportation'];
  }

  String? _extractDifficultyLevel(Map<String, dynamic> item) {
    return item['difficultyLevel'];
  }

  List<String> _extractTourTags(Map<String, dynamic> item) {
    return item['tags']?.cast<String>() ?? [];
  }

  bool _matchesDuration(Map<String, dynamic> item, String duration) {
    final itemDuration = _convertViatorDuration(item['duration']);
    return itemDuration == duration;
  }

  bool _matchesGroupSize(Map<String, dynamic> item, int groupSize) {
    final minSize = item['minGroupSize'] ?? 1;
    final maxSize = item['maxGroupSize'] ?? 20;
    return groupSize >= minSize && groupSize <= maxSize;
  }

  bool _matchesFamilyFriendly(Map<String, dynamic> item, bool familyFriendly) {
    return (item['familyFriendly'] ?? false) == familyFriendly;
  }

  String _convertWindDirection(int? degrees) {
    if (degrees == null) return 'N';
    
    final directions = ['N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE',
                       'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW'];
    final index = ((degrees + 11.25) / 22.5).floor() % 16;
    return directions[index];
  }

  String _determinePrecipitationType(String? weatherMain) {
    switch (weatherMain?.toLowerCase()) {
      case 'rain':
        return 'rain';
      case 'snow':
        return 'snow';
      case 'sleet':
        return 'sleet';
      default:
        return 'none';
    }
  }

  String _formatTime(int? timestamp) {
    if (timestamp == null) return '';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getMoonPhase(double? moonPhase) {
    if (moonPhase == null) return '';
    
    if (moonPhase == 0 || moonPhase == 1) return 'new';
    if (moonPhase < 0.25) return 'waxing_crescent';
    if (moonPhase == 0.25) return 'first_quarter';
    if (moonPhase < 0.5) return 'waxing_gibbous';
    if (moonPhase == 0.5) return 'full';
    if (moonPhase < 0.75) return 'waning_gibbous';
    if (moonPhase == 0.75) return 'last_quarter';
    return 'waning_crescent';
  }

  Map<String, dynamic>? _parseHourlyForecast(List<dynamic>? hourly) {
    if (hourly == null) return null;
    
    final forecast = <String, dynamic>{};
    for (int i = 0; i < hourly.length && i < 24; i++) {
      final hour = hourly[i];
      final time = DateTime.fromMillisecondsSinceEpoch(hour['dt'] * 1000);
      final hourKey = '${time.hour.toString().padLeft(2, '0')}:00';
      
      forecast[hourKey] = {
        'temp': hour['temp'].toDouble(),
        'feels_like': hour['feels_like'].toDouble(),
        'humidity': hour['humidity'],
        'wind_speed': hour['wind_speed'].toDouble(),
        'description': hour['weather'][0]['description'],
        'icon': hour['weather'][0]['icon'],
        'pop': hour['pop']?.toDouble() ?? 0,
      };
    }
    
    return forecast;
  }

  Map<String, dynamic>? _parseDailyForecast(List<dynamic>? daily) {
    if (daily == null) return null;
    
    final forecast = <String, dynamic>{};
    for (int i = 0; i < daily.length && i < 7; i++) {
      final day = daily[i];
      final time = DateTime.fromMillisecondsSinceEpoch(day['dt'] * 1000);
      final dayKey = _getDayName(time.weekday);
      
      forecast[dayKey] = {
        'temp_min': day['temp']['min'].toDouble(),
        'temp_max': day['temp']['max'].toDouble(),
        'humidity': day['humidity'],
        'wind_speed': day['wind_speed'].toDouble(),
        'description': day['weather'][0]['description'],
        'icon': day['weather'][0]['icon'],
        'pop': day['pop']?.toDouble() ?? 0,
        'uvi': day['uvi']?.toDouble() ?? 0,
      };
    }
    
    return forecast;
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Segunda';
      case 2:
        return 'Terça';
      case 3:
        return 'Quarta';
      case 4:
        return 'Quinta';
      case 5:
        return 'Sexta';
      case 6:
        return 'Sábado';
      case 7:
        return 'Domingo';
      default:
        return 'Desconhecido';
    }
  }

  // =====================================================
  // GOOGLE MAPS APIs GRATUITAS (FASE 1)
  // =====================================================

  /// Obtém coordenadas de uma atração usando Geocoding API
  Future<Map<String, dynamic>?> getAttractionCoordinates(String attractionName) async {
    try {
      debugPrint('🌍 Obtendo coordenadas para: $attractionName');
      return await _googleMapsService.getCoordinates(attractionName);
    } catch (e) {
      debugPrint('❌ Erro ao obter coordenadas: $e');
      return null;
    }
  }

  /// Calcula rota entre duas atrações usando Directions API
  Future<Map<String, dynamic>?> getRouteBetweenAttractions({
    required String origin,
    required String destination,
    String? mode = 'driving',
  }) async {
    try {
      debugPrint('🗺️ Calculando rota: $origin → $destination');
      return await _googleMapsService.getDirections(
        origin: origin,
        destination: destination,
        mode: mode,
      );
    } catch (e) {
      debugPrint('❌ Erro ao calcular rota: $e');
      return null;
    }
  }

  /// Calcula distâncias entre múltiplas atrações usando Distance Matrix API
  Future<List<Map<String, dynamic>>?> getDistancesBetweenAttractions({
    required List<String> attractions,
    String? mode = 'driving',
  }) async {
    try {
      debugPrint('📏 Calculando distâncias entre ${attractions.length} atrações');
      return await _googleMapsService.getDistanceMatrix(
        origins: attractions,
        destinations: attractions,
        mode: mode,
      );
    } catch (e) {
      debugPrint('❌ Erro ao calcular distâncias: $e');
      return null;
    }
  }

  /// Otimiza rota turística usando múltiplas APIs
  Future<Map<String, dynamic>?> optimizeTourRoute({
    required List<String> attractions,
    String? startingPoint,
    String? mode = 'driving',
  }) async {
    try {
      debugPrint('🎯 Otimizando rota turística com ${attractions.length} atrações');
      
      // Se não há ponto de partida, usar a primeira atração
      final startPoint = startingPoint ?? attractions.first;
      final remainingAttractions = startingPoint != null 
          ? attractions.where((a) => a != startingPoint).toList()
          : attractions.skip(1).toList();

      final optimizedRoute = <String>[];
      String currentPoint = startPoint;
      optimizedRoute.add(currentPoint);

      // Algoritmo simples: sempre ir para a atração mais próxima
      while (remainingAttractions.isNotEmpty) {
        final distances = await _googleMapsService.getDistanceMatrix(
          origins: [currentPoint],
          destinations: remainingAttractions,
          mode: mode,
        );

        if (distances != null && distances.isNotEmpty) {
          // Encontrar a atração mais próxima
          String? nearestAttraction;
          int? shortestDistance;

          for (final distance in distances) {
            final distMeters = distance['distance_meters'] as int?;
            if (distMeters != null && (shortestDistance == null || distMeters < shortestDistance)) {
              shortestDistance = distMeters;
              nearestAttraction = distance['destination'] as String?;
            }
          }

          if (nearestAttraction != null) {
            optimizedRoute.add(nearestAttraction);
            remainingAttractions.remove(nearestAttraction);
            currentPoint = nearestAttraction;
          } else {
            break;
          }
        } else {
          break;
        }
      }

      // Calcular rota completa
      final fullRoute = <Map<String, dynamic>>[];
      for (int i = 0; i < optimizedRoute.length - 1; i++) {
        final directions = await _googleMapsService.getDirections(
          origin: optimizedRoute[i],
          destination: optimizedRoute[i + 1],
          mode: mode,
        );
        if (directions != null) {
          fullRoute.add({
            'from': optimizedRoute[i],
            'to': optimizedRoute[i + 1],
            'directions': directions,
          });
        }
      }

      final result = {
        'optimized_route': optimizedRoute,
        'route_details': fullRoute,
        'total_attractions': optimizedRoute.length,
        'mode': mode,
      };

      debugPrint('✅ Rota otimizada calculada');
      return result;
    } catch (e) {
      debugPrint('❌ Erro ao otimizar rota: $e');
      return null;
    }
  }

  /// Obtém estatísticas de uso das APIs do Google Maps
  Map<String, dynamic> getGoogleMapsUsageStats() {
    return _googleMapsService.getUsageStats();
  }

  /// Limpa cache das APIs do Google Maps
  void clearGoogleMapsCache() {
    _googleMapsService.clearCache();
  }
} 

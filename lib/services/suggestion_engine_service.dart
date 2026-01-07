import 'package:supabase_flutter/supabase_flutter.dart';

/// Types of suggestions
enum SuggestionType {
  service,
  product,
  bundle,
  upsell,
  crossSell,
}

/// Reason/source for the suggestion
enum SuggestionReason {
  purchaseHistory,    // Based on what customer bought before
  popularInDestination, // Popular in the destination
  hotelRecommendation,  // Based on hotel type
  seasonalOffer,       // Seasonal promotions
  complementaryService, // Services that go well together
  similarCustomers,    // What similar customers bought
  newArrival,         // New services/products
  promotion,          // Current promotions
  weatherBased,       // Based on weather conditions
}

/// A single suggestion item
class Suggestion {
  final int id;
  final SuggestionType type;
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;
  final SuggestionReason reason;
  final String reasonText;
  final double relevanceScore;
  final Map<String, dynamic>? metadata;

  const Suggestion({
    required this.id,
    required this.type,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    required this.reason,
    required this.reasonText,
    this.relevanceScore = 1.0,
    this.metadata,
  });

  factory Suggestion.fromJson(Map<String, dynamic> json) {
    return Suggestion(
      id: json['id'] as int,
      type: _parseType(json['type'] ?? json['kind'] ?? 'service'),
      name: json['name'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      imageUrl: json['image_url'] as String?,
      reason: _parseReason(json['reason_code'] ?? 'popular'),
      reasonText: json['reason'] as String? ?? 'Recomendado para você',
      relevanceScore: (json['relevance_score'] as num?)?.toDouble() ?? 1.0,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  static SuggestionType _parseType(String type) {
    switch (type.toLowerCase()) {
      case 'service':
        return SuggestionType.service;
      case 'product':
        return SuggestionType.product;
      case 'bundle':
        return SuggestionType.bundle;
      case 'upsell':
        return SuggestionType.upsell;
      case 'cross_sell':
      case 'crosssell':
        return SuggestionType.crossSell;
      default:
        return SuggestionType.service;
    }
  }

  static SuggestionReason _parseReason(String reason) {
    switch (reason.toLowerCase()) {
      case 'purchase_history':
      case 'history':
        return SuggestionReason.purchaseHistory;
      case 'destination':
      case 'popular_destination':
        return SuggestionReason.popularInDestination;
      case 'hotel':
      case 'hotel_recommendation':
        return SuggestionReason.hotelRecommendation;
      case 'seasonal':
        return SuggestionReason.seasonalOffer;
      case 'complementary':
        return SuggestionReason.complementaryService;
      case 'similar_customers':
        return SuggestionReason.similarCustomers;
      case 'new':
      case 'new_arrival':
        return SuggestionReason.newArrival;
      case 'promotion':
        return SuggestionReason.promotion;
      case 'weather':
        return SuggestionReason.weatherBased;
      default:
        return SuggestionReason.complementaryService;
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'name': name,
    'description': description,
    'price': price,
    'image_url': imageUrl,
    'reason_code': reason.name,
    'reason': reasonText,
    'relevance_score': relevanceScore,
    'metadata': metadata,
  };
}

/// Collection of suggestions grouped by category
class SuggestionBundle {
  final List<Suggestion> byHistory;
  final List<Suggestion> byDestination;
  final List<Suggestion> byHotel;
  final List<Suggestion> seasonal;
  final List<Suggestion> complementary;
  final List<Suggestion> promotions;

  const SuggestionBundle({
    this.byHistory = const [],
    this.byDestination = const [],
    this.byHotel = const [],
    this.seasonal = const [],
    this.complementary = const [],
    this.promotions = const [],
  });

  /// Get all suggestions combined and sorted by relevance
  List<Suggestion> get all {
    final combined = [
      ...byHistory,
      ...byDestination,
      ...byHotel,
      ...seasonal,
      ...complementary,
      ...promotions,
    ];
    
    // Remove duplicates by ID
    final seen = <int>{};
    final unique = combined.where((s) => seen.add(s.id)).toList();
    
    // Sort by relevance
    unique.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));
    
    return unique;
  }

  /// Get top N suggestions
  List<Suggestion> getTop(int n) => all.take(n).toList();

  bool get isEmpty => all.isEmpty;
  int get totalCount => all.length;
}

/// Customer preference data
class CustomerPreference {
  final int clientId;
  final String preferenceType;
  final String preferenceValue;
  final double score;
  final String source;

  const CustomerPreference({
    required this.clientId,
    required this.preferenceType,
    required this.preferenceValue,
    this.score = 1.0,
    this.source = 'inferred',
  });

  factory CustomerPreference.fromJson(Map<String, dynamic> json) {
    return CustomerPreference(
      clientId: json['client_id'] as int,
      preferenceType: json['preference_type'] as String,
      preferenceValue: json['preference_value'] as String,
      score: (json['preference_score'] as num?)?.toDouble() ?? 1.0,
      source: json['source'] as String? ?? 'inferred',
    );
  }
}

/// Service for generating personalized suggestions
class SuggestionEngineService {
  SupabaseClient get _client => Supabase.instance.client;

  // =====================================================
  // MAIN SUGGESTION METHODS
  // =====================================================

  /// Get comprehensive suggestions for a quotation
  Future<SuggestionBundle> getSuggestionsForQuotation({
    required int quotationId,
    int? clientId,
    String? destination,
    String? hotel,
    List<int>? currentServiceIds,
    int limit = 5,
  }) async {
    try {
      // Fetch quotation data if needed
      Map<String, dynamic>? quotationData;
      if (clientId == null || destination == null) {
        final response = await _client
          .from('quotation')
          .select('client_id, destination, hotel, origin')
          .eq('id', quotationId)
          .maybeSingle();
        
        if (response != null) {
          quotationData = Map<String, dynamic>.from(response);
          clientId ??= quotationData['client_id'] as int?;
          destination ??= quotationData['destination'] as String? ?? quotationData['origin'] as String?;
          hotel ??= quotationData['hotel'] as String?;
        }
      }

      // Gather suggestions from different sources
      final results = await Future.wait([
        clientId != null ? _getSuggestionsByHistory(clientId, limit) : Future.value(<Suggestion>[]),
        destination != null ? _getSuggestionsByDestination(destination, limit) : Future.value(<Suggestion>[]),
        hotel != null ? _getSuggestionsByHotel(hotel, limit) : Future.value(<Suggestion>[]),
        _getSeasonalSuggestions(limit),
        currentServiceIds != null && currentServiceIds.isNotEmpty 
          ? _getComplementarySuggestions(currentServiceIds, limit) 
          : Future.value(<Suggestion>[]),
        _getPromotions(limit),
      ]);

      return SuggestionBundle(
        byHistory: results[0],
        byDestination: results[1],
        byHotel: results[2],
        seasonal: results[3],
        complementary: results[4],
        promotions: results[5],
      );
    } catch (e) {
      print('Erro ao buscar sugestões: $e');
      return const SuggestionBundle();
    }
  }

  /// Get suggestions for a specific customer
  Future<SuggestionBundle> getSuggestionsForCustomer({
    required int clientId,
    String? destination,
    int limit = 5,
  }) async {
    try {
      final results = await Future.wait([
        _getSuggestionsByHistory(clientId, limit),
        destination != null ? _getSuggestionsByDestination(destination, limit) : Future.value(<Suggestion>[]),
        _getPersonalizedSuggestions(clientId, limit),
        _getPromotions(limit),
      ]);

      return SuggestionBundle(
        byHistory: results[0],
        byDestination: results[1],
        complementary: results[2],
        promotions: results[3],
      );
    } catch (e) {
      print('Erro ao buscar sugestões para cliente: $e');
      return const SuggestionBundle();
    }
  }

  // =====================================================
  // SUGGESTION SOURCES
  // =====================================================

  /// Get suggestions based on customer's purchase history
  Future<List<Suggestion>> _getSuggestionsByHistory(int clientId, int limit) async {
    try {
      // Try RPC first
      final rpcResult = await _client.rpc<dynamic>('suggest_services_by_history', params: {
        'p_client_id': clientId,
      });

      if (rpcResult is List && rpcResult.isNotEmpty) {
        return rpcResult.map((e) {
          final data = Map<String, dynamic>.from(e);
          data['reason'] = 'Baseado em suas compras anteriores';
          data['reason_code'] = 'purchase_history';
          data['relevance_score'] = (data['relevance_score'] ?? 1.0) * 1.5; // Boost history-based
          return Suggestion.fromJson(data);
        }).toList();
      }

      // Fallback: direct query
      final response = await _client
        .from('service')
        .select('id, name, description, price')
        .eq('is_active', true)
        .inFilter('id', await _getClientPurchasedServiceIds(clientId))
        .order('id', ascending: false).limit(limit);

      return (response as List).map((e) {
        final data = Map<String, dynamic>.from(e);
        data['reason'] = 'Você comprou este serviço antes';
        data['reason_code'] = 'purchase_history';
        data['relevance_score'] = 1.5;
        return Suggestion.fromJson(data);
      }).toList();
    } catch (e) {
      print('Erro ao buscar sugestões por histórico: $e');
      return [];
    }
  }

  /// Get services the client has purchased before
  Future<List<int>> _getClientPurchasedServiceIds(int clientId) async {
    try {
      final response = await _client
        .from('sale_item')
        .select('service_id, sale!inner(customer_id)')
        .eq('sale.customer_id', clientId)
        .not('service_id', 'is', null);
      
      final ids = (response as List)
        .map((e) => e['service_id'] as int?)
        .whereType<int>()
        .toSet()
        .toList();
      
      return ids;
    } catch (e) {
      return [];
    }
  }

  /// Get suggestions based on destination
  Future<List<Suggestion>> _getSuggestionsByDestination(String destination, int limit) async {
    try {
      // Search services related to destination
      final response = await _client
        .from('service')
        .select('id, name, description, price')
        .eq('is_active', true)
        .or('name.ilike.%$destination%,description.ilike.%$destination%,name.ilike.%tour%,name.ilike.%city%')
        .order('id', ascending: false).limit(limit);

      return (response as List).map((e) {
        final data = Map<String, dynamic>.from(e);
        data['reason'] = 'Popular em $destination';
        data['reason_code'] = 'destination';
        data['relevance_score'] = 1.3;
        return Suggestion.fromJson(data);
      }).toList();
    } catch (e) {
      print('Erro ao buscar sugestões por destino: $e');
      return [];
    }
  }

  /// Get suggestions based on hotel type
  Future<List<Suggestion>> _getSuggestionsByHotel(String hotel, int limit) async {
    try {
      // Hotels typically need transfers and city tours
      final response = await _client
        .from('service')
        .select('id, name, description, price')
        .eq('is_active', true)
        .or('name.ilike.%transfer%,name.ilike.%city%,name.ilike.%tour%,name.ilike.%airport%')
        .order('price', ascending: false)
        .order('id', ascending: false).limit(limit);

      return (response as List).map((e) {
        final data = Map<String, dynamic>.from(e);
        data['reason'] = 'Recomendado para hóspedes';
        data['reason_code'] = 'hotel';
        data['relevance_score'] = 1.2;
        return Suggestion.fromJson(data);
      }).toList();
    } catch (e) {
      print('Erro ao buscar sugestões por hotel: $e');
      return [];
    }
  }

  /// Get seasonal suggestions
  Future<List<Suggestion>> _getSeasonalSuggestions(int limit) async {
    try {
      final now = DateTime.now();
      final month = now.month;
      
      // Determine season-related keywords for filtering
      final seasonKeyword = (month >= 6 && month <= 8) 
        ? 'summer' // Northern hemisphere summer
        : (month >= 12 || month <= 2) 
          ? 'winter' 
          : 'spring';

      // Search for seasonal services
      final response = await _client
        .from('service')
        .select('id, name, description, price')
        .eq('is_active', true)
        .or('name.ilike.%$seasonKeyword%,description.ilike.%seasonal%,description.ilike.%especial%')
        .order('id', ascending: false).limit(limit);

      final services = response as List;
      
      // If no seasonal services found, return popular services
      if (services.isEmpty) {
        final fallback = await _client
          .from('service')
          .select('id, name, description, price')
          .eq('is_active', true)
          .order('id', ascending: false).limit(limit);
        
        return (fallback as List).take(limit).map((e) {
          final data = Map<String, dynamic>.from(e);
          data['reason'] = 'Oferta da temporada';
          data['reason_code'] = 'seasonal';
          data['relevance_score'] = 1.1;
          return Suggestion.fromJson(data);
        }).toList();
      }

      return services.map((e) {
        final data = Map<String, dynamic>.from(e);
        data['reason'] = 'Oferta da temporada';
        data['reason_code'] = 'seasonal';
        data['relevance_score'] = 1.1;
        return Suggestion.fromJson(data);
      }).toList();
    } catch (e) {
      print('Erro ao buscar sugestões sazonais: $e');
      return [];
    }
  }

  /// Get complementary suggestions based on current services
  Future<List<Suggestion>> _getComplementarySuggestions(List<int> currentServiceIds, int limit) async {
    try {
      // Get category of current services
      final currentServices = await _client
        .from('service')
        .select('servicetype_id')
        .inFilter('id', currentServiceIds);
      
      final categoryIds = (currentServices as List)
        .map((e) => e['servicetype_id'] as int?)
        .whereType<int>()
        .toSet()
        .toList();

      if (categoryIds.isEmpty) return [];

      // Get other services from same categories (but not already selected)
      final response = await _client
        .from('service')
        .select('id, name, description, price')
        .eq('is_active', true)
        .inFilter('servicetype_id', categoryIds)
        .not('id', 'in', '(${currentServiceIds.join(',')})')
        .order('id', ascending: false).limit(limit);

      return (response as List).map((e) {
        final data = Map<String, dynamic>.from(e);
        data['reason'] = 'Combina com seus serviços selecionados';
        data['reason_code'] = 'complementary';
        data['relevance_score'] = 1.4;
        return Suggestion.fromJson(data);
      }).toList();
    } catch (e) {
      print('Erro ao buscar sugestões complementares: $e');
      return [];
    }
  }

  /// Get personalized suggestions based on customer preferences
  Future<List<Suggestion>> _getPersonalizedSuggestions(int clientId, int limit) async {
    try {
      // Get customer preferences
      final preferences = await getCustomerPreferences(clientId);
      
      if (preferences.isEmpty) {
        // Fallback to popular services
        return _getPopularServices(limit);
      }

      // Build filters based on preferences
      final categoryPrefs = preferences
        .where((p) => p.preferenceType == 'service_category')
        .map((p) => p.preferenceValue)
        .toList();

      if (categoryPrefs.isEmpty) {
        return _getPopularServices(limit);
      }

      final response = await _client
        .from('service')
        .select('id, name, description, price, service_category!inner(name)')
        .eq('is_active', true)
        .inFilter('service_category.name', categoryPrefs)
        .order('id', ascending: false).limit(limit);

      return (response as List).map((e) {
        final data = Map<String, dynamic>.from(e);
        data['reason'] = 'Baseado em suas preferências';
        data['reason_code'] = 'similar_customers';
        data['relevance_score'] = 1.3;
        return Suggestion.fromJson(data);
      }).toList();
    } catch (e) {
      print('Erro ao buscar sugestões personalizadas: $e');
      return [];
    }
  }

  /// Get current promotions
  Future<List<Suggestion>> _getPromotions(int limit) async {
    try {
      // Services with good prices (simulated promotions)
      final response = await _client
        .from('service')
        .select('id, name, description, price')
        .eq('is_active', true)
        .order('price', ascending: true)
        .order('id', ascending: false).limit(limit);

      return (response as List).map((e) {
        final data = Map<String, dynamic>.from(e);
        data['reason'] = 'Promoção especial';
        data['reason_code'] = 'promotion';
        data['relevance_score'] = 1.0;
        return Suggestion.fromJson(data);
      }).toList();
    } catch (e) {
      print('Erro ao buscar promoções: $e');
      return [];
    }
  }

  /// Get popular services
  Future<List<Suggestion>> _getPopularServices(int limit) async {
    try {
      // Get most sold services
      final response = await _client
        .from('service')
        .select('id, name, description, price')
        .eq('is_active', true)
        .order('price', ascending: false) // Higher price = more popular (simplified)
        .order('id', ascending: false).limit(limit);

      return (response as List).map((e) {
        final data = Map<String, dynamic>.from(e);
        data['reason'] = 'Popular entre nossos clientes';
        data['reason_code'] = 'popular';
        data['relevance_score'] = 1.0;
        return Suggestion.fromJson(data);
      }).toList();
    } catch (e) {
      print('Erro ao buscar serviços populares: $e');
      return [];
    }
  }

  // =====================================================
  // CUSTOMER PREFERENCES
  // =====================================================

  /// Get customer preferences
  Future<List<CustomerPreference>> getCustomerPreferences(int clientId) async {
    try {
      final response = await _client
        .from('customer_preference')
        .select('*')
        .eq('client_id', clientId)
        .order('preference_score', ascending: false);

      return (response as List)
        .map((e) => CustomerPreference.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    } catch (e) {
      print('Erro ao buscar preferências: $e');
      return [];
    }
  }

  /// Save customer preference
  Future<bool> saveCustomerPreference({
    required int clientId,
    required String preferenceType,
    required String preferenceValue,
    double score = 1.0,
    String source = 'explicit',
  }) async {
    try {
      await _client.from('customer_preference').upsert({
        'client_id': clientId,
        'preference_type': preferenceType,
        'preference_value': preferenceValue,
        'preference_score': score,
        'source': source,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'client_id,preference_type,preference_value');
      
      return true;
    } catch (e) {
      print('Erro ao salvar preferência: $e');
      return false;
    }
  }

  /// Infer preferences from purchase history
  Future<void> inferPreferencesFromHistory(int clientId) async {
    try {
      // Get purchased service categories
      final purchases = await _client
        .from('sale_item')
        .select('service:service_id(servicetype_id, service_category:servicetype_id(name)), sale!inner(customer_id)')
        .eq('sale.customer_id', clientId);

      final categoryCount = <String, int>{};
      for (final purchase in purchases as List) {
        final service = purchase['service'] as Map<String, dynamic>?;
        final category = service?['service_category'] as Map<String, dynamic>?;
        final categoryName = category?['name'] as String?;
        
        if (categoryName != null) {
          categoryCount[categoryName] = (categoryCount[categoryName] ?? 0) + 1;
        }
      }

      // Save preferences for frequently purchased categories
      for (final entry in categoryCount.entries) {
        if (entry.value >= 2) { // At least 2 purchases
          await saveCustomerPreference(
            clientId: clientId,
            preferenceType: 'service_category',
            preferenceValue: entry.key,
            score: entry.value.toDouble(),
            source: 'inferred',
          );
        }
      }
    } catch (e) {
      print('Erro ao inferir preferências: $e');
    }
  }

  // =====================================================
  // PRODUCT SUGGESTIONS
  // =====================================================

  /// Get product suggestions (tickets, etc.)
  Future<List<Suggestion>> getProductSuggestions({
    String? destination,
    String? category,
    int limit = 5,
  }) async {
    try {
      var query = _client
        .from('product')
        .select('product_id, name, price_per_unit, product_category:category_id(name)')
        .eq('active_for_sale', true);

      if (category != null) {
        query = query.eq('product_category.name', category);
      }

      final response = await query.order('id', ascending: false).limit(limit);

      return (response as List).map((e) {
        final data = Map<String, dynamic>.from(e);
        return Suggestion(
          id: data['product_id'] as int,
          type: SuggestionType.product,
          name: data['name'] as String,
          description: null,
          price: (data['price_per_unit'] as num?)?.toDouble() ?? 0,
          reason: SuggestionReason.complementaryService,
          reasonText: destination != null 
            ? 'Ingressos populares em $destination' 
            : 'Adicione à sua experiência',
          relevanceScore: 1.0,
        );
      }).toList();
    } catch (e) {
      print('Erro ao buscar produtos: $e');
      return [];
    }
  }

  // =====================================================
  // BUNDLE SUGGESTIONS
  // =====================================================

  /// Get bundle suggestions (combinations of services)
  Future<List<Suggestion>> getBundleSuggestions({
    required List<int> currentServiceIds,
    int limit = 3,
  }) async {
    try {
      if (currentServiceIds.isEmpty) return [];

      // Get complementary services that would make a good bundle
      final complementary = await _getComplementarySuggestions(currentServiceIds, limit);
      
      return complementary.map((s) => Suggestion(
        id: s.id,
        type: SuggestionType.bundle,
        name: 'Pacote: ${s.name}',
        description: s.description,
        price: s.price * 0.9, // 10% bundle discount
        reason: SuggestionReason.complementaryService,
        reasonText: 'Economize 10% adicionando ao pacote',
        relevanceScore: 1.5,
        metadata: {'original_price': s.price, 'discount_percent': 10},
      )).toList();
    } catch (e) {
      print('Erro ao buscar bundles: $e');
      return [];
    }
  }
}


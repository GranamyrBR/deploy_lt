import 'package:flutter/foundation.dart';
import '../services/google_maps_service.dart';

/// Provider para gerenciar as APIs gratuitas do Google Maps (Fase 1)
class GoogleMapsProvider extends ChangeNotifier {
  final GoogleMapsService _googleMapsService = GoogleMapsService();
  
  // Estados
  Map<String, dynamic>? _coordinates;
  Map<String, dynamic>? _directions;
  List<Map<String, dynamic>>? _distanceMatrix;
  Map<String, dynamic>? _optimizedRoute;
  
  // Estados de loading
  bool _isLoadingCoordinates = false;
  bool _isLoadingDirections = false;
  bool _isLoadingDistanceMatrix = false;
  bool _isLoadingOptimizedRoute = false;
  
  // Estados de erro
  String? _coordinatesError;
  String? _directionsError;
  String? _distanceMatrixError;
  String? _optimizedRouteError;

  // =====================================================
  // GETTERS
  // =====================================================

  Map<String, dynamic>? get coordinates => _coordinates;
  Map<String, dynamic>? get directions => _directions;
  List<Map<String, dynamic>>? get distanceMatrix => _distanceMatrix;
  Map<String, dynamic>? get optimizedRoute => _optimizedRoute;
  
  bool get isLoadingCoordinates => _isLoadingCoordinates;
  bool get isLoadingDirections => _isLoadingDirections;
  bool get isLoadingDistanceMatrix => _isLoadingDistanceMatrix;
  bool get isLoadingOptimizedRoute => _isLoadingOptimizedRoute;
  
  String? get coordinatesError => _coordinatesError;
  String? get directionsError => _directionsError;
  String? get distanceMatrixError => _distanceMatrixError;
  String? get optimizedRouteError => _optimizedRouteError;

  // =====================================================
  // GEOCODING API
  // =====================================================

  /// Obtém coordenadas de um endereço
  Future<void> getCoordinates(String address) async {
    if (address.isEmpty) return;
    
    _isLoadingCoordinates = true;
    _coordinatesError = null;
    notifyListeners();
    
    try {
      debugPrint('🌍 GoogleMapsProvider: Obtendo coordenadas para $address');
      _coordinates = await _googleMapsService.getCoordinates(address);
      
      if (_coordinates == null) {
        _coordinatesError = 'Não foi possível obter coordenadas para: $address';
      }
    } catch (e) {
      _coordinatesError = 'Erro ao obter coordenadas: $e';
      debugPrint('❌ GoogleMapsProvider: $e');
    } finally {
      _isLoadingCoordinates = false;
      notifyListeners();
    }
  }

  // =====================================================
  // DIRECTIONS API
  // =====================================================

  /// Calcula rota entre dois pontos
  Future<void> getDirections({
    required String origin,
    required String destination,
    String? mode = 'driving',
  }) async {
    if (origin.isEmpty || destination.isEmpty) return;
    
    _isLoadingDirections = true;
    _directionsError = null;
    notifyListeners();
    
    try {
      debugPrint('🗺️ GoogleMapsProvider: Calculando rota $origin → $destination');
      _directions = await _googleMapsService.getDirections(
        origin: origin,
        destination: destination,
        mode: mode,
      );
      
      if (_directions == null) {
        _directionsError = 'Não foi possível calcular rota entre $origin e $destination';
      }
    } catch (e) {
      _directionsError = 'Erro ao calcular rota: $e';
      debugPrint('❌ GoogleMapsProvider: $e');
    } finally {
      _isLoadingDirections = false;
      notifyListeners();
    }
  }

  // =====================================================
  // DISTANCE MATRIX API
  // =====================================================

  /// Calcula distâncias entre múltiplos pontos
  Future<void> getDistanceMatrix({
    required List<String> origins,
    required List<String> destinations,
    String? mode = 'driving',
  }) async {
    if (origins.isEmpty || destinations.isEmpty) return;
    
    _isLoadingDistanceMatrix = true;
    _distanceMatrixError = null;
    notifyListeners();
    
    try {
      debugPrint('📏 GoogleMapsProvider: Calculando distâncias ${origins.length} → ${destinations.length}');
      _distanceMatrix = await _googleMapsService.getDistanceMatrix(
        origins: origins,
        destinations: destinations,
        mode: mode,
      );
      
      if (_distanceMatrix == null) {
        _distanceMatrixError = 'Não foi possível calcular distâncias';
      }
    } catch (e) {
      _distanceMatrixError = 'Erro ao calcular distâncias: $e';
      debugPrint('❌ GoogleMapsProvider: $e');
    } finally {
      _isLoadingDistanceMatrix = false;
      notifyListeners();
    }
  }

  // =====================================================
  // ROTA OTIMIZADA (COMBINA MÚLTIPLAS APIs)
  // =====================================================

  /// Otimiza rota turística
  Future<void> optimizeTourRoute({
    required List<String> attractions,
    String? startingPoint,
    String? mode = 'driving',
  }) async {
    if (attractions.isEmpty) return;
    
    _isLoadingOptimizedRoute = true;
    _optimizedRouteError = null;
    notifyListeners();
    
    try {
      debugPrint('🎯 GoogleMapsProvider: Otimizando rota com ${attractions.length} atrações');
      
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

      _optimizedRoute = {
        'optimized_route': optimizedRoute,
        'route_details': fullRoute,
        'total_attractions': optimizedRoute.length,
        'mode': mode,
      };
      
      debugPrint('✅ GoogleMapsProvider: Rota otimizada calculada');
    } catch (e) {
      _optimizedRouteError = 'Erro ao otimizar rota: $e';
      debugPrint('❌ GoogleMapsProvider: $e');
    } finally {
      _isLoadingOptimizedRoute = false;
      notifyListeners();
    }
  }

  // =====================================================
  // MÉTODOS AUXILIARES
  // =====================================================

  /// Limpa todos os dados
  void clearAll() {
    _coordinates = null;
    _directions = null;
    _distanceMatrix = null;
    _optimizedRoute = null;
    
    _coordinatesError = null;
    _directionsError = null;
    _distanceMatrixError = null;
    _optimizedRouteError = null;
    
    notifyListeners();
  }

  /// Limpa dados específicos
  void clearCoordinates() {
    _coordinates = null;
    _coordinatesError = null;
    notifyListeners();
  }

  void clearDirections() {
    _directions = null;
    _directionsError = null;
    notifyListeners();
  }

  void clearDistanceMatrix() {
    _distanceMatrix = null;
    _distanceMatrixError = null;
    notifyListeners();
  }

  void clearOptimizedRoute() {
    _optimizedRoute = null;
    _optimizedRouteError = null;
    notifyListeners();
  }

  /// Obtém estatísticas de uso
  Map<String, dynamic> getUsageStats() {
    return _googleMapsService.getUsageStats();
  }

  /// Limpa cache
  void clearCache() {
    _googleMapsService.clearCache();
    debugPrint('🗑️ GoogleMapsProvider: Cache limpo');
  }
} 

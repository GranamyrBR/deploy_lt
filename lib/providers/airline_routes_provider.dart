import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:state_notifier/state_notifier.dart';

import '../models/airline_route.dart';
import '../services/airline_routes_service.dart';

// Service provider
final airlineRoutesServiceProvider = Provider<AirlineRoutesService>((ref) {
  return AirlineRoutesService();
});

// Main routes provider
final brazilUsaRoutesProvider = FutureProvider<List<AirlineRoute>>((ref) async {
  final service = ref.read(airlineRoutesServiceProvider);
  return await service.getBrazilUsaRoutes();
});

// Routes by direction
final routesByDirectionProvider = FutureProvider.family<List<AirlineRoute>, String>((ref, direction) async {
  final service = ref.read(airlineRoutesServiceProvider);
  return await service.getRoutesByDirection(direction);
});

// Routes by airline
final routesByAirlineProvider = FutureProvider.family<List<AirlineRoute>, String>((ref, airlineIata) async {
  final service = ref.read(airlineRoutesServiceProvider);
  return await service.getRoutesByAirline(airlineIata);
});

// Routes by origin airport
final routesByOriginProvider = FutureProvider.family<List<AirlineRoute>, String>((ref, airportIata) async {
  final service = ref.read(airlineRoutesServiceProvider);
  return await service.getRoutesByOrigin(airportIata);
});

// Routes by destination airport
final routesByDestinationProvider = FutureProvider.family<List<AirlineRoute>, String>((ref, airportIata) async {
  final service = ref.read(airlineRoutesServiceProvider);
  return await service.getRoutesByDestination(airportIata);
});

// Direct routes only
final directRoutesProvider = FutureProvider<List<AirlineRoute>>((ref) async {
  final service = ref.read(airlineRoutesServiceProvider);
  return await service.getDirectRoutes();
});

// Daily routes only
final dailyRoutesProvider = FutureProvider<List<AirlineRoute>>((ref) async {
  final service = ref.read(airlineRoutesServiceProvider);
  return await service.getDailyRoutes();
});

// Routes statistics
final routesStatisticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.read(airlineRoutesServiceProvider);
  return await service.getRoutesStatistics();
});

// Unique airports
final uniqueAirportsProvider = FutureProvider<Map<String, List<Map<String, String>>>>((ref) async {
  final service = ref.read(airlineRoutesServiceProvider);
  return await service.getUniqueAirports();
});

// Unique airlines
final uniqueAirlinesProvider = FutureProvider<List<Map<String, String>>>((ref) async {
  final service = ref.read(airlineRoutesServiceProvider);
  return await service.getUniqueAirlines();
});

// Filter state provider
class RouteFilters {
  final String? selectedAirline;
  final String? selectedOrigin;
  final String? selectedDestination;
  final String? selectedDirection;
  final bool onlyDirect;
  final bool onlyDaily;

  const RouteFilters({
    this.selectedAirline,
    this.selectedOrigin,
    this.selectedDestination,
    this.selectedDirection,
    this.onlyDirect = false,
    this.onlyDaily = false,
  });

  RouteFilters copyWith({
    String? selectedAirline,
    String? selectedOrigin,
    String? selectedDestination,
    String? selectedDirection,
    bool? onlyDirect,
    bool? onlyDaily,
  }) {
    return RouteFilters(
      selectedAirline: selectedAirline ?? this.selectedAirline,
      selectedOrigin: selectedOrigin ?? this.selectedOrigin,
      selectedDestination: selectedDestination ?? this.selectedDestination,
      selectedDirection: selectedDirection ?? this.selectedDirection,
      onlyDirect: onlyDirect ?? this.onlyDirect,
      onlyDaily: onlyDaily ?? this.onlyDaily,
    );
  }

  bool get hasActiveFilters {
    return selectedAirline != null ||
           selectedOrigin != null ||
           selectedDestination != null ||
           selectedDirection != null ||
           onlyDirect ||
           onlyDaily;
  }
}

class RouteFiltersNotifier extends StateNotifier<RouteFilters> {
  RouteFiltersNotifier() : super(const RouteFilters());

  void updateAirline(String? airline) {
    state = state.copyWith(selectedAirline: airline);
  }

  void updateOrigin(String? origin) {
    state = state.copyWith(selectedOrigin: origin);
  }

  void updateDestination(String? destination) {
    state = state.copyWith(selectedDestination: destination);
  }

  void updateDirection(String? direction) {
    state = state.copyWith(selectedDirection: direction);
  }

  void updateOnlyDirect(bool onlyDirect) {
    state = state.copyWith(onlyDirect: onlyDirect);
  }

  void updateOnlyDaily(bool onlyDaily) {
    state = state.copyWith(onlyDaily: onlyDaily);
  }

  void clearAllFilters() {
    state = const RouteFilters();
  }
}

final routeFiltersProvider = StateNotifierProvider<RouteFiltersNotifier, RouteFilters>((ref) {
  return RouteFiltersNotifier();
});

// Filtered routes provider
final filteredRoutesProvider = FutureProvider<List<AirlineRoute>>((ref) async {
  final filters = ref.watch(routeFiltersProvider);
  final service = ref.read(airlineRoutesServiceProvider);
  
  List<AirlineRoute> routes;
  
  // Start with all routes or apply primary filter
  if (filters.selectedAirline != null) {
    routes = await service.getRoutesByAirline(filters.selectedAirline!);
  } else if (filters.selectedOrigin != null) {
    routes = await service.getRoutesByOrigin(filters.selectedOrigin!);
  } else if (filters.selectedDestination != null) {
    routes = await service.getRoutesByDestination(filters.selectedDestination!);
  } else if (filters.selectedDirection != null) {
    routes = await service.getRoutesByDirection(filters.selectedDirection!);
  } else {
    routes = await service.getBrazilUsaRoutes();
  }
  
  // Apply additional filters
  if (filters.onlyDirect) {
    routes = routes.where((route) => route.isDirect).toList();
  }
  
  if (filters.onlyDaily) {
    routes = routes.where((route) => route.frequencyPerWeek == 7).toList();
  }
  
  // Apply remaining filters
  if (filters.selectedAirline != null && filters.selectedOrigin != null) {
    routes = routes.where((route) => route.originAirportIata == filters.selectedOrigin).toList();
  }
  
  if (filters.selectedAirline != null && filters.selectedDestination != null) {
    routes = routes.where((route) => route.destinationAirportIata == filters.selectedDestination).toList();
  }
  
  if (filters.selectedDirection != null && filters.selectedAirline != null) {
    routes = routes.where((route) => route.direction == filters.selectedDirection).toList();
  }
  
  return routes;
}); 

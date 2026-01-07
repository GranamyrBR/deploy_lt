import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/service.dart';
import '../services/services_service.dart';

// =====================================================
// SERVICES SERVICE PROVIDER
// =====================================================

final servicesServiceProvider = Provider<ServicesService>((ref) {
  return ServicesService();
});

// =====================================================
// SERVICES STATE MANAGEMENT
// =====================================================

class ServicesState {
  final List<Service> services;
  final bool isLoading;
  final String? error;
  final Service? selectedService;

  ServicesState({
    this.services = const [],
    this.isLoading = false,
    this.error,
    this.selectedService,
  });

  ServicesState copyWith({
    List<Service>? services,
    bool? isLoading,
    String? error,
    Service? selectedService,
  }) {
    return ServicesState(
      services: services ?? this.services,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      selectedService: selectedService ?? this.selectedService,
    );
  }
}

class ServicesNotifier extends StateNotifier<ServicesState> {
  final ServicesService _service;

  ServicesNotifier(this._service) : super(ServicesState()) {
    loadServices();
  }

  // Carregar todos os serviços
  Future<void> loadServices() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final services = await _service.getServices();
      // Ordenar serviços em ordem ascendente por nome
      services.sort((a, b) => (a.name ?? '').toLowerCase().compareTo((b.name ?? '').toLowerCase()));
      state = state.copyWith(
        services: services,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao carregar serviços: $e',
      );
    }
  }

  // Criar novo serviço
  Future<bool> createService({
    required String name,
    required String description,
    required double price,
    int? servicetypeId,
    bool isActive = true,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = {
        'name': name,
        'description': description,
        'price': price,
        'servicetype_id': servicetypeId,
        'is_active': isActive,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };
      
      final newService = await _service.createService(data);
      
      // Adicionar o novo serviço à lista
      final updatedServices = [...state.services, newService];
      state = state.copyWith(
        services: updatedServices,
        isLoading: false,
      );
      
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao criar serviço: $e',
      );
      return false;
    }
  }

  // Atualizar serviço existente
  Future<bool> updateService({
    required int id,
    String? name,
    String? description,
    double? price,
    int? servicetypeId,
    bool? isActive,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = <String, dynamic>{
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };
      
      if (name != null) data['name'] = name;
      if (description != null) data['description'] = description;
      if (price != null) data['price'] = price;
      
      // Atualizar o servicetypeId se fornecido
      if (servicetypeId != null) {
        data['servicetype_id'] = servicetypeId;
      }
      
      if (isActive != null) data['is_active'] = isActive;
      
      final updatedService = await _service.updateService(id, data);
      
      // Atualizar o serviço na lista
      final updatedServices = state.services.map((service) {
        return service.id == id ? updatedService : service;
      }).toList();
      
      state = state.copyWith(
        services: updatedServices,
        isLoading: false,
      );
      
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao atualizar serviço: $e',
      );
      return false;
    }
  }

  // Deletar serviço
  Future<bool> deleteService(int id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.deleteService(id);
      
      // Remover o serviço da lista
      final updatedServices = state.services.where((service) => service.id != id).toList();
      state = state.copyWith(
        services: updatedServices,
        isLoading: false,
      );
      
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao deletar serviço: $e',
      );
      return false;
    }
  }

  // Buscar serviços por nome
  Future<void> searchServices(String searchTerm) async {
    if (searchTerm.isEmpty) {
      await loadServices();
      return;
    }
    
    state = state.copyWith(isLoading: true, error: null);
    try {
      final services = await _service.searchServicesByName(searchTerm);
      state = state.copyWith(
        services: services,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao buscar serviços: $e',
      );
    }
  }

  // Filtrar serviços por categoria
  Future<void> filterByCategory(String category) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final services = await _service.getServicesByCategory(category);
      state = state.copyWith(
        services: services,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao filtrar serviços por categoria: $e',
      );
    }
  }

  // Selecionar um serviço
  void selectService(Service? service) {
    state = state.copyWith(selectedService: service);
  }

  // Limpar erro
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Refresh
  Future<void> refresh() async {
    await loadServices();
  }

  // Refresh com recarregamento de dados
  Future<void> refreshWithReload() async {
    await loadServices();
  }
}

// =====================================================
// PROVIDERS
// =====================================================

// Provider principal para gerenciar o estado dos serviços
final servicesProvider = StateNotifierProvider<ServicesNotifier, ServicesState>((ref) {
  final service = ref.watch(servicesServiceProvider);
  return ServicesNotifier(service);
});

// Provider para buscar um serviço específico por ID
final serviceByIdProvider = FutureProvider.family<Service?, int>((ref, id) async {
  final service = ref.watch(servicesServiceProvider);
  return await service.getServiceById(id);
});

// Provider para estatísticas de serviços
final serviceStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.watch(servicesServiceProvider);
  return await service.getServiceStats();
});

// Provider para serviços ativos apenas
final activeServicesProvider = Provider<List<Service>>((ref) {
  final servicesState = ref.watch(servicesProvider);
  return servicesState.services.where((service) => service.isActive == true).toList();
});

// Provider para serviços por categoria
final servicesByCategoryProvider = FutureProvider.family<List<Service>, String>((ref, category) async {
  final service = ref.watch(servicesServiceProvider);
  return await service.getServicesByCategory(category);
});

// Provider para busca de serviços
final searchServicesProvider = FutureProvider.family<List<Service>, String>((ref, searchTerm) async {
  final service = ref.watch(servicesServiceProvider);
  if (searchTerm.isEmpty) {
    return await service.getServices();
  }
  return await service.searchServicesByName(searchTerm);
});

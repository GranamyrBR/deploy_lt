import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:state_notifier/state_notifier.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/service_type.dart';

class ServiceTypesNotifier extends StateNotifier<AsyncValue<List<ServiceType>>> {
  ServiceTypesNotifier() : super(const AsyncValue.loading()) {
    fetchServiceTypes();
  }

  Future<void> fetchServiceTypes() async {
    try {
      state = const AsyncValue.loading();
      
      final supabase = Supabase.instance.client;
      
      // Buscar service_types da tabela correta com campos específicos e ordenação
      final response = await supabase
          .from('service_category')
          .select('id, name')
          .order('name');

      // Converter para ServiceType
      final serviceTypes = (response as List)
          .map((json) => ServiceType.fromJson(json))
          .toList();

      state = AsyncValue.data(serviceTypes);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    await fetchServiceTypes();
  }
}

// Usando um cache para evitar múltiplas requisições
final serviceTypesProvider = StateNotifierProvider<ServiceTypesNotifier, AsyncValue<List<ServiceType>>>(
  (ref) => ServiceTypesNotifier(),
);

// Provider alternativo que carrega apenas os dados essenciais para dropdown
final serviceTypeDropdownProvider = FutureProvider<List<ServiceType>>((ref) async {
  final supabase = Supabase.instance.client;
  
  // Buscar apenas id e name, ordenados por nome
  final response = await supabase
      .from('service_category')
      .select('id, name')
      .order('name');
  
  return (response as List)
      .map((json) => ServiceType.fromJson(json))
      .toList();
});

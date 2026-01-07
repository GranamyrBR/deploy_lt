import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:state_notifier/state_notifier.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/car.dart';

final carProviderRestoredDb = StateNotifierProvider<CarNotifierRestoredDb, AsyncValue<List<Car>>>((ref) {
  return CarNotifierRestoredDb();
});

class CarNotifierRestoredDb extends StateNotifier<AsyncValue<List<Car>>> {
  CarNotifierRestoredDb() : super(const AsyncValue.loading()) {
    loadCars();
  }

  SupabaseClient get _supabase => Supabase.instance.client;

  Future<void> loadCars() async {
    try {
      state = const AsyncValue.loading();
      
      final response = await _supabase
          .from('car')
          .select('*')
          .order('make')
          .order('model');

      if (response != null) {
        final cars = (response as List)
            .map((data) => Car.fromJson(data))
            .toList();
        state = AsyncValue.data(cars);
      } else {
        state = const AsyncValue.data([]);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> addCar(Car car) async {
    try {
      final response = await _supabase
          .from('car')
          .insert(car.toJson())
          .select()
          .single();

      final newCar = Car.fromJson(response);
      state.whenData((cars) {
        state = AsyncValue.data([...cars, newCar]);
      });
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateCar(Car car) async {
    try {
      await _supabase
          .from('car')
          .update(car.toJson())
          .eq('id', car.id);

      state.whenData((cars) {
        final updatedCars = cars.map((c) {
          return c.id == car.id ? car : c;
        }).toList();
        state = AsyncValue.data(updatedCars);
      });
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteCar(int id) async {
    try {
      await _supabase
          .from('car')
          .delete()
          .eq('id', id);

      state.whenData((cars) {
        final filteredCars = cars.where((c) => c.id != id).toList();
        state = AsyncValue.data(filteredCars);
      });
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  List<Car> get availableCars => 
      state.value?.where((car) => true).toList() ?? []; // Todos os carros estão disponíveis no banco restaurado

  List<Car> get carsInUse => 
      state.value?.where((car) => false).toList() ?? []; // Não há status de uso no banco restaurado

  List<Car> get carsInMaintenance => 
      state.value?.where((car) => false).toList() ?? []; // Não há status de manutenção no banco restaurado
}

// Provider para um carro específico
final carByIdProviderRestoredDb = FutureProvider.family<Car?, int>((ref, id) async {
  final carsAsync = ref.watch(carProviderRestoredDb);
  return carsAsync.when(
    data: (cars) {
      try {
        return cars.firstWhere((car) => car.id == id);
      } catch (e) {
        return null;
      }
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

// Provider para carros disponíveis
final availableCarsProviderRestoredDb = Provider<AsyncValue<List<Car>>>((ref) {
  final carsAsync = ref.watch(carProviderRestoredDb);
  
  return carsAsync.when(
    data: (cars) => AsyncValue.data(cars), // Todos os carros estão disponíveis
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
}); 

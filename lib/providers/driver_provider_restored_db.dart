import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/driver.dart';
import '../models/car.dart';

final driverProviderRestoredDb = StateNotifierProvider<DriverNotifierRestoredDb, AsyncValue<List<Driver>>>((ref) {
  return DriverNotifierRestoredDb();
});

class DriverNotifierRestoredDb extends StateNotifier<AsyncValue<List<Driver>>> {
  DriverNotifierRestoredDb() : super(const AsyncValue.loading()) {
    loadDrivers();
  }

  SupabaseClient get _supabase => Supabase.instance.client;

  Future<void> loadDrivers() async {
    try {
      state = const AsyncValue.loading();
      
      final response = await _supabase
          .from('driver')
          .select('''
            *,
            car:car_id(*)
          ''')
          .order('name');

      final drivers = (response as List)
          .map((data) => Driver.fromJson(data))
          .toList();
      state = AsyncValue.data(drivers);
        } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> addDriver(Driver driver) async {
    try {
      final response = await _supabase
          .from('driver')
          .insert(driver.toJson())
          .select()
          .single();

      final newDriver = Driver.fromJson(response);
      state.whenData((drivers) {
        state = AsyncValue.data([...drivers, newDriver]);
      });
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateDriver(Driver driver) async {
    try {
      await _supabase
          .from('driver')
          .update(driver.toJson())
          .eq('id', driver.id);

      state.whenData((drivers) {
        final updatedDrivers = drivers.map((d) {
          return d.id == driver.id ? driver : d;
        }).toList();
        state = AsyncValue.data(updatedDrivers);
      });
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteDriver(int id) async {
    try {
      await _supabase
          .from('driver')
          .delete()
          .eq('id', id);

      state.whenData((drivers) {
        final filteredDrivers = drivers.where((d) => d.id != id).toList();
        state = AsyncValue.data(filteredDrivers);
      });
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> assignCarToDriver(int driverId, int carId) async {
    try {
      // Update the driver's car_id
      await _supabase
          .from('driver')
          .update({'car_id': carId})
          .eq('id', driverId);

      // Also add to driver_car table for many-to-many relationship
      await _supabase
          .from('driver_car')
          .upsert({
            'driver_id': driverId,
            'car_id': carId,
            'is_active': true,
          });

      // Reload drivers to get updated data
      await loadDrivers();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> unassignCarFromDriver(int driverId) async {
    try {
      // Remove car_id from driver
      await _supabase
          .from('driver')
          .update({'car_id': null})
          .eq('id', driverId);

      // Deactivate in driver_car table
      await _supabase
          .from('driver_car')
          .update({'is_active': false})
          .eq('driver_id', driverId);

      // Reload drivers to get updated data
      await loadDrivers();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<List<Car>> getDriverCars(int driverId) async {
    try {
      final response = await _supabase
          .from('driver_car')
          .select('''
            car:car_id(*)
          ''')
          .eq('driver_id', driverId)
          .eq('is_active', true);

      return (response as List)
          .map((data) => Car.fromJson(data['car']))
          .toList();
    } catch (error) {
      print('Error getting driver cars: $error');
      return [];
    }
  }

  Future<Car?> getDriverAssignedCar(int driverId) async {
    try {
      final response = await _supabase
          .from('driver')
          .select('car:car_id(*)')
          .eq('id', driverId)
          .single();

      if (response['car'] != null) {
        return Car.fromJson(response['car']);
      }
      return null;
    } catch (error) {
      print('Error getting driver assigned car: $error');
      return null;
    }
  }
}

// Provider for a single driver
final driverByIdProviderRestoredDb = FutureProvider.family<Driver?, int>((ref, id) async {
  final driversAsync = ref.watch(driverProviderRestoredDb);
  return driversAsync.when(
    data: (drivers) {
      try {
        return drivers.firstWhere((driver) => driver.id == id);
      } catch (e) {
        return null;
      }
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

// Comentado temporariamente - Driver.carId não existe no modelo
// // Provider for drivers without cars
// final driversWithoutCarProviderRestoredDb = Provider<AsyncValue<List<Driver>>>((ref) {
//   final driversAsync = ref.watch(driverProviderRestoredDb);
//   
//   return driversAsync.when(
//     data: (drivers) => AsyncValue.data(drivers.where((d) => d.carId == null).toList()),
//     loading: () => const AsyncValue.loading(),
//     error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
//   );
// });

// // Provider for drivers with cars
// final driversWithCarProviderRestoredDb = Provider<AsyncValue<List<Driver>>>((ref) {
//   final driversAsync = ref.watch(driverProviderRestoredDb);
//   
//   return driversAsync.when(
//     data: (drivers) => AsyncValue.data(drivers.where((d) => d.carId != null).toList()),
//     loading: () => const AsyncValue.loading(),
//     error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
//   );
// }); 

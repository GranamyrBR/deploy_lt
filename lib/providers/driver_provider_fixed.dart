import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/driver.dart';
import '../models/car.dart';
import '../models/driver_car.dart';

class DriverProviderState {
  final List<Driver> drivers;
  final List<Car> cars;
  final List<DriverCar> driverCars;
  final bool isLoading;
  final String? errorMessage;
  final int? selectedDriverId;
  final int? selectedCarId;

  DriverProviderState({
    this.drivers = const [],
    this.cars = const [],
    this.driverCars = const [],
    this.isLoading = false,
    this.errorMessage,
    this.selectedDriverId,
    this.selectedCarId,
  });

  DriverProviderState copyWith({
    List<Driver>? drivers,
    List<Car>? cars,
    List<DriverCar>? driverCars,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    int? selectedDriverId,
    int? selectedCarId,
  }) {
    return DriverProviderState(
      drivers: drivers ?? this.drivers,
      cars: cars ?? this.cars,
      driverCars: driverCars ?? this.driverCars,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      selectedDriverId: selectedDriverId ?? this.selectedDriverId,
      selectedCarId: selectedCarId ?? this.selectedCarId,
    );
  }

  Driver? get driver =>
      selectedDriverId != null ? drivers.firstWhere(
        (d) => d.id == selectedDriverId, 
        orElse: () => Driver(id: 0, name: '', email: '', phone: '', createdAt: DateTime(2000,1,1), updatedAt: DateTime(2000,1,1))
      ) : null;

  Car? get car =>
      selectedCarId != null ? cars.firstWhere(
        (c) => c.id == selectedCarId, 
        orElse: () => Car(id: 0, make: '', model: '', year: 0, licensePlate: '', hasWifi: false, createdAt: DateTime(2000,1,1), updatedAt: DateTime(2000,1,1))
      ) : null;

  // Helper methods para relacionamentos muitos-para-muitos
  List<Car> getCarsForDriver(int driverId) {
    final activeRelationships = driverCars.where((dc) => 
      dc.driverId == driverId && dc.isActive
    ).toList();
    
    return cars.where((car) => 
      activeRelationships.any((dc) => dc.carId == car.id)
    ).toList();
  }

  List<Driver> getDriversForCar(int carId) {
    final activeRelationships = driverCars.where((dc) => 
      dc.carId == carId && dc.isActive
    ).toList();
    
    return drivers.where((driver) => 
      activeRelationships.any((dc) => dc.driverId == driver.id)
    ).toList();
  }

  List<Car> getAvailableCars() {
    final assignedCarIds = driverCars
        .where((dc) => dc.isActive)
        .map((dc) => dc.carId)
        .toSet();
    
    return cars.where((car) => !assignedCarIds.contains(car.id)).toList();
  }

  List<Driver> getAvailableDrivers() {
    final assignedDriverIds = driverCars
        .where((dc) => dc.isActive)
        .map((dc) => dc.driverId)
        .toSet();
    
    return drivers.where((driver) => !assignedDriverIds.contains(driver.id)).toList();
  }

  DriverCar? getDriverCarRelationship(int driverId, int carId) {
    try {
      return driverCars.firstWhere((dc) => 
        dc.driverId == driverId && 
        dc.carId == carId && 
        dc.isActive
      );
    } catch (e) {
      return null;
    }
  }
}

class DriverNotifier extends StateNotifier<DriverProviderState> {
  final SupabaseClient _supabase;

  DriverNotifier(this._supabase) : super(DriverProviderState()) {
    fetchInitialData();
  }

  Future<void> fetchInitialData() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      debugPrint('DriverProvider: Making database queries');
      
      final driverResponseFuture = _supabase.from('driver').select().order('name', ascending: true);
      final carResponseFuture = _supabase.from('car').select().order('make', ascending: true).order('model', ascending: true);
      final driverCarsResponseFuture = _supabase.from('driver_car').select().eq('is_active', true);

      final responses = await Future.wait([
        driverResponseFuture,
        carResponseFuture,
        driverCarsResponseFuture,
      ]);

      debugPrint('DriverProvider: Database queries completed');
      
      final driverData = responses[0] as List<dynamic>;
      final carData = responses[1] as List<dynamic>;
      final driverCarsData = responses[2] as List<dynamic>;

      debugPrint('DriverProvider: Found ${driverData.length} drivers, ${carData.length} cars, and ${driverCarsData.length} driver-car relationships');

      final drivers = driverData
          .map((data) => Driver.fromJson(data as Map<String, dynamic>))
          .toList();
          
      final cars = carData
          .map((data) => Car.fromJson(data as Map<String, dynamic>))
          .toList();
          
      final driverCars = driverCarsData
          .map((data) => DriverCar.fromJson(data as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        drivers: drivers,
        cars: cars,
        driverCars: driverCars,
        isLoading: false,
      );
      
      debugPrint('DriverProvider: State updated successfully');
    } catch (e) {
      debugPrint('DriverProvider: Error fetching data: $e');
      state = state.copyWith(
        isLoading: false, 
        errorMessage: 'Erro ao buscar dados: $e'
      );
    }
  }

  Future<bool> addDriver({
    required String name,
    required String? email,
    required String? phone,
    required String? cityName,
    List<int>? carIds,
    Map<int, String>? carNotes,
    String? photoUrl,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      // Validar dados obrigatórios
      if (name.trim().isEmpty) {
        state = state.copyWith(
          isLoading: false, 
          errorMessage: 'Nome é obrigatório'
        );
        return false;
      }

      // Inserir novo driver no Supabase
      final response = await _supabase.from('driver').insert({
        'name': name.trim(),
        'email': email?.trim().isEmpty == true ? null : email?.trim(),
        'phone': phone?.trim().isEmpty == true ? null : phone?.trim(),
        'city_name': cityName?.trim().isEmpty == true ? null : cityName?.trim(),
        'photo_url': photoUrl?.trim().isEmpty == true ? null : photoUrl?.trim(),
      }).select().single();

      // Criar objeto Driver a partir da resposta
      final newDriver = Driver.fromJson(response);
      
      // Atualizar a lista de drivers
      final updatedDrivers = [...state.drivers, newDriver];
      updatedDrivers.sort((a, b) => a.name.compareTo(b.name));
      
      // Se carIds foram fornecidos, atribuir carros ao motorista
      if (carIds != null && carIds.isNotEmpty) {
        await _assignCarsToDriver(newDriver.id, carIds, carNotes);
      }
      
      state = state.copyWith(
        drivers: updatedDrivers,
        isLoading: false,
      );
      
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false, 
        errorMessage: 'Erro ao adicionar motorista: $e'
      );
      return false;
    }
  }

  Future<bool> updateDriver({
    required int driverId,
    required String name,
    required String? email,
    required String? phone,
    required String? cityName,
    List<int>? carIds,
    Map<int, String>? carNotes,
    String? photoUrl,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      // Validar dados obrigatórios
      if (name.trim().isEmpty) {
        state = state.copyWith(
          isLoading: false, 
          errorMessage: 'Nome é obrigatório'
        );
        return false;
      }

      // Atualizar driver no Supabase
      await _supabase.from('driver').update({
        'name': name.trim(),
        'email': email?.trim().isEmpty == true ? null : email?.trim(),
        'phone': phone?.trim().isEmpty == true ? null : phone?.trim(),
        'city_name': cityName?.trim().isEmpty == true ? null : cityName?.trim(),
        'photo_url': photoUrl?.trim().isEmpty == true ? null : photoUrl?.trim(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', driverId);

      // Atualizar relacionamentos de carros se fornecidos
      if (carIds != null) {
        await _updateDriverCars(driverId, carIds, carNotes);
      }

      // Recarregar dados para garantir sincronização
      await fetchInitialData();
      
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false, 
        errorMessage: 'Erro ao atualizar motorista: $e'
      );
      return false;
    }
  }

  Future<bool> deleteDriver(int driverId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      // Desativar relacionamentos de carros primeiro
      await _supabase.from('driver_car').update({
        'is_active': false,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('driver_id', driverId);
      
      // Remover o driver
      await _supabase.from('driver').delete().eq('id', driverId);
      
      // Recarregar dados
      await fetchInitialData();
      
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false, 
        errorMessage: 'Erro ao excluir motorista: $e'
      );
      return false;
    }
  }

  // Métodos para gerenciar relacionamentos muitos-para-muitos
  Future<void> _assignCarsToDriver(int driverId, List<int> carIds, Map<int, String>? carNotes) async {
    // Inserir relacionamentos na tabela driver_car
    for (int carId in carIds) {
      await _supabase.from('driver_car').insert({
        'driver_id': driverId,
        'car_id': carId,
        'is_active': true,
        'notes': carNotes?[carId],
        'assigned_at': DateTime.now().toUtc().toIso8601String(),
      });
    }
    
    // Recarregar dados para atualizar o estado
    await fetchInitialData();
  }

  Future<void> _updateDriverCars(int driverId, List<int> newCarIds, Map<int, String>? carNotes) async {
    // Primeiro, desativar todos os relacionamentos existentes do motorista
    await _supabase.from('driver_car').update({
      'is_active': false,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('driver_id', driverId).eq('is_active', true);

    // Depois, criar os novos relacionamentos
    if (newCarIds.isNotEmpty) {
      await _assignCarsToDriver(driverId, newCarIds, carNotes);
    }
  }

  Future<bool> assignCarToDriver(int driverId, int carId, {String? notes}) async {
    try {
      await _supabase.from('driver_car').insert({
        'driver_id': driverId,
        'car_id': carId,
        'is_active': true,
        'notes': notes,
        'assigned_at': DateTime.now().toUtc().toIso8601String(),
      });

      await fetchInitialData();
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Erro ao atribuir carro: $e'
      );
      return false;
    }
  }

  Future<bool> removeCarFromDriver(int driverId, int carId) async {
    try {
      await _supabase.from('driver_car').update({
        'is_active': false,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('driver_id', driverId).eq('car_id', carId).eq('is_active', true);

      await fetchInitialData();
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Erro ao remover carro: $e'
      );
      return false;
    }
  }

  // Métodos para obter dados específicos
  List<Car> getAvailableCarsForDriver(int driverId) {
    final driverCarIds = state.getCarsForDriver(driverId).map((c) => c.id).toSet();
    return state.cars.where((car) => !driverCarIds.contains(car.id)).toList();
  }

  List<Driver> getAvailableDriversForCar(int carId) {
    final carDriverIds = state.getDriversForCar(carId).map((d) => d.id).toSet();
    return state.drivers.where((driver) => !carDriverIds.contains(driver.id)).toList();
  }
}

final driverProviderFixed =
    StateNotifierProvider<DriverNotifier, DriverProviderState>((ref) {
  final supabase = Supabase.instance.client;
  return DriverNotifier(supabase);
}); 

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:state_notifier/state_notifier.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

class Car {
  final int id;
  final String make;
  final String model;
  final String licensePlate;
  final int? year;
  final String? color;
  final String? status;
  final int? driverId;
  final String? driverName;
  final DateTime createdAt;
  final DateTime updatedAt;

  Car({
    required this.id,
    required this.make,
    required this.model,
    required this.licensePlate,
    this.year,
    this.color,
    this.status,
    this.driverId,
    this.driverName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Car.fromJson(Map<String, dynamic> json) {
    return Car(
      id: json['id'],
      make: json['make'] ?? 'Marca não especificada',
      model: json['model'] ?? 'Modelo não especificado',
      licensePlate: json['license_plate'] ?? '',
      year: json['year'],
      color: json['color'],
      status: json['status'] ?? 'available',
      driverId: json['driver_id'],
      driverName: json['driver_name'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'make': make,
      'model': model,
      'license_plate': licensePlate,
      'year': year,
      'color': color,
      'status': status,
      'driver_id': driverId,
      'driver_name': driverName,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get displayName => '$make $model';
  String get name => displayName; // Para compatibilidade
  
  bool get isAvailable => status == 'available';
  bool get isInUse => status == 'in_use';
  bool get isMaintenance => status == 'maintenance';
  bool get hasDriver => driverId != null && driverName != null;
}

class CarsNotifier extends StateNotifier<AsyncValue<List<Car>>> {
  CarsNotifier() : super(const AsyncValue.loading());

  Future<void> loadCars() async {
    try {
      state = const AsyncValue.loading();
      
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('cars')
          .select('*, drivers(name)')
          .order('name');

      if (response == null) {
        state = const AsyncValue.data([]);
        return;
      }

      final cars = (response as List)
          .map((json) => Car.fromJson(json))
          .toList();

      state = AsyncValue.data(cars);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> addCar(Car car) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('cars').insert(car.toJson());
      await loadCars();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateCar(Car car) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase
          .from('cars')
          .update(car.toJson())
          .eq('id', car.id);
      await loadCars();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteCar(int id) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('cars').delete().eq('id', id);
      await loadCars();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  List<Car> get availableCars => 
      state.value?.where((car) => car.isAvailable).toList() ?? [];

  List<Car> get carsInUse => 
      state.value?.where((car) => car.isInUse).toList() ?? [];

  List<Car> get carsInMaintenance => 
      state.value?.where((car) => car.isMaintenance).toList() ?? [];
}

final carsProvider = StateNotifierProvider<CarsNotifier, AsyncValue<List<Car>>>(
  (ref) => CarsNotifier(),
);

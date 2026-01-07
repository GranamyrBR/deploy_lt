import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

class Driver {
  final int id;
  final String name;
  final String? email;
  final String? phone;
  final String? cityName;
  final String? photoUrl;
  final String? status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Driver({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.cityName,
    this.photoUrl,
    this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id'],
      name: json['name'] ?? 'Motorista não especificado',
      email: json['email'],
      phone: json['phone'],
      cityName: json['city_name'],
      photoUrl: json['photo_url'],
      status: json['status'] ?? 'available',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'city_name': cityName,
      'photo_url': photoUrl,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isAvailable => status == 'available';
  bool get isBusy => status == 'busy';
  bool get isOffline => status == 'offline';
}

class DriversNotifier extends StateNotifier<AsyncValue<List<Driver>>> {
  DriversNotifier() : super(const AsyncValue.loading());

  Future<void> loadDrivers() async {
    try {
      state = const AsyncValue.loading();
      
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('driver')
          .select('*')
          .order('name');

      final drivers = (response as List)
          .map((json) => Driver.fromJson(json))
          .toList();

      state = AsyncValue.data(drivers);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> addDriver(Driver driver) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('driver').insert(driver.toJson());
      await loadDrivers();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateDriver(Driver driver) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase
          .from('driver')
          .update(driver.toJson())
          .eq('id', driver.id);
      await loadDrivers();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteDriver(int id) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('driver').delete().eq('id', id);
      await loadDrivers();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  List<Driver> get availableDrivers => 
      state.value?.where((driver) => driver.isAvailable).toList() ?? [];

  List<Driver> get busyDrivers => 
      state.value?.where((driver) => driver.isBusy).toList() ?? [];

  List<Driver> get offlineDrivers => 
      state.value?.where((driver) => driver.isOffline).toList() ?? [];
}

final driversProvider = StateNotifierProvider<DriversNotifier, AsyncValue<List<Driver>>>(
  (ref) => DriversNotifier(),
); 

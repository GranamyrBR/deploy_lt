import 'package:json_annotation/json_annotation.dart';

part 'driver_car.g.dart';

@JsonSerializable()
class DriverCar {
  final int id;
  @JsonKey(name: 'driver_id')
  final int driverId;
  @JsonKey(name: 'car_id')
  final int carId;
  @JsonKey(name: 'assigned_at')
  final DateTime assignedAt;
  @JsonKey(name: 'is_active', defaultValue: true)
  final bool isActive;
  final String? notes;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  DriverCar({
    required this.id,
    required this.driverId,
    required this.carId,
    required this.assignedAt,
    required this.isActive,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DriverCar.fromJson(Map<String, dynamic> json) => _$DriverCarFromJson(json);
  Map<String, dynamic> toJson() => _$DriverCarToJson(this);
} 

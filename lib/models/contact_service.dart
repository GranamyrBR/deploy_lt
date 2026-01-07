import 'package:json_annotation/json_annotation.dart';

part 'contact_service.g.dart';

@JsonSerializable()
class ContactService {
  final int id;
  @JsonKey(name: 'contact_id')
  final int contactId;
  @JsonKey(name: 'service_id')
  final int serviceId;
  @JsonKey(name: 'driver_id')
  final int? driverId;
  @JsonKey(name: 'car_id')
  final int? carId;
  @JsonKey(name: 'agency_id')
  final int? agencyId;
  @JsonKey(name: 'scheduled_date')
  final DateTime scheduledDate;
  @JsonKey(name: 'number_of_passengers')
  final int? numberOfPassengers;
  @JsonKey(name: 'pickup_location')
  final String? pickupLocation;
  @JsonKey(name: 'dropoff_location')
  final String? dropoffLocation;
  @JsonKey(name: 'special_instructions')
  final String? specialInstructions;
  @JsonKey(name: 'final_price')
  final double? finalPrice;
  @JsonKey(name: 'discount_amount')
  final double? discountAmount;
  @JsonKey(name: 'payment_status')
  final String? paymentStatus;
  final String? status;
  @JsonKey(name: 'flight_number')
  final String? flightNumber;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  // Campos relacionados (via JOIN)
  @JsonKey(name: 'contact')
  final Map<String, dynamic>? contact;
  @JsonKey(name: 'service')
  final Map<String, dynamic>? service;
  @JsonKey(name: 'driver')
  final Map<String, dynamic>? driver;
  @JsonKey(name: 'car')
  final Map<String, dynamic>? car;
  @JsonKey(name: 'agency')
  final Map<String, dynamic>? agency;

  ContactService({
    required this.id,
    required this.contactId,
    required this.serviceId,
    this.driverId,
    this.carId,
    this.agencyId,
    required this.scheduledDate,
    this.numberOfPassengers,
    this.pickupLocation,
    this.dropoffLocation,
    this.specialInstructions,
    this.finalPrice,
    this.discountAmount,
    this.paymentStatus,
    this.status,
    this.flightNumber,
    this.createdAt,
    this.updatedAt,
    this.contact,
    this.service,
    this.driver,
    this.car,
    this.agency,
  });

  factory ContactService.fromJson(Map<String, dynamic> json) => _$ContactServiceFromJson(json);
  Map<String, dynamic> toJson() => _$ContactServiceToJson(this);

  // Getters para dados relacionados
  String get contactName => contact?['name'] as String? ?? 'N/A';
  String get serviceName => service?['name'] as String? ?? 'N/A';
  String get driverName => driver?['name'] as String? ?? 'N/A';
  String get carInfo => car != null ? '${car!['make']} ${car!['model']} (${car!['license_plate']})' : 'N/A';
  String get agencyName => agency?['name'] as String? ?? 'N/A';
} 

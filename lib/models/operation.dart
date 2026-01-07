import 'package:json_annotation/json_annotation.dart';

part 'operation.g.dart';

@JsonSerializable()
class Operation {
  final int id;
  final int saleId;
  final int saleItemId;
  final int? serviceId; // Opcional para operações de produtos
  final int? productId; // Para operações de produtos
  final int customerId;
  final int? driverId;
  final int? carId;
  final String status; // pending, assigned, in_progress, completed, cancelled, failed
  final String priority; // low, normal, high, urgent
  final DateTime scheduledDate;
  final int? estimatedDurationMinutes;
  final DateTime? actualStartTime;
  final DateTime? actualEndTime;
  final int? actualDurationMinutes;
  final String? pickupLocation;
  final String? dropoffLocation;
  final Map<String, double>? pickupCoordinates; // {lat: double, lng: double}
  final Map<String, double>? dropoffCoordinates; // {lat: double, lng: double}
  final int numberOfPassengers;
  final int luggageCount;
  final String? specialInstructions;
  final String? customerNotes;
  final String? driverNotes;
  final double? serviceValueUsd; // Para operações de serviços
  final double? productValueUsd; // Para operações de produtos
  final int? quantity; // Quantidade para operações de produtos
  final double driverCommissionUsd;
  final double driverCommissionPercentage;
  final bool whatsappMessageSent;
  final DateTime? whatsappMessageSentAt;
  final String? whatsappMessageId;
  final String? googleCalendarEventId;
  final bool googleCalendarEventCreated;
  final DateTime? googleCalendarEventCreatedAt;
  final int? customerRating;
  final String? customerFeedback;
  final int? driverRating;
  final String? driverFeedback;
  final String? createdByUserId;
  final String? assignedByUserId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Operation({
    required this.id,
    required this.saleId,
    required this.saleItemId,
    this.serviceId, // Opcional
    this.productId, // Opcional
    required this.customerId,
    this.driverId,
    this.carId,
    required this.status,
    required this.priority,
    required this.scheduledDate,
    this.estimatedDurationMinutes,
    this.actualStartTime,
    this.actualEndTime,
    this.actualDurationMinutes,
    this.pickupLocation,
    this.dropoffLocation,
    this.pickupCoordinates,
    this.dropoffCoordinates,
    this.numberOfPassengers = 1,
    this.luggageCount = 0,
    this.specialInstructions,
    this.customerNotes,
    this.driverNotes,
    this.serviceValueUsd, // Opcional
    this.productValueUsd, // Opcional
    this.quantity, // Opcional
    this.driverCommissionUsd = 0,
    this.driverCommissionPercentage = 0,
    this.whatsappMessageSent = false,
    this.whatsappMessageSentAt,
    this.whatsappMessageId,
    this.googleCalendarEventId,
    this.googleCalendarEventCreated = false,
    this.googleCalendarEventCreatedAt,
    this.customerRating,
    this.customerFeedback,
    this.driverRating,
    this.driverFeedback,
    this.createdByUserId,
    this.assignedByUserId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Operation.fromJson(Map<String, dynamic> json) => _$OperationFromJson(json);
  Map<String, dynamic> toJson() => _$OperationToJson(this);

  Operation copyWith({
    int? id,
    int? saleId,
    int? saleItemId,
    int? serviceId,
    int? productId,
    int? customerId,
    int? driverId,
    int? carId,
    String? status,
    String? priority,
    DateTime? scheduledDate,
    int? estimatedDurationMinutes,
    DateTime? actualStartTime,
    DateTime? actualEndTime,
    int? actualDurationMinutes,
    String? pickupLocation,
    String? dropoffLocation,
    Map<String, double>? pickupCoordinates,
    Map<String, double>? dropoffCoordinates,
    int? numberOfPassengers,
    int? luggageCount,
    String? specialInstructions,
    String? customerNotes,
    String? driverNotes,
    double? serviceValueUsd,
    double? productValueUsd,
    int? quantity,
    double? driverCommissionUsd,
    double? driverCommissionPercentage,
    bool? whatsappMessageSent,
    DateTime? whatsappMessageSentAt,
    String? whatsappMessageId,
    String? googleCalendarEventId,
    bool? googleCalendarEventCreated,
    DateTime? googleCalendarEventCreatedAt,
    int? customerRating,
    String? customerFeedback,
    int? driverRating,
    String? driverFeedback,
    String? createdByUserId,
    String? assignedByUserId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Operation(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      saleItemId: saleItemId ?? this.saleItemId,
      serviceId: serviceId ?? this.serviceId,
      productId: productId ?? this.productId,
      customerId: customerId ?? this.customerId,
      driverId: driverId ?? this.driverId,
      carId: carId ?? this.carId,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      estimatedDurationMinutes: estimatedDurationMinutes ?? this.estimatedDurationMinutes,
      actualStartTime: actualStartTime ?? this.actualStartTime,
      actualEndTime: actualEndTime ?? this.actualEndTime,
      actualDurationMinutes: actualDurationMinutes ?? this.actualDurationMinutes,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      dropoffLocation: dropoffLocation ?? this.dropoffLocation,
      pickupCoordinates: pickupCoordinates ?? this.pickupCoordinates,
      dropoffCoordinates: dropoffCoordinates ?? this.dropoffCoordinates,
      numberOfPassengers: numberOfPassengers ?? this.numberOfPassengers,
      luggageCount: luggageCount ?? this.luggageCount,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      customerNotes: customerNotes ?? this.customerNotes,
      driverNotes: driverNotes ?? this.driverNotes,
      serviceValueUsd: serviceValueUsd ?? this.serviceValueUsd,
      productValueUsd: productValueUsd ?? this.productValueUsd,
      quantity: quantity ?? this.quantity,
      driverCommissionUsd: driverCommissionUsd ?? this.driverCommissionUsd,
      driverCommissionPercentage: driverCommissionPercentage ?? this.driverCommissionPercentage,
      whatsappMessageSent: whatsappMessageSent ?? this.whatsappMessageSent,
      whatsappMessageSentAt: whatsappMessageSentAt ?? this.whatsappMessageSentAt,
      whatsappMessageId: whatsappMessageId ?? this.whatsappMessageId,
      googleCalendarEventId: googleCalendarEventId ?? this.googleCalendarEventId,
      googleCalendarEventCreated: googleCalendarEventCreated ?? this.googleCalendarEventCreated,
      googleCalendarEventCreatedAt: googleCalendarEventCreatedAt ?? this.googleCalendarEventCreatedAt,
      customerRating: customerRating ?? this.customerRating,
      customerFeedback: customerFeedback ?? this.customerFeedback,
      driverRating: driverRating ?? this.driverRating,
      driverFeedback: driverFeedback ?? this.driverFeedback,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      assignedByUserId: assignedByUserId ?? this.assignedByUserId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

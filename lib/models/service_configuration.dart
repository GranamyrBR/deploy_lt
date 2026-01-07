import 'package:json_annotation/json_annotation.dart';

part 'service_configuration.g.dart';

@JsonSerializable()
class ServiceConfiguration {
  final int id;
  final int serviceId;
  final bool requiresFlightData;
  final bool requiresDriverAssignment;
  final bool requiresCarAssignment;
  final bool requiresPickupLocation;
  final bool requiresDropoffLocation;
  final double defaultDriverCommissionPercentage;
  final double defaultDriverCommissionFixedUsd;
  final bool autoCreateGoogleCalendarEvent;
  final bool autoSendWhatsappMessage;
  final bool autoFetchFlightData;
  final int notifyDriverMinutesBefore;
  final int notifyCustomerMinutesBefore;
  final DateTime createdAt;
  final DateTime updatedAt;

  ServiceConfiguration({
    required this.id,
    required this.serviceId,
    this.requiresFlightData = false,
    this.requiresDriverAssignment = true,
    this.requiresCarAssignment = true,
    this.requiresPickupLocation = true,
    this.requiresDropoffLocation = true,
    this.defaultDriverCommissionPercentage = 0,
    this.defaultDriverCommissionFixedUsd = 0,
    this.autoCreateGoogleCalendarEvent = false,
    this.autoSendWhatsappMessage = false,
    this.autoFetchFlightData = false,
    this.notifyDriverMinutesBefore = 30,
    this.notifyCustomerMinutesBefore = 60,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ServiceConfiguration.fromJson(Map<String, dynamic> json) => _$ServiceConfigurationFromJson(json);
  Map<String, dynamic> toJson() => _$ServiceConfigurationToJson(this);

  ServiceConfiguration copyWith({
    int? id,
    int? serviceId,
    bool? requiresFlightData,
    bool? requiresDriverAssignment,
    bool? requiresCarAssignment,
    bool? requiresPickupLocation,
    bool? requiresDropoffLocation,
    double? defaultDriverCommissionPercentage,
    double? defaultDriverCommissionFixedUsd,
    bool? autoCreateGoogleCalendarEvent,
    bool? autoSendWhatsappMessage,
    bool? autoFetchFlightData,
    int? notifyDriverMinutesBefore,
    int? notifyCustomerMinutesBefore,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ServiceConfiguration(
      id: id ?? this.id,
      serviceId: serviceId ?? this.serviceId,
      requiresFlightData: requiresFlightData ?? this.requiresFlightData,
      requiresDriverAssignment: requiresDriverAssignment ?? this.requiresDriverAssignment,
      requiresCarAssignment: requiresCarAssignment ?? this.requiresCarAssignment,
      requiresPickupLocation: requiresPickupLocation ?? this.requiresPickupLocation,
      requiresDropoffLocation: requiresDropoffLocation ?? this.requiresDropoffLocation,
      defaultDriverCommissionPercentage: defaultDriverCommissionPercentage ?? this.defaultDriverCommissionPercentage,
      defaultDriverCommissionFixedUsd: defaultDriverCommissionFixedUsd ?? this.defaultDriverCommissionFixedUsd,
      autoCreateGoogleCalendarEvent: autoCreateGoogleCalendarEvent ?? this.autoCreateGoogleCalendarEvent,
      autoSendWhatsappMessage: autoSendWhatsappMessage ?? this.autoSendWhatsappMessage,
      autoFetchFlightData: autoFetchFlightData ?? this.autoFetchFlightData,
      notifyDriverMinutesBefore: notifyDriverMinutesBefore ?? this.notifyDriverMinutesBefore,
      notifyCustomerMinutesBefore: notifyCustomerMinutesBefore ?? this.notifyCustomerMinutesBefore,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 

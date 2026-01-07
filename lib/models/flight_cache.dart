import 'package:json_annotation/json_annotation.dart';

part 'flight_cache.g.dart';

@JsonSerializable()
class FlightCache {
  final int id;
  final String flightNumber;
  final String? airlineCode;
  final String? departureAirportCode;
  final String? arrivalAirportCode;
  final DateTime flightDate;
  final Map<String, dynamic> flightData;
  final String? flightawareFlightId;
  final String cacheKey;
  final bool isValid;
  final DateTime expiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  FlightCache({
    required this.id,
    required this.flightNumber,
    this.airlineCode,
    this.departureAirportCode,
    this.arrivalAirportCode,
    required this.flightDate,
    required this.flightData,
    this.flightawareFlightId,
    required this.cacheKey,
    this.isValid = true,
    required this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FlightCache.fromJson(Map<String, dynamic> json) => _$FlightCacheFromJson(json);
  Map<String, dynamic> toJson() => _$FlightCacheToJson(this);

  FlightCache copyWith({
    int? id,
    String? flightNumber,
    String? airlineCode,
    String? departureAirportCode,
    String? arrivalAirportCode,
    DateTime? flightDate,
    Map<String, dynamic>? flightData,
    String? flightawareFlightId,
    String? cacheKey,
    bool? isValid,
    DateTime? expiresAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FlightCache(
      id: id ?? this.id,
      flightNumber: flightNumber ?? this.flightNumber,
      airlineCode: airlineCode ?? this.airlineCode,
      departureAirportCode: departureAirportCode ?? this.departureAirportCode,
      arrivalAirportCode: arrivalAirportCode ?? this.arrivalAirportCode,
      flightDate: flightDate ?? this.flightDate,
      flightData: flightData ?? this.flightData,
      flightawareFlightId: flightawareFlightId ?? this.flightawareFlightId,
      cacheKey: cacheKey ?? this.cacheKey,
      isValid: isValid ?? this.isValid,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 

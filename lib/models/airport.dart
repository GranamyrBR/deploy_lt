import 'package:json_annotation/json_annotation.dart';

part 'airport.g.dart';

@JsonSerializable()
class Airport {
  final int id;
  final String iataCode;
  final String? icaoCode;
  final String name;
  final String city;
  final String? state;
  final String country;
  final String? countryCode;
  final double? latitude;
  final double? longitude;
  final String? timezone;
  final bool isActive;
  final bool isMajorAirport;
  final DateTime createdAt;
  final DateTime updatedAt;

  Airport({
    required this.id,
    required this.iataCode,
    this.icaoCode,
    required this.name,
    required this.city,
    this.state,
    required this.country,
    this.countryCode,
    this.latitude,
    this.longitude,
    this.timezone,
    this.isActive = true,
    this.isMajorAirport = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Airport.fromJson(Map<String, dynamic> json) => _$AirportFromJson(json);
  Map<String, dynamic> toJson() => _$AirportToJson(this);

  Airport copyWith({
    int? id,
    String? iataCode,
    String? icaoCode,
    String? name,
    String? city,
    String? state,
    String? country,
    String? countryCode,
    double? latitude,
    double? longitude,
    String? timezone,
    bool? isActive,
    bool? isMajorAirport,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Airport(
      id: id ?? this.id,
      iataCode: iataCode ?? this.iataCode,
      icaoCode: icaoCode ?? this.icaoCode,
      name: name ?? this.name,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      countryCode: countryCode ?? this.countryCode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      timezone: timezone ?? this.timezone,
      isActive: isActive ?? this.isActive,
      isMajorAirport: isMajorAirport ?? this.isMajorAirport,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 

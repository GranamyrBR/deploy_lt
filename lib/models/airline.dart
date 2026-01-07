import 'package:json_annotation/json_annotation.dart';

part 'airline.g.dart';

@JsonSerializable()
class Airline {
  final int id;
  final String iataCode;
  final String? icaoCode;
  final String name;
  final String? callsign;
  final String? country;
  final String? countryCode;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Airline({
    required this.id,
    required this.iataCode,
    this.icaoCode,
    required this.name,
    this.callsign,
    this.country,
    this.countryCode,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Airline.fromJson(Map<String, dynamic> json) => _$AirlineFromJson(json);
  Map<String, dynamic> toJson() => _$AirlineToJson(this);

  Airline copyWith({
    int? id,
    String? iataCode,
    String? icaoCode,
    String? name,
    String? callsign,
    String? country,
    String? countryCode,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Airline(
      id: id ?? this.id,
      iataCode: iataCode ?? this.iataCode,
      icaoCode: icaoCode ?? this.icaoCode,
      name: name ?? this.name,
      callsign: callsign ?? this.callsign,
      country: country ?? this.country,
      countryCode: countryCode ?? this.countryCode,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 

import 'package:json_annotation/json_annotation.dart';

part 'flight_data.g.dart';

@JsonSerializable()
class FlightData {
  final int id;
  final int operationId;
  final String flightNumber;
  final String? airlineCode;
  final String? airlineName;
  final String? departureAirportCode;
  final String? departureAirportName;
  final String? departureAirportCity;
  final String? departureAirportCountry;
  final String? arrivalAirportCode;
  final String? arrivalAirportName;
  final String? arrivalAirportCity;
  final String? arrivalAirportCountry;
  final DateTime? scheduledDepartureTime;
  final DateTime? scheduledArrivalTime;
  final DateTime? actualDepartureTime;
  final DateTime? actualArrivalTime;
  final String flightStatus; // scheduled, boarding, departed, arrived, delayed, cancelled, diverted
  final int delayMinutes;
  final String? departureTerminal;
  final String? departureGate;
  final String? arrivalTerminal;
  final String? arrivalGate;
  final String? flightawareFlightId;
  final DateTime? flightawareLastUpdated;
  final Map<String, dynamic>? flightawareData;
  final DateTime createdAt;
  final DateTime updatedAt;

  FlightData({
    required this.id,
    required this.operationId,
    required this.flightNumber,
    this.airlineCode,
    this.airlineName,
    this.departureAirportCode,
    this.departureAirportName,
    this.departureAirportCity,
    this.departureAirportCountry,
    this.arrivalAirportCode,
    this.arrivalAirportName,
    this.arrivalAirportCity,
    this.arrivalAirportCountry,
    this.scheduledDepartureTime,
    this.scheduledArrivalTime,
    this.actualDepartureTime,
    this.actualArrivalTime,
    required this.flightStatus,
    this.delayMinutes = 0,
    this.departureTerminal,
    this.departureGate,
    this.arrivalTerminal,
    this.arrivalGate,
    this.flightawareFlightId,
    this.flightawareLastUpdated,
    this.flightawareData,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FlightData.fromJson(Map<String, dynamic> json) => _$FlightDataFromJson(json);
  Map<String, dynamic> toJson() => _$FlightDataToJson(this);

  FlightData copyWith({
    int? id,
    int? operationId,
    String? flightNumber,
    String? airlineCode,
    String? airlineName,
    String? departureAirportCode,
    String? departureAirportName,
    String? departureAirportCity,
    String? departureAirportCountry,
    String? arrivalAirportCode,
    String? arrivalAirportName,
    String? arrivalAirportCity,
    String? arrivalAirportCountry,
    DateTime? scheduledDepartureTime,
    DateTime? scheduledArrivalTime,
    DateTime? actualDepartureTime,
    DateTime? actualArrivalTime,
    String? flightStatus,
    int? delayMinutes,
    String? departureTerminal,
    String? departureGate,
    String? arrivalTerminal,
    String? arrivalGate,
    String? flightawareFlightId,
    DateTime? flightawareLastUpdated,
    Map<String, dynamic>? flightawareData,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FlightData(
      id: id ?? this.id,
      operationId: operationId ?? this.operationId,
      flightNumber: flightNumber ?? this.flightNumber,
      airlineCode: airlineCode ?? this.airlineCode,
      airlineName: airlineName ?? this.airlineName,
      departureAirportCode: departureAirportCode ?? this.departureAirportCode,
      departureAirportName: departureAirportName ?? this.departureAirportName,
      departureAirportCity: departureAirportCity ?? this.departureAirportCity,
      departureAirportCountry: departureAirportCountry ?? this.departureAirportCountry,
      arrivalAirportCode: arrivalAirportCode ?? this.arrivalAirportCode,
      arrivalAirportName: arrivalAirportName ?? this.arrivalAirportName,
      arrivalAirportCity: arrivalAirportCity ?? this.arrivalAirportCity,
      arrivalAirportCountry: arrivalAirportCountry ?? this.arrivalAirportCountry,
      scheduledDepartureTime: scheduledDepartureTime ?? this.scheduledDepartureTime,
      scheduledArrivalTime: scheduledArrivalTime ?? this.scheduledArrivalTime,
      actualDepartureTime: actualDepartureTime ?? this.actualDepartureTime,
      actualArrivalTime: actualArrivalTime ?? this.actualArrivalTime,
      flightStatus: flightStatus ?? this.flightStatus,
      delayMinutes: delayMinutes ?? this.delayMinutes,
      departureTerminal: departureTerminal ?? this.departureTerminal,
      departureGate: departureGate ?? this.departureGate,
      arrivalTerminal: arrivalTerminal ?? this.arrivalTerminal,
      arrivalGate: arrivalGate ?? this.arrivalGate,
      flightawareFlightId: flightawareFlightId ?? this.flightawareFlightId,
      flightawareLastUpdated: flightawareLastUpdated ?? this.flightawareLastUpdated,
      flightawareData: flightawareData ?? this.flightawareData,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 

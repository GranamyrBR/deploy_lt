import 'package:json_annotation/json_annotation.dart';

part 'flight_info.g.dart'; // Gerado pelo json_serializable

@JsonSerializable()
class FlightInfo {
  @JsonKey(name: 'flight_date')
  final String? flightDate;
  @JsonKey(name: 'flight_status')
  final String? flightStatus;
  @JsonKey(
      name: 'departure', fromJson: _departureFromJson, toJson: _departureToJson)
  final DepartureInfo? departure;
  @JsonKey(name: 'arrival', fromJson: _arrivalFromJson, toJson: _arrivalToJson)
  final ArrivalInfo? arrival;
  @JsonKey(name: 'airline', fromJson: _airlineFromJson, toJson: _airlineToJson)
  final AirlineInfo? airline;
  @JsonKey(
      name: 'flight',
      fromJson: _flightDetailsFromJson,
      toJson: _flightDetailsToJson)
  final FlightDetails? flight;

  FlightInfo({
    this.flightDate,
    this.flightStatus,
    this.departure,
    this.arrival,
    this.airline,
    this.flight,
  });

  factory FlightInfo.fromJson(Map<String, dynamic> json) =>
      _$FlightInfoFromJson(json);

  Map<String, dynamic> toJson() => _$FlightInfoToJson(this);

  // Getters para compatibilidade com OperationalRoute
  String? get flightNumber => flight?.number;
  String? get airlineCode => airline?.iata;
  String? get airlineName => airline?.name;
  String? get departureAirportCode => departure?.iata;
  String? get departureAirportName => departure?.airport;
  String? get arrivalAirportCode => arrival?.iata;
  String? get arrivalAirportName => arrival?.airport;
  String? get scheduledDepartureTime => departure?.scheduled;
  String? get scheduledArrivalTime => arrival?.scheduled;
  String? get departureTerminal => departure?.terminal;
  String? get arrivalTerminal => arrival?.terminal;

  static DepartureInfo? _departureFromJson(Map<String, dynamic>? json) =>
      json == null ? null : DepartureInfo.fromJson(json);
  static Map<String, dynamic>? _departureToJson(DepartureInfo? departure) =>
      departure?.toJson();

  static ArrivalInfo? _arrivalFromJson(Map<String, dynamic>? json) =>
      json == null ? null : ArrivalInfo.fromJson(json);
  static Map<String, dynamic>? _arrivalToJson(ArrivalInfo? arrival) =>
      arrival?.toJson();

  static AirlineInfo? _airlineFromJson(Map<String, dynamic>? json) =>
      json == null ? null : AirlineInfo.fromJson(json);
  static Map<String, dynamic>? _airlineToJson(AirlineInfo? airline) =>
      airline?.toJson();

  static FlightDetails? _flightDetailsFromJson(Map<String, dynamic>? json) =>
      json == null ? null : FlightDetails.fromJson(json);
  static Map<String, dynamic>? _flightDetailsToJson(FlightDetails? flight) =>
      flight?.toJson();
}

@JsonSerializable()
class DepartureInfo {
  final String? airport;
  final String? iata;
  final String? scheduled;
  final String? estimated;
  final String? terminal;
  final String? gate;

  DepartureInfo({
    this.airport,
    this.iata,
    this.scheduled,
    this.estimated,
    this.terminal,
    this.gate,
  });

  factory DepartureInfo.fromJson(Map<String, dynamic> json) =>
      _$DepartureInfoFromJson(json);
  Map<String, dynamic> toJson() => _$DepartureInfoToJson(this);
}

@JsonSerializable()
class ArrivalInfo {
  final String? airport;
  final String? iata;
  final String? scheduled;
  final String? estimated;
  final String? terminal;
  final String? gate;

  ArrivalInfo({
    this.airport,
    this.iata,
    this.scheduled,
    this.estimated,
    this.terminal,
    this.gate,
  });

  factory ArrivalInfo.fromJson(Map<String, dynamic> json) =>
      _$ArrivalInfoFromJson(json);
  Map<String, dynamic> toJson() => _$ArrivalInfoToJson(this);
}

@JsonSerializable()
class AirlineInfo {
  final String? name;
  final String? iata;

  AirlineInfo({this.name, this.iata});

  factory AirlineInfo.fromJson(Map<String, dynamic> json) =>
      _$AirlineInfoFromJson(json);
  Map<String, dynamic> toJson() => _$AirlineInfoToJson(this);
}

@JsonSerializable()
class FlightDetails {
  final String? number;
  final String? iata;

  FlightDetails({this.number, this.iata});

  factory FlightDetails.fromJson(Map<String, dynamic> json) =>
      _$FlightDetailsFromJson(json);
  Map<String, dynamic> toJson() => _$FlightDetailsToJson(this);
}

// Estrutura da resposta da API AviationStack (geralmente uma lista dentro de 'data')
@JsonSerializable()
class AviationStackResponse {
  final List<FlightInfo> data;

  AviationStackResponse({required this.data});

  factory AviationStackResponse.fromJson(Map<String, dynamic> json) =>
      _$AviationStackResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AviationStackResponseToJson(this);
}

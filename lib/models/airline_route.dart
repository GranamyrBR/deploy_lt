import 'package:json_annotation/json_annotation.dart';

part 'airline_route.g.dart';

@JsonSerializable()
class AirlineRoute {
  final int id;
  @JsonKey(name: 'route_code')
  final String routeCode;
  @JsonKey(name: 'airline_iata')
  final String airlineIata;
  @JsonKey(name: 'airline_name')
  final String airlineName;
  @JsonKey(name: 'flight_number')
  final String flightNumber;
  
  // Origem
  @JsonKey(name: 'origin_airport_iata')
  final String originAirportIata;
  @JsonKey(name: 'origin_airport_name')
  final String originAirportName;
  @JsonKey(name: 'origin_city')
  final String originCity;
  @JsonKey(name: 'origin_country')
  final String originCountry;
  
  // Destino
  @JsonKey(name: 'destination_airport_iata')
  final String destinationAirportIata;
  @JsonKey(name: 'destination_airport_name')
  final String destinationAirportName;
  @JsonKey(name: 'destination_city')
  final String destinationCity;
  @JsonKey(name: 'destination_country')
  final String destinationCountry;
  
  // Detalhes do voo
  @JsonKey(name: 'aircraft_type')
  final String? aircraftType;
  @JsonKey(name: 'flight_duration_minutes')
  final int? flightDurationMinutes;
  @JsonKey(name: 'frequency_per_week')
  final int? frequencyPerWeek;
  @JsonKey(name: 'operating_days')
  final String? operatingDays;
  
  // Horários
  @JsonKey(name: 'typical_departure_time')
  final String? typicalDepartureTime;
  @JsonKey(name: 'typical_arrival_time')
  final String? typicalArrivalTime;
  
  // Status
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'seasonal')
  final bool? seasonal;
  @JsonKey(name: 'start_date')
  final DateTime? startDate;
  @JsonKey(name: 'end_date')
  final DateTime? endDate;
  
  // Direção calculada (Brasil → EUA ou EUA → Brasil)
  final String? direction;
  
  AirlineRoute({
    required this.id,
    required this.routeCode,
    required this.airlineIata,
    required this.airlineName,
    required this.flightNumber,
    required this.originAirportIata,
    required this.originAirportName,
    required this.originCity,
    required this.originCountry,
    required this.destinationAirportIata,
    required this.destinationAirportName,
    required this.destinationCity,
    required this.destinationCountry,
    this.aircraftType,
    this.flightDurationMinutes,
    this.frequencyPerWeek,
    this.operatingDays,
    this.typicalDepartureTime,
    this.typicalArrivalTime,
    this.isActive = true,
    this.seasonal,
    this.startDate,
    this.endDate,
    this.direction,
  });

  factory AirlineRoute.fromJson(Map<String, dynamic> json) => _$AirlineRouteFromJson(json);
  Map<String, dynamic> toJson() => _$AirlineRouteToJson(this);

  // Helpers para formatação
  String get formattedDuration {
    if (flightDurationMinutes == null) return 'N/A';
    final hours = flightDurationMinutes! ~/ 60;
    final minutes = flightDurationMinutes! % 60;
    return '${hours}h ${minutes}m';
  }
  
  String get frequencyDescription {
    if (frequencyPerWeek == null) return 'N/A';
    switch (frequencyPerWeek!) {
      case 7: return 'Diário';
      case 6: return '6x por semana';
      case 5: return '5x por semana';
      case 4: return '4x por semana';
      case 3: return '3x por semana';
      case 2: return '2x por semana';
      case 1: return '1x por semana';
      default: return '$frequencyPerWeek x por semana';
    }
  }
  
  String get operatingDaysDescription {
    if (operatingDays == null || operatingDays!.isEmpty) return 'N/A';
    
    final days = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
    final operatingList = <String>[];
    
    for (int i = 0; i < operatingDays!.length; i++) {
      final dayNumber = int.tryParse(operatingDays![i]);
      if (dayNumber != null && dayNumber >= 1 && dayNumber <= 7) {
        operatingList.add(days[dayNumber - 1]);
      }
    }
    
    return operatingList.join(', ');
  }
  
  String get routeDescription => '$originCity → $destinationCity';
  
  String get fullRouteDescription => 
    '$originCity ($originAirportIata) → $destinationCity ($destinationAirportIata)';
  
  bool get isDirect => aircraftType != null && !routeCode.contains('PTY') && !routeCode.contains('FRA');
  
  String get connectionDescription {
    if (isDirect) return 'Direto';
    if (routeCode.contains('PTY')) return 'Via Panamá';
    if (routeCode.contains('FRA')) return 'Via Frankfurt';
    return 'Com conexão';
  }

  AirlineRoute copyWith({
    int? id,
    String? routeCode,
    String? airlineIata,
    String? airlineName,
    String? flightNumber,
    String? originAirportIata,
    String? originAirportName,
    String? originCity,
    String? originCountry,
    String? destinationAirportIata,
    String? destinationAirportName,
    String? destinationCity,
    String? destinationCountry,
    String? aircraftType,
    int? flightDurationMinutes,
    int? frequencyPerWeek,
    String? operatingDays,
    String? typicalDepartureTime,
    String? typicalArrivalTime,
    bool? isActive,
    bool? seasonal,
    DateTime? startDate,
    DateTime? endDate,
    String? direction,
  }) {
    return AirlineRoute(
      id: id ?? this.id,
      routeCode: routeCode ?? this.routeCode,
      airlineIata: airlineIata ?? this.airlineIata,
      airlineName: airlineName ?? this.airlineName,
      flightNumber: flightNumber ?? this.flightNumber,
      originAirportIata: originAirportIata ?? this.originAirportIata,
      originAirportName: originAirportName ?? this.originAirportName,
      originCity: originCity ?? this.originCity,
      originCountry: originCountry ?? this.originCountry,
      destinationAirportIata: destinationAirportIata ?? this.destinationAirportIata,
      destinationAirportName: destinationAirportName ?? this.destinationAirportName,
      destinationCity: destinationCity ?? this.destinationCity,
      destinationCountry: destinationCountry ?? this.destinationCountry,
      aircraftType: aircraftType ?? this.aircraftType,
      flightDurationMinutes: flightDurationMinutes ?? this.flightDurationMinutes,
      frequencyPerWeek: frequencyPerWeek ?? this.frequencyPerWeek,
      operatingDays: operatingDays ?? this.operatingDays,
      typicalDepartureTime: typicalDepartureTime ?? this.typicalDepartureTime,
      typicalArrivalTime: typicalArrivalTime ?? this.typicalArrivalTime,
      isActive: isActive ?? this.isActive,
      seasonal: seasonal ?? this.seasonal,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      direction: direction ?? this.direction,
    );
  }
} 

import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'flight_info.dart';

part 'operational_route.g.dart';

@JsonSerializable()
class OperationalRoute {
  final String voo;
  final String cia;
  @JsonKey(name: 'nome_cia')
  final String nomeCia;
  final String origem;
  final String destino;
  final String rota;
  @JsonKey(name: 'terminal_origem')
  final String? terminalOrigem;
  @JsonKey(name: 'terminal_destino')
  final String? terminalDestino;
  final String saida;
  final String chegada;
  @JsonKey(name: 'chegar_para_dropoff')
  final String chegarParaDropoff;
  @JsonKey(name: 'pickup_disponivel')
  final String pickupDisponivel;
  @JsonKey(name: 'check_in_area')
  final String? checkInArea;
  @JsonKey(name: 'desembarque_area')
  final String? desembarqueArea;
  final String? observacoes;
  final String operacao;

  OperationalRoute({
    required this.voo,
    required this.cia,
    required this.nomeCia,
    required this.origem,
    required this.destino,
    required this.rota,
    this.terminalOrigem,
    this.terminalDestino,
    required this.saida,
    required this.chegada,
    required this.chegarParaDropoff,
    required this.pickupDisponivel,
    this.checkInArea,
    this.desembarqueArea,
    this.observacoes,
    required this.operacao,
  });

  factory OperationalRoute.fromJson(Map<String, dynamic> json) =>
      _$OperationalRouteFromJson(json);

  Map<String, dynamic> toJson() => _$OperationalRouteToJson(this);

  // Converter FlightInfo para OperationalRoute
  factory OperationalRoute.fromFlightInfo(FlightInfo flight) {
    final origem = flight.departureAirportCode ?? '';
    final destino = flight.arrivalAirportCode ?? '';
    
    return OperationalRoute(
      voo: flight.flightNumber ?? '',
      cia: flight.airlineCode ?? '',
      nomeCia: flight.airlineName ?? '',
      origem: origem,
      destino: destino,
      rota: '$origem → $destino',
      terminalOrigem: flight.departureTerminal,
      terminalDestino: flight.arrivalTerminal,
      saida: flight.scheduledDepartureTime?.substring(11, 16) ?? '',
      chegada: flight.scheduledArrivalTime?.substring(11, 16) ?? '',
      chegarParaDropoff: 'Chegar 180 min antes',
      pickupDisponivel: 'Pickup após 60 min',
      checkInArea: 'Consultar terminal',
      desembarqueArea: 'Consultar terminal',
      observacoes: flight.flightStatus,
      operacao: _determineOperacao(origem),
    );
  }

  static String _determineOperacao(String origem) {
    final brazilAirports = [
      'GRU', 'GIG', 'BSB', 'VCP', 'CGH', 'SSA', 'REC', 'FOR', 
      'POA', 'CWB', 'BHZ', 'MAO', 'NAT', 'BEL', 'CGR', 'GYN'
    ];
    return brazilAirports.contains(origem) ? 'SAÍDA DO BRASIL' : 'CHEGADA AO BRASIL';
  }

  // Getters para facilitar o uso
  bool get isSaidaBrasil => operacao == 'SAÍDA DO BRASIL';
  bool get isChegadaBrasil => operacao == 'CHEGADA AO BRASIL';
  
  String get aeroportoOrigem {
    switch (origem) {
      case 'GRU': return 'São Paulo (Guarulhos)';
      case 'GIG': return 'Rio de Janeiro (Galeão)';
      case 'BSB': return 'Brasília';
      case 'VCP': return 'Campinas (Viracopos)';
      case 'MIA': return 'Miami';
      case 'JFK': return 'Nova York (JFK)';
      case 'LAX': return 'Los Angeles';
      case 'ORD': return 'Chicago';
      case 'IAH': return 'Houston';
      case 'ATL': return 'Atlanta';
      case 'CLT': return 'Charlotte';
      case 'EWR': return 'Newark';
      case 'YYZ': return 'Toronto';
      default: return origem;
    }
  }
  
  String get aeroportoDestino {
    switch (destino) {
      case 'GRU': return 'São Paulo (Guarulhos)';
      case 'GIG': return 'Rio de Janeiro (Galeão)';
      case 'BSB': return 'Brasília';
      case 'VCP': return 'Campinas (Viracopos)';
      case 'MIA': return 'Miami';
      case 'JFK': return 'Nova York (JFK)';
      case 'LAX': return 'Los Angeles';
      case 'ORD': return 'Chicago';
      case 'IAH': return 'Houston';
      case 'ATL': return 'Atlanta';
      case 'CLT': return 'Charlotte';
      case 'EWR': return 'Newark';
      case 'YYZ': return 'Toronto';
      default: return destino;
    }
  }

  Color get companiaColor {
    switch (cia) {
      case 'AA': return const Color(0xFF1E3A8A); // American Airlines - Azul
      case 'LA': return const Color(0xFF7C2D92); // LATAM - Roxo
      case 'UA': return const Color(0xFF0F172A); // United - Azul escuro
      case 'DL': return const Color(0xFFDC2626); // Delta - Vermelho
      case 'CM': return const Color(0xFF0EA5E9); // Copa - Azul claro
      case 'AV': return const Color(0xFFE11D48); // Avianca - Vermelho/Rosa
      case 'AC': return const Color(0xFFDC2626); // Air Canada - Vermelho
      case 'G3': return const Color(0xFFF59E0B); // GOL - Laranja
      case 'AD': return const Color(0xFF3B82F6); // Azul - Azul
      default: return const Color(0xFF6B7280); // Cinza
    }
  }

  IconData get operacaoIcon {
    return isSaidaBrasil ? Icons.flight_takeoff : Icons.flight_land;
  }

  // URL do favicon da companhia
  String get companhiaFaviconUrl {
    switch (cia) {
      case 'AA': return 'https://lecotour-dashboard.supabase.co/storage/v1/object/public/favicons/aa-favicon.ico';
      case 'LA': return 'https://lecotour-dashboard.supabase.co/storage/v1/object/public/favicons/latam-favicon.ico';
      case 'UA': return 'https://lecotour-dashboard.supabase.co/storage/v1/object/public/favicons/united-favicon.ico';
      case 'DL': return 'https://lecotour-dashboard.supabase.co/storage/v1/object/public/favicons/delta-favicon.ico';
      default: return 'https://via.placeholder.com/32x32/3B82F6/FFFFFF?text=$cia';
    }
  }
} 

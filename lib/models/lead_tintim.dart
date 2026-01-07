import 'package:json_annotation/json_annotation.dart';

part 'lead_tintim.g.dart';

enum LeadStatus {
  @JsonValue('new') // Assuming 'new' is the string value in JSON
  newLead,
  @JsonValue('contacted')
  contacted,
  @JsonValue('converted')
  converted,
  // Add other status as needed
  unknown, // Fallback or default
}
// Note: The @JsonValue annotations here are for string values.
// If your database stores integers, we'll need custom helpers below.

// Helper to convert integer from JSON to LeadStatus enum
LeadStatus? _leadStatusFromJson(dynamic statusValue) {
  if (statusValue == null) return null;

  // Explicit mapping for integer status (adjust as per your database schema)
  const Map<int, LeadStatus> intStatusMap = {
    0: LeadStatus.newLead, // Example: 0 means newLead
    1: LeadStatus.contacted, // Example: 1 means contacted
    2: LeadStatus.converted, // Example: 2 means converted
    // Add other integer mappings if necessary
  };

  // Explicit mapping for known string status
  final Map<String, LeadStatus> stringStatusMap = {
    'new': LeadStatus.newLead,
    'contacted': LeadStatus.contacted,
    'fez contato': LeadStatus.contacted, // Handling "Fez Contato"
    'converted': LeadStatus.converted, // Example
    'comprou': LeadStatus.converted, // Adiciona o mapeamento para "Comprou"
    // Add other string mappings if necessary (case-insensitive)
  };

  if (statusValue is int) {
    return intStatusMap[statusValue]; // Returns the enum or null if not in map
  } else if (statusValue is String) {
    final lowerCaseStatus = statusValue.toLowerCase();
    if (stringStatusMap.containsKey(lowerCaseStatus)) {
      return stringStatusMap[lowerCaseStatus];
    }
  }

  // Se o tipo for inesperado ou o valor não mapear, registre e retorne 'unknown'
  print(
      'Aviso: Valor ou tipo de status inesperado do webhook: $statusValue, tipo: ${statusValue.runtimeType}');
  return LeadStatus.unknown;
}

// Helper to convert LeadStatus enum to integer for JSON (if needed for sending data)
int? _leadStatusToJson(LeadStatus? status) {
  if (status == null || status == LeadStatus.unknown) return null;

  // Map enum value back to its integer ID.
  // This should be the inverse of the integer mapping in _leadStatusFromJson.
  const Map<LeadStatus, int> statusToIntMap = {
    LeadStatus.newLead: 0,
    LeadStatus.contacted: 1,
    LeadStatus.converted: 2,
    // Add other mappings if necessary
  };
  return statusToIntMap[status];
}

String? _stringFromJson(dynamic value) {
  if (value == null) return null;
  if (value is String) return value;
  if (value is num) return value.toString(); // Converte número para string
  print(
      'Aviso: Valor inesperado para campo string: $value, tipo: ${value.runtimeType}');
  return null; // Ou um valor padrão, ou lançar um erro se for crítico
}

double? _doubleFromJson(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();

  if (value is String) return double.tryParse(value);
  print(
      'Aviso: Valor inesperado para campo double: $value, tipo: ${value.runtimeType}');
  return null;
}
// E usar em @JsonKey: fromJson: _doubleFromJson

// Helper para converter from_me de String para bool
bool? _boolFromString(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is String) {
    if (value.toLowerCase() == 'true') return true;
    if (value.toLowerCase() == 'false') return false;
  }
  return null;
}

@JsonSerializable()
class LeadTintim {
  // Tornando o ID anulável para maior robustez com dados de webhook
  final int? id;
  @JsonKey(
      name: 'created_at', fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime? createdAt;
  final String? name;
  final String? phone;
  @JsonKey(
      name: 'datefirst', fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime? datefirst;
  @JsonKey(
      name: 'datelast', fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime? datelast;
  final String? source;
  @JsonKey(
      name: 'status', fromJson: _leadStatusFromJson, toJson: _leadStatusToJson)
  final LeadStatus? status; // Now the field is the enum type
  @JsonKey(
      name: 'saledate', fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime? saledate;
  final String? message;
  @JsonKey(name: 'messageid')
  final String? messageid;
  final String? country;
  final String? state;
  @JsonKey(name: 'salevalue')
  final double? salevalue;
  @JsonKey(name: 'salemessage', fromJson: _stringFromJson) // Adiciona o helper
  final String? salemessage;
  @JsonKey(name: 'from_me', fromJson: _boolFromString)
  final bool? fromMe;

  LeadTintim({
    // Não é mais 'required' se for anulável, mas ainda pode ser se a lógica de negócio exigir um ID
    this.id,
    this.createdAt,
    this.name,
    this.phone,
    this.datefirst,
    this.datelast,
    this.source,
    this.status,
    this.saledate,
    this.message,
    this.messageid,
    this.country,
    this.state,
    this.salevalue,
    this.salemessage,
    this.fromMe,
  });

  factory LeadTintim.fromJson(Map<String, dynamic> json) =>
      _$LeadTintimFromJson(json);
  Map<String, dynamic> toJson() => _$LeadTintimToJson(this);

  static DateTime? _dateTimeFromJson(String? json) =>
      json == null ? null : DateTime.tryParse(json);
  static String? _dateTimeToJson(DateTime? dateTime) =>
      dateTime?.toIso8601String();
}

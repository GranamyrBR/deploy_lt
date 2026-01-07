import 'package:json_annotation/json_annotation.dart';

part 'firebase_account.g.dart';

@JsonSerializable()
class FirebaseAccount {
  final String id;
  final String name;
  final String displayName;
  final String projectId;
  final String apiKey;
  final String? description;
  final bool isActive;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // URLs das Cloud Functions específicas desta conta
  final String? testConnectionUrl;
  final String? searchFlightUrl;
  final String? getAirportFlightsUrl;
  final String? getBrazilUsaFlightsUrl;

  FirebaseAccount({
    required this.id,
    required this.name,
    required this.displayName,
    required this.projectId,
    required this.apiKey,
    this.description,
    this.isActive = true,
    this.isDefault = false,
    required this.createdAt,
    required this.updatedAt,
    this.testConnectionUrl,
    this.searchFlightUrl,
    this.getAirportFlightsUrl,
    this.getBrazilUsaFlightsUrl,
  });

  factory FirebaseAccount.fromJson(Map<String, dynamic> json) =>
      _$FirebaseAccountFromJson(json);

  Map<String, dynamic> toJson() => _$FirebaseAccountToJson(this);

  // Método para criar uma cópia com alterações
  FirebaseAccount copyWith({
    String? id,
    String? name,
    String? displayName,
    String? projectId,
    String? apiKey,
    String? description,
    bool? isActive,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? testConnectionUrl,
    String? searchFlightUrl,
    String? getAirportFlightsUrl,
    String? getBrazilUsaFlightsUrl,
  }) {
    return FirebaseAccount(
      id: id ?? this.id,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      projectId: projectId ?? this.projectId,
      apiKey: apiKey ?? this.apiKey,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      testConnectionUrl: testConnectionUrl ?? this.testConnectionUrl,
      searchFlightUrl: searchFlightUrl ?? this.searchFlightUrl,
      getAirportFlightsUrl: getAirportFlightsUrl ?? this.getAirportFlightsUrl,
      getBrazilUsaFlightsUrl: getBrazilUsaFlightsUrl ?? this.getBrazilUsaFlightsUrl,
    );
  }

  @override
  String toString() {
    return 'FirebaseAccount(id: $id, name: $name, displayName: $displayName, projectId: $projectId, isActive: $isActive, isDefault: $isDefault)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FirebaseAccount && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

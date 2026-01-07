import 'package:json_annotation/json_annotation.dart';

part 'driver.g.dart';

@JsonSerializable()
class Driver {
  final int id;
  final String name;
  final String? email;
  final String? phone;
  @JsonKey(name: 'city_name')
  final String? cityName;
  @JsonKey(name: 'photo_url')
  final String? photoUrl;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  @JsonKey(name: 'car_status_id')
  final String? carStatusId; // Adicionado para compatibilidade com a tabela

  Driver({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.cityName,
    this.photoUrl,
    required this.createdAt,
    required this.updatedAt,
    this.carStatusId, // Adicionado para compatibilidade
  });

  factory Driver.fromJson(Map<String, dynamic> json) => _$DriverFromJson(json);
  Map<String, dynamic> toJson() => _$DriverToJson(this);
}

import 'package:json_annotation/json_annotation.dart';

part 'service_type.g.dart';

@JsonSerializable()
class ServiceType {
  final int id;
  final String? name;
  final String? description;
  final String? color;
  final String? icon;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ServiceType({
    required this.id,
    this.name,
    this.description,
    this.color,
    this.icon,
    this.createdAt,
    this.updatedAt,
  });

  factory ServiceType.fromJson(Map<String, dynamic> json) => ServiceType(
    id: json['id'] as int,
    name: json['name'] as String?,
    description: json['description'] as String?,
    color: json['color'] as String?,
    icon: json['icon'] as String?,
    createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
    updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'color': color,
    'icon': icon,
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };
} 

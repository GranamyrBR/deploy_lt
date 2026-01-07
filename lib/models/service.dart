import 'package:json_annotation/json_annotation.dart';

part 'service.g.dart';

@JsonSerializable()
class Service {
  final int id;
  final String? name;
  final String? description;
  final double? price;
  final String? category;
  final int? servicetypeId;
  final bool? isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Service({
    required this.id,
    this.name,
    this.description,
    this.price,
    this.category,
    this.servicetypeId,
    this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory Service.fromJson(Map<String, dynamic> json) => Service(
    id: json['id'] as int,
    name: json['name'] as String?,
    description: json['description'] as String?,
    price: json['price'] != null ? (json['price'] as num).toDouble() : null,
    category: json['category'] as String?,
    servicetypeId: json['servicetype_id'] as int?,
    isActive: json['is_active'] as bool? ?? true,
    createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
    updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'price': price,
    'category': category,
    'servicetype_id': servicetypeId,
    'is_active': isActive,
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };
} 

import 'package:json_annotation/json_annotation.dart';

part 'service_category.g.dart';

@JsonSerializable()
class ServiceCategory {
  final int id;
  final String name;
  final String? description;
  final String? color;
  final String? icon;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ServiceCategory({
    required this.id,
    required this.name,
    this.description,
    this.color,
    this.icon,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ServiceCategory.fromJson(Map<String, dynamic> json) => _$ServiceCategoryFromJson(json);
  Map<String, dynamic> toJson() => _$ServiceCategoryToJson(this);

  ServiceCategory copyWith({
    int? id,
    String? name,
    String? description,
    String? color,
    String? icon,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ServiceCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // As categorias agora vêm do banco de dados, não mais do CSV

  // Categorias predefinidas para uso em formulários
  static List<ServiceCategory> get predefinedCategories => [
    ServiceCategory(
      id: 1,
      name: 'Transporte Aeroporto',
      description: 'Serviços de transporte de/para aeroporto',
      color: '#2196F3',
      icon: 'flight',
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    ServiceCategory(
      id: 2,
      name: 'City Tour',
      description: 'Tours pela cidade',
      color: '#4CAF50',
      icon: 'tour',
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    ServiceCategory(
      id: 3,
      name: 'Transporte Privado',
      description: 'Serviços de transporte privado',
      color: '#FF9800',
      icon: 'directions_car',
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    ServiceCategory(
      id: 4,
      name: 'Excursões',
      description: 'Excursões e passeios',
      color: '#9C27B0',
      icon: 'landscape',
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  // Verificar se é categoria que requer dados de voo
  bool get requiresFlightData => 
    name.toLowerCase().contains('aeroporto') || 
    name.toLowerCase().contains('airport');

  // Verificar se é categoria que requer dados de estação
  bool get requiresStationData => 
    name.toLowerCase().contains('rodoviário') || 
    name.toLowerCase().contains('penn station');

  // Verificar se é categoria de tour
  bool get isTourCategory => 
    name.toLowerCase().contains('tour') || 
    name.toLowerCase().contains('city');

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ServiceCategory && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'ServiceCategory(id: $id, name: $name)';
}

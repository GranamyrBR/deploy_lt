import 'package:json_annotation/json_annotation.dart';

part 'position.g.dart';

@JsonSerializable()
class Position {
  final int id;
  final String name;
  final String? description;
  final String? category;
  @JsonKey(name: 'hierarchy_level')
  final int? hierarchyLevel;
  @JsonKey(name: 'is_active')
  final bool? isActive;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  Position({
    required this.id,
    required this.name,
    this.description,
    this.category,
    this.hierarchyLevel,
    this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory Position.fromJson(Map<String, dynamic> json) => _$PositionFromJson(json);
  Map<String, dynamic> toJson() => _$PositionToJson(this);

  Position copyWith({
    int? id,
    String? name,
    String? description,
    String? category,
    int? hierarchyLevel,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Position(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      hierarchyLevel: hierarchyLevel ?? this.hierarchyLevel,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Getters úteis
  bool get isExecutive => category == 'executive';
  bool get isSales => category == 'sales';
  bool get isOperational => category == 'operational';
  bool get isSupport => category == 'support';
  
  String get categoryDisplayName {
    switch (category) {
      case 'executive': return 'Executivo';
      case 'sales': return 'Vendas';
      case 'operational': return 'Operacional';
      case 'support': return 'Suporte';
      default: return category ?? '';
    }
  }

  String get hierarchyDisplay {
    switch (hierarchyLevel) {
      case 5: return 'Alto Executivo';
      case 4: return 'Executivo';
      case 3: return 'Gerente';
      case 2: return 'Sênior';
      case 1: return 'Júnior';
      default: return 'Nível $hierarchyLevel';
    }
  }
} 

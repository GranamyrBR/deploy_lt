import 'package:json_annotation/json_annotation.dart';

part 'department.g.dart';

@JsonSerializable()
class Department {
  final int id;
  final String name;
  final String? description;
  final String? color;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  @JsonKey(name: 'default_permissions')
  final List<String>? defaultPermissions;

  Department({
    required this.id,
    required this.name,
    this.description,
    this.color,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.defaultPermissions,
  });

  factory Department.fromJson(Map<String, dynamic> json) => _$DepartmentFromJson(json);
  Map<String, dynamic> toJson() => _$DepartmentToJson(this);

  Department copyWith({
    int? id,
    String? name,
    String? description,
    String? color,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? defaultPermissions,
  }) {
    return Department(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      defaultPermissions: defaultPermissions ?? this.defaultPermissions,
    );
  }

  // Getters úteis
  String get displayName {
    switch (name.toLowerCase()) {
      case 'executivo': return 'Executivo';
      case 'vendas': return 'Vendas';
      case 'marketing': return 'Marketing';
      case 'operacional': return 'Operacional';
      case 'suporte': return 'Suporte';
      case 'financeiro': return 'Financeiro';
      case 'rh': return 'RH';
      case 'ti': return 'TI';
      default: return name;
    }
  }

  String get defaultColor {
    return color ?? '#3B82F6'; // Azul padrão
  }

  bool get isExecutive => name.toLowerCase() == 'executivo';
  bool get isSales => name.toLowerCase() == 'vendas';
  bool get isMarketing => name.toLowerCase() == 'marketing';
  bool get isSupport => name.toLowerCase() == 'suporte';
  bool get isFinance => name.toLowerCase() == 'financeiro';
  bool get isIT => name.toLowerCase() == 'ti';
  bool get isHR => name.toLowerCase() == 'rh';
  bool get isOperational => name.toLowerCase() == 'operacional';
} 

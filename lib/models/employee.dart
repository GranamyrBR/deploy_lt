import 'package:json_annotation/json_annotation.dart';

part 'employee.g.dart';

@JsonSerializable()
class Employee {
  final int id;
  final String name;
  final String? email;
  final String? phone;
  final String? whatsapp;
  final String? extension;
  final String position;
  final String department;
  @JsonKey(name: 'hierarchy_level')
  final int hierarchyLevel;
  @JsonKey(name: 'is_primary_contact')
  final bool isPrimaryContact;
  @JsonKey(name: 'is_active')
  final bool isActive;
  final String? notes;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  
  // Campos relacionados (via JOIN)
  @JsonKey(name: 'department_id')
  final int? departmentId;
  @JsonKey(name: 'department_description')
  final String? departmentDescription;
  @JsonKey(name: 'department_color')
  final String? departmentColor;

  Employee({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.whatsapp,
    this.extension,
    required this.position,
    required this.department,
    this.hierarchyLevel = 1,
    this.isPrimaryContact = false,
    this.isActive = true,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.departmentId,
    this.departmentDescription,
    this.departmentColor,
  });

  factory Employee.fromJson(Map<String, dynamic> json) => _$EmployeeFromJson(json);
  Map<String, dynamic> toJson() => _$EmployeeToJson(this);

  Employee copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? whatsapp,
    String? extension,
    String? position,
    String? department,
    int? hierarchyLevel,
    bool? isPrimaryContact,
    bool? isActive,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? departmentId,
    String? departmentDescription,
    String? departmentColor,
  }) {
    return Employee(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      whatsapp: whatsapp ?? this.whatsapp,
      extension: extension ?? this.extension,
      position: position ?? this.position,
      department: department ?? this.department,
      hierarchyLevel: hierarchyLevel ?? this.hierarchyLevel,
      isPrimaryContact: isPrimaryContact ?? this.isPrimaryContact,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      departmentId: departmentId ?? this.departmentId,
      departmentDescription: departmentDescription ?? this.departmentDescription,
      departmentColor: departmentColor ?? this.departmentColor,
    );
  }

  // Getters úteis
  bool get isExecutive => department.toLowerCase() == 'executivo';
  bool get isSales => department.toLowerCase() == 'vendas';
  bool get isMarketing => department.toLowerCase() == 'marketing';
  bool get isSupport => department.toLowerCase() == 'suporte';
  bool get isFinance => department.toLowerCase() == 'financeiro';
  bool get isIT => department.toLowerCase() == 'ti';
  bool get isHR => department.toLowerCase() == 'rh';
  bool get isOperational => department.toLowerCase() == 'operacional';
  
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

  String get departmentDisplayName {
    switch (department.toLowerCase()) {
      case 'executivo': return 'Executivo';
      case 'vendas': return 'Vendas';
      case 'marketing': return 'Marketing';
      case 'operacional': return 'Operacional';
      case 'suporte': return 'Suporte';
      case 'financeiro': return 'Financeiro';
      case 'rh': return 'RH';
      case 'ti': return 'TI';
      default: return department;
    }
  }

  String get displayContact {
    final parts = <String>[];
    if (phone != null && phone!.isNotEmpty) parts.add(phone!);
    if (extension != null && extension!.isNotEmpty) parts.add('Ramal: $extension');
    if (whatsapp != null && whatsapp!.isNotEmpty) parts.add('WhatsApp: $whatsapp');
    return parts.join(' | ');
  }

  String get displayInfo {
    return '$position - $departmentDisplayName';
  }
} 

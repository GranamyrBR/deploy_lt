import 'account_employee.dart';

/// Data Transfer Object for AccountEmployee
/// Used for creating new employees without requiring an ID
class AccountEmployeeDto {
  final int accountId;
  final String name;
  final int positionId;
  final int departmentId;
  final String? email;
  final String? phone;
  final String? whatsapp;
  final String? extension;
  final bool isPrimaryContact;
  final bool isDecisionMaker;
  final int hierarchyLevel;
  final String preferredContactMethod;
  final String? notes;
  final bool isActive;
  final DateTime? updatedAt;

  AccountEmployeeDto({
    required this.accountId,
    required this.name,
    required this.positionId,
    required this.departmentId,
    this.email,
    this.phone,
    this.whatsapp,
    this.extension,
    this.isPrimaryContact = false,
    this.isDecisionMaker = false,
    this.hierarchyLevel = 1,
    this.preferredContactMethod = 'email',
    this.notes,
    this.isActive = true,
    this.updatedAt,
  });

  /// Convert from AccountEmployee model
  factory AccountEmployeeDto.fromAccountEmployee(AccountEmployee employee) {
    return AccountEmployeeDto(
      accountId: employee.accountId,
      name: employee.name,
      positionId: employee.positionId,
      departmentId: employee.departmentId,
      email: employee.email,
      phone: employee.phone,
      whatsapp: employee.whatsapp,
      extension: employee.extension,
      isPrimaryContact: employee.isPrimaryContact,
      isDecisionMaker: employee.isDecisionMaker,
      hierarchyLevel: employee.hierarchyLevel,
      preferredContactMethod: employee.preferredContactMethod,
      notes: employee.notes,
      isActive: employee.isActive,
      updatedAt: employee.updatedAt,
    );
  }

  /// Convert to Map for database operations
  Map<String, dynamic> toMap() {
    return {
      'account_id': accountId,
      'name': name,
      'position_id': positionId,
      'department_id': departmentId,
      'email': email,
      'phone': phone,
      'whatsapp': whatsapp,
      'extension': extension,
      'is_primary_contact': isPrimaryContact,
      'is_decision_maker': isDecisionMaker,
      'hierarchy_level': hierarchyLevel,
      'preferred_contact_method': preferredContactMethod,
      'notes': notes,
      'is_active': isActive,
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Manual JSON serialization
  factory AccountEmployeeDto.fromJson(Map<String, dynamic> json) {
    return AccountEmployeeDto(
      accountId: json['account_id'] as int,
      name: json['name'] as String,
      positionId: json['position_id'] as int,
      departmentId: json['department_id'] as int,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      whatsapp: json['whatsapp'] as String?,
      extension: json['extension'] as String?,
      isPrimaryContact: json['is_primary_contact'] as bool? ?? false,
      isDecisionMaker: json['is_decision_maker'] as bool? ?? false,
      hierarchyLevel: json['hierarchy_level'] as int? ?? 1,
      preferredContactMethod: json['preferred_contact_method'] as String? ?? 'email',
      notes: json['notes'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() => toMap();
}

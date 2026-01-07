import 'package:json_annotation/json_annotation.dart';

part 'account_employee.g.dart';

@JsonSerializable()
class AccountEmployee {
  final int id;
  @JsonKey(name: 'account_id')
  final int accountId;
  final String name;
  @JsonKey(name: 'position_id')
  final int positionId;
  @JsonKey(name: 'department_id')
  final int departmentId;
  final String? email;
  final String? phone;
  final String? whatsapp;
  final String? extension;
  @JsonKey(name: 'is_primary_contact')
  final bool isPrimaryContact;
  @JsonKey(name: 'is_decision_maker')
  final bool isDecisionMaker;
  @JsonKey(name: 'hierarchy_level')
  final int hierarchyLevel;
  @JsonKey(name: 'preferred_contact_method')
  final String preferredContactMethod;
  final String? notes;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  AccountEmployee({
    required this.id,
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
    this.createdAt,
    this.updatedAt,
  });

  factory AccountEmployee.fromJson(Map<String, dynamic> json) => _$AccountEmployeeFromJson(json);
  Map<String, dynamic> toJson() => _$AccountEmployeeToJson(this);
} 

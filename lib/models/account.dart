import 'package:json_annotation/json_annotation.dart';

part 'account.g.dart';

@JsonSerializable()
class Account {
  final int id;
  final String name;
  @JsonKey(name: 'contact_name')
  final String? contactName;
  @JsonKey(name: 'domain')
  final String? domain;
  @JsonKey(name: 'phone')
  final String? phone;
  @JsonKey(name: 'email')
  final String? email;
  @JsonKey(name: 'logo_url')
  final String? logoUrl;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  @JsonKey(name: 'chave_id')
  final int? chaveId;
  @JsonKey(name: 'is_active')
  final bool isActive;
  
  // Novos campos da refatoração conservadora
  @JsonKey(name: 'account_type')
  final String? accountType;
  @JsonKey(name: 'agency_id')
  final int? agencyId;
  @JsonKey(name: 'position_id')
  final int? positionId;
  @JsonKey(name: 'is_primary_contact')
  final bool? isPrimaryContact;
  @JsonKey(name: 'whatsapp')
  final String? whatsapp;
  @JsonKey(name: 'extension')
  final String? extension;

  Account({
    required this.id,
    required this.name,
    this.contactName,
    this.domain,
    this.phone,
    this.email,
    this.logoUrl,
    required this.createdAt,
    required this.updatedAt,
    this.chaveId,
    this.isActive = true,
    this.accountType,
    this.agencyId,
    this.positionId,
    this.isPrimaryContact,
    this.whatsapp,
    this.extension,
  });

  factory Account.fromJson(Map<String, dynamic> json) => _$AccountFromJson(json);
  Map<String, dynamic> toJson() => _$AccountToJson(this);

  Account copyWith({
    int? id,
    String? name,
    String? contactName,
    String? domain,
    String? phone,
    String? email,
    String? logoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? chaveId,
    bool? isActive,
    String? accountType,
    int? agencyId,
    int? positionId,
    bool? isPrimaryContact,
    String? whatsapp,
    String? extension,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      contactName: contactName ?? this.contactName,
      domain: domain ?? this.domain,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      logoUrl: logoUrl ?? this.logoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      chaveId: chaveId ?? this.chaveId,
      isActive: isActive ?? this.isActive,
      accountType: accountType ?? this.accountType,
      agencyId: agencyId ?? this.agencyId,
      positionId: positionId ?? this.positionId,
      isPrimaryContact: isPrimaryContact ?? this.isPrimaryContact,
      whatsapp: whatsapp ?? this.whatsapp,
      extension: extension ?? this.extension,
    );
  }

  // Getters úteis
  bool get isInternalContact => accountType == 'internal';
  bool get isClient => accountType == 'client' || accountType == null;
  bool get isPrimary => isPrimaryContact == true;
} 

import 'package:json_annotation/json_annotation.dart';

part 'contact.g.dart';

// Enum para tipos de usuário
enum UserType {
  normal,
  driver,
  employee,
  agency,
}

@JsonSerializable()
class Contact {
  final int id;
  final String? name;
  final String? email;
  final String? phone;
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  final String? zipCode;
  final String? gender;
  final int? sourceId;
  final String? source;
  @JsonKey(name: 'account_id')
  final int? accountId;
  final String? accountType;
  @JsonKey(name: 'contact_category_id')
  final int? contactCategoryId;
  final String? contactCategory;
  @JsonKey(name: 'is_vip')
  final bool? isVip;
  @JsonKey(name: 'user_type')
  final UserType? userType;
  // account_type_id removido - acessar via account.chave_id -> account_category.account_type
  final bool? isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  // Campos adicionais para compatibilidade com contact_model.dart
  final String? mobile;
  final String? whatsapp;
  final String? cpf;
  final String? passport;
  final String? cep;

  Contact({
    required this.id,
    this.name,
    this.email,
    this.phone,
    this.address,
    this.city,
    this.state,
    this.country,
    this.zipCode,
    this.gender,
    this.sourceId,
    this.source,
    this.accountId,
    this.accountType,
    this.contactCategoryId,
    this.contactCategory,
    this.isVip,
    this.userType,
    this.isActive,
    this.createdAt,
    this.updatedAt,
    this.mobile,
    this.whatsapp,
    this.cpf,
    this.passport,
    this.cep,
  });

  factory Contact.fromJson(Map<String, dynamic> json) => _$ContactFromJson(json);
  Map<String, dynamic> toJson() => _$ContactToJson(this);

  @override
  String toString() {
    return 'Contact(id: $id, name: $name, phone: $phone, email: $email, sourceId: $sourceId, userType: $userType)';
  }

  // Getters para informações relacionadas
  String get vipStatusText => isVip == true ? 'VIP' : 'Regular';
  bool get isVipClient => isVip == true;
  
  // Getters para compatibilidade com código que usa contact_model.dart
  bool get canReceiveEmails => email != null && (isActive ?? true);
  bool get canReceiveWhatsApp => phone != null && (isActive ?? true);
}

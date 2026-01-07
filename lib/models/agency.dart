import 'package:json_annotation/json_annotation.dart';

part 'agency.g.dart';

@JsonSerializable()
class Agency {
  final int id;
  final String name;
  @JsonKey(name: 'legal_name')
  final String? legalName;
  final String? cnpj;
  final String? email;
  final String? phone;
  final String? website;
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  @JsonKey(name: 'postal_code')
  final String? postalCode;
  @JsonKey(name: 'logo_url')
  final String? logoUrl;
  @JsonKey(name: 'commission_rate')
  final double? commissionRate;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  
  // Campos adicionais para compatibilidade
  @JsonKey(name: 'city_name')
  final String? cityName;
  @JsonKey(name: 'state_code')
  final String? stateCode;
  @JsonKey(name: 'country_code')
  final String? countryCode;
  @JsonKey(name: 'zip_code')
  final String? zipCode;
  @JsonKey(name: 'contact_person')
  final String? contactPerson;

  Agency({
    required this.id,
    required this.name,
    this.legalName,
    this.cnpj,
    this.email,
    this.phone,
    this.website,
    this.address,
    this.city,
    this.state,
    this.country,
    this.postalCode,
    this.logoUrl,
    this.commissionRate,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.cityName,
    this.stateCode,
    this.countryCode,
    this.zipCode,
    this.contactPerson,
  });

  factory Agency.fromJson(Map<String, dynamic> json) => _$AgencyFromJson(json);
  Map<String, dynamic> toJson() => _$AgencyToJson(this);

  Agency copyWith({
    int? id,
    String? name,
    String? legalName,
    String? cnpj,
    String? email,
    String? phone,
    String? website,
    String? address,
    String? city,
    String? state,
    String? country,
    String? postalCode,
    String? logoUrl,
    double? commissionRate,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? cityName,
    String? stateCode,
    String? countryCode,
    String? zipCode,
    String? contactPerson,
  }) {
    return Agency(
      id: id ?? this.id,
      name: name ?? this.name,
      legalName: legalName ?? this.legalName,
      cnpj: cnpj ?? this.cnpj,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      website: website ?? this.website,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      postalCode: postalCode ?? this.postalCode,
      logoUrl: logoUrl ?? this.logoUrl,
      commissionRate: commissionRate ?? this.commissionRate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      cityName: cityName ?? this.cityName,
      stateCode: stateCode ?? this.stateCode,
      countryCode: countryCode ?? this.countryCode,
      zipCode: zipCode ?? this.zipCode,
      contactPerson: contactPerson ?? this.contactPerson,
    );
  }

  // Getters úteis
  String get displayName => legalName ?? name;
  String get location => [city, state].where((e) => e != null).join(', ');
  String get fullAddress => [address, city, state, postalCode].where((e) => e != null).join(', ');
} 

import 'package:flutter/foundation.dart';

enum ContactType {
  client,
  agency,
  supplier,
  guide,
  driver,
  other,
}

class Contact {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? mobile;
  final String? whatsapp;
  final String? cpf;
  final String? passport;
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  final String? cep;
  final DateTime? birthDate;
  final ContactType type;
  final String? agencyId;
  final String? notes;
  final bool isActive;
  final bool receiveEmails;
  final bool receiveWhatsApp;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Contact({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.mobile,
    this.whatsapp,
    this.cpf,
    this.passport,
    this.address,
    this.city,
    this.state,
    this.country,
    this.cep,
    this.birthDate,
    required this.type,
    this.agencyId,
    this.notes,
    this.isActive = true,
    this.receiveEmails = true,
    this.receiveWhatsApp = true,
    required this.createdAt,
    this.updatedAt,
  });

  String get displayName {
    if (type == ContactType.client) return name;
    return '$name (${_getTypeDisplayName()})';
  }

  String _getTypeDisplayName() {
    switch (type) {
      case ContactType.client:
        return 'Cliente';
      case ContactType.agency:
        return 'Agência';
      case ContactType.supplier:
        return 'Fornecedor';
      case ContactType.guide:
        return 'Guia';
      case ContactType.driver:
        return 'Motorista';
      case ContactType.other:
        return 'Outro';
    }
  }

  String? get primaryPhone {
    return whatsapp ?? mobile ?? phone;
  }

  String? get primaryEmail {
    return email;
  }

  bool get canReceiveEmails => receiveEmails && email != null && isActive;
  bool get canReceiveWhatsApp => receiveWhatsApp && whatsapp != null && isActive;

  Contact copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? mobile,
    String? whatsapp,
    String? cpf,
    String? passport,
    String? address,
    String? city,
    String? state,
    String? country,
    String? cep,
    DateTime? birthDate,
    ContactType? type,
    String? agencyId,
    String? notes,
    bool? isActive,
    bool? receiveEmails,
    bool? receiveWhatsApp,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Contact(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      mobile: mobile ?? this.mobile,
      whatsapp: whatsapp ?? this.whatsapp,
      cpf: cpf ?? this.cpf,
      passport: passport ?? this.passport,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      cep: cep ?? this.cep,
      birthDate: birthDate ?? this.birthDate,
      type: type ?? this.type,
      agencyId: agencyId ?? this.agencyId,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      receiveEmails: receiveEmails ?? this.receiveEmails,
      receiveWhatsApp: receiveWhatsApp ?? this.receiveWhatsApp,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'mobile': mobile,
      'whatsapp': whatsapp,
      'cpf': cpf,
      'passport': passport,
      'address': address,
      'city': city,
      'state': state,
      'country': country,
      'cep': cep,
      'birthDate': birthDate?.toIso8601String(),
      'type': type.name,
      'agencyId': agencyId,
      'notes': notes,
      'isActive': isActive,
      'receiveEmails': receiveEmails,
      'receiveWhatsApp': receiveWhatsApp,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory Contact.fromMap(Map<String, dynamic> map) {
    return Contact(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      phone: map['phone'],
      mobile: map['mobile'],
      whatsapp: map['whatsapp'],
      cpf: map['cpf'],
      passport: map['passport'],
      address: map['address'],
      city: map['city'],
      state: map['state'],
      country: map['country'],
      cep: map['cep'],
      birthDate: map['birthDate'] != null ? DateTime.parse(map['birthDate']) : null,
      type: ContactType.values.firstWhere((e) => e.name == map['type']),
      agencyId: map['agencyId'],
      notes: map['notes'],
      isActive: map['isActive'] ?? true,
      receiveEmails: map['receiveEmails'] ?? true,
      receiveWhatsApp: map['receiveWhatsApp'] ?? true,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }
}
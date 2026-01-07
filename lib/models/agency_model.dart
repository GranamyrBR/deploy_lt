
class Agency {
  final String id;
  final String name;
  final String? cnpj;
  final String? email;
  final String? phone;
  final String? address;
  final String? city;
  final String? state;
  final String? cep;
  final String? contactPerson;
  final double? commissionRate;
  final String? paymentTerms;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Agency({
    required this.id,
    required this.name,
    this.cnpj,
    this.email,
    this.phone,
    this.address,
    this.city,
    this.state,
    this.cep,
    this.contactPerson,
    this.commissionRate,
    this.paymentTerms,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  Agency copyWith({
    String? id,
    String? name,
    String? cnpj,
    String? email,
    String? phone,
    String? address,
    String? city,
    String? state,
    String? cep,
    String? contactPerson,
    double? commissionRate,
    String? paymentTerms,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Agency(
      id: id ?? this.id,
      name: name ?? this.name,
      cnpj: cnpj ?? this.cnpj,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      cep: cep ?? this.cep,
      contactPerson: contactPerson ?? this.contactPerson,
      commissionRate: commissionRate ?? this.commissionRate,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'cnpj': cnpj,
      'email': email,
      'phone': phone,
      'address': address,
      'city': city,
      'state': state,
      'cep': cep,
      'contactPerson': contactPerson,
      'commissionRate': commissionRate,
      'paymentTerms': paymentTerms,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory Agency.fromMap(Map<String, dynamic> map) {
    return Agency(
      id: map['id'],
      name: map['name'],
      cnpj: map['cnpj'],
      email: map['email'],
      phone: map['phone'],
      address: map['address'],
      city: map['city'],
      state: map['state'],
      cep: map['cep'],
      contactPerson: map['contactPerson'],
      commissionRate: map['commissionRate']?.toDouble(),
      paymentTerms: map['paymentTerms'],
      isActive: map['isActive'] ?? true,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt:
          map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }
}

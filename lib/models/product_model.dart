import 'package:flutter/foundation.dart';

enum ProductType {
  ticket,        // Ingresso
  voucher,       // Vale-presente
  package,       // Pacote
  supplement,    // Suplemento
  insurance,     // Seguro
  fee,           // Taxa
  other,         // Outro
}

enum ProductCategory {
  attraction,    // Atração turística
  show,          // Show/Espectáculo
  museum,        // Museu
  park,          // Parque
  tour,          // Passeio
  transport,     // Transporte
  accommodation, // Hospedagem
  food,          // Alimentação
  other,         // Outro
}

class Product {
  final String id;
  final String name;
  final String description;
  final ProductType type;
  final ProductCategory category;
  final double basePrice;
  final double? commissionRate;
  final String? provider;
  final String? location;
  final String? duration;
  final String? validity; // Validade do produto
  final String? terms;    // Condições de uso
  final bool requiresReservation;
  final int? advanceBookingDays;
  final bool isRefundable;
  final double? refundPercentage;
  final String? notes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.category,
    required this.basePrice,
    this.commissionRate,
    this.provider,
    this.location,
    this.duration,
    this.validity,
    this.terms,
    this.requiresReservation = false,
    this.advanceBookingDays,
    this.isRefundable = true,
    this.refundPercentage,
    this.notes,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  String get displayName {
    return '$name (${_getTypeDisplayName()} - ${_getCategoryDisplayName()})';
  }

  String _getTypeDisplayName() {
    switch (type) {
      case ProductType.ticket:
        return 'Ingresso';
      case ProductType.voucher:
        return 'Vale-presente';
      case ProductType.package:
        return 'Pacote';
      case ProductType.supplement:
        return 'Suplemento';
      case ProductType.insurance:
        return 'Seguro';
      case ProductType.fee:
        return 'Taxa';
      case ProductType.other:
        return 'Outro';
    }
  }

  String _getCategoryDisplayName() {
    switch (category) {
      case ProductCategory.attraction:
        return 'Atração';
      case ProductCategory.show:
        return 'Show';
      case ProductCategory.museum:
        return 'Museu';
      case ProductCategory.park:
        return 'Parque';
      case ProductCategory.tour:
        return 'Passeio';
      case ProductCategory.transport:
        return 'Transporte';
      case ProductCategory.accommodation:
        return 'Hospedagem';
      case ProductCategory.food:
        return 'Alimentação';
      case ProductCategory.other:
        return 'Outro';
    }
  }

  double calculatePrice({double? customCommissionRate}) {
    double price = basePrice;
    
    // Aplicar taxa de comissão se houver
    final commission = customCommissionRate ?? commissionRate ?? 0.0;
    if (commission > 0) {
      price = price + (price * commission / 100);
    }

    return price;
  }

  bool canBeBooked(DateTime bookingDate) {
    if (!requiresReservation) return true;
    if (advanceBookingDays == null) return true;
    
    final advanceDeadline = DateTime.now().add(Duration(days: advanceBookingDays!));
    return bookingDate.isAfter(advanceDeadline) || bookingDate.isAtSameMomentAs(advanceDeadline);
  }

  double calculateRefund(DateTime purchaseDate, DateTime cancellationDate) {
    if (!isRefundable) return 0.0;
    if (refundPercentage == null) return 0.0;
    
    return basePrice * (refundPercentage! / 100);
  }

  Product copyWith({
    String? id,
    String? name,
    String? description,
    ProductType? type,
    ProductCategory? category,
    double? basePrice,
    double? commissionRate,
    String? provider,
    String? location,
    String? duration,
    String? validity,
    String? terms,
    bool? requiresReservation,
    int? advanceBookingDays,
    bool? isRefundable,
    double? refundPercentage,
    String? notes,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      category: category ?? this.category,
      basePrice: basePrice ?? this.basePrice,
      commissionRate: commissionRate ?? this.commissionRate,
      provider: provider ?? this.provider,
      location: location ?? this.location,
      duration: duration ?? this.duration,
      validity: validity ?? this.validity,
      terms: terms ?? this.terms,
      requiresReservation: requiresReservation ?? this.requiresReservation,
      advanceBookingDays: advanceBookingDays ?? this.advanceBookingDays,
      isRefundable: isRefundable ?? this.isRefundable,
      refundPercentage: refundPercentage ?? this.refundPercentage,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.name,
      'category': category.name,
      'basePrice': basePrice,
      'commissionRate': commissionRate,
      'provider': provider,
      'location': location,
      'duration': duration,
      'validity': validity,
      'terms': terms,
      'requiresReservation': requiresReservation,
      'advanceBookingDays': advanceBookingDays,
      'isRefundable': isRefundable,
      'refundPercentage': refundPercentage,
      'notes': notes,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      type: ProductType.values.firstWhere((e) => e.name == map['type']),
      category: ProductCategory.values.firstWhere((e) => e.name == map['category']),
      basePrice: map['basePrice']?.toDouble(),
      commissionRate: map['commissionRate']?.toDouble(),
      provider: map['provider'],
      location: map['location'],
      duration: map['duration'],
      validity: map['validity'],
      terms: map['terms'],
      requiresReservation: map['requiresReservation'] ?? false,
      advanceBookingDays: map['advanceBookingDays'],
      isRefundable: map['isRefundable'] ?? true,
      refundPercentage: map['refundPercentage']?.toDouble(),
      notes: map['notes'],
      isActive: map['isActive'] ?? true,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }
}
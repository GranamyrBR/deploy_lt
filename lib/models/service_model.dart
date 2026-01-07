
enum ServiceType {
  transfer,      // Transfer aeroporto/hotel
  cityTour,      // City tour
  excursion,     // Excursão
  guide,         // Guia de turismo
  transportation, // Transporte
  accommodation, // Hospedagem
  ticket,        // Ingresso
  other,         // Outro
}

enum ServiceCategory {
  regular,       // Regular
  private,       // Privativo
  shared,        // Compartilhado
  vip,           // VIP
}

class Service {
  final String id;
  final String name;
  final String description;
  final ServiceType type;
  final ServiceCategory category;
  final double basePrice;
  final double? commissionRate;
  final String? duration;
  final String? includes;
  final String? excludes;
  final String? notes;
  final bool isActive;
  final int? minPassengers;
  final int? maxPassengers;
  final bool requiresAdvanceBooking;
  final int? advanceBookingDays;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Service({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.category,
    required this.basePrice,
    this.commissionRate,
    this.duration,
    this.includes,
    this.excludes,
    this.notes,
    this.isActive = true,
    this.minPassengers,
    this.maxPassengers,
    this.requiresAdvanceBooking = false,
    this.advanceBookingDays,
    required this.createdAt,
    this.updatedAt,
  });

  String get displayName {
    return '$name (${_getTypeDisplayName()} - ${_getCategoryDisplayName()})';
  }

  String _getTypeDisplayName() {
    switch (type) {
      case ServiceType.transfer:
        return 'Transfer';
      case ServiceType.cityTour:
        return 'City Tour';
      case ServiceType.excursion:
        return 'Excursão';
      case ServiceType.guide:
        return 'Guia';
      case ServiceType.transportation:
        return 'Transporte';
      case ServiceType.accommodation:
        return 'Hospedagem';
      case ServiceType.ticket:
        return 'Ingresso';
      case ServiceType.other:
        return 'Outro';
    }
  }

  String _getCategoryDisplayName() {
    switch (category) {
      case ServiceCategory.regular:
        return 'Regular';
      case ServiceCategory.private:
        return 'Privativo';
      case ServiceCategory.shared:
        return 'Compartilhado';
      case ServiceCategory.vip:
        return 'VIP';
    }
  }

  double calculatePrice(int passengers, {double? customCommissionRate}) {
    double price = basePrice;
    
    // Aplicar taxa de comissão se houver
    final commission = customCommissionRate ?? commissionRate ?? 0.0;
    if (commission > 0) {
      price = price + (price * commission / 100);
    }

    return price;
  }

  bool isAvailableForPassengers(int passengers) {
    if (minPassengers != null && passengers < minPassengers!) return false;
    if (maxPassengers != null && passengers > maxPassengers!) return false;
    return true;
  }

  bool canBeBooked(DateTime bookingDate) {
    if (!requiresAdvanceBooking) return true;
    if (advanceBookingDays == null) return true;
    
    final advanceDeadline = DateTime.now().add(Duration(days: advanceBookingDays!));
    return bookingDate.isAfter(advanceDeadline) || bookingDate.isAtSameMomentAs(advanceDeadline);
  }

  Service copyWith({
    String? id,
    String? name,
    String? description,
    ServiceType? type,
    ServiceCategory? category,
    double? basePrice,
    double? commissionRate,
    String? duration,
    String? includes,
    String? excludes,
    String? notes,
    bool? isActive,
    int? minPassengers,
    int? maxPassengers,
    bool? requiresAdvanceBooking,
    int? advanceBookingDays,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Service(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      category: category ?? this.category,
      basePrice: basePrice ?? this.basePrice,
      commissionRate: commissionRate ?? this.commissionRate,
      duration: duration ?? this.duration,
      includes: includes ?? this.includes,
      excludes: excludes ?? this.excludes,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      minPassengers: minPassengers ?? this.minPassengers,
      maxPassengers: maxPassengers ?? this.maxPassengers,
      requiresAdvanceBooking: requiresAdvanceBooking ?? this.requiresAdvanceBooking,
      advanceBookingDays: advanceBookingDays ?? this.advanceBookingDays,
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
      'duration': duration,
      'includes': includes,
      'excludes': excludes,
      'notes': notes,
      'isActive': isActive,
      'minPassengers': minPassengers,
      'maxPassengers': maxPassengers,
      'requiresAdvanceBooking': requiresAdvanceBooking,
      'advanceBookingDays': advanceBookingDays,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory Service.fromMap(Map<String, dynamic> map) {
    return Service(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      type: ServiceType.values.firstWhere((e) => e.name == map['type']),
      category: ServiceCategory.values.firstWhere((e) => e.name == map['category']),
      basePrice: map['basePrice']?.toDouble(),
      commissionRate: map['commissionRate']?.toDouble(),
      duration: map['duration'],
      includes: map['includes'],
      excludes: map['excludes'],
      notes: map['notes'],
      isActive: map['isActive'] ?? true,
      minPassengers: map['minPassengers'],
      maxPassengers: map['maxPassengers'],
      requiresAdvanceBooking: map['requiresAdvanceBooking'] ?? false,
      advanceBookingDays: map['advanceBookingDays'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }
}
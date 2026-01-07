import 'package:flutter/foundation.dart';
import 'contact.dart';
import 'agency_model.dart';
import 'service_model.dart';
import 'product_model.dart';
import 'service.dart' as db;
import 'product.dart' as dbp;

enum QuotationType {
  tourism,       // Turismo
  corporate,     // Corporativo
  event,         // Evento
  transfer,      // Transfer
  other,         // Outro
}

enum QuotationStatus {
  draft,         // Rascunho
  sent,          // Enviado
  viewed,        // Visualizado
  accepted,      // Aceito
  rejected,      // Rejeitado
  expired,       // Expirado
  cancelled,     // Cancelado
}

class QuotationItem {
  final String id;
  final String description;
  final DateTime date;
  final double value;
  final String category; // 'service', 'product', 'ticket', 'fee'
  final String? serviceId;
  final String? productId;
  final int quantity;
  final double? discount;
  final String? notes;
  final DateTime? startTime;
  final DateTime? endTime;
  final String? location;
  final String? provider;

  QuotationItem({
    required this.id,
    required this.description,
    required this.date,
    required this.value,
    required this.category,
    this.serviceId,
    this.productId,
    this.quantity = 1,
    this.discount,
    this.notes,
    this.startTime,
    this.endTime,
    this.location,
    this.provider,
  });

  double get totalValue {
    double itemTotal = value * quantity;
    if (discount != null && discount! > 0) {
      itemTotal = itemTotal - (itemTotal * discount! / 100);
    }
    return itemTotal;
  }

  double get discountAmount {
    if (discount == null || discount == 0) return 0;
    return (value * quantity) * (discount! / 100);
  }

  QuotationItem copyWith({
    String? id,
    String? description,
    DateTime? date,
    double? value,
    String? category,
    String? serviceId,
    String? productId,
    int? quantity,
    double? discount,
    String? notes,
    DateTime? startTime,
    DateTime? endTime,
    String? location,
    String? provider,
  }) {
    return QuotationItem(
      id: id ?? this.id,
      description: description ?? this.description,
      date: date ?? this.date,
      value: value ?? this.value,
      category: category ?? this.category,
      serviceId: serviceId ?? this.serviceId,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      discount: discount ?? this.discount,
      notes: notes ?? this.notes,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      provider: provider ?? this.provider,
    );
  }

  factory QuotationItem.fromJson(Map<String, dynamic> json) {
    return QuotationItem(
      id: json['id']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      date: json['date'] != null 
        ? DateTime.parse(json['date'].toString())
        : DateTime.now(),
      value: json['value'] != null ? (json['value'] as num).toDouble() : 0.0,
      category: json['category']?.toString() ?? 'service',
      serviceId: json['service_id']?.toString() ?? json['serviceId']?.toString(),
      productId: json['product_id']?.toString() ?? json['productId']?.toString(),
      quantity: json['quantity'] ?? 1,
      discount: json['discount'] != null ? (json['discount'] as num).toDouble() : null,
      notes: json['notes']?.toString(),
      startTime: json['start_time'] != null 
        ? DateTime.parse(json['start_time'].toString())
        : json['startTime'] != null
          ? DateTime.parse(json['startTime'].toString())
          : null,
      endTime: json['end_time'] != null 
        ? DateTime.parse(json['end_time'].toString())
        : json['endTime'] != null
          ? DateTime.parse(json['endTime'].toString())
          : null,
      location: json['location']?.toString(),
      provider: json['provider']?.toString(),
    );
  }

  factory QuotationItem.fromService(Service service, {
    required DateTime date,
    int quantity = 1,
    double? customPrice,
    double? discount,
    String? notes,
  }) {
    return QuotationItem(
      id: 'service_${service.id}_${DateTime.now().millisecondsSinceEpoch}',
      description: service.name,
      date: date,
      value: customPrice ?? service.basePrice,
      category: 'service',
      serviceId: service.id,
      quantity: quantity,
      discount: discount,
      notes: notes ?? service.description,
      provider: null, // Service doesn't have provider field
    );
  }

  factory QuotationItem.fromDbService(db.Service service, {
    required DateTime date,
    int quantity = 1,
    double? customPrice,
    double? discount,
    String? notes,
  }) {
    return QuotationItem(
      id: 'service_${service.id}_${DateTime.now().millisecondsSinceEpoch}',
      description: service.name ?? 'Serviço',
      date: date,
      value: customPrice ?? (service.price ?? 0.0),
      category: 'service',
      serviceId: service.id.toString(),
      quantity: quantity,
      discount: discount,
      notes: notes ?? (service.description ?? ''),
      provider: null,
    );
  }

  factory QuotationItem.fromProduct(Product product, {
    required DateTime date,
    int quantity = 1,
    double? customPrice,
    double? discount,
    String? notes,
  }) {
    return QuotationItem(
      id: 'product_${product.id}_${DateTime.now().millisecondsSinceEpoch}',
      description: product.name,
      date: date,
      value: customPrice ?? product.calculatePrice(),
      category: 'product',
      productId: product.id,
      quantity: quantity,
      discount: discount,
      notes: notes ?? product.description,
      provider: product.provider,
      location: product.location,
    );
  }

  factory QuotationItem.fromDbProduct(dbp.Product product, {
    required DateTime date,
    int quantity = 1,
    double? customPrice,
    double? discount,
    String? notes,
  }) {
    return QuotationItem(
      id: 'product_${product.productId}_${DateTime.now().millisecondsSinceEpoch}',
      description: product.name,
      date: date,
      value: customPrice ?? product.pricePerUnit,
      category: 'product',
      productId: product.productId.toString(),
      quantity: quantity,
      discount: discount,
      notes: notes ?? product.description,
      provider: null,
      location: null,
    );
  }
}

class Quotation {
  final String id;
  final String quotationNumber;
  final QuotationType type;
  final QuotationStatus status;
  
  // Client Information
  final String clientName;
  final String clientEmail;
  final String? clientPhone;
  final String? clientDocument;
  final Contact? clientContact;
  
  // Agency Information
  final Agency? agency;
  final double? agencyCommissionRate;
  
  // Trip Details
  final DateTime travelDate;
  final DateTime? returnDate;
  final int passengerCount;
  final String? origin;
  final String? destination;
  
  // Accommodation
  final String? hotel;
  final String? roomType;
  final int? nights;
  
  // Transportation
  final String? vehicle;
  final String? driver;
  
  // Dates
  final DateTime quotationDate;
  final DateTime? expirationDate;
  final DateTime? sentDate;
  final DateTime? viewedDate;
  final DateTime? acceptedDate;
  final DateTime? rejectedDate;
  
  // Items and Pricing
  final List<QuotationItem> items;
  final double subtotal;
  final double discountAmount;
  final double taxRate;
  final double taxAmount;
  final double total;
  final String currency;
  
  // Additional Information
  final String? notes;
  final String? specialRequests;
  final String? cancellationPolicy;
  final String? paymentTerms;
  
  // System
  final String createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Quotation({
    required this.id,
    required this.quotationNumber,
    required this.type,
    required this.status,
    required this.clientName,
    required this.clientEmail,
    this.clientPhone,
    this.clientDocument,
    this.clientContact,
    this.agency,
    this.agencyCommissionRate,
    required this.travelDate,
    this.returnDate,
    required this.passengerCount,
    this.origin,
    this.destination,
    this.hotel,
    this.roomType,
    this.nights,
    this.vehicle,
    this.driver,
    required this.quotationDate,
    this.expirationDate,
    this.sentDate,
    this.viewedDate,
    this.acceptedDate,
    this.rejectedDate,
    required this.items,
    required this.subtotal,
    this.discountAmount = 0.0,
    required this.taxRate,
    required this.taxAmount,
    required this.total,
    this.currency = 'USD',
    this.notes,
    this.specialRequests,
    this.cancellationPolicy,
    this.paymentTerms,
    required this.createdBy,
    required this.createdAt,
    this.updatedAt,
  });

  String get formattedTotal {
    return '$currency ${total.toStringAsFixed(2)}';
  }

  String get formattedSubtotal {
    return '$currency ${subtotal.toStringAsFixed(2)}';
  }

  String get formattedTax {
    return '$currency ${taxAmount.toStringAsFixed(2)}';
  }

  String get formattedDiscount {
    return '$currency ${discountAmount.toStringAsFixed(2)}';
  }

  String get statusDisplayName {
    switch (status) {
      case QuotationStatus.draft:
        return 'Rascunho';
      case QuotationStatus.sent:
        return 'Enviado';
      case QuotationStatus.viewed:
        return 'Visualizado';
      case QuotationStatus.accepted:
        return 'Aceito';
      case QuotationStatus.rejected:
        return 'Rejeitado';
      case QuotationStatus.expired:
        return 'Expirado';
      case QuotationStatus.cancelled:
        return 'Cancelado';
    }
  }

  String get typeDisplayName {
    switch (type) {
      case QuotationType.tourism:
        return 'Turismo';
      case QuotationType.corporate:
        return 'Corporativo';
      case QuotationType.event:
        return 'Evento';
      case QuotationType.transfer:
        return 'Transfer';
      case QuotationType.other:
        return 'Outro';
    }
  }

  bool get isExpired {
    if (expirationDate == null) return false;
    return DateTime.now().isAfter(expirationDate!);
  }

  double get agencyCommission {
    if (agency == null || agencyCommissionRate == null) return 0.0;
    return subtotal * (agencyCommissionRate! / 100);
  }

  Quotation copyWith({
    String? id,
    String? quotationNumber,
    QuotationType? type,
    QuotationStatus? status,
    String? clientName,
    String? clientEmail,
    String? clientPhone,
    String? clientDocument,
    Contact? clientContact,
    Agency? agency,
    double? agencyCommissionRate,
    DateTime? travelDate,
    DateTime? returnDate,
    int? passengerCount,
    String? origin,
    String? destination,
    String? hotel,
    String? roomType,
    int? nights,
    String? vehicle,
    String? driver,
    DateTime? quotationDate,
    DateTime? expirationDate,
    DateTime? sentDate,
    DateTime? viewedDate,
    DateTime? acceptedDate,
    DateTime? rejectedDate,
    List<QuotationItem>? items,
    double? subtotal,
    double? discountAmount,
    double? taxRate,
    double? taxAmount,
    double? total,
    String? currency,
    String? notes,
    String? specialRequests,
    String? cancellationPolicy,
    String? paymentTerms,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Quotation(
      id: id ?? this.id,
      quotationNumber: quotationNumber ?? this.quotationNumber,
      type: type ?? this.type,
      status: status ?? this.status,
      clientName: clientName ?? this.clientName,
      clientEmail: clientEmail ?? this.clientEmail,
      clientPhone: clientPhone ?? this.clientPhone,
      clientDocument: clientDocument ?? this.clientDocument,
      clientContact: clientContact ?? this.clientContact,
      agency: agency ?? this.agency,
      agencyCommissionRate: agencyCommissionRate ?? this.agencyCommissionRate,
      travelDate: travelDate ?? this.travelDate,
      returnDate: returnDate ?? this.returnDate,
      passengerCount: passengerCount ?? this.passengerCount,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      hotel: hotel ?? this.hotel,
      roomType: roomType ?? this.roomType,
      nights: nights ?? this.nights,
      vehicle: vehicle ?? this.vehicle,
      driver: driver ?? this.driver,
      quotationDate: quotationDate ?? this.quotationDate,
      expirationDate: expirationDate ?? this.expirationDate,
      sentDate: sentDate ?? this.sentDate,
      viewedDate: viewedDate ?? this.viewedDate,
      acceptedDate: acceptedDate ?? this.acceptedDate,
      rejectedDate: rejectedDate ?? this.rejectedDate,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      discountAmount: discountAmount ?? this.discountAmount,
      taxRate: taxRate ?? this.taxRate,
      taxAmount: taxAmount ?? this.taxAmount,
      total: total ?? this.total,
      currency: currency ?? this.currency,
      notes: notes ?? this.notes,
      specialRequests: specialRequests ?? this.specialRequests,
      cancellationPolicy: cancellationPolicy ?? this.cancellationPolicy,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Quotation.fromJson(Map<String, dynamic> json) {
    return Quotation(
      id: json['id']?.toString() ?? '',
      quotationNumber: json['quotation_number']?.toString() ?? json['quotationNumber']?.toString() ?? '',
      type: QuotationType.values.firstWhere(
        (e) => e.name == (json['type'] ?? 'tourism'),
        orElse: () => QuotationType.tourism,
      ),
      status: QuotationStatus.values.firstWhere(
        (e) => e.name == (json['status'] ?? 'draft'),
        orElse: () => QuotationStatus.draft,
      ),
      clientName: json['client_name']?.toString() ?? json['clientName']?.toString() ?? '',
      clientEmail: json['client_email']?.toString() ?? json['clientEmail']?.toString() ?? '',
      clientPhone: json['client_phone']?.toString() ?? json['clientPhone']?.toString(),
      clientDocument: json['client_document']?.toString() ?? json['clientDocument']?.toString(),
      clientContact: null, // TODO: Parse Contact if needed
      agency: null, // TODO: Parse Agency if needed
      agencyCommissionRate: json['agency_commission_rate'] != null 
        ? (json['agency_commission_rate'] as num).toDouble()
        : json['agencyCommissionRate'] != null
          ? (json['agencyCommissionRate'] as num).toDouble()
          : null,
      travelDate: json['travel_date'] != null 
        ? DateTime.parse(json['travel_date'].toString())
        : json['travelDate'] != null
          ? DateTime.parse(json['travelDate'].toString())
          : DateTime.now(),
      returnDate: json['return_date'] != null 
        ? DateTime.parse(json['return_date'].toString())
        : json['returnDate'] != null
          ? DateTime.parse(json['returnDate'].toString())
          : null,
      passengerCount: json['passenger_count'] ?? json['passengerCount'] ?? 1,
      origin: json['origin']?.toString(),
      destination: json['destination']?.toString(),
      hotel: json['hotel']?.toString(),
      roomType: json['room_type']?.toString() ?? json['roomType']?.toString(),
      nights: json['nights'],
      vehicle: json['vehicle']?.toString(),
      driver: json['driver']?.toString(),
      quotationDate: json['quotation_date'] != null 
        ? DateTime.parse(json['quotation_date'].toString())
        : json['quotationDate'] != null
          ? DateTime.parse(json['quotationDate'].toString())
          : DateTime.now(),
      expirationDate: json['expiration_date'] != null 
        ? DateTime.parse(json['expiration_date'].toString())
        : json['expirationDate'] != null
          ? DateTime.parse(json['expirationDate'].toString())
          : null,
      sentDate: json['sent_date'] != null 
        ? DateTime.parse(json['sent_date'].toString())
        : json['sentDate'] != null
          ? DateTime.parse(json['sentDate'].toString())
          : null,
      viewedDate: json['viewed_date'] != null 
        ? DateTime.parse(json['viewed_date'].toString())
        : json['viewedDate'] != null
          ? DateTime.parse(json['viewedDate'].toString())
          : null,
      acceptedDate: json['accepted_date'] != null 
        ? DateTime.parse(json['accepted_date'].toString())
        : json['acceptedDate'] != null
          ? DateTime.parse(json['acceptedDate'].toString())
          : null,
      rejectedDate: json['rejected_date'] != null 
        ? DateTime.parse(json['rejected_date'].toString())
        : json['rejectedDate'] != null
          ? DateTime.parse(json['rejectedDate'].toString())
          : null,
      items: json['items'] != null 
        ? (json['items'] as List).map((item) => QuotationItem.fromJson(Map<String, dynamic>.from(item))).toList()
        : [],
      subtotal: json['subtotal'] != null ? (json['subtotal'] as num).toDouble() : 0.0,
      discountAmount: json['discount_amount'] != null 
        ? (json['discount_amount'] as num).toDouble()
        : json['discountAmount'] != null
          ? (json['discountAmount'] as num).toDouble()
          : 0.0,
      taxRate: json['tax_rate'] != null 
        ? (json['tax_rate'] as num).toDouble()
        : json['taxRate'] != null
          ? (json['taxRate'] as num).toDouble()
          : 0.0,
      taxAmount: json['tax_amount'] != null 
        ? (json['tax_amount'] as num).toDouble()
        : json['taxAmount'] != null
          ? (json['taxAmount'] as num).toDouble()
          : 0.0,
      total: json['total'] != null ? (json['total'] as num).toDouble() : 0.0,
      currency: json['currency']?.toString() ?? 'USD',
      notes: json['notes']?.toString(),
      specialRequests: json['special_requests']?.toString() ?? json['specialRequests']?.toString(),
      cancellationPolicy: json['cancellation_policy']?.toString() ?? json['cancellationPolicy']?.toString(),
      paymentTerms: json['payment_terms']?.toString() ?? json['paymentTerms']?.toString(),
      createdBy: json['created_by']?.toString() ?? json['createdBy']?.toString() ?? 'system',
      createdAt: json['created_at'] != null 
        ? DateTime.parse(json['created_at'].toString())
        : json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
        ? DateTime.parse(json['updated_at'].toString())
        : json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'].toString())
          : null,
    );
  }

  factory Quotation.fromKanbanData({
    required String id,
    required String quotationNumber,
    required String clientName,
    required String clientEmail,
    String? clientPhone,
    Contact? clientContact,
    Agency? agency,
    double? agencyCommissionRate,
    required DateTime travelDate,
    DateTime? returnDate,
    int passengerCount = 1,
    String? hotel,
    String? roomType,
    String? vehicle,
    String? destination,
    String? origin,
    required List<QuotationItem> items,
    double taxRate = 0.0,
    String createdBy = 'system',
    String? notes,
    String? specialRequests,
  }) {
    final subtotal = items.fold(0.0, (sum, item) => sum + item.totalValue);
    final discountAmount = items.fold(0.0, (sum, item) => sum + item.discountAmount);
    final taxAmount = subtotal * (taxRate / 100);
    final total = subtotal + taxAmount;

    return Quotation(
      id: id,
      quotationNumber: quotationNumber,
      type: QuotationType.tourism,
      status: QuotationStatus.draft,
      clientName: clientName,
      clientEmail: clientEmail,
      clientPhone: clientPhone,
      clientContact: clientContact,
      agency: agency,
      agencyCommissionRate: agencyCommissionRate,
      travelDate: travelDate,
      returnDate: returnDate,
      passengerCount: passengerCount,
      hotel: hotel,
      roomType: roomType,
      vehicle: vehicle,
      destination: destination,
      origin: origin,
      items: items,
      subtotal: subtotal,
      discountAmount: discountAmount,
      taxRate: taxRate,
      taxAmount: taxAmount,
      total: total,
      quotationDate: DateTime.now(),
      expirationDate: DateTime.now().add(const Duration(days: 7)),
      notes: notes,
      specialRequests: specialRequests,
      cancellationPolicy: 'Cancelamento gratuito até 7 dias antes da viagem. Após esse período, será cobrada taxa de 50%.',
      paymentTerms: '50% na confirmação, 50% até 7 dias antes da viagem.',
      createdBy: createdBy,
      createdAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'quotationNumber': quotationNumber,
      'type': type.name,
      'status': status.name,
      'clientName': clientName,
      'clientEmail': clientEmail,
      'clientPhone': clientPhone,
      'clientDocument': clientDocument, // ✅ REATIVADO - será adicionado no banco via migration
      'clientContact': clientContact?.id, // Apenas o ID, não o objeto completo
      'agency': agency?.toMap(),
      'agencyCommissionRate': agencyCommissionRate,
      'travelDate': travelDate.toIso8601String(),
      'returnDate': returnDate?.toIso8601String(),
      'passengerCount': passengerCount,
      'origin': origin,
      'destination': destination,
      'hotel': hotel,
      'roomType': roomType,
      'nights': nights,
      'vehicle': vehicle,
      'driver': driver,
      'quotationDate': quotationDate.toIso8601String(),
      'expirationDate': expirationDate?.toIso8601String(),
      'sentDate': sentDate?.toIso8601String(),
      'viewedDate': viewedDate?.toIso8601String(),
      'acceptedDate': acceptedDate?.toIso8601String(),
      'rejectedDate': rejectedDate?.toIso8601String(),
      'items': items.map((item) => {
        'id': item.id,
        'description': item.description,
        'date': item.date.toIso8601String(),
        'value': item.value,
        'category': item.category,
        'serviceId': item.serviceId,
        'productId': item.productId,
        'quantity': item.quantity,
        'discount': item.discount,
        'notes': item.notes,
        'startTime': item.startTime?.toIso8601String(),
        'endTime': item.endTime?.toIso8601String(),
        'location': item.location,
        'provider': item.provider,
      }).toList(),
      'subtotal': subtotal,
      'discountAmount': discountAmount,
      'taxRate': taxRate,
      'taxAmount': taxAmount,
      'total': total,
      'currency': currency,
      'notes': notes,
      'specialRequests': specialRequests,
      'cancellationPolicy': cancellationPolicy,
      'paymentTerms': paymentTerms,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
import 'package:flutter/foundation.dart';

class QuotationItem {
  final String id;
  final String description;
  final DateTime date;
  final double value;
  final String category; // 'service' ou 'ticket'
  final String? notes;

  QuotationItem({
    required this.id,
    required this.description,
    required this.date,
    required this.value,
    required this.category,
    this.notes,
  });

  QuotationItem copyWith({
    String? id,
    String? description,
    DateTime? date,
    double? value,
    String? category,
    String? notes,
  }) {
    return QuotationItem(
      id: id ?? this.id,
      description: description ?? this.description,
      date: date ?? this.date,
      value: value ?? this.value,
      category: category ?? this.category,
      notes: notes ?? this.notes,
    );
  }
}

class Quotation {
  final String id;
  final String clientName;
  final String clientEmail;
  final String? clientPhone;
  final DateTime quotationDate;
  final DateTime? expirationDate;
  final String baseDescription;
  final String hotel;
  final String vehicle;
  final int passengerCount;
  final List<QuotationItem> items;
  final double subtotal;
  final double taxRate;
  final double total;
  final String status; // 'draft', 'sent', 'accepted', 'rejected'
  final String? notes;
  final DateTime? sentDate;
  final DateTime? acceptedDate;

  Quotation({
    required this.id,
    required this.clientName,
    required this.clientEmail,
    this.clientPhone,
    required this.quotationDate,
    this.expirationDate,
    required this.baseDescription,
    required this.hotel,
    required this.vehicle,
    required this.passengerCount,
    required this.items,
    required this.subtotal,
    required this.taxRate,
    required this.total,
    this.status = 'draft',
    this.notes,
    this.sentDate,
    this.acceptedDate,
  });

  double get taxAmount => subtotal * (taxRate / 100);

  String get formattedTotal {
    return 'USD ${total.toStringAsFixed(2)}';
  }

  String get formattedSubtotal {
    return 'USD ${subtotal.toStringAsFixed(2)}';
  }

  String get formattedTax {
    return 'USD ${taxAmount.toStringAsFixed(2)}';
  }

  Quotation copyWith({
    String? id,
    String? clientName,
    String? clientEmail,
    String? clientPhone,
    DateTime? quotationDate,
    DateTime? expirationDate,
    String? baseDescription,
    String? hotel,
    String? vehicle,
    int? passengerCount,
    List<QuotationItem>? items,
    double? subtotal,
    double? taxRate,
    double? total,
    String? status,
    String? notes,
    DateTime? sentDate,
    DateTime? acceptedDate,
  }) {
    return Quotation(
      id: id ?? this.id,
      clientName: clientName ?? this.clientName,
      clientEmail: clientEmail ?? this.clientEmail,
      clientPhone: clientPhone ?? this.clientPhone,
      quotationDate: quotationDate ?? this.quotationDate,
      expirationDate: expirationDate ?? this.expirationDate,
      baseDescription: baseDescription ?? this.baseDescription,
      hotel: hotel ?? this.hotel,
      vehicle: vehicle ?? this.vehicle,
      passengerCount: passengerCount ?? this.passengerCount,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      taxRate: taxRate ?? this.taxRate,
      total: total ?? this.total,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      sentDate: sentDate ?? this.sentDate,
      acceptedDate: acceptedDate ?? this.acceptedDate,
    );
  }

  factory Quotation.fromKanbanData({
    required String id,
    required String clientName,
    required String clientEmail,
    String? clientPhone,
    required BoardItem kanbanItem,
    List<QuotationItem>? additionalItems,
    double taxRate = 0.0,
  }) {
    final items = <QuotationItem>[
      QuotationItem(
        id: '1',
        description: kanbanItem.title,
        date: DateTime.now(),
        value: kanbanItem.value,
        category: 'service',
        notes: kanbanItem.subtitle,
      ),
      if (additionalItems != null) ...additionalItems,
    ];

    final subtotal = items.fold(0.0, (sum, item) => sum + item.value);
    final total = subtotal + (subtotal * (taxRate / 100));

    return Quotation(
      id: id,
      clientName: clientName,
      clientEmail: clientEmail,
      clientPhone: clientPhone,
      quotationDate: DateTime.now(),
      expirationDate: DateTime.now().add(const Duration(days: 7)),
      baseDescription: 'Serviços de transporte turístico',
      hotel: 'A ser definido',
      vehicle: 'Van executiva',
      passengerCount: 1,
      items: items,
      subtotal: subtotal,
      taxRate: taxRate,
      total: total,
      status: 'draft',
    );
  }
}

class ChartData {
  final String category;
  final double value;
  final Color color;

  ChartData(this.category, this.value, this.color);
}

import 'package:json_annotation/json_annotation.dart';

part 'invoice.g.dart';

@JsonSerializable()
class Invoice {
  final int id;
  final String invoiceNumber;
  final int contactServiceId;
  final String contactName;
  final String serviceName;
  final double totalAmount;
  final double discountAmount;
  final double commissionAmount;
  final double netAmount;
  final String currency;
  final String status; // 'draft', 'sent', 'paid', 'overdue', 'cancelled'
  final String? paymentMethod;
  final DateTime? dueDate;
  final DateTime? paidAt;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.contactServiceId,
    required this.contactName,
    required this.serviceName,
    required this.totalAmount,
    this.discountAmount = 0.0,
    this.commissionAmount = 0.0,
    required this.netAmount,
    this.currency = 'BRL',
    this.status = 'draft',
    this.paymentMethod,
    this.dueDate,
    this.paidAt,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) => _$InvoiceFromJson(json);
  Map<String, dynamic> toJson() => _$InvoiceToJson(this);

  // Helper methods
  bool get isPaid => status == 'paid';
  bool get isOverdue => status == 'overdue' || (dueDate != null && dueDate!.isBefore(DateTime.now()) && !isPaid);
  bool get isDraft => status == 'draft';
  bool get isSent => status == 'sent';
  bool get isCancelled => status == 'cancelled';
  
  String get statusDisplay {
    switch (status) {
      case 'draft':
        return 'Rascunho';
      case 'sent':
        return 'Enviada';
      case 'paid':
        return 'Paga';
      case 'overdue':
        return 'Vencida';
      case 'cancelled':
        return 'Cancelada';
      default:
        return 'Desconhecido';
    }
  }
} 

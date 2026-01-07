import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

part 'provisional_invoice.g.dart';

@JsonSerializable()
class ProvisionalInvoice {
  final int id;
  final int accountId;
  final String accountName;
  final String contactName;
  final String serviceName;
  final String invoiceNumber;
  final DateTime issueDate;
  final DateTime? dueDate;
  final double totalAmount;
  final double discountAmount;
  final double netAmount;
  final int currencyId;
  final String currencyCode;
  final String? termsAndConditions;
  final String status; // 'Pending', 'Approved', 'Rejected', 'Converted'
  final int? convertedToSaleId;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Multi-moeda
  final double? exchangeRateToUsd;
  final double? totalAmountInBrl;
  final double? totalAmountInUsd;

  ProvisionalInvoice({
    required this.id,
    required this.accountId,
    required this.accountName,
    required this.contactName,
    required this.serviceName,
    required this.invoiceNumber,
    required this.issueDate,
    this.dueDate,
    required this.totalAmount,
    required this.discountAmount,
    required this.netAmount,
    required this.currencyId,
    required this.currencyCode,
    this.termsAndConditions,
    required this.status,
    this.convertedToSaleId,
    required this.createdAt,
    required this.updatedAt,
    this.exchangeRateToUsd,
    this.totalAmountInBrl,
    this.totalAmountInUsd,
  });

  factory ProvisionalInvoice.fromJson(Map<String, dynamic> json) => _$ProvisionalInvoiceFromJson(json);
  Map<String, dynamic> toJson() => _$ProvisionalInvoiceToJson(this);

  // Helper methods
  bool get isConverted => convertedToSaleId != null;
  bool get isOverdue => dueDate != null && dueDate!.isBefore(DateTime.now()) && status != 'Converted';
  bool get isPending => status == 'Pending';
  bool get isApproved => status == 'Approved';
  bool get isRejected => status == 'Rejected';

  String get statusDisplay {
    switch (status) {
      case 'Pending':
        return 'Pendente';
      case 'Approved':
        return 'Aprovada';
      case 'Rejected':
        return 'Rejeitada';
      case 'Converted':
        return 'Convertida';
      default:
        return status;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Approved':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      case 'Converted':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  // Formatação de valores
  String get totalAmountFormatted {
    if (currencyCode == 'BRL') {
      return 'R\$ ${totalAmount.toStringAsFixed(2)}';
    } else if (currencyCode == 'USD') {
      return 'US\$ ${totalAmount.toStringAsFixed(2)}';
    } else {
      return '${totalAmount.toStringAsFixed(2)} $currencyCode';
    }
  }

  String get issueDateFormatted {
    return '${issueDate.day.toString().padLeft(2, '0')}/${issueDate.month.toString().padLeft(2, '0')}/${issueDate.year}';
  }

  String? get dueDateFormatted {
    if (dueDate == null) return null;
    return '${dueDate!.day.toString().padLeft(2, '0')}/${dueDate!.month.toString().padLeft(2, '0')}/${dueDate!.year}';
  }

  // Exibição em dual currency
  String get dualCurrencyDisplay {
    if (currencyCode == 'BRL' && totalAmountInUsd != null) {
      return '$totalAmountFormatted (US\$ ${totalAmountInUsd!.toStringAsFixed(2)})';
    } else if (currencyCode == 'USD' && totalAmountInBrl != null) {
      return '$totalAmountFormatted (R\$ ${totalAmountInBrl!.toStringAsFixed(2)})';
    } else {
      return totalAmountFormatted;
    }
  }
} 

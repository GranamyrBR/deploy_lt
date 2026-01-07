import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

part 'sales_cancellation_payment.g.dart';

@JsonSerializable()
class SalesCancellationPayment {
  final int id;
  final int cancellationLogId;
  final int? paymentMethodId;
  final String? paymentMethodName;
  final double amount;
  
  // Multi-moeda
  final int currencyId;
  final String currencyCode;
  final double exchangeRateToUsd;
  final double amountInBrl;
  final double amountInUsd;
  
  final DateTime paymentDate;
  final String? transactionId;
  final bool isAdvancePayment;
  
  // Status do reembolso
  final bool refundRequired;
  final String refundStatus; // 'pending', 'processed', 'completed', 'failed'
  final DateTime? refundDate;
  final String? refundTransactionId;
  
  // Informações de auditoria
  final DateTime createdAt;

  SalesCancellationPayment({
    required this.id,
    required this.cancellationLogId,
    this.paymentMethodId,
    this.paymentMethodName,
    required this.amount,
    required this.currencyId,
    required this.currencyCode,
    required this.exchangeRateToUsd,
    required this.amountInBrl,
    required this.amountInUsd,
    required this.paymentDate,
    this.transactionId,
    required this.isAdvancePayment,
    required this.refundRequired,
    required this.refundStatus,
    this.refundDate,
    this.refundTransactionId,
    required this.createdAt,
  });

  factory SalesCancellationPayment.fromJson(Map<String, dynamic> json) => _$SalesCancellationPaymentFromJson(json);
  Map<String, dynamic> toJson() => _$SalesCancellationPaymentToJson(this);

  // Helper methods
  bool get isRefundPending => refundStatus == 'pending';
  bool get isRefundProcessed => refundStatus == 'processed';
  bool get isRefundCompleted => refundStatus == 'completed';
  bool get isRefundFailed => refundStatus == 'failed';

  // Formatação de valores
  String get amountFormatted {
    if (currencyCode == 'BRL') {
      return 'R\$ ${amount.toStringAsFixed(2)}';
    } else if (currencyCode == 'USD') {
      return 'US\$ ${amount.toStringAsFixed(2)}';
    } else {
      return '${amount.toStringAsFixed(2)} $currencyCode';
    }
  }

  String get amountBrlFormatted => 'R\$ ${amountInBrl.toStringAsFixed(2)}';
  String get amountUsdFormatted => 'US\$ ${amountInUsd.toStringAsFixed(2)}';

  // Exibição em dual currency
  String get dualCurrencyDisplay {
    if (currencyCode == 'BRL' && amountInUsd > 0) {
      return '$amountFormatted (US\$ ${amountInUsd.toStringAsFixed(2)})';
    } else if (currencyCode == 'USD' && amountInBrl > 0) {
      return '$amountFormatted (R\$ ${amountInBrl.toStringAsFixed(2)})';
    } else {
      return amountFormatted;
    }
  }

  // Status do reembolso
  String get refundStatusDisplay {
    switch (refundStatus) {
      case 'pending':
        return 'Pendente';
      case 'processed':
        return 'Processado';
      case 'completed':
        return 'Concluído';
      case 'failed':
        return 'Falhou';
      default:
        return 'Desconhecido';
    }
  }

  Color get refundStatusColor {
    switch (refundStatus) {
      case 'pending':
        return Colors.orange;
      case 'processed':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Data formatada
  String get paymentDateFormatted {
    return '${paymentDate.day.toString().padLeft(2, '0')}/${paymentDate.month.toString().padLeft(2, '0')}/${paymentDate.year}';
  }

  String get refundDateFormatted {
    if (refundDate == null) return '-';
    return '${refundDate!.day.toString().padLeft(2, '0')}/${refundDate!.month.toString().padLeft(2, '0')}/${refundDate!.year}';
  }

  // Tipo de pagamento
  String get paymentTypeDisplay {
    if (isAdvancePayment) {
      return 'Pagamento Antecipado';
    } else {
      return 'Pagamento Normal';
    }
  }

  // Verificar se precisa de reembolso
  bool get needsRefund => refundRequired && refundStatus != 'completed';
} 

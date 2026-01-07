import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

part 'sales_cancellation_log.g.dart';

@JsonSerializable()
class SalesCancellationLog {
  final int id;
  final int saleId;
  final int contactId;
  final String contactName;
  final String? contactEmail;
  final String? contactPhone;
  final String userId;
  final String userName;
  
  // Valores da venda no momento do cancelamento
  final double totalAmount;
  final double totalAmountBrl;
  final double totalAmountUsd;
  final double totalPaid;
  final double totalPaidBrl;
  final double totalPaidUsd;
  final double remainingAmount;
  final double remainingAmountBrl;
  final double remainingAmountUsd;
  
  final int currencyId;
  final String currencyCode;
  final double exchangeRateToUsd;
  
  // Status e informações de cancelamento
  final String originalStatus;
  final String cancellationReason;
  final String cancellationType; // 'client_request', 'payment_issue', 'service_unavailable', 'error', 'other'
  
  // Informações de reembolso
  final bool refundRequired;
  final double refundAmount;
  final double refundAmountBrl;
  final double refundAmountUsd;
  final String refundStatus; // 'pending', 'processed', 'completed', 'failed'
  final DateTime? refundDate;
  final String? refundMethod;
  final String? refundTransactionId;
  
  // Informações de auditoria
  final String cancelledByUserId;
  final String cancelledByUserName;
  final DateTime cancelledAt;
  
  // Informações adicionais
  final String? notes;
  final List<String>? tags;
  
  // Datas de auditoria
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Resumo de itens e pagamentos cancelados (da view)
  final int? totalItemsCancelled;
  final int? totalQuantityCancelled;
  final int? totalPaymentsCancelled;
  final double? totalPaymentsAmount;

  SalesCancellationLog({
    required this.id,
    required this.saleId,
    required this.contactId,
    required this.contactName,
    this.contactEmail,
    this.contactPhone,
    required this.userId,
    required this.userName,
    required this.totalAmount,
    required this.totalAmountBrl,
    required this.totalAmountUsd,
    required this.totalPaid,
    required this.totalPaidBrl,
    required this.totalPaidUsd,
    required this.remainingAmount,
    required this.remainingAmountBrl,
    required this.remainingAmountUsd,
    required this.currencyId,
    required this.currencyCode,
    required this.exchangeRateToUsd,
    required this.originalStatus,
    required this.cancellationReason,
    required this.cancellationType,
    required this.refundRequired,
    required this.refundAmount,
    required this.refundAmountBrl,
    required this.refundAmountUsd,
    required this.refundStatus,
    this.refundDate,
    this.refundMethod,
    this.refundTransactionId,
    required this.cancelledByUserId,
    required this.cancelledByUserName,
    required this.cancelledAt,
    this.notes,
    this.tags,
    required this.createdAt,
    required this.updatedAt,
    this.totalItemsCancelled,
    this.totalQuantityCancelled,
    this.totalPaymentsCancelled,
    this.totalPaymentsAmount,
  });

  factory SalesCancellationLog.fromJson(Map<String, dynamic> json) => _$SalesCancellationLogFromJson(json);
  Map<String, dynamic> toJson() => _$SalesCancellationLogToJson(this);

  // Helper methods
  bool get isRefundRequired => refundRequired;
  bool get isRefundPending => refundStatus == 'pending';
  bool get isRefundProcessed => refundStatus == 'processed';
  bool get isRefundCompleted => refundStatus == 'completed';
  bool get isRefundFailed => refundStatus == 'failed';

  // Formatação de valores
  String get totalAmountFormatted {
    if (currencyCode == 'BRL') {
      return 'R\$ ${totalAmount.toStringAsFixed(2)}';
    } else {
      return 'US\$ ${totalAmount.toStringAsFixed(2)}';
    }
  }

  String get totalAmountBrlFormatted => 'R\$ ${totalAmountBrl.toStringAsFixed(2)}';
  String get totalAmountUsdFormatted => 'US\$ ${totalAmountUsd.toStringAsFixed(2)}';
  
  String get totalPaidFormatted {
    if (currencyCode == 'BRL') {
      return 'R\$ ${totalPaid.toStringAsFixed(2)}';
    } else {
      return 'US\$ ${totalPaid.toStringAsFixed(2)}';
    }
  }

  String get totalPaidBrlFormatted => 'R\$ ${totalPaidBrl.toStringAsFixed(2)}';
  String get totalPaidUsdFormatted => 'US\$ ${totalPaidUsd.toStringAsFixed(2)}';
  
  String get remainingAmountFormatted {
    if (currencyCode == 'BRL') {
      return 'R\$ ${remainingAmount.toStringAsFixed(2)}';
    } else {
      return 'US\$ ${remainingAmount.toStringAsFixed(2)}';
    }
  }

  String get remainingAmountBrlFormatted => 'R\$ ${remainingAmountBrl.toStringAsFixed(2)}';
  String get remainingAmountUsdFormatted => 'US\$ ${remainingAmountUsd.toStringAsFixed(2)}';
  
  String get refundAmountFormatted {
    if (currencyCode == 'BRL') {
      return 'R\$ ${refundAmount.toStringAsFixed(2)}';
    } else {
      return 'US\$ ${refundAmount.toStringAsFixed(2)}';
    }
  }

  String get refundAmountBrlFormatted => 'R\$ ${refundAmountBrl.toStringAsFixed(2)}';
  String get refundAmountUsdFormatted => 'US\$ ${refundAmountUsd.toStringAsFixed(2)}';

  // Status de cancelamento
  String get cancellationTypeDisplay {
    switch (cancellationType) {
      case 'client_request':
        return 'Solicitação do Cliente';
      case 'payment_issue':
        return 'Problema de Pagamento';
      case 'service_unavailable':
        return 'Serviço Indisponível';
      case 'error':
        return 'Erro do Sistema';
      case 'other':
        return 'Outro';
      default:
        return 'Desconhecido';
    }
  }

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

  // Informações de resumo
  String get itemsSummary {
    if (totalItemsCancelled == null || totalItemsCancelled == 0) return 'Sem itens';
    if (totalItemsCancelled == 1) return '1 item';
    return '$totalItemsCancelled itens';
  }

  String get paymentsSummary {
    if (totalPaymentsCancelled == null || totalPaymentsCancelled == 0) return 'Sem pagamentos';
    if (totalPaymentsCancelled == 1) return '1 pagamento';
    return '$totalPaymentsCancelled pagamentos';
  }

  // Data formatada
  String get cancelledAtFormatted {
    return '${cancelledAt.day.toString().padLeft(2, '0')}/${cancelledAt.month.toString().padLeft(2, '0')}/${cancelledAt.year}';
  }

  String get refundDateFormatted {
    if (refundDate == null) return '-';
    return '${refundDate!.day.toString().padLeft(2, '0')}/${refundDate!.month.toString().padLeft(2, '0')}/${refundDate!.year}';
  }

  // Verificar se precisa de reembolso
  bool get needsRefund => refundRequired && refundStatus != 'completed';
} 

import 'package:json_annotation/json_annotation.dart';

part 'sale_payment.g.dart';

@JsonSerializable()
class SalePayment {
  final int paymentId;
  final int salesId;
  final int paymentMethodId;
  final String paymentMethodName;
  final double amount;
  final int currencyId;
  final String currencyCode;
  final DateTime paymentDate;
  final String? transactionId;
  final bool isAdvancePayment;
  
  // Multi-moeda
  final double? exchangeRateToUsd;
  final double? amountInBrl;
  final double? amountInUsd;

  // Campos de auditoria (adicionados conforme novo schema)
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? createdBy;
  final int? updatedBy;

  SalePayment({
    required this.paymentId,
    required this.salesId,
    required this.paymentMethodId,
    required this.paymentMethodName,
    required this.amount,
    required this.currencyId,
    required this.currencyCode,
    required this.paymentDate,
    this.transactionId,
    required this.isAdvancePayment,
    this.exchangeRateToUsd,
    this.amountInBrl,
    this.amountInUsd,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.createdBy,
    this.updatedBy,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory SalePayment.fromJson(Map<String, dynamic> json) => _$SalePaymentFromJson(json);
  Map<String, dynamic> toJson() => _$SalePaymentToJson(this);

  // Helper methods
  String get amountFormatted {
    if (currencyCode == 'BRL') {
      return 'R\$ ${amount.toStringAsFixed(2)}';
    } else if (currencyCode == 'USD') {
      return 'US\$ ${amount.toStringAsFixed(2)}';
    } else {
      return '${amount.toStringAsFixed(2)} $currencyCode';
    }
  }

  String get paymentDateFormatted {
    return '${paymentDate.day.toString().padLeft(2, '0')}/${paymentDate.month.toString().padLeft(2, '0')}/${paymentDate.year}';
  }

  // Exibição em dual currency
  String get dualCurrencyDisplay {
    if (currencyCode == 'BRL' && amountInUsd != null) {
      return '$amountFormatted (US\$ ${amountInUsd!.toStringAsFixed(2)})';
    } else if (currencyCode == 'USD' && amountInBrl != null) {
      return '$amountFormatted (R\$ ${amountInBrl!.toStringAsFixed(2)})';
    } else {
      return amountFormatted;
    }
  }

  // Status do pagamento
  String get paymentTypeDisplay => isAdvancePayment ? 'Adiantamento' : 'Pagamento';
}

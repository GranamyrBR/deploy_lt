import 'package:json_annotation/json_annotation.dart';

part 'provisional_invoice_item.g.dart';

@JsonSerializable()
class ProvisionalInvoiceItem {
  final int id;
  final int provisionalInvoiceId;
  final int serviceId;
  final String serviceName;
  final String? serviceDescription;
  final int quantity;
  @JsonKey(name: 'unit_price')
  final double unitPriceAtProposal;
  final double taxPercentageAtProposal;
  final double itemTotal;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Multi-moeda (se aplicável)
  final int? currencyId;
  final String? currencyCode;
  final double? exchangeRateToUsd;
  final double? unitPriceInBrl;
  final double? unitPriceInUsd;
  final double? itemTotalInBrl;
  final double? itemTotalInUsd;

  ProvisionalInvoiceItem({
    required this.id,
    required this.provisionalInvoiceId,
    required this.serviceId,
    required this.serviceName,
    this.serviceDescription,
    required this.quantity,
    required this.unitPriceAtProposal,
    required this.taxPercentageAtProposal,
    required this.itemTotal,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.currencyId,
    this.currencyCode,
    this.exchangeRateToUsd,
    this.unitPriceInBrl,
    this.unitPriceInUsd,
    this.itemTotalInBrl,
    this.itemTotalInUsd,
  });

  factory ProvisionalInvoiceItem.fromJson(Map<String, dynamic> json) => _$ProvisionalInvoiceItemFromJson(json);
  Map<String, dynamic> toJson() => _$ProvisionalInvoiceItemToJson(this);

  // Helper methods
  double get taxAmount => (unitPriceAtProposal * quantity * taxPercentageAtProposal) / 100;
  double get subtotal => unitPriceAtProposal * quantity;
  double get totalWithTax => subtotal + taxAmount;

  // Formatação de valores
  String get unitPriceFormatted {
    if (currencyCode == 'BRL') {
      return 'R\$ ${unitPriceAtProposal.toStringAsFixed(2)}';
    } else if (currencyCode == 'USD') {
      return 'US\$ ${unitPriceAtProposal.toStringAsFixed(2)}';
    } else {
      return unitPriceAtProposal.toStringAsFixed(2);
    }
  }

  String get itemTotalFormatted {
    if (currencyCode == 'BRL') {
      return 'R\$ ${itemTotal.toStringAsFixed(2)}';
    } else if (currencyCode == 'USD') {
      return 'US\$ ${itemTotal.toStringAsFixed(2)}';
    } else {
      return itemTotal.toStringAsFixed(2);
    }
  }

  String get taxAmountFormatted {
    if (currencyCode == 'BRL') {
      return 'R\$ ${taxAmount.toStringAsFixed(2)}';
    } else if (currencyCode == 'USD') {
      return 'US\$ ${taxAmount.toStringAsFixed(2)}';
    } else {
      return taxAmount.toStringAsFixed(2);
    }
  }

  // Exibição em dual currency
  String get dualCurrencyDisplay {
    if (currencyCode == 'BRL' && itemTotalInUsd != null) {
      return '$itemTotalFormatted (US\$ ${itemTotalInUsd!.toStringAsFixed(2)})';
    } else if (currencyCode == 'USD' && itemTotalInBrl != null) {
      return '$itemTotalFormatted (R\$ ${itemTotalInBrl!.toStringAsFixed(2)})';
    } else {
      return itemTotalFormatted;
    }
  }
}

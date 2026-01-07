import 'package:json_annotation/json_annotation.dart';

part 'sales_cancellation_item.g.dart';

@JsonSerializable()
class SalesCancellationItem {
  final int id;
  final int cancellationLogId;
  final int serviceId;
  final String serviceName;
  final String? serviceDescription;
  
  // Valores do item no momento do cancelamento
  final int quantity;
  final int pax;
  final double unitPriceAtSale;
  
  // Descontos e taxas
  final double discountPercentage;
  final double discountAmount;
  final double surchargePercentage;
  final double surchargeAmount;
  final double taxPercentage;
  final double taxAmount;
  
  final double subtotal;
  final double itemTotal;
  
  // Multi-moeda
  final int currencyId;
  final String currencyCode;
  final double exchangeRateToUsd;
  final double unitPriceInBrl;
  final double unitPriceInUsd;
  final double itemTotalInBrl;
  final double itemTotalInUsd;
  
  // Informações de auditoria
  final DateTime createdAt;

  SalesCancellationItem({
    required this.id,
    required this.cancellationLogId,
    required this.serviceId,
    required this.serviceName,
    this.serviceDescription,
    required this.quantity,
    required this.pax,
    required this.unitPriceAtSale,
    required this.discountPercentage,
    required this.discountAmount,
    required this.surchargePercentage,
    required this.surchargeAmount,
    required this.taxPercentage,
    required this.taxAmount,
    required this.subtotal,
    required this.itemTotal,
    required this.currencyId,
    required this.currencyCode,
    required this.exchangeRateToUsd,
    required this.unitPriceInBrl,
    required this.unitPriceInUsd,
    required this.itemTotalInBrl,
    required this.itemTotalInUsd,
    required this.createdAt,
  });

  factory SalesCancellationItem.fromJson(Map<String, dynamic> json) => _$SalesCancellationItemFromJson(json);
  Map<String, dynamic> toJson() => _$SalesCancellationItemToJson(this);

  // Helper methods
  double get totalWithTax => subtotal + taxAmount;
  double get totalWithDiscount => subtotal - discountAmount;
  double get totalWithSurcharge => subtotal + surchargeAmount;

  // Formatação de valores
  String get unitPriceFormatted {
    if (currencyCode == 'BRL') {
      return 'R\$ ${unitPriceAtSale.toStringAsFixed(2)}';
    } else if (currencyCode == 'USD') {
      return 'US\$ ${unitPriceAtSale.toStringAsFixed(2)}';
    } else {
      return unitPriceAtSale.toStringAsFixed(2);
    }
  }

  String get subtotalFormatted {
    if (currencyCode == 'BRL') {
      return 'R\$ ${subtotal.toStringAsFixed(2)}';
    } else if (currencyCode == 'USD') {
      return 'US\$ ${subtotal.toStringAsFixed(2)}';
    } else {
      return subtotal.toStringAsFixed(2);
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

  String get itemTotalBrlFormatted => 'R\$ ${itemTotalInBrl.toStringAsFixed(2)}';
  String get itemTotalUsdFormatted => 'US\$ ${itemTotalInUsd.toStringAsFixed(2)}';

  // Exibição em dual currency
  String get dualCurrencyDisplay {
    if (currencyCode == 'BRL' && itemTotalInUsd > 0) {
      return '$itemTotalFormatted (US\$ ${itemTotalInUsd.toStringAsFixed(2)})';
    } else if (currencyCode == 'USD' && itemTotalInBrl > 0) {
      return '$itemTotalFormatted (R\$ ${itemTotalInBrl.toStringAsFixed(2)})';
    } else {
      return itemTotalFormatted;
    }
  }

  // Resumo do item
  String get itemSummary {
    if (quantity == 1) {
      return '$serviceName';
    } else {
      return '$serviceName (x$quantity)';
    }
  }

  String get paxSummary {
    if (pax == 1) {
      return '1 pessoa';
    } else {
      return '$pax pessoas';
    }
  }

  // Verificar se tem desconto
  bool get hasDiscount => discountAmount > 0;
  bool get hasSurcharge => surchargeAmount > 0;
  bool get hasTax => taxAmount > 0;
} 

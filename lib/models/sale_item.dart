import 'package:json_annotation/json_annotation.dart';

part 'sale_item.g.dart';

enum SaleItemType { product, service }

@JsonSerializable()
class SaleItem {
  final SaleItemType type;
  final int id;
  final String name;
  final double price;
  int quantity;
  final double taxPercentage;
  final String? imageUrl;
  final String? sku;
  final int? stock;

  // Multi-moeda (se aplicável)
  final int? currencyId;
  final String? currencyCode;
  final double? exchangeRateToUsd;
  final double? unitPriceInBrl;
  final double? unitPriceInUsd;
  final double? itemTotalInBrl;
  final double? itemTotalInUsd;

  SaleItem({
    required this.type,
    required this.id,
    required this.name,
    required this.price,
    this.quantity = 1,
    this.taxPercentage = 0.0,
    this.imageUrl,
    this.sku,
    this.stock,
    this.currencyId,
    this.currencyCode,
    this.exchangeRateToUsd,
    this.unitPriceInBrl,
    this.unitPriceInUsd,
    this.itemTotalInBrl,
    this.itemTotalInUsd,
  });

  factory SaleItem.fromJson(Map<String, dynamic> json) => _$SaleItemFromJson(json);
  Map<String, dynamic> toJson() => _$SaleItemToJson(this);

  // Helper methods
  double get taxAmount => (price * quantity * taxPercentage) / 100;
  double get subtotal => price * quantity;
  double get totalWithTax => subtotal + taxAmount;

  // Formatação de valores
  String get unitPriceFormatted {
    if (currencyCode == 'BRL') {
      return 'R\$ ${price.toStringAsFixed(2)}';
    } else if (currencyCode == 'USD') {
      return 'US\$ ${price.toStringAsFixed(2)}';
    } else {
      return price.toStringAsFixed(2);
    }
  }

  String get itemTotalFormatted {
    if (currencyCode == 'BRL') {
      return 'R\$ ${totalWithTax.toStringAsFixed(2)}';
    } else if (currencyCode == 'USD') {
      return 'US\$ ${totalWithTax.toStringAsFixed(2)}';
    } else {
      return totalWithTax.toStringAsFixed(2);
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

import '../models/service.dart';
import '../models/product.dart';

class SaleItemDetail {
  final Service? service;
  final Product? product;
  final double quantity;
  final int pax;
  final double unitPrice;
  final double discount;
  final double surcharge;
  final double tax;
  final String? itemDescription;
  final int? serviceId;
  final int? productId;
  final int? saleItemId;

  SaleItemDetail({
    this.service,
    this.product,
    required this.quantity,
    required this.pax,
    required this.unitPrice,
    this.discount = 0,
    this.surcharge = 0,
    this.tax = 0,
    this.itemDescription,
    this.serviceId,
    this.productId,
    this.saleItemId,
  });

  double get subtotal => unitPrice * quantity;
  double get discountAmount => subtotal * (discount / 100);
  double get surchargeAmount => subtotal * (surcharge / 100);
  double get taxAmount => subtotal * (tax / 100);
  double get totalPrice => subtotal - discountAmount + surchargeAmount + taxAmount;

  String get itemName {
    if (itemDescription != null && itemDescription!.isNotEmpty) {
      return itemDescription!;
    }
    if (service != null) {
      return service!.name ?? 'Serviço';
    }
    if (product != null) {
      return product!.name;
    }
    return 'Item';
  }

  String get itemType {
    if (service != null) return 'Serviço';
    if (product != null) return 'Produto';
    return 'Item';
  }

  factory SaleItemDetail.fromJson(Map<String, dynamic> json) {
    final unitPriceValue = json['unit_price_at_sale'];
    
    // Validação de campos obrigatórios (NOT NULL no banco)
    final serviceId = json['service_id'] as int?;
    if (serviceId == null) {
      throw ArgumentError('service_id é obrigatório e não pode ser null');
    }
    
    return SaleItemDetail(
      quantity: json['quantity'] != null ? (json['quantity'] as num).toDouble() : 1.0,
      pax: json['pax'] != null ? (json['pax'] as num).toInt() : 1,
      unitPrice: unitPriceValue != null ? (unitPriceValue as num).toDouble() : 0.0,
      discount: json['discount'] != null ? (json['discount'] as num).toDouble() : 0.0,
      surcharge: json['surcharge'] != null ? (json['surcharge'] as num).toDouble() : 0.0,
      tax: json['tax'] != null ? (json['tax'] as num).toDouble() : 0.0,
      itemDescription: json['item_name'] as String?,
      serviceId: serviceId, // Agora obrigatório
      productId: json['product_id'] as int?,
      saleItemId: json['sales_item_id'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'quantity': quantity,
      'pax': pax,
      'unit_price_at_sale': unitPrice,
      'discount': discount,
      'surcharge': surcharge,
      'tax': tax,
      'item_name': itemDescription ?? itemName,
      'service_id': serviceId ?? service?.id,
      'product_id': productId ?? product?.productId,
      'sales_item_id': saleItemId,
    };
  }
}

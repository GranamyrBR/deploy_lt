import 'package:flutter/material.dart';
import 'sale_item_detail.dart';
import 'sale_payment.dart';
// import 'package:json_annotation/json_annotation.dart'; // Remover ou comentar
// part 'sale.g.dart'; // Remover ou comentar

enum PaymentStatus {
  paid,
  partial,
  pending,
}

// SalePayment class moved to sale_payment.dart

// @JsonSerializable() // Remover ou comentar
class Sale {
  final int id;
  final int contactId;
  final String contactName;
  final String? contactEmail;
  final String? contactPhone;
  final bool? contactIsVip;
  final int? contactAgencyId;
  final String? contactAgencyName;
  final int? contactAccountTypeId;
  final String userId;
  final String userName;
  final String? sellerName;
  final String? sellerEmail;
  
  // Campos de status e controle
  final String? status;
  final String? notes;
  final DateTime? dueDate;
  
  // Campos de serviço (mantidos para compatibilidade)
  final int? serviceId;
  final String? serviceName;
  final String? serviceDescription;
  
  // Resumo de itens (novos campos da view)
  final int? totalItems;
  final int? totalQuantity;
  
  // Multi-moeda - valores totais
  final double totalAmount; // valor total na moeda original
  final int currencyId;
  final String currencyCode;
  final String? currencyName;
  final double? exchangeRateToUsd;
  final double totalAmountBrl; // valor total convertido para BRL
  final double totalAmountUsd; // valor total convertido para USD
  
  // Resumo de pagamentos (novos campos da view)
  final double totalPaid; // total pago na moeda original
  final double totalPaidBrl; // total pago em BRL
  final double totalPaidUsd; // total pago em USD
  final double remainingAmount; // valor restante na moeda original
  final double remainingAmountBrl; // valor restante em BRL
  final double remainingAmountUsd; // valor restante em USD
  
  // Status de pagamento calculado
  final String? paymentStatus;
  
  // Taxas (mantidas para compatibilidade)
  final double? taxAmount;
  final double? taxPercentage;
  
  // Status e datas
  final DateTime createdAt;
  final DateTime? paidAt;
  final DateTime updatedAt;

  final List<SalePayment> payments;
  
  // Lista de itens detalhados da venda
  final List<SaleItemDetail> items;

  Sale({
    required this.id,
    required this.contactId,
    required this.contactName,
    this.contactEmail,
    this.contactPhone,
    this.contactIsVip,
    this.contactAgencyId,
    this.contactAgencyName,
    this.contactAccountTypeId,
    required this.userId,
    required this.userName,
    this.sellerName,
    this.sellerEmail,
    this.status,
    this.notes,
    this.dueDate,
    this.serviceId,
    this.serviceName,
    this.serviceDescription,
    this.totalItems,
    this.totalQuantity,
    required this.totalAmount,
    required this.currencyId,
    required this.currencyCode,
    this.currencyName,
    this.exchangeRateToUsd,
    required this.totalAmountBrl,
    required this.totalAmountUsd,
    required this.totalPaid,
    required this.totalPaidBrl,
    required this.totalPaidUsd,
    required this.remainingAmount,
    required this.remainingAmountBrl,
    required this.remainingAmountUsd,
    this.paymentStatus,
    this.taxAmount,
    this.taxPercentage,
    required this.createdAt,
    this.paidAt,
    required this.updatedAt,
    required this.payments,
    this.items = const [],
  });

  // factory Sale.fromJson(Map<String, dynamic> json) => _$SaleFromJson(json);
  factory Sale.fromJson(Map<String, dynamic> json) {
    // Garante que payments sempre será uma lista
    final paymentsJson = json['sale_payment'] ?? json['payments'] ?? [];
    
    // Extrair dados do cliente - agora obrigatórios devido ao NOT NULL no banco
    final contactName = json['customer_name'] ?? 'Cliente não informado';
    final contactEmail = json['customer_email'] as String?;
    final contactPhone = json['customer_phone'] as String?;
    
    // Extrair dados do vendedor da view - agora obrigatórios
    final sellerName = json['seller_name'] ?? 'Vendedor não informado';
    final sellerEmail = json['seller_email'] as String?;
    
    // Usar total_amount_usd como valor principal, fallback para total_amount
    final totalAmountUsd = (json['total_amount_usd'] ?? json['total_amount'] ?? 0) as double;
    final totalAmountBrl = (json['total_amount_brl'] ?? 0) as double;
    
    // Validações de campos obrigatórios (NOT NULL no banco)
    final customerId = json['customer_id'] as int?;
    if (customerId == null) {
      throw ArgumentError('customer_id é obrigatório e não pode ser null');
    }
    
    final userId = json['user_id'] as String?;
    if (userId == null || userId.isEmpty) {
      throw ArgumentError('user_id é obrigatório e não pode ser null ou vazio');
    }
    
    final currencyId = json['currency_id'] as int?;
    if (currencyId == null) {
      throw ArgumentError('currency_id é obrigatório e não pode ser null');
    }
    
    return Sale(
      id: json['id'] as int? ?? 0,
      contactId: customerId, // Agora obrigatório
      contactName: contactName,
      contactEmail: contactEmail,
      contactPhone: contactPhone,
      contactIsVip: json['customer_is_vip'] as bool?,
      contactAgencyId: json['customer_agency_id'] as int?,
      contactAgencyName: json['customer_agency_name'] as String?,
      contactAccountTypeId: json['customer_account_type_id'] as int?,
      userId: userId, // Agora obrigatório
      userName: sellerName,
      sellerName: sellerName,
      sellerEmail: sellerEmail,
      status: json['status'] as String?,
      notes: json['notes'] as String?,
      dueDate: json['due_date'] != null ? DateTime.tryParse(json['due_date']) : null,
      serviceId: json['service_id'] as int?,
      serviceName: json['service_name'] as String?,
      serviceDescription: json['service_description'] as String?,
      totalItems: json['total_items'] as int?,
      totalQuantity: json['total_quantity'] as int?,
      totalAmount: totalAmountUsd, // Usar USD como valor principal
      currencyId: currencyId, // Agora obrigatório
      currencyCode: json['currency_code'] ?? 'USD', // Default para USD
      currencyName: json['currency_name'] as String?,
      exchangeRateToUsd: (json['exchange_rate_to_usd'] as num?)?.toDouble(),
      totalAmountBrl: totalAmountBrl,
      totalAmountUsd: totalAmountUsd,
      totalPaid: (json['total_paid'] ?? 0) as double,
      totalPaidBrl: (json['total_paid_brl'] ?? 0) as double,
      totalPaidUsd: (json['total_paid_usd'] ?? 0) as double,
      remainingAmount: (json['remaining_amount'] ?? 0) as double,
      remainingAmountBrl: (json['remaining_amount_brl'] ?? 0) as double,
      remainingAmountUsd: (json['remaining_amount_usd'] ?? 0) as double,
      paymentStatus: json['payment_status'] as String?,
      taxAmount: (json['tax_amount'] as num?)?.toDouble(),
      taxPercentage: (json['tax_percentage'] as num?)?.toDouble(),
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      paidAt: json['paid_at'] != null ? DateTime.tryParse(json['paid_at']) : null,
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
      payments: paymentsJson is List 
          ? (paymentsJson).map((payment) => SalePayment(
              paymentId: payment['id'] ?? 0,
              salesId: payment['sales_id'] ?? 0,
              paymentMethodId: payment['payment_method_id'] ?? 0,
              paymentMethodName: payment['payment_method']?['method_name'] ?? 'Não informado',
              amount: (payment['amount'] ?? 0) as double,
              currencyId: payment['currency_id'] ?? 1,
              currencyCode: (payment['currency_id'] == 2) ? 'BRL' : 'USD',
              paymentDate: DateTime.tryParse(payment['payment_date'] ?? '') ?? DateTime.now(),
              transactionId: payment['transaction_id'],
              isAdvancePayment: payment['is_advance_payment'] ?? false,
              exchangeRateToUsd: (payment['exchange_rate_to_usd'] as num?)?.toDouble(),
              amountInBrl: (payment['amount_in_brl'] as num?)?.toDouble(),
              amountInUsd: (payment['amount_in_usd'] as num?)?.toDouble(),
            )).cast<SalePayment>().toList()
          : [],
      items: _parseItems(json['sale_items'] ?? []),
    );
  }
  
  // Método auxiliar para parsear os itens da venda
  static List<SaleItemDetail> _parseItems(dynamic itemsData) {
    if (itemsData == null) return [];
    
    if (itemsData is List) {
      return itemsData.map((item) => SaleItemDetail.fromJson(item as Map<String, dynamic>)).toList();
    }
    
    return [];
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contact_id': contactId,
      'contact_name': contactName,
      'contact_email': contactEmail,
      'contact_phone': contactPhone,
      'user_id': userId,
      'user_name': userName,
      'seller_name': sellerName,
      'seller_email': sellerEmail,
      'status': status,
      'notes': notes,
      'due_date': dueDate?.toIso8601String(),
      'service_id': serviceId,
      'service_name': serviceName,
      'service_description': serviceDescription,
      'total_items': totalItems,
      'total_quantity': totalQuantity,
      'total_amount': totalAmount,
      'currency_id': currencyId,
      'currency_code': currencyCode,
      'currency_name': currencyName,
      'exchange_rate_to_usd': exchangeRateToUsd,
      'total_amount_brl': totalAmountBrl,
      'total_amount_usd': totalAmountUsd,
      'total_paid': totalPaid,
      'total_paid_brl': totalPaidBrl,
      'total_paid_usd': totalPaidUsd,
      'remaining_amount': remainingAmount,
      'remaining_amount_brl': remainingAmountBrl,
      'remaining_amount_usd': remainingAmountUsd,
      'payment_status': paymentStatus,
      'tax_amount': taxAmount,
      'tax_percentage': taxPercentage,
      'created_at': createdAt.toIso8601String(),
      'paid_at': paidAt?.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper methods para formatação
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

  // Método para obter o valor total em ambas as moedas
  String get dualCurrencyDisplay {
    if (currencyCode == 'BRL') {
      return '$totalAmountFormatted ($totalAmountUsdFormatted)';
    } else {
      return '$totalAmountFormatted ($totalAmountBrlFormatted)';
    }
  }

  // Status calculado
  bool get isPaid => paymentStatus == 'paid' || paymentStatus == 'Pago' || paidAt != null;
  bool get isPartiallyPaid => paymentStatus == 'partial' || paymentStatus == 'Parcial';
  bool get isPending => paymentStatus == 'pending' || paymentStatus == 'Pendente' || paymentStatus == null;
  
  String get statusDisplay {
    if (isPaid) return 'Pago';
    if (isPartiallyPaid) return 'Parcial';
    return 'Pendente';
  }
  
  Color get statusColor {
    if (isPaid) return Colors.green;
    if (isPartiallyPaid) return Colors.orange;
    return Colors.red;
  }

  // Informações de resumo
  String get itemsSummary {
    if (totalItems == null || totalItems == 0) return 'Sem itens';
    if (totalItems == 1) return '1 item';
    return '$totalItems itens';
  }

  String get paymentSummary {
    if (isPaid) return 'Totalmente pago';
    if (isPartiallyPaid) return 'Parcialmente pago';
    return 'Aguardando pagamento';
  }

  // Verificar se está em atraso
  bool get isOverdue {
    if (dueDate == null) return false;
    return dueDate!.isBefore(DateTime.now()) && !isPaid;
  }

  int get daysOverdue {
    if (dueDate == null || !isOverdue) return 0;
    return DateTime.now().difference(dueDate!).inDays;
  }

  // Métodos para trabalhar com itens da venda
  String get itemsDetailedSummary {
    if (items.isEmpty) return 'Sem itens';
    return items.map((item) => item.itemDescription ?? 'Item sem descrição').join('\n');
  }

  List<String> get itemsDescriptionList {
    return items.map((item) => item.itemDescription ?? 'Item sem descrição').toList();
  }

  bool get hasItems => items.isNotEmpty;

  int get itemsCount => items.length;
  
  // Getters para informações do cliente
  bool get isVipCustomer => contactIsVip ?? false;
  String get customerVipStatus => isVipCustomer ? 'VIP' : 'Regular';
  bool get hasAgency => contactAgencyId != null;
  String get agencyDisplayName => contactAgencyName ?? 'Sem agência';
  String? get customerAgencyEmail => null; // Campo não disponível no modelo atual
  String? get customerAgencyPhone => null; // Campo não disponível no modelo atual
  String? get customerAgencyCity => null; // Campo não disponível no modelo atual
  double? get customerAgencyCommissionRate => null; // Campo não disponível no modelo atual
  String get customerTypeDisplay {
    final parts = <String>[];
    if (isVipCustomer) parts.add('VIP');
    if (hasAgency) parts.add(agencyDisplayName);
    return parts.isNotEmpty ? parts.join(' • ') : 'Cliente Regular';
  }

  String get itemsShortSummary {
    if (items.isEmpty) return 'Sem itens';
    if (items.length == 1) return '1 item';
    return '${items.length} itens';
  }
}

import '../models/enhanced_quotation_model.dart';
import '../models/contact.dart';

/// Serviço para converter Cotações em Vendas
/// Mapeia todos os dados relevantes e permite edição antes de salvar
class QuotationToSaleConverter {
  
  /// Converte uma cotação em dados para criar uma venda
  /// Retorna um Map com os dados pré-preenchidos para o CreateSaleScreen
  static Map<String, dynamic> convertToSaleData({
    required Quotation quotation,
    Contact? contact,
    String? userId,
    String? userName,
  }) {
    
    // Mapear itens da cotação para itens de venda
    final List<Map<String, dynamic>> saleItems = quotation.items.map((quotationItem) {
      return {
        'service_id': quotationItem.serviceId,
        'product_id': quotationItem.productId,
        'item_type': quotationItem.category, // 'service', 'product', 'ticket', 'fee'
        'item_description': quotationItem.description,
        'quantity': quotationItem.quantity,
        'unit_price': quotationItem.value,
        'total_price': quotationItem.totalValue,
        'start_date': quotationItem.date.toIso8601String(),
        'end_date': quotationItem.endTime?.toIso8601String(),
        'notes': quotationItem.notes,
        'discount': quotationItem.discount,
        'location': quotationItem.location,
        'provider': quotationItem.provider,
        'currency_id': 1, // Default USD - ajustar conforme necessário
      };
    }).toList();

    // Calcular totais (já calculados na cotação)
    final double subtotal = quotation.subtotal;
    final double taxAmount = quotation.taxAmount;
    final double totalAmount = quotation.total;
    final double discountAmount = quotation.discountAmount;

    // Montar dados da venda
    return {
      // Identificação da cotação original
      'quotation_id': quotation.id,
      'quotation_number': quotation.quotationNumber,
      
      // Dados do cliente
      'contact_id': quotation.clientContact?.id ?? contact?.id,
      'contact_name': quotation.clientName,
      'contact_email': quotation.clientEmail,
      'contact_phone': quotation.clientPhone,
      'contact_document': quotation.clientDocument,
      
      // Dados do vendedor
      'user_id': userId ?? quotation.createdBy,
      'user_name': userName,
      
      // Moeda
      'currency_id': quotation.currency == 'BRL' ? 2 : 1, // 1=USD, 2=BRL
      'currency_code': quotation.currency,
      
      // Valores
      'subtotal': subtotal,
      'discount_amount': discountAmount,
      'tax_amount': taxAmount,
      'tax_percentage': quotation.taxRate,
      'total_amount': totalAmount,
      
      // Itens da venda
      'items': saleItems,
      
      // Datas
      'sale_date': DateTime.now().toIso8601String(),
      'due_date': quotation.expirationDate?.toIso8601String(),
      'travel_date': quotation.travelDate.toIso8601String(),
      'return_date': quotation.returnDate?.toIso8601String(),
      
      // Detalhes da viagem
      'passenger_count': quotation.passengerCount,
      'origin': quotation.origin,
      'destination': quotation.destination,
      'hotel': quotation.hotel,
      'room_type': quotation.roomType,
      'nights': quotation.nights,
      'vehicle': quotation.vehicle,
      'driver': quotation.driver,
      
      // Observações e notas
      'notes': _buildNotesFromQuotation(quotation),
      'special_requests': quotation.specialRequests,
      
      // Status inicial
      'status': 'pending', // Venda criada mas pendente de pagamento
      'payment_status': 'pending',
      
      // Agência (se houver)
      'agency_id': quotation.agency?.id,
      'agency_commission_rate': quotation.agencyCommissionRate,
      
      // Metadados
      'created_from': 'quotation',
      'source': 'quotation_conversion',
      'quotation_type': quotation.type.name,
    };
  }

  /// Constrói as notas da venda baseadas na cotação
  static String _buildNotesFromQuotation(Quotation quotation) {
    final buffer = StringBuffer();
    
    buffer.writeln('📋 Venda criada a partir da cotação ${quotation.quotationNumber}');
    buffer.writeln('Tipo: ${quotation.typeDisplayName}');
    buffer.writeln('');
    
    if (quotation.notes != null && quotation.notes!.isNotEmpty) {
      buffer.writeln('Observações da cotação:');
      buffer.writeln(quotation.notes);
      buffer.writeln('');
    }
    
    // Adicionar informações da viagem
    buffer.writeln('📅 Detalhes da Viagem:');
    buffer.writeln('Data: ${quotation.travelDate.toLocal().toString().split(' ')[0]}');
    if (quotation.returnDate != null) {
      buffer.writeln('Retorno: ${quotation.returnDate!.toLocal().toString().split(' ')[0]}');
    }
    buffer.writeln('Passageiros: ${quotation.passengerCount}');
    
    if (quotation.origin != null) {
      buffer.writeln('Origem: ${quotation.origin}');
    }
    if (quotation.destination != null) {
      buffer.writeln('Destino: ${quotation.destination}');
    }
    
    // Acomodação
    if (quotation.hotel != null) {
      buffer.writeln('');
      buffer.writeln('🏨 Acomodação:');
      buffer.writeln('Hotel: ${quotation.hotel}');
      if (quotation.roomType != null) {
        buffer.writeln('Tipo de quarto: ${quotation.roomType}');
      }
      if (quotation.nights != null) {
        buffer.writeln('Noites: ${quotation.nights}');
      }
    }
    
    // Transporte
    if (quotation.vehicle != null) {
      buffer.writeln('');
      buffer.writeln('🚗 Transporte:');
      buffer.writeln('Veículo: ${quotation.vehicle}');
      if (quotation.driver != null) {
        buffer.writeln('Motorista: ${quotation.driver}');
      }
    }
    
    // Políticas
    if (quotation.cancellationPolicy != null) {
      buffer.writeln('');
      buffer.writeln('📜 Política de Cancelamento:');
      buffer.writeln(quotation.cancellationPolicy);
    }
    
    if (quotation.paymentTerms != null) {
      buffer.writeln('');
      buffer.writeln('💳 Termos de Pagamento:');
      buffer.writeln(quotation.paymentTerms);
    }
    
    return buffer.toString().trim();
  }

  /// Valida se a cotação pode ser convertida em venda
  static ValidationResult canConvert(Quotation quotation) {
    final errors = <String>[];
    
    // Validações obrigatórias
    if (quotation.clientContact == null && quotation.clientEmail.isEmpty) {
      errors.add('Cotação deve ter um cliente/contato associado');
    }
    
    if (quotation.items.isEmpty) {
      errors.add('Cotação deve ter pelo menos 1 item');
    }
    
    if (quotation.total <= 0) {
      errors.add('Cotação deve ter um valor total válido');
    }
    
    // Validações de status
    if (quotation.status == QuotationStatus.cancelled || 
        quotation.status == QuotationStatus.rejected) {
      errors.add('Cotação cancelada ou rejeitada não pode ser convertida');
    }
    
    // Avisos (não impedem conversão)
    final warnings = <String>[];
    
    if (quotation.status == QuotationStatus.accepted) {
      warnings.add('Esta cotação já foi aceita anteriormente');
    }
    
    if (quotation.expirationDate != null && 
        quotation.expirationDate!.isBefore(DateTime.now())) {
      warnings.add('Cotação está expirada');
    }
    
    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Converte lista de QuotationItem para lista de Maps (compatível com SaleItem)
  static List<Map<String, dynamic>> convertItemsToMaps(List<QuotationItem> quotationItems) {
    return quotationItems.map((item) {
      return {
        'service_id': item.serviceId != null ? int.tryParse(item.serviceId!) : null,
        'product_id': item.productId != null ? int.tryParse(item.productId!) : null,
        'item_type': item.category,
        'item_description': item.description,
        'quantity': item.quantity,
        'unit_price': item.value,
        'total_price': item.totalValue,
        'discount': item.discount,
        'start_date': item.date.toIso8601String(),
        'end_date': item.endTime?.toIso8601String(),
        'notes': item.notes,
        'location': item.location,
        'provider': item.provider,
      };
    }).toList();
  }

  /// Prepara dados para abrir o CreateSaleScreen pré-preenchido
  static Map<String, dynamic> prepareForCreateScreen({
    required Quotation quotation,
    Contact? contact,
    String? userId,
    String? userName,
  }) {
    final saleData = convertToSaleData(
      quotation: quotation,
      contact: contact,
      userId: userId,
      userName: userName,
    );
    
    return {
      'mode': 'create_from_quotation',
      'quotation_id': quotation.id,
      'quotation': quotation,
      'prefilled_data': saleData,
      'allow_edit': true, // Permitir edição antes de salvar
    };
  }
}

/// Resultado da validação de conversão
class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;
  
  ValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
  });
  
  bool get hasWarnings => warnings.isNotEmpty;
  bool get hasErrors => errors.isNotEmpty;
  
  String get errorMessage => errors.join('\n');
  String get warningMessage => warnings.join('\n');
  
  String get fullMessage {
    final buffer = StringBuffer();
    
    if (hasErrors) {
      buffer.writeln('❌ Erros:');
      buffer.writeln(errorMessage);
    }
    
    if (hasWarnings) {
      if (hasErrors) buffer.writeln('');
      buffer.writeln('⚠️ Avisos:');
      buffer.writeln(warningMessage);
    }
    
    return buffer.toString();
  }
}

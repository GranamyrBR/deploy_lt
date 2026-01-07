import 'package:flutter_test/flutter_test.dart';
import 'package:lecotour_dashboard/models/enhanced_quotation_model.dart';
import 'package:lecotour_dashboard/services/quotation_service.dart';

void main() {
  group('QuotationItem', () {
    test('should create QuotationItem with required fields', () {
      final item = QuotationItem(
        id: 'item_1',
        description: 'Transfer aeroporto',
        date: DateTime(2025, 1, 10),
        value: 120.0,
        category: 'service',
      );

      expect(item.id, 'item_1');
      expect(item.description, 'Transfer aeroporto');
      expect(item.value, 120.0);
      expect(item.category, 'service');
      expect(item.quantity, 1);
    });

    test('should calculate totalValue correctly', () {
      final item = QuotationItem(
        id: 'item_1',
        description: 'City Tour',
        date: DateTime(2025, 1, 10),
        value: 100.0,
        category: 'service',
        quantity: 3,
      );

      expect(item.totalValue, 300.0);
    });

    test('should calculate totalValue with discount', () {
      final item = QuotationItem(
        id: 'item_1',
        description: 'City Tour',
        date: DateTime(2025, 1, 10),
        value: 100.0,
        category: 'service',
        quantity: 2,
        discount: 10.0, // 10% discount
      );

      // 100 * 2 = 200, 10% discount = 20, total = 180
      expect(item.totalValue, 180.0);
    });

    test('should calculate discountAmount correctly', () {
      final item = QuotationItem(
        id: 'item_1',
        description: 'City Tour',
        date: DateTime(2025, 1, 10),
        value: 100.0,
        category: 'service',
        quantity: 2,
        discount: 10.0,
      );

      expect(item.discountAmount, 20.0);
    });

    test('should return zero discountAmount when no discount', () {
      final item = QuotationItem(
        id: 'item_1',
        description: 'City Tour',
        date: DateTime(2025, 1, 10),
        value: 100.0,
        category: 'service',
        quantity: 2,
      );

      expect(item.discountAmount, 0.0);
    });

    test('should copyWith correctly', () {
      final original = QuotationItem(
        id: 'item_1',
        description: 'Transfer',
        date: DateTime(2025, 1, 10),
        value: 100.0,
        category: 'service',
      );

      final copy = original.copyWith(
        value: 150.0,
        quantity: 2,
      );

      expect(copy.id, 'item_1');
      expect(copy.description, 'Transfer');
      expect(copy.value, 150.0);
      expect(copy.quantity, 2);
    });
  });

  group('Quotation', () {
    test('should create Quotation with required fields', () {
      final quotation = Quotation.fromKanbanData(
        id: 'q_1',
        quotationNumber: 'QT-2025-001',
        clientName: 'João Silva',
        clientEmail: 'joao@email.com',
        travelDate: DateTime(2025, 2, 15),
        passengerCount: 2,
        items: [
          QuotationItem(
            id: 'item_1',
            description: 'Transfer Aeroporto',
            date: DateTime(2025, 2, 15),
            value: 120.0,
            category: 'service',
          ),
        ],
        taxRate: 0.0,
        createdBy: 'vendedor_1',
      );

      expect(quotation.quotationNumber, 'QT-2025-001');
      expect(quotation.clientName, 'João Silva');
      expect(quotation.clientEmail, 'joao@email.com');
      expect(quotation.passengerCount, 2);
      expect(quotation.items.length, 1);
      expect(quotation.status, QuotationStatus.draft);
    });

    test('should calculate subtotal correctly', () {
      final quotation = Quotation.fromKanbanData(
        id: 'q_1',
        quotationNumber: 'QT-2025-001',
        clientName: 'João Silva',
        clientEmail: 'joao@email.com',
        travelDate: DateTime(2025, 2, 15),
        passengerCount: 2,
        items: [
          QuotationItem(
            id: 'item_1',
            description: 'Transfer',
            date: DateTime(2025, 2, 15),
            value: 100.0,
            category: 'service',
          ),
          QuotationItem(
            id: 'item_2',
            description: 'City Tour',
            date: DateTime(2025, 2, 16),
            value: 200.0,
            category: 'service',
          ),
        ],
        taxRate: 0.0,
        createdBy: 'vendedor_1',
      );

      expect(quotation.subtotal, 300.0);
      expect(quotation.total, 300.0);
    });

    test('should calculate total with tax', () {
      final quotation = Quotation.fromKanbanData(
        id: 'q_1',
        quotationNumber: 'QT-2025-001',
        clientName: 'João Silva',
        clientEmail: 'joao@email.com',
        travelDate: DateTime(2025, 2, 15),
        passengerCount: 2,
        items: [
          QuotationItem(
            id: 'item_1',
            description: 'Transfer',
            date: DateTime(2025, 2, 15),
            value: 100.0,
            category: 'service',
          ),
        ],
        taxRate: 10.0, // 10% tax
        createdBy: 'vendedor_1',
      );

      expect(quotation.subtotal, 100.0);
      expect(quotation.taxAmount, 10.0);
      expect(quotation.total, 110.0);
    });

    test('should format total correctly', () {
      final quotation = Quotation.fromKanbanData(
        id: 'q_1',
        quotationNumber: 'QT-2025-001',
        clientName: 'João Silva',
        clientEmail: 'joao@email.com',
        travelDate: DateTime(2025, 2, 15),
        passengerCount: 2,
        items: [
          QuotationItem(
            id: 'item_1',
            description: 'Transfer',
            date: DateTime(2025, 2, 15),
            value: 123.45,
            category: 'service',
          ),
        ],
        taxRate: 0.0,
        createdBy: 'vendedor_1',
      );

      expect(quotation.formattedTotal, 'USD 123.45');
    });

    test('should detect expired quotation', () {
      final expiredQuotation = Quotation(
        id: 'q_1',
        quotationNumber: 'QT-2025-001',
        type: QuotationType.tourism,
        status: QuotationStatus.sent,
        clientName: 'João Silva',
        clientEmail: 'joao@email.com',
        travelDate: DateTime(2025, 2, 15),
        passengerCount: 2,
        items: [],
        subtotal: 0,
        taxRate: 0,
        taxAmount: 0,
        total: 0,
        quotationDate: DateTime.now().subtract(const Duration(days: 30)),
        expirationDate: DateTime.now().subtract(const Duration(days: 1)), // Expired yesterday
        createdBy: 'vendedor_1',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      );

      expect(expiredQuotation.isExpired, true);
    });

    test('should not detect non-expired quotation', () {
      final validQuotation = Quotation(
        id: 'q_1',
        quotationNumber: 'QT-2025-001',
        type: QuotationType.tourism,
        status: QuotationStatus.sent,
        clientName: 'João Silva',
        clientEmail: 'joao@email.com',
        travelDate: DateTime(2025, 2, 15),
        passengerCount: 2,
        items: [],
        subtotal: 0,
        taxRate: 0,
        taxAmount: 0,
        total: 0,
        quotationDate: DateTime.now(),
        expirationDate: DateTime.now().add(const Duration(days: 7)), // Expires in 7 days
        createdBy: 'vendedor_1',
        createdAt: DateTime.now(),
      );

      expect(validQuotation.isExpired, false);
    });

    test('should display status name correctly', () {
      final draftQuotation = Quotation(
        id: 'q_1',
        quotationNumber: 'QT-2025-001',
        type: QuotationType.tourism,
        status: QuotationStatus.draft,
        clientName: 'João Silva',
        clientEmail: 'joao@email.com',
        travelDate: DateTime(2025, 2, 15),
        passengerCount: 2,
        items: [],
        subtotal: 0,
        taxRate: 0,
        taxAmount: 0,
        total: 0,
        quotationDate: DateTime.now(),
        createdBy: 'vendedor_1',
        createdAt: DateTime.now(),
      );

      expect(draftQuotation.statusDisplayName, 'Rascunho');
    });

    test('should display type name correctly', () {
      final quotation = Quotation(
        id: 'q_1',
        quotationNumber: 'QT-2025-001',
        type: QuotationType.corporate,
        status: QuotationStatus.draft,
        clientName: 'João Silva',
        clientEmail: 'joao@email.com',
        travelDate: DateTime(2025, 2, 15),
        passengerCount: 2,
        items: [],
        subtotal: 0,
        taxRate: 0,
        taxAmount: 0,
        total: 0,
        quotationDate: DateTime.now(),
        createdBy: 'vendedor_1',
        createdAt: DateTime.now(),
      );

      expect(quotation.typeDisplayName, 'Corporativo');
    });

    test('should calculate agency commission', () {
      final quotation = Quotation(
        id: 'q_1',
        quotationNumber: 'QT-2025-001',
        type: QuotationType.tourism,
        status: QuotationStatus.draft,
        clientName: 'João Silva',
        clientEmail: 'joao@email.com',
        agency: Agency(
          id: '1',
          name: 'Agência ABC',
          commissionRate: 10.0,
        ),
        agencyCommissionRate: 10.0,
        travelDate: DateTime(2025, 2, 15),
        passengerCount: 2,
        items: [],
        subtotal: 1000.0,
        taxRate: 0,
        taxAmount: 0,
        total: 1000.0,
        quotationDate: DateTime.now(),
        createdBy: 'vendedor_1',
        createdAt: DateTime.now(),
      );

      expect(quotation.agencyCommission, 100.0); // 10% of 1000
    });

    test('toMap should include all fields', () {
      final quotation = Quotation.fromKanbanData(
        id: 'q_1',
        quotationNumber: 'QT-2025-001',
        clientName: 'João Silva',
        clientEmail: 'joao@email.com',
        travelDate: DateTime(2025, 2, 15),
        passengerCount: 2,
        items: [
          QuotationItem(
            id: 'item_1',
            description: 'Transfer',
            date: DateTime(2025, 2, 15),
            value: 100.0,
            category: 'service',
          ),
        ],
        taxRate: 5.0,
        createdBy: 'vendedor_1',
      );

      final map = quotation.toMap();

      expect(map['quotationNumber'], 'QT-2025-001');
      expect(map['clientName'], 'João Silva');
      expect(map['clientEmail'], 'joao@email.com');
      expect(map['passengerCount'], 2);
      expect(map['taxRate'], 5.0);
      expect(map['items'], isA<List>());
      expect((map['items'] as List).length, 1);
    });
  });

  group('QuotationFilter', () {
    test('should create filter with default values', () {
      const filter = QuotationFilter();

      expect(filter.limit, 50);
      expect(filter.offset, 0);
      expect(filter.id, isNull);
      expect(filter.clientId, isNull);
      expect(filter.status, isNull);
    });

    test('should create filter with custom values', () {
      final filter = QuotationFilter(
        clientId: 123,
        status: 'sent',
        fromDate: DateTime(2025, 1, 1),
        toDate: DateTime(2025, 12, 31),
        limit: 20,
      );

      expect(filter.clientId, 123);
      expect(filter.status, 'sent');
      expect(filter.fromDate, DateTime(2025, 1, 1));
      expect(filter.limit, 20);
    });

    test('toParams should include all non-null values', () {
      final filter = QuotationFilter(
        clientId: 123,
        status: 'sent',
        limit: 20,
      );

      final params = filter.toParams();

      expect(params['p_client_id'], 123);
      expect(params['p_status'], 'sent');
      expect(params['p_limit'], 20);
      expect(params['p_id'], isNull);
    });
  });

  group('QuotationSaveResult', () {
    test('should create successful result', () {
      final result = QuotationSaveResult(id: 123, success: true);

      expect(result.id, 123);
      expect(result.success, true);
      expect(result.errorMessage, isNull);
    });

    test('should create failed result with error', () {
      final result = QuotationSaveResult(
        id: 0,
        success: false,
        errorMessage: 'Validation failed',
      );

      expect(result.id, 0);
      expect(result.success, false);
      expect(result.errorMessage, 'Validation failed');
    });

    test('should parse from JSON', () {
      final json = {
        'id': 456,
        'success': true,
      };

      final result = QuotationSaveResult.fromJson(json);

      expect(result.id, 456);
      expect(result.success, true);
    });
  });

  group('SmartSuggestions', () {
    test('should combine suggestions from all sources', () {
      final suggestions = SmartSuggestions(
        byHistory: [
          {'id': 1, 'name': 'Service A'},
        ].map((e) => e).toList().cast<Map<String, dynamic>>(),
        byDestination: [
          {'id': 2, 'name': 'Service B'},
        ].map((e) => e).toList().cast<Map<String, dynamic>>(),
        byHotel: [
          {'id': 3, 'name': 'Service C'},
        ].map((e) => e).toList().cast<Map<String, dynamic>>(),
      );

      expect(suggestions.all.length, 3);
      expect(suggestions.isEmpty, false);
    });

    test('should detect empty suggestions', () {
      const suggestions = SmartSuggestions(
        byHistory: [],
        byDestination: [],
        byHotel: [],
      );

      expect(suggestions.isEmpty, true);
      expect(suggestions.all.length, 0);
    });
  });

  group('PreTripAction', () {
    test('should parse from JSON', () {
      final json = {
        'id': 1,
        'quotation_id': 100,
        'action_type': 'call',
        'scheduled_at': '2025-02-14T10:00:00Z',
        'client_name': 'João Silva',
        'client_phone': '+55 11 99999-9999',
        'quotation_number': 'QT-2025-001',
      };

      final action = PreTripAction.fromJson(json);

      expect(action.id, 1);
      expect(action.quotationId, 100);
      expect(action.actionType, 'call');
      expect(action.clientName, 'João Silva');
      expect(action.quotationNumber, 'QT-2025-001');
    });
  });

  group('QuotationStats', () {
    test('should parse from JSON', () {
      final json = {
        'total': 100,
        'by_status': {'draft': 20, 'sent': 50, 'accepted': 30},
        'total_value_usd': 50000.0,
        'avg_value_usd': 500.0,
        'conversion_rate': 60.0,
      };

      final stats = QuotationStats.fromJson(json);

      expect(stats.total, 100);
      expect(stats.byStatus['draft'], 20);
      expect(stats.byStatus['sent'], 50);
      expect(stats.byStatus['accepted'], 30);
      expect(stats.totalValueUsd, 50000.0);
      expect(stats.avgValueUsd, 500.0);
      expect(stats.conversionRate, 60.0);
    });
  });

  group('QuotationService Validation', () {
    late QuotationService service;

    setUp(() {
      service = QuotationService();
    });

    test('should validate empty client name', () {
      final quotation = Quotation(
        id: 'q_1',
        quotationNumber: 'QT-2025-001',
        type: QuotationType.tourism,
        status: QuotationStatus.draft,
        clientName: '', // Empty
        clientEmail: 'test@email.com',
        travelDate: DateTime(2025, 2, 15),
        passengerCount: 2,
        items: [
          QuotationItem(
            id: 'item_1',
            description: 'Transfer',
            date: DateTime(2025, 2, 15),
            value: 100.0,
            category: 'service',
          ),
        ],
        subtotal: 100.0,
        taxRate: 0,
        taxAmount: 0,
        total: 100.0,
        quotationDate: DateTime.now(),
        createdBy: 'vendedor_1',
        createdAt: DateTime.now(),
      );

      final error = service.validateQuotation(quotation);
      expect(error, 'Nome do cliente é obrigatório');
    });

    test('should validate empty client email', () {
      final quotation = Quotation(
        id: 'q_1',
        quotationNumber: 'QT-2025-001',
        type: QuotationType.tourism,
        status: QuotationStatus.draft,
        clientName: 'João Silva',
        clientEmail: '', // Empty
        travelDate: DateTime(2025, 2, 15),
        passengerCount: 2,
        items: [
          QuotationItem(
            id: 'item_1',
            description: 'Transfer',
            date: DateTime(2025, 2, 15),
            value: 100.0,
            category: 'service',
          ),
        ],
        subtotal: 100.0,
        taxRate: 0,
        taxAmount: 0,
        total: 100.0,
        quotationDate: DateTime.now(),
        createdBy: 'vendedor_1',
        createdAt: DateTime.now(),
      );

      final error = service.validateQuotation(quotation);
      expect(error, 'Email do cliente é obrigatório');
    });

    test('should validate invalid email format', () {
      final quotation = Quotation(
        id: 'q_1',
        quotationNumber: 'QT-2025-001',
        type: QuotationType.tourism,
        status: QuotationStatus.draft,
        clientName: 'João Silva',
        clientEmail: 'invalid-email', // Invalid format
        travelDate: DateTime(2025, 2, 15),
        passengerCount: 2,
        items: [
          QuotationItem(
            id: 'item_1',
            description: 'Transfer',
            date: DateTime(2025, 2, 15),
            value: 100.0,
            category: 'service',
          ),
        ],
        subtotal: 100.0,
        taxRate: 0,
        taxAmount: 0,
        total: 100.0,
        quotationDate: DateTime.now(),
        createdBy: 'vendedor_1',
        createdAt: DateTime.now(),
      );

      final error = service.validateQuotation(quotation);
      expect(error, 'Email do cliente inválido');
    });

    test('should validate empty items', () {
      final quotation = Quotation(
        id: 'q_1',
        quotationNumber: 'QT-2025-001',
        type: QuotationType.tourism,
        status: QuotationStatus.draft,
        clientName: 'João Silva',
        clientEmail: 'joao@email.com',
        travelDate: DateTime(2025, 2, 15),
        passengerCount: 2,
        items: [], // Empty items
        subtotal: 0,
        taxRate: 0,
        taxAmount: 0,
        total: 0,
        quotationDate: DateTime.now(),
        createdBy: 'vendedor_1',
        createdAt: DateTime.now(),
      );

      final error = service.validateQuotation(quotation);
      expect(error, 'Cotação deve ter pelo menos um item');
    });

    test('should validate invalid passenger count', () {
      final quotation = Quotation(
        id: 'q_1',
        quotationNumber: 'QT-2025-001',
        type: QuotationType.tourism,
        status: QuotationStatus.draft,
        clientName: 'João Silva',
        clientEmail: 'joao@email.com',
        travelDate: DateTime(2025, 2, 15),
        passengerCount: 0, // Invalid
        items: [
          QuotationItem(
            id: 'item_1',
            description: 'Transfer',
            date: DateTime(2025, 2, 15),
            value: 100.0,
            category: 'service',
          ),
        ],
        subtotal: 100.0,
        taxRate: 0,
        taxAmount: 0,
        total: 100.0,
        quotationDate: DateTime.now(),
        createdBy: 'vendedor_1',
        createdAt: DateTime.now(),
      );

      final error = service.validateQuotation(quotation);
      expect(error, 'Número de passageiros deve ser maior que zero');
    });

    test('should pass validation for valid quotation', () {
      final quotation = Quotation(
        id: 'q_1',
        quotationNumber: 'QT-2025-001',
        type: QuotationType.tourism,
        status: QuotationStatus.draft,
        clientName: 'João Silva',
        clientEmail: 'joao@email.com',
        travelDate: DateTime(2025, 2, 15),
        passengerCount: 2,
        items: [
          QuotationItem(
            id: 'item_1',
            description: 'Transfer',
            date: DateTime(2025, 2, 15),
            value: 100.0,
            category: 'service',
          ),
        ],
        subtotal: 100.0,
        taxRate: 0,
        taxAmount: 0,
        total: 100.0,
        quotationDate: DateTime.now(),
        createdBy: 'vendedor_1',
        createdAt: DateTime.now(),
      );

      final error = service.validateQuotation(quotation);
      expect(error, isNull); // No error = valid
    });
  });
}

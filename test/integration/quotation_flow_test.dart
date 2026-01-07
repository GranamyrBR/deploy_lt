import 'package:flutter_test/flutter_test.dart';
import 'package:lecotour_dashboard/models/enhanced_quotation_model.dart';
import 'package:lecotour_dashboard/services/quotation_service.dart';
import 'package:lecotour_dashboard/services/pre_trip_action_service.dart';
import 'package:lecotour_dashboard/services/suggestion_engine_service.dart';

/// Integration tests for the quotation system flow
/// These tests verify the complete quotation lifecycle
void main() {
  group('Quotation Lifecycle Flow', () {
    late QuotationService quotationService;
    late PreTripActionService preTripActionService;
    late SuggestionEngineService suggestionEngine;

    setUp(() {
      quotationService = QuotationService();
      preTripActionService = PreTripActionService(
        quotationService: quotationService,
      );
      suggestionEngine = SuggestionEngineService();
    });

    test('should create a complete quotation with items', () {
      // Arrange
      final items = [
        QuotationItem(
          id: 'item_1',
          description: 'Transfer Aeroporto JFK -> Manhattan',
          date: DateTime(2025, 3, 15, 14, 0),
          value: 150.0,
          category: 'service',
          serviceId: '1',
          quantity: 1,
        ),
        QuotationItem(
          id: 'item_2',
          description: 'City Tour New York',
          date: DateTime(2025, 3, 16, 9, 0),
          value: 200.0,
          category: 'service',
          serviceId: '2',
          quantity: 2,
        ),
        QuotationItem(
          id: 'item_3',
          description: 'Ingresso Estátua da Liberdade',
          date: DateTime(2025, 3, 16, 10, 0),
          value: 25.0,
          category: 'product',
          productId: '10',
          quantity: 2,
        ),
      ];

      // Act
      final quotation = Quotation.fromKanbanData(
        id: 'q_test_1',
        quotationNumber: 'QT-2025-TEST-001',
        clientName: 'Maria Santos',
        clientEmail: 'maria.santos@email.com',
        clientPhone: '+55 11 98765-4321',
        travelDate: DateTime(2025, 3, 15),
        passengerCount: 2,
        items: items,
        taxRate: 8.0, // 8% tax
        createdBy: 'test_user',
        notes: 'Cliente VIP - primeira viagem',
      );

      // Assert
      expect(quotation.items.length, 3);
      expect(quotation.subtotal, 600.0); // 150 + (200*2) + (25*2) = 600
      expect(quotation.taxAmount, 48.0); // 8% of 600
      expect(quotation.total, 648.0);
      expect(quotation.status, QuotationStatus.draft);
      expect(quotation.currency, 'USD');
    });

    test('should validate quotation before saving', () {
      // Arrange - Invalid quotation (no items)
      final invalidQuotation = Quotation(
        id: 'q_invalid',
        quotationNumber: 'QT-INVALID',
        type: QuotationType.tourism,
        status: QuotationStatus.draft,
        clientName: 'Test Client',
        clientEmail: 'test@email.com',
        travelDate: DateTime(2025, 3, 15),
        passengerCount: 1,
        items: [], // No items
        subtotal: 0,
        taxRate: 0,
        taxAmount: 0,
        total: 0,
        quotationDate: DateTime.now(),
        createdBy: 'test',
        createdAt: DateTime.now(),
      );

      // Act
      final error = quotationService.validateQuotation(invalidQuotation);

      // Assert
      expect(error, isNotNull);
      expect(error, contains('pelo menos um item'));
    });

    test('should transition through quotation statuses correctly', () {
      // Arrange
      final quotation = Quotation(
        id: 'q_status_test',
        quotationNumber: 'QT-STATUS-001',
        type: QuotationType.tourism,
        status: QuotationStatus.draft,
        clientName: 'Status Test Client',
        clientEmail: 'status@email.com',
        travelDate: DateTime(2025, 4, 1),
        passengerCount: 1,
        items: [
          QuotationItem(
            id: 'item_1',
            description: 'Test Service',
            date: DateTime(2025, 4, 1),
            value: 100.0,
            category: 'service',
          ),
        ],
        subtotal: 100.0,
        taxRate: 0,
        taxAmount: 0,
        total: 100.0,
        quotationDate: DateTime.now(),
        createdBy: 'test',
        createdAt: DateTime.now(),
      );

      // Assert initial state
      expect(quotation.status, QuotationStatus.draft);

      // Simulate status transitions
      final sentQuotation = quotation.copyWith(
        status: QuotationStatus.sent,
        sentDate: DateTime.now(),
      );
      expect(sentQuotation.status, QuotationStatus.sent);
      expect(sentQuotation.sentDate, isNotNull);

      final viewedQuotation = sentQuotation.copyWith(
        status: QuotationStatus.viewed,
        viewedDate: DateTime.now(),
      );
      expect(viewedQuotation.status, QuotationStatus.viewed);

      final acceptedQuotation = viewedQuotation.copyWith(
        status: QuotationStatus.accepted,
        acceptedDate: DateTime.now(),
      );
      expect(acceptedQuotation.status, QuotationStatus.accepted);
      expect(acceptedQuotation.acceptedDate, isNotNull);
    });

    test('should calculate agency commission correctly', () {
      // Arrange
      final quotation = Quotation(
        id: 'q_commission',
        quotationNumber: 'QT-COMM-001',
        type: QuotationType.tourism,
        status: QuotationStatus.draft,
        clientName: 'Commission Test',
        clientEmail: 'comm@email.com',
        agency: Agency(
          id: 'ag_1',
          name: 'Travel Agency XYZ',
          email: 'agency@xyz.com',
          commissionRate: 15.0,
        ),
        agencyCommissionRate: 15.0,
        travelDate: DateTime(2025, 5, 1),
        passengerCount: 4,
        items: [
          QuotationItem(
            id: 'item_1',
            description: 'VIP Transfer',
            date: DateTime(2025, 5, 1),
            value: 500.0,
            category: 'service',
            quantity: 1,
          ),
          QuotationItem(
            id: 'item_2',
            description: 'Full Day Tour',
            date: DateTime(2025, 5, 2),
            value: 1500.0,
            category: 'service',
            quantity: 1,
          ),
        ],
        subtotal: 2000.0,
        taxRate: 0,
        taxAmount: 0,
        total: 2000.0,
        quotationDate: DateTime.now(),
        createdBy: 'test',
        createdAt: DateTime.now(),
      );

      // Act
      final commission = quotation.agencyCommission;

      // Assert
      expect(commission, 300.0); // 15% of 2000 = 300
    });

    test('should detect expired quotations', () {
      // Arrange - Expired quotation
      final expiredQuotation = Quotation(
        id: 'q_expired',
        quotationNumber: 'QT-EXP-001',
        type: QuotationType.tourism,
        status: QuotationStatus.sent,
        clientName: 'Expired Test',
        clientEmail: 'expired@email.com',
        travelDate: DateTime(2025, 6, 1),
        passengerCount: 1,
        items: [
          QuotationItem(
            id: 'item_1',
            description: 'Test',
            date: DateTime(2025, 6, 1),
            value: 100.0,
            category: 'service',
          ),
        ],
        subtotal: 100.0,
        taxRate: 0,
        taxAmount: 0,
        total: 100.0,
        quotationDate: DateTime.now().subtract(const Duration(days: 14)),
        expirationDate: DateTime.now().subtract(const Duration(days: 1)), // Expired yesterday
        createdBy: 'test',
        createdAt: DateTime.now().subtract(const Duration(days: 14)),
      );

      // Valid quotation
      final validQuotation = expiredQuotation.copyWith(
        expirationDate: DateTime.now().add(const Duration(days: 7)),
      );

      // Assert
      expect(expiredQuotation.isExpired, true);
      expect(validQuotation.isExpired, false);
    });

    test('should generate correct quotation map for database', () {
      // Arrange
      final quotation = Quotation.fromKanbanData(
        id: 'q_map_test',
        quotationNumber: 'QT-MAP-001',
        clientName: 'Map Test Client',
        clientEmail: 'map@email.com',
        clientPhone: '+1 555 123 4567',
        travelDate: DateTime(2025, 7, 15),
        passengerCount: 3,
        items: [
          QuotationItem(
            id: 'item_1',
            description: 'Airport Transfer',
            date: DateTime(2025, 7, 15),
            value: 120.0,
            category: 'service',
            serviceId: '5',
          ),
        ],
        taxRate: 10.0,
        createdBy: 'map_test_user',
        notes: 'Test notes',
      );

      // Act
      final map = quotation.toMap();

      // Assert
      expect(map['quotationNumber'], 'QT-MAP-001');
      expect(map['clientName'], 'Map Test Client');
      expect(map['clientEmail'], 'map@email.com');
      expect(map['clientPhone'], '+1 555 123 4567');
      expect(map['passengerCount'], 3);
      expect(map['taxRate'], 10.0);
      expect(map['subtotal'], 120.0);
      expect(map['taxAmount'], 12.0); // 10% of 120
      expect(map['total'], 132.0);
      expect(map['status'], 'draft');
      expect(map['type'], 'tourism');
      expect(map['currency'], 'USD');
      expect(map['createdBy'], 'map_test_user');
      expect(map['notes'], 'Test notes');
      expect(map['items'], isA<List>());
      expect((map['items'] as List).first['serviceId'], '5');
    });
  });

  group('Pre-Trip Actions Flow', () {
    test('should build template context correctly', () {
      // Arrange
      final preTripService = PreTripActionService();
      final action = PreTripAction(
        id: 1,
        quotationId: 100,
        actionType: 'call',
        scheduledAt: DateTime(2025, 3, 14, 10, 0),
        clientName: 'John Doe',
        clientPhone: '+1 555 999 8888',
        clientEmail: 'john@email.com',
        travelDate: DateTime(2025, 3, 15, 14, 0),
        quotationNumber: 'QT-2025-100',
      );

      final quotationData = {
        'pickup_location': 'JFK Airport Terminal 4',
        'vehicle': 'Mercedes Sprinter',
        'driver': 'Carlos Silva',
        'passenger_count': 2,
        'service_description': 'Airport Transfer',
        'total': 180.0,
        'notes': 'VIP client',
      };

      // Act
      final context = preTripService.buildTemplateContext(action, quotationData);

      // Assert
      expect(context['client_name'], 'John Doe');
      expect(context['client_phone'], '+1 555 999 8888');
      expect(context['client_email'], 'john@email.com');
      expect(context['quotation_number'], 'QT-2025-100');
      expect(context['pickup_location'], 'JFK Airport Terminal 4');
      expect(context['vehicle'], 'Mercedes Sprinter');
      expect(context['driver_name'], 'Carlos Silva');
      expect(context['passenger_count'], '2');
      expect(context['service_description'], 'Airport Transfer');
      expect(context['notes'], 'VIP client');
    });

    test('should get message templates by type', () {
      // Arrange
      final preTripService = PreTripActionService();

      // Act
      final whatsappTemplates = preTripService.getTemplatesByType(PreTripActionType.whatsapp);
      final callTemplates = preTripService.getTemplatesByType(PreTripActionType.call);
      final emailTemplates = preTripService.getTemplatesByType(PreTripActionType.email);

      // Assert
      expect(whatsappTemplates.length, greaterThan(0));
      expect(callTemplates.length, greaterThan(0));
      expect(emailTemplates.length, greaterThan(0));
      
      // Verify all templates match their type
      for (final template in whatsappTemplates) {
        expect(template.actionType, PreTripActionType.whatsapp);
      }
    });
  });

  group('Suggestion Engine Flow', () {
    test('should create Suggestion from JSON', () {
      // Arrange
      final json = {
        'id': 5,
        'kind': 'service',
        'name': 'City Tour Premium',
        'description': 'Full day guided city tour',
        'price': 250.0,
        'reason': 'Popular em New York',
        'reason_code': 'destination',
        'relevance_score': 1.3,
      };

      // Act
      final suggestion = Suggestion.fromJson(json);

      // Assert
      expect(suggestion.id, 5);
      expect(suggestion.type, SuggestionType.service);
      expect(suggestion.name, 'City Tour Premium');
      expect(suggestion.description, 'Full day guided city tour');
      expect(suggestion.price, 250.0);
      expect(suggestion.reason, SuggestionReason.popularInDestination);
      expect(suggestion.reasonText, 'Popular em New York');
      expect(suggestion.relevanceScore, 1.3);
    });

    test('should combine SuggestionBundle correctly', () {
      // Arrange
      final bundle = SuggestionBundle(
        byHistory: [
          Suggestion(
            id: 1,
            type: SuggestionType.service,
            name: 'Service A',
            price: 100,
            reason: SuggestionReason.purchaseHistory,
            reasonText: 'You bought this before',
            relevanceScore: 1.5,
          ),
        ],
        byDestination: [
          Suggestion(
            id: 2,
            type: SuggestionType.service,
            name: 'Service B',
            price: 200,
            reason: SuggestionReason.popularInDestination,
            reasonText: 'Popular in NYC',
            relevanceScore: 1.3,
          ),
        ],
        byHotel: [
          Suggestion(
            id: 3,
            type: SuggestionType.service,
            name: 'Service C',
            price: 150,
            reason: SuggestionReason.hotelRecommendation,
            reasonText: 'For hotel guests',
            relevanceScore: 1.2,
          ),
        ],
      );

      // Act
      final all = bundle.all;
      final top2 = bundle.getTop(2);

      // Assert
      expect(all.length, 3);
      expect(bundle.isEmpty, false);
      expect(bundle.totalCount, 3);
      
      // Should be sorted by relevance (descending)
      expect(all[0].id, 1); // relevanceScore 1.5
      expect(all[1].id, 2); // relevanceScore 1.3
      expect(all[2].id, 3); // relevanceScore 1.2
      
      expect(top2.length, 2);
      expect(top2[0].id, 1);
      expect(top2[1].id, 2);
    });

    test('should remove duplicate suggestions', () {
      // Arrange - Same suggestion in multiple categories
      final bundle = SuggestionBundle(
        byHistory: [
          Suggestion(
            id: 1,
            type: SuggestionType.service,
            name: 'Transfer',
            price: 100,
            reason: SuggestionReason.purchaseHistory,
            reasonText: 'Reason 1',
            relevanceScore: 1.5,
          ),
        ],
        byDestination: [
          Suggestion(
            id: 1, // Same ID
            type: SuggestionType.service,
            name: 'Transfer',
            price: 100,
            reason: SuggestionReason.popularInDestination,
            reasonText: 'Reason 2',
            relevanceScore: 1.3,
          ),
        ],
      );

      // Act
      final all = bundle.all;

      // Assert - Should have only one entry for ID 1
      expect(all.length, 1);
      expect(all[0].id, 1);
      // Should keep the first occurrence (higher relevance)
      expect(all[0].relevanceScore, 1.5);
    });

    test('should parse customer preference from JSON', () {
      // Arrange
      final json = {
        'client_id': 123,
        'preference_type': 'service_category',
        'preference_value': 'transfers',
        'preference_score': 2.5,
        'source': 'inferred',
      };

      // Act
      final preference = CustomerPreference.fromJson(json);

      // Assert
      expect(preference.clientId, 123);
      expect(preference.preferenceType, 'service_category');
      expect(preference.preferenceValue, 'transfers');
      expect(preference.score, 2.5);
      expect(preference.source, 'inferred');
    });
  });

  group('QuotationFilter Edge Cases', () {
    test('should handle all filter parameters', () {
      // Arrange
      final filter = QuotationFilter(
        id: 100,
        clientId: 200,
        agencyId: 300,
        status: 'accepted',
        type: 'corporate',
        fromDate: DateTime(2025, 1, 1),
        toDate: DateTime(2025, 12, 31),
        travelDateFrom: DateTime(2025, 3, 1),
        travelDateTo: DateTime(2025, 3, 31),
        createdBy: 'user_123',
        isExpired: false,
        limit: 25,
        offset: 50,
      );

      // Act
      final params = filter.toParams();

      // Assert
      expect(params['p_id'], 100);
      expect(params['p_client_id'], 200);
      expect(params['p_agency_id'], 300);
      expect(params['p_status'], 'accepted');
      expect(params['p_type'], 'corporate');
      expect(params['p_limit'], 25);
      expect(params['p_offset'], 50);
    });

    test('should handle default filter values', () {
      // Arrange
      const filter = QuotationFilter();

      // Assert
      expect(filter.id, isNull);
      expect(filter.clientId, isNull);
      expect(filter.status, isNull);
      expect(filter.limit, 50);
      expect(filter.offset, 0);
    });
  });
}


import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lecotour_dashboard/widgets/customer_profile_modal.dart';
import 'package:lecotour_dashboard/services/customer_analytics_service.dart';

class FakeAnalyticsService extends CustomerAnalyticsService {
  @override
  Future<Map<String, dynamic>> getCustomerAnalytics(int customerId) async {
    return {
      'customer': {
        'id': customerId,
        'name': 'Cliente Modal',
        'email': 'modal@example.com',
        'phone': '123',
        'city': 'Cidade',
        'state': 'Estado',
        'country': 'País',
        'is_vip': false,
        'account': {'name': 'Agência Y'},
      },
      'sales': {
        'sales': [],
        'statistics': {
          'totalSales': 0,
          'totalSpentUSD': 0.0,
          'averageOrderValue': 0.0,
        }
      },
      'operations': {
        'operations': [],
        'statistics': {
          'totalOperations': 0,
          'completedOperations': 0,
          'cancelledOperations': 0,
          'averageCustomerRating': 0.0,
        }
      },
      'ratings': {'allRatings': []},
      'metrics': {
        'firstPurchase': null,
        'lastPurchase': null,
        'purchaseFrequency': 0.0,
        'completionRate': 0.0,
      },
      'comparative': {'allCustomers': {}, 'agency': {}},
    };
  }
}

void main() {
  testWidgets('CustomerProfileModal renderiza conteúdo compartilhado', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) {
        Future.microtask(() {
          showDialog(
            context: context,
            builder: (_) => CustomerProfileModal(
              customerId: 999,
              customerName: 'Cliente Modal',
              analyticsService: FakeAnalyticsService(),
            ),
          );
        });
        return const SizedBox.shrink();
      }),
    ));

    await tester.pumpAndSettle();

    expect(find.text('Visão Geral'), findsOneWidget);
    expect(find.text('Cliente Modal'), findsWidgets);
  });
}

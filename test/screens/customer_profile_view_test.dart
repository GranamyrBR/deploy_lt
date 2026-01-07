import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lecotour_dashboard/widgets/customer_profile_view.dart';
import 'package:lecotour_dashboard/services/customer_analytics_service.dart';

class FakeAnalyticsService extends CustomerAnalyticsService {
  @override
  Future<Map<String, dynamic>> getCustomerAnalytics(int customerId) async {
    return {
      'customer': {
        'id': customerId,
        'name': 'Cliente Teste',
        'email': 'teste@example.com',
        'phone': '123',
        'city': 'Cidade',
        'state': 'Estado',
        'country': 'País',
        'is_vip': false,
        'account': {'name': 'Agência X'},
      },
      'sales': {
        'sales': [
          {'id': 1, 'sale_number': 'S-001', 'status': 'completed', 'total_amount_usd': 100.0},
        ],
        'statistics': {
          'totalSales': 1,
          'totalSpentUSD': 100.0,
          'averageOrderValue': 100.0,
        }
      },
      'operations': {
        'operations': [
          {'id': 1, 'status': 'completed', 'pickup_location': 'A', 'dropoff_location': 'B', 'service_value_usd': 50.0}
        ],
        'statistics': {
          'totalOperations': 1,
          'completedOperations': 1,
          'cancelledOperations': 0,
          'averageCustomerRating': 4.5,
        }
      },
      'ratings': {
        'allRatings': [
          {'id': 1, 'customer_rating': 5, 'customer_feedback': 'Ótimo'}
        ]
      },
      'metrics': {
        'firstPurchase': DateTime.now().toIso8601String(),
        'lastPurchase': DateTime.now().toIso8601String(),
        'purchaseFrequency': 1.0,
        'completionRate': 1.0,
      },
      'comparative': {'allCustomers': {}, 'agency': {}},
    };
  }
}

void main() {
  testWidgets('CustomerProfileView exibe tabs e nome do cliente', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CustomerProfileView(
          customerId: 123,
          customerName: 'Cliente Teste',
          analyticsService: FakeAnalyticsService(),
        ),
      ),
    ));

    // aguardar carregamento
    await tester.pumpAndSettle();

    expect(find.text('Visão Geral'), findsOneWidget);
    expect(find.text('Vendas'), findsOneWidget);
    expect(find.text('Operações'), findsOneWidget);
    expect(find.text('Avaliações'), findsOneWidget);
    expect(find.text('Comparativo'), findsOneWidget);
    expect(find.text('Cliente Teste'), findsWidgets);
  });
}

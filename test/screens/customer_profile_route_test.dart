import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lecotour_dashboard/main.dart';
import 'package:lecotour_dashboard/screens/customer_profile_screen.dart';

void main() {
  testWidgets('Rota /customer-profile navega para CustomerProfileScreen', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      routes: {
        '/customer-profile': (context) => const CustomerProfileScreen(customerId: 1, customerName: 'Teste'),
      },
      home: Builder(builder: (context) {
        return Center(
          child: ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/customer-profile'),
            child: const Text('Ir'),
          ),
        );
      }),
    ));

    await tester.tap(find.text('Ir'));
    await tester.pumpAndSettle();

    expect(find.byType(CustomerProfileScreen), findsOneWidget);
    expect(find.text('Teste'), findsWidgets);
  });
}


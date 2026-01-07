import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lecotour_dashboard/widgets/contacts_multi_view.dart';

void main() {
  testWidgets('ContactsMultiView agrupa por categoria e mostra cabeçalhos', (WidgetTester tester) async {
    final contacts = [
      {'id': 1, 'name': 'Alice', 'contact_category': {'name': 'VIP'}},
      {'id': 2, 'name': 'Bob', 'contact_category': {'name': 'Regular'}},
      {'id': 3, 'name': 'Carol', 'contact_category': {'name': 'VIP'}},
    ];

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ContactsMultiView(
          contacts: contacts,
          onOpenProfileModal: (_) {},
          onOpenProfilePage: (_) {},
          onOpenWhatsApp: (_) {},
          onCreateSale: (_) {},
        ),
      ),
    ));

    await tester.tap(find.text('Sem agrupamento'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Categoria'));
    await tester.pumpAndSettle();

    expect(find.textContaining('VIP'), findsWidgets);
    expect(find.textContaining('Regular'), findsWidgets);
  });
}


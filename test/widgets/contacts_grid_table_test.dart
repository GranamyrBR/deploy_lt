import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lecotour_dashboard/widgets/contacts_grid_table.dart';

void main() {
  testWidgets('ContactsGridTable exibe colunas e aciona ações', (WidgetTester tester) async {
    final calls = <String>[];
    final contacts = [
      {
        'id': 1,
        'name': 'Alice',
        'email': 'alice@example.com',
        'phone': '111',
        'city': 'NYC',
        'country': 'USA',
        'account': {'name': 'Agency A'},
        'contact_category': {'name': 'VIP'},
        'updated_at': '2025-12-01'
      }
    ];

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ContactsGridTable(
          contacts: contacts,
          onOpenProfileModal: (c) => calls.add('modal_${c['id']}'),
          onOpenProfilePage: (c) => calls.add('page_${c['id']}'),
          onOpenWhatsApp: (c) => calls.add('wa_${c['id']}'),
          onCreateSale: (c) => calls.add('sale_${c['id']}'),
        ),
      ),
    ));

    expect(find.text('Nome'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Telefone'), findsOneWidget);
    expect(find.text('Agência'), findsOneWidget);
    expect(find.text('Categoria'), findsOneWidget);
    expect(find.text('Alice'), findsOneWidget);

    await tester.drag(find.byType(SingleChildScrollView).first, const Offset(-800, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Perfil').first, warnIfMissed: false);
    await tester.pump();
    expect(calls.contains('modal_1'), isTrue);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lecotour_dashboard/widgets/contacts_multi_view.dart';

void main() {
  testWidgets('ContactsMultiView filtra, ordena e aciona callbacks', (WidgetTester tester) async {
    final calls = <String>[];
    final contacts = [
      {'id': 1, 'name': 'Alice', 'email': 'alice@example.com', 'phone': '111'},
      {'id': 2, 'name': 'Bob', 'email': 'bob@example.com', 'phone': '222'},
      {'id': 3, 'name': 'Carol', 'email': 'carol@example.com', 'phone': '333'},
    ];

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ContactsMultiView(
          contacts: contacts,
          onOpenProfileModal: (c) => calls.add('modal_${c['id']}'),
          onOpenProfilePage: (c) => calls.add('page_${c['id']}'),
          onOpenWhatsApp: (c) => calls.add('wa_${c['id']}'),
          onCreateSale: (c) => calls.add('sale_${c['id']}'),
        ),
      ),
    ));

    await tester.enterText(find.byType(TextField), 'bo');
    await tester.pumpAndSettle();
    expect(find.text('Bob'), findsOneWidget);
    expect(find.text('Alice'), findsNothing);

    await tester.tap(find.byIcon(Icons.analytics).first);
    await tester.pump();
    expect(calls.any((e) => e.startsWith('modal_')), isTrue);

    await tester.tap(find.byIcon(Icons.open_in_new).first);
    await tester.pump();
    expect(calls.any((e) => e.startsWith('page_')), isTrue);

    await tester.tap(find.byIcon(Icons.shopping_cart).first);
    await tester.pump();
    expect(calls.any((e) => e.startsWith('sale_')), isTrue);

    await tester.tap(find.byIcon(Icons.chat_bubble).first);
    await tester.pump();
    expect(calls.any((e) => e.startsWith('wa_')), isTrue);
  });
}


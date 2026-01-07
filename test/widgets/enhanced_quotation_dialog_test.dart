import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lecotour_dashboard/widgets/enhanced_quotation_dialog.dart';

void main() {
  testWidgets('EnhancedQuotationDialog UI excludes search buttons and phone field', (tester) async {
    await tester.pumpWidget(ProviderScope(child: MaterialApp(
      home: Builder(builder: (context) {
        return Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () {
                showDialog(context: context, builder: (_) => const EnhancedQuotationDialog(leadTitle: 'Teste'));
              },
              child: const Text('Open'),
            ),
          ),
        );
      }),
    )));

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Criar Cotação Profissional'), findsOneWidget);
    expect(find.text('Selecionar'), findsNothing);
    expect(find.text('Telefone do Cliente'), findsNothing);
  });
}

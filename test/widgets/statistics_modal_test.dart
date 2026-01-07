import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lecotour_dashboard/widgets/statistics_modal.dart';
import 'package:lecotour_dashboard/services/contacts_service.dart';

class _FakeContactsService extends ContactsService {
  @override
  Future<List<Map<String, dynamic>>> getContactsCountByCountry({DateTime? start, DateTime? end, String? categoryName, String? search, int pageSize = 200}) async {
    await Future.delayed(const Duration(milliseconds: 10));
    return [
      {'country': 'Brasil', 'total': 120, 'percent': 60.0},
      {'country': 'Estados Unidos', 'total': 80, 'percent': 40.0},
    ];
  }
}

void main() {
  testWidgets('Modal Estatísticas abre com Contatos por País', (tester) async {
    final svc = _FakeContactsService();
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) {
        return Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () {
                showDialog(context: context, builder: (_) => StatisticsModal(contactsService: svc));
              },
              child: const Text('Abrir'),
            ),
          ),
        );
      }),
    ));

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    expect(find.text('Estatísticas'), findsOneWidget);
    expect(find.text('Contatos por País'), findsOneWidget);
    expect(find.text('País'), findsOneWidget);
    expect(find.text('Total'), findsOneWidget);
  });
}


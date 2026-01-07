import 'package:flutter/material.dart';
import '../widgets/contacts_grid_table.dart';
import '../services/contacts_service.dart';

class ContactsGridTableScreen extends StatelessWidget {
  final List<Map<String, dynamic>> contacts;
  final void Function(Map<String, dynamic>) onOpenProfileModal;
  final void Function(Map<String, dynamic>) onOpenProfilePage;
  final void Function(Map<String, dynamic>) onOpenWhatsApp;
  final void Function(Map<String, dynamic>) onCreateSale;

  const ContactsGridTableScreen({
    Key? key,
    required this.contacts,
    required this.onOpenProfileModal,
    required this.onOpenProfilePage,
    required this.onOpenWhatsApp,
    required this.onCreateSale,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final service = ContactsService();
    return Scaffold(
      appBar: AppBar(title: const Text('Contatos (Tabela)')),
      body: ContactsGridTable(
        contacts: contacts,
        loader: ({limit = 100, offset = 0, String? search, int? sortColumnIndex, bool ascending = true}) {
          String sortField = 'name';
          switch (sortColumnIndex) {
            case 0:
              sortField = 'name';
              break;
            case 1:
              sortField = 'email';
              break;
            case 2:
              sortField = 'phone';
              break;
            case 3:
              sortField = 'city';
              break;
            case 4:
              sortField = 'country';
              break;
            case 5:
              sortField = 'account_id';
              break;
            case 6:
              sortField = 'contact_category_id';
              break;
            case 7:
              sortField = 'updated_at';
              break;
          }
          return service.getContactsPage(
            limit: limit,
            offset: offset,
            search: search,
            sortField: sortField,
            ascending: ascending,
          );
        },
        onOpenProfileModal: onOpenProfileModal,
        onOpenProfilePage: onOpenProfilePage,
        onOpenWhatsApp: onOpenWhatsApp,
        onCreateSale: onCreateSale,
      ),
    );
  }
}

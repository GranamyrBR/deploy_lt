import 'package:flutter/material.dart';
import '../widgets/contacts_multi_view.dart';

class ContactsMultiViewScreen extends StatelessWidget {
  final List<Map<String, dynamic>> contacts;
  final void Function(Map<String, dynamic>) onOpenProfileModal;
  final void Function(Map<String, dynamic>) onOpenProfilePage;
  final void Function(Map<String, dynamic>) onOpenWhatsApp;
  final void Function(Map<String, dynamic>) onCreateSale;

  const ContactsMultiViewScreen({
    Key? key,
    required this.contacts,
    required this.onOpenProfileModal,
    required this.onOpenProfilePage,
    required this.onOpenWhatsApp,
    required this.onCreateSale,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contatos')), 
      body: ContactsMultiView(
        contacts: contacts,
        onOpenProfileModal: onOpenProfileModal,
        onOpenProfilePage: onOpenProfilePage,
        onOpenWhatsApp: onOpenWhatsApp,
        onCreateSale: onCreateSale,
      ),
    );
  }
}


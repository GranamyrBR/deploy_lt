import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/contact.dart';
import '../services/contacts_service.dart';

// Provider para o serviço de contatos
final contactsServiceProvider = Provider<ContactsService>((ref) {
  return ContactsService();
});

// Provider para buscar todos os contatos
final contactsProvider = FutureProvider.family<List<Contact>, bool?>((ref, isActive) async {
  final service = ref.watch(contactsServiceProvider);
  return await service.getContacts(isActive: isActive);
});

// Provider para buscar contato por ID
final contactProvider = FutureProvider.family<Contact?, int>((ref, id) async {
  final service = ref.watch(contactsServiceProvider);
  return await service.getContactById(id);
});

// Provider para buscar contato por email
final contactByEmailProvider = FutureProvider.family<Contact?, String>((ref, email) async {
  final service = ref.watch(contactsServiceProvider);
  return await service.getContactByEmail(email);
});

// Provider para buscar contato por telefone
final contactByPhoneProvider = FutureProvider.family<Contact?, String>((ref, phone) async {
  final service = ref.watch(contactsServiceProvider);
  return await service.getContactByPhone(phone);
});

// Provider para buscar contatos por termo de busca
final searchContactsProvider = FutureProvider.family<List<Contact>, String>((ref, term) async {
  final service = ref.watch(contactsServiceProvider);
  return await service.searchContacts(term);
}); 

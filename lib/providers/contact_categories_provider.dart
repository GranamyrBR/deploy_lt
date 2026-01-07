import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/contact_category.dart';
import '../services/contacts_service.dart';

final contactServiceProvider = Provider<ContactsService>((ref) => ContactsService());

// Provider para buscar categorias de contatos
final contactCategoriesProvider = FutureProvider<List<ContactCategory>>((ref) async {
  final service = ref.watch(contactServiceProvider);
  return await service.getContactCategories();
});

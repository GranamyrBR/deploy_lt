import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/service.dart';
import 'sales_provider.dart';

final filteredServicesProvider = FutureProvider.family<List<Service>, int?>((ref, serviceTypeId) async {
  final servicesAsync = await ref.read(servicesProvider(true).future);
  
  if (serviceTypeId == null) {
    return servicesAsync;
  }
  
  return servicesAsync.where((service) => service.servicetypeId == serviceTypeId).toList();
}); 

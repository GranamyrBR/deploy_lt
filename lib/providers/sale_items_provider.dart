import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:state_notifier/state_notifier.dart';

import '../models/sale_item.dart';

class SaleItemsNotifier extends StateNotifier<List<SaleItem>> {
  SaleItemsNotifier() : super([]);

  void addItem(SaleItem item) {
    final index = state.indexWhere((e) => e.type == item.type && e.id == item.id);
    if (index >= 0) {
      state[index].quantity += item.quantity;
      state = List.from(state);
    } else {
      state = [...state, item];
    }
  }

  void removeItem(SaleItem item) {
    state = state.where((e) => !(e.type == item.type && e.id == item.id)).toList();
  }

  void updateQuantity(SaleItem item, int quantity) {
    final index = state.indexWhere((e) => e.type == item.type && e.id == item.id);
    if (index >= 0) {
      state[index].quantity = quantity;
      state = List.from(state);
    }
  }

  void clear() {
    state = [];
  }
}

final saleItemsProvider = StateNotifierProvider<SaleItemsNotifier, List<SaleItem>>((ref) => SaleItemsNotifier()); 

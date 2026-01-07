import 'package:flutter_riverpod/flutter_riverpod.dart';


class BoardItem {
  final String id;
  final String title;
  final String subtitle;
  final double value;
  BoardItem({required this.id, required this.title, required this.subtitle, required this.value});
}

class BoardColumn {
  final String key;
  final String name;
  final List<BoardItem> items;
  BoardColumn({required this.key, required this.name, required this.items});
}

class SellerBoardState {
  final List<BoardColumn> kanbanColumns;
  final List<BoardColumn> todoColumns;
  SellerBoardState({required this.kanbanColumns, required this.todoColumns});
  SellerBoardState copyWith({List<BoardColumn>? kanbanColumns, List<BoardColumn>? todoColumns}) {
    return SellerBoardState(
      kanbanColumns: kanbanColumns ?? this.kanbanColumns,
      todoColumns: todoColumns ?? this.todoColumns,
    );
  }
}

class SellerBoardNotifier extends StateNotifier<SellerBoardState> {
  SellerBoardNotifier()
      : super(
          SellerBoardState(
            kanbanColumns: [
              BoardColumn(key: 'leads', name: 'Leads', items: [
                BoardItem(id: 'c1', title: 'Agência Alpha', subtitle: 'WhatsApp', value: 5200),
                BoardItem(id: 'c2', title: 'Cliente Beta', subtitle: 'Email', value: 1800),
              ]),
              BoardColumn(key: 'qualified', name: 'Qualificados', items: [
                BoardItem(id: 'c3', title: 'Cliente Gamma', subtitle: 'Telefone', value: 2800),
              ]),
              BoardColumn(key: 'proposal', name: 'Propostas', items: [
                BoardItem(id: 'c4', title: 'Agência Delta', subtitle: 'WhatsApp', value: 2200),
              ]),
              BoardColumn(key: 'won', name: 'Fechados', items: [
                BoardItem(id: 'c5', title: 'Cliente Sigma', subtitle: 'WhatsApp', value: 1850),
              ]),
            ],
            todoColumns: [
              BoardColumn(key: 'todo', name: 'To-Do', items: [
                BoardItem(id: 't1', title: 'Enviar proposta Alpha', subtitle: 'Hoje', value: 0),
                BoardItem(id: 't2', title: 'Agendar call Beta', subtitle: 'Amanhã', value: 0),
              ]),
              BoardColumn(key: 'doing', name: 'Em Progresso', items: [
                BoardItem(id: 't3', title: 'Negociação Gamma', subtitle: 'Esta semana', value: 0),
              ]),
              BoardColumn(key: 'done', name: 'Concluídos', items: [
                BoardItem(id: 't4', title: 'Fechamento Sigma', subtitle: 'Ontem', value: 0),
              ]),
            ],
          ),
        );

  void moveKanbanItem(String itemId, String fromKey, String toKey, int toIndex) {
    final cols = [...state.kanbanColumns];
    final fromColIndex = cols.indexWhere((c) => c.key == fromKey);
    final toColIndex = cols.indexWhere((c) => c.key == toKey);
    if (fromColIndex < 0 || toColIndex < 0) return;
    final fromItems = [...cols[fromColIndex].items];
    final itemIndex = fromItems.indexWhere((i) => i.id == itemId);
    if (itemIndex < 0) return;
    final item = fromItems.removeAt(itemIndex);
    final toItems = [...cols[toColIndex].items];
    final insertIndex = toIndex.clamp(0, toItems.length);
    toItems.insert(insertIndex, item);
    cols[fromColIndex] = BoardColumn(key: cols[fromColIndex].key, name: cols[fromColIndex].name, items: fromItems);
    cols[toColIndex] = BoardColumn(key: cols[toColIndex].key, name: cols[toColIndex].name, items: toItems);
    state = state.copyWith(kanbanColumns: cols);
  }

  void moveTodoItem(String itemId, String fromKey, String toKey, int toIndex) {
    final cols = [...state.todoColumns];
    final fromColIndex = cols.indexWhere((c) => c.key == fromKey);
    final toColIndex = cols.indexWhere((c) => c.key == toKey);
    if (fromColIndex < 0 || toColIndex < 0) return;
    final fromItems = [...cols[fromColIndex].items];
    final itemIndex = fromItems.indexWhere((i) => i.id == itemId);
    if (itemIndex < 0) return;
    final item = fromItems.removeAt(itemIndex);
    final toItems = [...cols[toColIndex].items];
    final insertIndex = toIndex.clamp(0, toItems.length);
    toItems.insert(insertIndex, item);
    cols[fromColIndex] = BoardColumn(key: cols[fromColIndex].key, name: cols[fromColIndex].name, items: fromItems);
    cols[toColIndex] = BoardColumn(key: cols[toColIndex].key, name: cols[toColIndex].name, items: toItems);
    state = state.copyWith(todoColumns: cols);
  }
}

final sellerBoardProvider = StateNotifierProvider<SellerBoardNotifier, SellerBoardState>((ref) {
  return SellerBoardNotifier();
});
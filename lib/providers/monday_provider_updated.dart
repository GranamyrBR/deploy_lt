import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/monday_entry_updated.dart';

// Estado para paginação com dados enriquecidos
class MondayPaginationStateUpdated {
  final List<MondayEntryWithReferences> entries;
  final int currentPage;
  final int pageSize;
  final bool hasMore;
  final bool isLoading;
  final String? error;

  MondayPaginationStateUpdated({
    required this.entries,
    required this.currentPage,
    required this.pageSize,
    required this.hasMore,
    required this.isLoading,
    this.error,
  });

  MondayPaginationStateUpdated copyWith({
    List<MondayEntryWithReferences>? entries,
    int? currentPage,
    int? pageSize,
    bool? hasMore,
    bool? isLoading,
    String? error,
  }) {
    return MondayPaginationStateUpdated(
      entries: entries ?? this.entries,
      currentPage: currentPage ?? this.currentPage,
      pageSize: pageSize ?? this.pageSize,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Classe que combina MondayEntry com dados de referência
class MondayEntryWithReferences {
  final MondayEntryUpdated entry;
  final String? statusName;
  final String? sourceName;
  final String? accountName;
  final String? customerTypeName;

  MondayEntryWithReferences({
    required this.entry,
    this.statusName,
    this.sourceName,
    this.accountName,
    this.customerTypeName,
  });

  // Getters para compatibilidade
  String? get status => statusName;
  String? get source => sourceName;
  String? get account => accountName;
  String? get customerType => customerTypeName;
  
  // Delegate para campos do entry
  int get contactId => entry.contactId;
  String? get name => entry.name;
  String? get email => entry.email;
  String? get phone => entry.phone;
  String? get city => entry.city;
  String? get gender => entry.gender;
  String? get previsaoStart => entry.previsaoStart;
  String? get previsaoEnd => entry.previsaoEnd;
  String? get servicos => entry.servicos;
  String? get observacao => entry.observacao;
  String? get contactDate => entry.contactDate;
  String? get closingDate => entry.closingDate;
  String? get log => entry.log;
  String? get logAtual => entry.logAtual;
  String? get diasViagem => entry.diasViagem;
  String? get closingDay => entry.closingDay;
  String? get mondayId => entry.mondayId;
  String? get vendedor => entry.vendedor;
}

// Provider para gerenciar a paginação com JOINs
class MondayPaginationNotifierUpdated extends StateNotifier<MondayPaginationStateUpdated> {
  MondayPaginationNotifierUpdated() : super(MondayPaginationStateUpdated(
    entries: [],
    currentPage: 0,
    pageSize: 50,
    hasMore: true,
    isLoading: false,
  ));

  Future<void> loadNextPage() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final offset = state.currentPage * state.pageSize;
      
      // Query com JOINs para melhor performance
      final response = await Supabase.instance.client
          .from('monday')
          .select('''
            *,
            contact_category!contact_category_id(name),
            source!source_id(name),
            account!account_id(name),
            contact_category!customer_type_id(name)
          ''')
          .order('contact_id', ascending: false)
          .range(offset, offset + state.pageSize - 1);

      final newEntries = (response as List).map((json) {
        final entry = MondayEntryUpdated.fromJson(json);
        
        return MondayEntryWithReferences(
          entry: entry,
          statusName: json['contact_category']?['name'],
          sourceName: json['source']?['name'],
          accountName: json['account']?['name'],
          customerTypeName: json['contact_category']?['name'], // Pode ser diferente se customer_type_id != contact_category_id
        );
      }).toList();

      final hasMore = newEntries.length == state.pageSize;

      state = state.copyWith(
        entries: [...state.entries, ...newEntries],
        currentPage: state.currentPage + 1,
        hasMore: hasMore,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao carregar dados: $e',
      );
    }
  }

  Future<void> refresh() async {
    state = MondayPaginationStateUpdated(
      entries: [],
      currentPage: 0,
      pageSize: 50,
      hasMore: true,
      isLoading: false,
    );
    await loadNextPage();
  }

  Future<void> search(String query) async {
    if (query.isEmpty) {
      await loadAllEntries();
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Busca com JOINs
      final response = await Supabase.instance.client
          .from('monday')
          .select('''
            *,
            contact_category!contact_category_id(name),
            source!source_id(name),
            account!account_id(name),
            contact_category!customer_type_id(name)
          ''')
          .or('name.ilike.%$query%,email.ilike.%$query%,phone.ilike.%$query%')
          .order('contact_id', ascending: false)
          .order('id', ascending: false).limit(50);

      final searchResults = (response as List).map((json) {
        final entry = MondayEntryUpdated.fromJson(json);
        
        return MondayEntryWithReferences(
          entry: entry,
          statusName: json['contact_category']?['name'],
          sourceName: json['source']?['name'],
          accountName: json['account']?['name'],
          customerTypeName: json['contact_category']?['name'],
        );
      }).toList();

      state = state.copyWith(
        entries: searchResults,
        currentPage: 0,
        hasMore: false,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro na busca: $e',
      );
    }
  }

  Future<void> loadAllEntries() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Carregar todos com JOINs
      final response = await Supabase.instance.client
          .from('monday')
          .select('''
            *,
            contact_category!contact_category_id(name),
            source!source_id(name),
            account!account_id(name),
            contact_category!customer_type_id(name)
          ''')
          .order('contact_id', ascending: false);

      final allEntries = (response as List).map((json) {
        final entry = MondayEntryUpdated.fromJson(json);
        
        return MondayEntryWithReferences(
          entry: entry,
          statusName: json['contact_category']?['name'],
          sourceName: json['source']?['name'],
          accountName: json['account']?['name'],
          customerTypeName: json['contact_category']?['name'],
        );
      }).toList();

      state = state.copyWith(
        entries: allEntries,
        currentPage: 0,
        hasMore: false,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao carregar todos os dados: $e',
      );
    }
  }

  // Método para filtrar por status
  List<MondayEntryWithReferences> getEntriesByStatus(String status) {
    if (status == 'all') return state.entries;
    return state.entries.where((entry) => entry.status == status).toList();
  }

  // Método para obter estatísticas
  Map<String, int> getStatusCounts() {
    final counts = <String, int>{};
    counts['all'] = state.entries.length;
    counts['lead'] = state.entries.where((e) => e.status?.toLowerCase() == 'lead').length;
    counts['prospect'] = state.entries.where((e) => e.status?.toLowerCase() == 'prospect').length;
    counts['negociado'] = state.entries.where((e) => e.status?.toLowerCase() == 'negociado').length;
    counts['lead perdido'] = state.entries.where((e) => e.status?.toLowerCase() == 'lead perdido').length;
    return counts;
  }
}

// Providers
final mondayPaginationProviderUpdated = StateNotifierProvider<MondayPaginationNotifierUpdated, MondayPaginationStateUpdated>((ref) {
  return MondayPaginationNotifierUpdated();
});

// Provider para estatísticas
final mondayStatsProvider = Provider<Map<String, int>>((ref) {
  final state = ref.watch(mondayPaginationProviderUpdated);
  final notifier = ref.read(mondayPaginationProviderUpdated.notifier);
  return notifier.getStatusCounts();
});

// Provider para contagem total
final mondayCountProviderUpdated = FutureProvider<int>((ref) async {
  try {
    final response = await Supabase.instance.client
        .from('monday')
        .select('contact_id');

    return (response as List).length;
  } catch (e) {
    print('Erro ao contar registros da tabela monday: $e');
    return 0;
  }
}); 

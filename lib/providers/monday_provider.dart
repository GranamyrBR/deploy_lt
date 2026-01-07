import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/monday_entry.dart';

// Estado para paginação
class MondayPaginationState {
  final List<MondayEntry> entries;
  final int currentPage;
  final int pageSize;
  final bool hasMore;
  final bool isLoading;
  final String? error;

  MondayPaginationState({
    required this.entries,
    required this.currentPage,
    required this.pageSize,
    required this.hasMore,
    required this.isLoading,
    this.error,
  });

  MondayPaginationState copyWith({
    List<MondayEntry>? entries,
    int? currentPage,
    int? pageSize,
    bool? hasMore,
    bool? isLoading,
    String? error,
  }) {
    return MondayPaginationState(
      entries: entries ?? this.entries,
      currentPage: currentPage ?? this.currentPage,
      pageSize: pageSize ?? this.pageSize,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Provider para gerenciar a paginação
class MondayPaginationNotifier extends StateNotifier<MondayPaginationState> {
  MondayPaginationNotifier() : super(MondayPaginationState(
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
      
      final response = await Supabase.instance.client
          .from('monday')
          .select('''
            *,
            contact_category:contact_category_id(id, name),
            source:source_id(id, name),
            account:account_id(id, name)
          ''')
          .order('contact_id', ascending: false)
          .range(offset, offset + state.pageSize - 1);

      final newEntries = (response as List)
          .map((json) => MondayEntry(
                id: json['contact_id'],
                name: json['name'],
                email: json['email'],
                telefone: json['phone'] ?? json['telefone'],
                cidade: json['city'] ?? json['cidade'],
                state: json['state'],
                country: json['country'],
                postalCode: json['postalCode'],
                address: json['address'],
                sexo: json['gender'] ?? json['sexo'],
                font: json['source']?['name'] ?? json['font'],
                contas: json['account']?['name'] ?? json['contas'],
                tipo: json['customer_type'] ?? json['tipo'],
                status: null, // não existe mais
                vendedor: json['vendedor'],
                previsaoStart: json['previsao_Start'],
                previsaoEnd: json['previsao_End'],
                servicos: json['servicos'],
                observacao: json['observacao'],
                contactDate: json['contact_date'],
                closingDate: json['closing_date'],
                log: json['log'],
                logAtual: json['log_atual'],
                diasViagem: json['dias_viagem'],
                closingDay: json['closing_day'],
                mondayId: json['monday_id'],
                createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
                updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
                contactCategoryId: json['contact_category_id'],
                contactCategoryName: json['contact_category']?['name'],
                sourceId: json['source_id'],
                sourceName: json['source']?['name'],
                accountId: json['account_id'],
                accountName: json['account']?['name'],
                customerTypeName: json['contact_category']?['name'], // usar contact_category como fallback
              ))
          .toList();

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
    state = MondayPaginationState(
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
      final response = await Supabase.instance.client
          .from('monday')
          .select('''
            *,
            contact_category:contact_category_id(id, name),
            source:source_id(id, name),
            account:account_id(id, name)
          ''')
          .or('name.ilike.%$query%,email.ilike.%$query%,phone.ilike.%$query%')
          .order('contact_id', ascending: false)
          .order('id', ascending: false).limit(50);

      final searchResults = (response as List)
          .map((json) => MondayEntry(
                id: json['contact_id'],
                name: json['name'],
                email: json['email'],
                telefone: json['phone'] ?? json['telefone'],
                cidade: json['city'] ?? json['cidade'],
                state: json['state'],
                country: json['country'],
                postalCode: json['postalCode'],
                address: json['address'],
                sexo: json['gender'] ?? json['sexo'],
                font: json['source']?['name'] ?? json['font'],
                contas: json['account']?['name'] ?? json['contas'],
                tipo: json['customer_type'] ?? json['tipo'],
                status: null, // não existe mais
                vendedor: json['vendedor'],
                previsaoStart: json['previsao_Start'],
                previsaoEnd: json['previsao_End'],
                servicos: json['servicos'],
                observacao: json['observacao'],
                contactDate: json['contact_date'],
                closingDate: json['closing_date'],
                log: json['log'],
                logAtual: json['log_atual'],
                diasViagem: json['dias_viagem'],
                closingDay: json['closing_day'],
                mondayId: json['monday_id'],
                createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
                updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
                contactCategoryId: json['contact_category_id'],
                contactCategoryName: json['contact_category']?['name'],
                sourceId: json['source_id'],
                sourceName: json['source']?['name'],
                accountId: json['account_id'],
                accountName: json['account']?['name'],
                customerTypeName: json['contact_category']?['name'], // usar contact_category como fallback
              ))
          .toList();

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
      final response = await Supabase.instance.client
          .from('monday')
          .select('''
            *,
            contact_category:contact_category_id(id, name),
            source:source_id(id, name),
            account:account_id(id, name)
          ''')
          .order('contact_id', ascending: false);

      final allEntries = (response as List)
          .map((json) => MondayEntry(
                id: json['contact_id'],
                name: json['name'],
                email: json['email'],
                telefone: json['phone'] ?? json['telefone'],
                cidade: json['city'] ?? json['cidade'],
                state: json['state'],
                country: json['country'],
                postalCode: json['postalCode'],
                address: json['address'],
                sexo: json['gender'] ?? json['sexo'],
                font: json['source']?['name'] ?? json['font'],
                contas: json['account']?['name'] ?? json['contas'],
                tipo: json['customer_type'] ?? json['tipo'],
                status: null, // não existe mais
                vendedor: json['vendedor'],
                previsaoStart: json['previsao_Start'],
                previsaoEnd: json['previsao_End'],
                servicos: json['servicos'],
                observacao: json['observacao'],
                contactDate: json['contact_date'],
                closingDate: json['closing_date'],
                log: json['log'],
                logAtual: json['log_atual'],
                diasViagem: json['dias_viagem'],
                closingDay: json['closing_day'],
                mondayId: json['monday_id'],
                createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
                updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
                contactCategoryId: json['contact_category_id'],
                contactCategoryName: json['contact_category']?['name'],
                sourceId: json['source_id'],
                sourceName: json['source']?['name'],
                accountId: json['account_id'],
                accountName: json['account']?['name'],
                customerTypeName: json['contact_category']?['name'], // usar contact_category como fallback
              ))
          .toList();

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

  Future<void> addEntry(Map<String, dynamic> entryData) async {
    try {
      final response = await Supabase.instance.client
          .from('monday')
          .insert(entryData)
          .select()
          .single();

      final newEntry = MondayEntry(
        id: response['contact_id'],
        name: response['name'],
        email: response['email'],
        telefone: response['phone'] ?? response['telefone'],
        cidade: response['city'] ?? response['cidade'],
        state: response['state'],
        country: response['country'],
        postalCode: response['postalCode'],
        address: response['address'],
        sexo: response['gender'] ?? response['sexo'],
        font: response['source']?['name'] ?? response['font'],
        contas: response['account']?['name'] ?? response['contas'],
        tipo: response['customer_type'] ?? response['tipo'],
        status: null,
        vendedor: response['vendedor'],
        previsaoStart: response['previsao_Start'],
        previsaoEnd: response['previsao_End'],
        servicos: response['servicos'],
        observacao: response['observacao'],
        contactDate: response['contact_date'],
        closingDate: response['closing_date'],
        log: response['log'],
        logAtual: response['log_atual'],
        diasViagem: response['dias_viagem'],
        closingDay: response['closing_day'],
        mondayId: response['monday_id'],
        createdAt: response['created_at'] != null ? DateTime.tryParse(response['created_at']) : null,
        updatedAt: response['updated_at'] != null ? DateTime.tryParse(response['updated_at']) : null,
        contactCategoryId: response['contact_category_id'],
        contactCategoryName: null,
        sourceId: response['source_id'],
        sourceName: null,
        accountId: response['account_id'],
        accountName: null,
        customerTypeName: null,
      );

      state = state.copyWith(
        entries: [newEntry, ...state.entries],
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Erro ao adicionar entrada: $e',
      );
    }
  }

  Future<void> updateEntry(int id, Map<String, dynamic> updateData) async {
    try {
      final response = await Supabase.instance.client
          .from('monday')
          .update(updateData)
          .eq('contact_id', id)
          .select()
          .single();

      final updatedEntry = MondayEntry(
        id: response['contact_id'],
        name: response['name'],
        email: response['email'],
        telefone: response['phone'] ?? response['telefone'],
        cidade: response['city'] ?? response['cidade'],
        state: response['state'],
        country: response['country'],
        postalCode: response['postalCode'],
        address: response['address'],
        sexo: response['gender'] ?? response['sexo'],
        font: response['source']?['name'] ?? response['font'],
        contas: response['account']?['name'] ?? response['contas'],
        tipo: response['customer_type'] ?? response['tipo'],
        status: null,
        vendedor: response['vendedor'],
        previsaoStart: response['previsao_Start'],
        previsaoEnd: response['previsao_End'],
        servicos: response['servicos'],
        observacao: response['observacao'],
        contactDate: response['contact_date'],
        closingDate: response['closing_date'],
        log: response['log'],
        logAtual: response['log_atual'],
        diasViagem: response['dias_viagem'],
        closingDay: response['closing_day'],
        mondayId: response['monday_id'],
        createdAt: response['created_at'] != null ? DateTime.tryParse(response['created_at']) : null,
        updatedAt: response['updated_at'] != null ? DateTime.tryParse(response['updated_at']) : null,
        contactCategoryId: response['contact_category_id'],
        contactCategoryName: null,
        sourceId: response['source_id'],
        sourceName: null,
        accountId: response['account_id'],
        accountName: null,
        customerTypeName: null,
      );

      final updatedEntries = state.entries.map((entry) {
        return entry.id == id ? updatedEntry : entry;
      }).toList();

      state = state.copyWith(entries: updatedEntries);
    } catch (e) {
      state = state.copyWith(
        error: 'Erro ao atualizar entrada: $e',
      );
    }
  }

  Future<void> deleteEntry(int id) async {
    try {
      await Supabase.instance.client
          .from('monday')
          .delete()
          .eq('contact_id', id);

      final updatedEntries = state.entries.where((entry) => entry.id != id).toList();
      state = state.copyWith(entries: updatedEntries);
    } catch (e) {
      state = state.copyWith(
        error: 'Erro ao deletar entrada: $e',
      );
    }
  }
}

// Provider
final mondayPaginationProvider = StateNotifierProvider<MondayPaginationNotifier, MondayPaginationState>((ref) {
  return MondayPaginationNotifier();
});

// Provider simples para compatibilidade (mantém apenas os primeiros 50 registros)
final mondayProvider = FutureProvider<List<MondayEntry>>((ref) async {
  try {
    final response = await Supabase.instance.client
        .from('monday')
        .select('''
          *,
          contact_category:contact_category_id(id, name),
          source:source_id(id, name),
          account:account_id(id, name)
        ''')
        .order('contact_id', ascending: false)
        .order('id', ascending: false).limit(50);

    return (response as List)
        .map((json) => MondayEntry(
              id: json['contact_id'],
              name: json['name'],
              email: json['email'],
              telefone: json['phone'] ?? json['telefone'],
              cidade: json['city'] ?? json['cidade'],
              state: json['state'],
              country: json['country'],
              postalCode: json['postalCode'],
              address: json['address'],
              sexo: json['gender'] ?? json['sexo'],
              font: json['source']?['name'] ?? json['font'],
              contas: json['account']?['name'] ?? json['contas'],
              tipo: json['customer_type'] ?? json['tipo'],
              status: null, // não existe mais
              vendedor: json['vendedor'],
              previsaoStart: json['previsao_Start'],
              previsaoEnd: json['previsao_End'],
              servicos: json['servicos'],
              observacao: json['observacao'],
              contactDate: json['contact_date'],
              closingDate: json['closing_date'],
              log: json['log'],
              logAtual: json['log_atual'],
              diasViagem: json['dias_viagem'],
              closingDay: json['closing_day'],
              mondayId: json['monday_id'],
              createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
              updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
              contactCategoryId: json['contact_category_id'],
              contactCategoryName: json['contact_category']?['name'],
              sourceId: json['source_id'],
              sourceName: json['source']?['name'],
              accountId: json['account_id'],
              accountName: json['account']?['name'],
              customerTypeName: json['contact_category']?['name'], // usar contact_category como fallback
            ))
        .toList();
  } catch (e) {
    print('Erro ao buscar dados da tabela monday: $e');
    return [];
  }
});

final mondayCountProvider = FutureProvider<int>((ref) async {
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

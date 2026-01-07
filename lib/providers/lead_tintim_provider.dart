import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:state_notifier/state_notifier.dart';

import 'package:lecotour_dashboard/models/lead_tintim.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_provider.dart';

// Estado para o nosso notifier
class GroupedLeadsState {
  final Map<String, List<LeadTintim>> groupedLeads;
  final bool isLoadingMore;
  final bool hasMore;
  final String? errorMessage;
  final DateTime? lastUpdated;

  GroupedLeadsState({
    this.groupedLeads = const {},
    this.isLoadingMore = false,
    this.hasMore = true, // Default hasMore to true
    this.errorMessage,
    this.lastUpdated,
  });

  GroupedLeadsState copyWith({
    Map<String, List<LeadTintim>>? groupedLeads,
    bool? isLoadingMore,
    bool? hasMore,
    String? errorMessage,
    bool clearErrorMessage = false,
    DateTime? lastUpdated,
  }) {
    return GroupedLeadsState(
      groupedLeads: groupedLeads ?? this.groupedLeads,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      errorMessage:
          clearErrorMessage ? null : errorMessage ?? this.errorMessage,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class LeadTintimNotifier extends StateNotifier<GroupedLeadsState> {
  final SupabaseClient _supabase;
  // REMOVIDO: Variáveis de paginação não são mais necessárias
  // pois agora carregamos TODOS os leads de uma vez

  LeadTintimNotifier(this._supabase) : super(GroupedLeadsState()) {
    // Só busca automaticamente se já houver sessão válida
    if (_supabase.auth.currentSession != null) {
      fetchInitialLeads();
    }
  }

  bool needsRefresh(Duration ttl) {
    final last = state.lastUpdated;
    return state.groupedLeads.isEmpty || last == null || DateTime.now().difference(last) > ttl;
  }

  Future<void> fetchInitialLeads() async {
    // REMOVIDO: Reset de página não é mais necessário
    state = state.copyWith(
      isLoadingMore: true, 
      hasMore: false, // Sempre false pois carregamos tudo
      lastUpdated: DateTime.now(),
    ); // Reset e loading inicial
    await _fetchLeads();
  }

  // REMOVIDO: Função fetchMoreLeads não é mais necessária
  // pois agora carregamos TODOS os leads de uma vez
  Future<void> fetchMoreLeads() async {
    print('ℹ️ LeadTintimNotifier: fetchMoreLeads() chamado, mas todos os dados já foram carregados');
    // Não faz nada pois já temos todos os dados
    return;
  }

  Future<void> _fetchLeads() async {
    try {
      print('🔍 LeadTintimNotifier: Iniciando busca de leads...');
      // REMOVIDO: Logs de paginação não são mais necessários
      
      final startTime = DateTime.now();
      
      // CORREÇÃO: Buscar TODOS os leads sem limitação de data
      // Removendo a limitação que estava causando o problema de mostrar apenas mensagens recentes
      final response = await _supabase
          .from('leadstintim')
          .select()
          .order('phone', ascending: true) // Primeiro ordena por telefone
          .order('datelast', ascending: false); // Depois por data dentro de cada telefone

      final endTime = DateTime.now();
      final queryTime = endTime.difference(startTime).inMilliseconds;
      
      final List<Map<String, dynamic>> leadsData = response;
      print('✅ LeadTintimNotifier: Consulta executada em ${queryTime}ms');
      print('✅ LeadTintimNotifier: Dados brutos recebidos (TODOS os registros): ${leadsData.length} itens');
      
      if (queryTime > 1000) {
        print('⚠️  LeadTintimNotifier: PERFORMANCE LENTA - Consulta demorou ${queryTime}ms');
      }

      if (leadsData.isEmpty) {
        // Nenhum lead encontrado
        state = state
            .copyWith(groupedLeads: {}, isLoadingMore: false, hasMore: false);
        return;
      }

      print('🔍 LeadTintimNotifier: Processando ${leadsData.length} registros...');
      
      // Agrupar TODOS os leads por telefone (sem limitação de paginação)
      final Map<String, List<LeadTintim>> allGroupedLeads = {};
      int processedCount = 0;
      int errorCount = 0;
      
      for (var jsonMap in leadsData) {
        try {
          final lead = LeadTintim.fromJson(jsonMap);
          final phone = lead.phone ?? 'Sem telefone';
          
          if (!allGroupedLeads.containsKey(phone)) {
            allGroupedLeads[phone] = [];
          }
          allGroupedLeads[phone]!.add(lead);
          processedCount++;
        } catch (e, s) {
          errorCount++;
          print('❌ LeadTintimNotifier: Falha ao processar lead JSON: $jsonMap');
          print('❌ LeadTintimNotifier: Erro de desserialização: $e');
          print('❌ LeadTintimNotifier: Stacktrace: $s');
        }
      }
      
      print('✅ LeadTintimNotifier: Processados com sucesso: $processedCount');
      if (errorCount > 0) {
        print('⚠️  LeadTintimNotifier: Erros de processamento: $errorCount');
      }

      // Ordenar leads dentro de cada grupo por data (mais recente primeiro)
      allGroupedLeads.forEach((phone, leads) {
        leads.sort((a, b) {
          final dateA = a.datelast ?? DateTime(1970);
          final dateB = b.datelast ?? DateTime(1970);
          return dateB.compareTo(dateA); // Mais recente primeiro
        });
      });

      final totalGroups = allGroupedLeads.length;
      final totalLeads = allGroupedLeads.values.fold<int>(0, (sum, leads) => sum + leads.length);
      
      print('📊 LeadTintimNotifier: TODOS os leads agrupados por telefone: $totalGroups grupos');
      allGroupedLeads.forEach((phone, leads) {
        print('📱 LeadTintimNotifier: $phone: ${leads.length} mensagens (HISTÓRICO COMPLETO)');
      });
      
      // Atualizar estado com TODOS os leads (sem paginação)
      state = state.copyWith(
        groupedLeads: allGroupedLeads,
        isLoadingMore: false,
        hasMore: false, // Não há mais dados pois carregamos tudo
        clearErrorMessage: true,
      );
      
      print('✅ LeadTintimNotifier: Estado atualizado com ${totalGroups} grupos de leads (HISTÓRICO COMPLETO)');
      print('✅ LeadTintimNotifier: Total de registros carregados: ${leadsData.length}');
      print('✅ LeadTintimNotifier: Estado atualizado com sucesso');
    } catch (e, stackTrace) {
      print('❌ LeadTintimNotifier: ERRO ao buscar leads: $e');
      print('❌ LeadTintimNotifier: Stack trace: $stackTrace');
      
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: 'Falha ao carregar mais leads: $e',
        // hasMore pode ser mantido como true para permitir nova tentativa, ou false se for um erro fatal
      );
      
      print('❌ LeadTintimNotifier: Estado atualizado com erro');
    }
  }
}

// O provider agora é um StateNotifierProvider
final leadTintimProvider =
    StateNotifierProvider<LeadTintimNotifier, GroupedLeadsState>((ref) {
  final supabase = Supabase.instance.client;
  final notifier = LeadTintimNotifier(supabase);

  // Recarrega automaticamente após login, respeitando cache TTL
  ref.listen<AppAuthState>(authProvider, (prev, next) {
    if (next.isAuthenticated) {
      if (notifier.needsRefresh(const Duration(minutes: 5))) {
        notifier.fetchInitialLeads();
      }
    }
  });

  return notifier;
});

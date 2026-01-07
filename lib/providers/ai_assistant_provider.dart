import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/ai_request_model.dart';
import '../services/ai_assistant_service.dart';

// Provider para o serviço de IA
final aiAssistantServiceProvider = Provider<AIAssistantService>((ref) {
  return AIAssistantService();
});

// Provider para gerenciar o estado da conversa
final aiConversationProvider = StateNotifierProvider<AIConversationNotifier, AIConversationState>((ref) {
  final service = ref.watch(aiAssistantServiceProvider);
  return AIConversationNotifier(service);
});

// Provider para métricas de uso da IA
final aiUsageMetricsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, userId) async {
  final supabase = Supabase.instance.client;
  
  try {
    // Obter métricas dos últimos 30 dias
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    
    final metrics = await supabase
        .from('ai_usage_metrics')
        .select('''
          date,
          total_requests,
          total_tokens,
          average_response_time_ms,
          error_count,
          success_count
        ''')
        .eq('user_id', userId)
        .gte('date', thirtyDaysAgo.toIso8601String())
        .order('date', ascending: false);
    
    // Obter total de interações de hoje
    final todayInteractions = await supabase
        .from('ai_interactions')
        .select('*')
        .eq('user_id', userId)
        .gte('created_at', DateTime.now().toUtc().toIso8601String().substring(0, 10));
    
    return {
      'metrics': metrics,
      'today_interactions': todayInteractions.length,
      'total_tokens_last_30_days': metrics.fold<int>(0, (sum, m) => sum + (m['total_tokens'] as int? ?? 0)),
    };
  } catch (e) {
    return {
      'metrics': [],
      'today_interactions': 0,
      'total_tokens_last_30_days': 0,
      'error': e.toString(),
    };
  }
});

// Provider para histórico de conversas
final aiConversationHistoryProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, userId) async {
  final supabase = Supabase.instance.client;
  
  try {
    final history = await supabase
        .from('ai_interactions')
        .select('''
          conversation_id,
          request_message,
          response_message,
          tokens_used,
          model,
          response_time_ms,
          created_at
        ''')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .order('id', ascending: false).limit(50);
    
    return history;
  } catch (e) {
    return [];
  }
});

// Estado da conversa
class AIConversationState {
  final List<AIChatMessage> messages;
  final bool isLoading;
  final String? error;
  final String currentConversationId;
  final DateTime? lastInteraction;
  final int tokensUsed;
  final Map<String, dynamic>? context;

  AIConversationState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    required this.currentConversationId,
    this.lastInteraction,
    this.tokensUsed = 0,
    this.context,
  });

  AIConversationState copyWith({
    List<AIChatMessage>? messages,
    bool? isLoading,
    String? error,
    String? currentConversationId,
    DateTime? lastInteraction,
    int? tokensUsed,
    Map<String, dynamic>? context,
  }) {
    return AIConversationState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      currentConversationId: currentConversationId ?? this.currentConversationId,
      lastInteraction: lastInteraction ?? this.lastInteraction,
      tokensUsed: tokensUsed ?? this.tokensUsed,
      context: context ?? this.context,
    );
  }
}

// Modelo de mensagem de chat
class AIChatMessage {
  final String id;
  final String role; // 'user', 'assistant', 'system'
  final String content;
  final DateTime timestamp;
  final int? tokensUsed;
  final int? responseTimeMs;
  final bool isError;
  final String? errorMessage;

  AIChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.tokensUsed,
    this.responseTimeMs,
    this.isError = false,
    this.errorMessage,
  });

  factory AIChatMessage.user({
    required String content,
    DateTime? timestamp,
  }) {
    return AIChatMessage(
      id: const Uuid().v4(),
      role: 'user',
      content: content,
      timestamp: timestamp ?? DateTime.now(),
    );
  }

  factory AIChatMessage.assistant({
    required String content,
    required int tokensUsed,
    required int responseTimeMs,
    DateTime? timestamp,
  }) {
    return AIChatMessage(
      id: const Uuid().v4(),
      role: 'assistant',
      content: content,
      timestamp: timestamp ?? DateTime.now(),
      tokensUsed: tokensUsed,
      responseTimeMs: responseTimeMs,
    );
  }

  factory AIChatMessage.error({
    required String errorMessage,
    DateTime? timestamp,
  }) {
    return AIChatMessage(
      id: const Uuid().v4(),
      role: 'system',
      content: '❌ Erro: $errorMessage',
      timestamp: timestamp ?? DateTime.now(),
      isError: true,
      errorMessage: errorMessage,
    );
  }
}

// Notificador da conversa
class AIConversationNotifier extends StateNotifier<AIConversationState> {
  final AIAssistantService _aiService;

  AIConversationNotifier(this._aiService) 
      : super(AIConversationState(
          currentConversationId: const Uuid().v4(),
        ));

  Future<void> sendMessage(String message, String userId) async {
    if (message.trim().isEmpty) return;

    // Adicionar mensagem do usuário
    final userMessage = AIChatMessage.user(content: message.trim());
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      error: null,
    );

    try {
      // Criar requisição
      final request = AIRequest(
        message: message.trim(),
        userId: userId,
        conversationId: state.currentConversationId,
        context: state.context,
      );

      // Processar com IA
      final startTime = DateTime.now();
      final response = await _aiService.processRequest(request);
      final responseTime = DateTime.now().difference(startTime).inMilliseconds;

      // Adicionar resposta da IA
      final assistantMessage = AIChatMessage.assistant(
        content: response.message,
        tokensUsed: response.tokensUsed,
        responseTimeMs: responseTime,
      );

      state = state.copyWith(
        messages: [...state.messages, assistantMessage],
        isLoading: false,
        lastInteraction: DateTime.now(),
        tokensUsed: state.tokensUsed + response.tokensUsed,
      );

    } catch (e) {
      // Adicionar mensagem de erro
      final errorMessage = AIChatMessage.error(
        errorMessage: _getErrorMessage(e),
      );

      state = state.copyWith(
        messages: [...state.messages, errorMessage],
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error.toString().contains('Rate limit exceeded')) {
      return 'Limite de requisições excedido. Aguarde um momento e tente novamente.';
    } else if (error.toString().contains('OpenAI API key not configured')) {
      return '⚠️ API OpenAI não configurada. Por favor, adicione sua chave de API no arquivo .env (OPENAI_API_KEY). Obtenha sua chave em: https://platform.openai.com/api-keys';
    } else if (error.toString().contains('timeout')) {
      return 'Tempo limite excedido. Por favor, tente novamente.';
    } else if (error.toString().contains('Invalid API key')) {
      return 'Chave de API OpenAI inválida. Verifique sua chave no arquivo .env.';
    } else if (error.toString().contains('insufficient_quota')) {
      return 'Quota da API OpenAI esgotada. Verifique seu plano e uso na plataforma OpenAI.';
    } else {
      return 'Erro ao processar sua mensagem. Tente novamente.';
    }
  }

  void clearConversation() {
    state = AIConversationState(
      currentConversationId: const Uuid().v4(),
    );
  }

  void setContext(Map<String, dynamic> context) {
    state = state.copyWith(context: context);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  // Métodos auxiliares para tipos específicos de consultas
  Future<void> analyzeSales(String userId, {DateTime? startDate, DateTime? endDate}) async {
    final message = 'Analise o desempenho de vendas ${startDate != null ? 'desde ${startDate.toLocal().toString().substring(0, 10)}' : 'dos últimos 30 dias'}';
    await sendMessage(message, userId);
  }

  Future<void> getCustomerInsights(String userId, int customerId) async {
    final message = 'Forneça insights detalhados sobre o cliente ID $customerId, incluindo histórico de compras e preferências';
    await sendMessage(message, userId);
  }

  Future<void> getProductRecommendations(String userId, {Map<String, dynamic>? filters}) async {
    final message = 'Recomende produtos e serviços ${filters != null ? 'com base nos filtros: ${filters.toString()}' : 'mais populares'}';
    await sendMessage(message, userId);
  }

  Future<void> getFinancialInsights(String userId, {String? period}) async {
    final message = 'Analise os dados financeiros ${period ?? 'do mês atual'} e forneça insights sobre receitas e tendências';
    await sendMessage(message, userId);
  }
}
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ai_response_model.dart';
import '../models/ai_request_model.dart';

class AIAssistantService {
  static final AIAssistantService _instance = AIAssistantService._internal();
  factory AIAssistantService() => _instance;
  AIAssistantService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  
  static const String _model = 'gpt-4-turbo-preview';
  static const int _maxTokens = 1000;
  static const double _temperature = 0.7;
  static const int _rateLimitPerMinute = 20;
  
  DateTime _lastRequestTime = DateTime.now();
  int _requestCount = 0;

  Future<AIResponse> processRequest(AIRequest request) async {
    try {
      // Verificar rate limiting
      await _checkRateLimit();
      
      // Obter contexto do banco de dados
      final context = await _getDatabaseContext(request.userId);
      
      // Construir prompt otimizado
      final prompt = await _buildOptimizedPrompt(request, context);
      
      // Fazer chamada à API
      final response = await _callOpenAIAPI(prompt, request.conversationId);
      
      // Registrar log de auditoria
      await _logAIInteraction(request, response);
      
      return response;
      
    } catch (e) {
      await _logAIError(request, e.toString());
      rethrow;
    }
  }

  Future<void> _checkRateLimit() async {
    final now = DateTime.now();
    if (now.difference(_lastRequestTime).inSeconds < 60) {
      _requestCount++;
      if (_requestCount > _rateLimitPerMinute) {
        throw Exception('Rate limit exceeded. Please wait a moment.');
      }
    } else {
      _requestCount = 1;
      _lastRequestTime = now;
    }
  }

  Future<Map<String, dynamic>> _getDatabaseContext(String userId) async {
    try {
      // Obter dados do usuário
      final userData = await _getUserContext(userId);
      
      // Obter métricas recentes
      final metrics = await _getRecentMetrics();
      
      // Obter informações de vendas
      final salesData = await _getSalesContext();
      
      // Obter dados de produtos/serviços
      final productsData = await _getProductsContext();
      
      return {
        'user': userData,
        'metrics': metrics,
        'sales': salesData,
        'products': productsData,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      };
    } catch (e) {
      debugPrint('Error getting database context: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> _getUserContext(String userId) async {
    try {
      // Buscar dados do usuário (sem relacionamento com agency)
      final userResponse = await _supabase
          .from('user')
          .select('*')
          .eq('id', userId)
          .single();
      
      // Buscar permissões e papel
      return {
        'profile': userResponse,
        'role': 'user', // Default role since user_roles table doesn't exist
        'permissions': [], // Default empty permissions
      };
    } catch (e) {
      debugPrint('Error getting user context: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> _getRecentMetrics() async {
    try {
      // Obter métricas dos últimos 30 dias
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      
      // Vendas totais
      final salesCount = await _supabase
          .from('sale')
          .select('*')
          .gte('created_at', thirtyDaysAgo.toIso8601String());
      
      // Valor total de vendas (usando soma direta)
      final salesTotalResponse = await _supabase
          .from('sale')
          .select('total_amount')
          .gte('created_at', thirtyDaysAgo.toIso8601String());
      
      // Calcular total manualmente
      double totalSales = 0;
      for (var sale in salesTotalResponse) {
        totalSales += (sale['total_amount'] as num?)?.toDouble() ?? 0;
      }
      
      // Número de clientes ativos
      final activeCustomers = await _supabase
          .from('contact')
          .select('*')
          .gte('updated_at', thirtyDaysAgo.toIso8601String());
      
      return {
        'total_sales': salesCount.length,
        'total_revenue': totalSales,
        'active_customers': activeCustomers.length,
        'period': '30_days',
      };
    } catch (e) {
      debugPrint('Error getting metrics: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> _getSalesContext() async {
    try {
      // Vendas recentes (últimos 7 dias)
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      
      final recentSales = await _supabase
          .from('sale')
          .select('''
            id,
            total_amount,
            currency_id,
            payment_status,
            created_at,
            contact(name)
          ''')
          .gte('created_at', sevenDaysAgo.toIso8601String())
          .order('created_at', ascending: false)
          .order('id', ascending: false).limit(10);
      
      // Métodos de pagamento mais usados (simplificado)
      final paymentMethods = await _supabase
          .from('sale_payment')
          .select('payment_method_id')
          .gte('created_at', sevenDaysAgo.toIso8601String());
      
      return {
        'recent_sales': recentSales,
        'payment_methods': paymentMethods,
        'period': '7_days',
      };
    } catch (e) {
      debugPrint('Error getting sales context: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> _getProductsContext() async {
    try {
      // Produtos/serviços mais vendidos (simplificado)
      final topProducts = await _supabase
          .from('sale_item')
          .select('''
            product_id,
            quantity,
            tax_amount
          ''')
          .order('id', ascending: false).limit(10);
      
      // Agrupar manualmente por product_id
      Map<String, dynamic> productStats = {};
      for (var item in topProducts) {
        String productId = item['product_id'].toString();
        if (!productStats.containsKey(productId)) {
          productStats[productId] = {
            'product_id': productId,
            'total_quantity': 0,
            'total_revenue': 0.0,
          };
        }
        productStats[productId]!['total_quantity'] += (item['quantity'] as num?)?.toInt() ?? 0;
        productStats[productId]!['total_revenue'] += (item['tax_amount'] as num?)?.toDouble() ?? 0.0;
      }
      
      // Converter para lista e ordenar
      List<dynamic> topProductsList = productStats.values.toList();
      topProductsList.sort((a, b) => (b['total_quantity'] as int).compareTo(a['total_quantity'] as int));
      
      // Categorias de produtos
      final productCategories = await _supabase
          .from('product_category')
          .select('name, description')
          .order('name');
      
      return {
        'top_products': topProductsList.take(5).toList().cast<Map<String, dynamic>>(),
        'categories': productCategories,
      };
    } catch (e) {
      debugPrint('Error getting products context: $e');
      return {};
    }
  }

  Future<String> _buildOptimizedPrompt(AIRequest request, Map<String, dynamic> context) async {
    final userRole = context['user']?['role'] ?? 'user';
    final permissions = context['user']?['permissions'] ?? [];
    
    final systemPrompt = _buildSystemPrompt(userRole, permissions, context);
    final userPrompt = request.message;
    
    return '''$systemPrompt

Contexto Atual do Sistema:
${jsonEncode(context)}

Pergunta do Usuário:
$userPrompt

Por favor, forneça uma resposta útil e segura baseada no contexto fornecido.''';
  }

  String _buildSystemPrompt(String role, List<dynamic> permissions, Map<String, dynamic> context) {
    return '''Você é um assistente inteligente especializado no sistema Lecotour, uma empresa de receptivos em Nova York.

SEU PAPEL:
- Fornecer informações precisas sobre vendas, clientes, produtos e métricas
- Ajudar com análises e insights baseados nos dados do sistema
- Responder em português de forma clara e profissional
- Sempre proteger informações sensíveis e seguir políticas de privacidade

REGRAS DE SEGURANÇA:
1. Nunca revele informações pessoais de clientes (CPF, telefone, email)
2. Não forneça dados financeiros detalhados sem permissão adequada
3. Respeite os limites de acesso baseado no papel do usuário: $role
4. Mantenha todas as interações dentro do escopo empresarial

PERMISSÕES DO USUÁRIO:
${permissions.join(', ')}

CONTEXTO DISPONÍVEL:
- Dados de vendas e métricas (últimos 30 dias)
- Informações de produtos e serviços
- Dados agregados de performance
- Histórico de operações (quando relevante)

RESPONDA SEMPRE:
- De forma concisa e objetiva
- Com dados concretos quando disponíveis
- Oferecendo insights acionáveis
- Mantendo tom profissional e amigável''';
  }

  Future<AIResponse> _callOpenAIAPI(String prompt, String conversationId) async {
    // No Flutter Web, usar Supabase Edge Function para evitar CORS
    if (kIsWeb) {
      return await _callViaSupabaseEdgeFunction(prompt, conversationId);
    }

    // No mobile/desktop, pode chamar direto (mas ainda vamos usar edge function para segurança)
    return await _callViaSupabaseEdgeFunction(prompt, conversationId);
  }

  Future<AIResponse> _callViaSupabaseEdgeFunction(String prompt, String conversationId) async {
    try {
      // URL do backend Node.js
      const backendUrl = kIsWeb 
          ? 'http://localhost:3030/api/ai/chat'  // Desenvolvimento
          : 'https://seu-backend.axioscode.com/api/ai/chat';  // Produção
      
      final response = await http.post(
        Uri.parse(backendUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'message': prompt,
          'model': _model,
          'maxTokens': _maxTokens,
          'temperature': _temperature,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Backend error: ${response.statusCode} - ${response.body}');
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      
      return AIResponse(
        message: data['response'] as String? ?? '',
        conversationId: conversationId,
        timestamp: DateTime.now(),
        tokensUsed: data['tokensUsed'] as int? ?? 0,
        model: data['model'] as String? ?? _model,
      );
    } catch (e) {
      throw Exception('OpenAI API error: $e');
    }
  }

  Future<void> _logAIInteraction(AIRequest request, AIResponse response) async {
    try {
      await _supabase.from('ai_interactions').insert({
        'user_id': request.userId,
        'conversation_id': request.conversationId,
        'request_message': request.message,
        'response_message': response.message,
        'tokens_used': response.tokensUsed,
        'model': response.model,
        'response_time_ms': DateTime.now().difference(response.timestamp).inMilliseconds.abs(),
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      // silent failure for logging to avoid noisy console
    }
  }

  Future<void> _logAIError(AIRequest request, String error) async {
    try {
      await _supabase.from('ai_interactions').insert({
        'user_id': request.userId,
        'conversation_id': request.conversationId,
        'request_message': request.message,
        'response_message': 'AI error: $error',
        'tokens_used': 0,
        'model': _model,
        'response_time_ms': 0,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (_) {}

    try {
      await _supabase.from('ai_errors').insert({
        'user_id': request.userId,
        'conversation_id': request.conversationId,
        'request_message': request.message,
        'error_message': error,
        'error_type': 'ai_service_error',
        'stack_trace': error,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (_) {}
  }

  // Métodos auxiliares para diferentes tipos de consultas
  
  Future<String> analyzeSalesPerformance({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final request = AIRequest(
      message: 'Analise o desempenho de vendas do período ${startDate?.toLocal().toString().substring(0, 10) ?? "últimos 30 dias"}',
      userId: userId,
      conversationId: 'sales_analysis_${DateTime.now().millisecondsSinceEpoch}',
    );
    
    final response = await processRequest(request);
    return response.message;
  }

  Future<String> getCustomerInsights({
    required String userId,
    required int customerId,
  }) async {
    final request = AIRequest(
      message: 'Forneça insights sobre o cliente ID $customerId',
      userId: userId,
      conversationId: 'customer_insights_${DateTime.now().millisecondsSinceEpoch}',
    );
    
    final response = await processRequest(request);
    return response.message;
  }

  Future<String> getProductRecommendations({
    required String userId,
    Map<String, dynamic>? filters,
  }) async {
    final request = AIRequest(
      message: 'Recomende produtos/serviços com base nos filtros: ${filters?.toString() ?? "todos"}',
      userId: userId,
      conversationId: 'product_recs_${DateTime.now().millisecondsSinceEpoch}',
    );
    
    final response = await processRequest(request);
    return response.message;
  }
}
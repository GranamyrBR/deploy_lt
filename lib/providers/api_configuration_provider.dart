import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lecotour_dashboard/models/api_configuration.dart';

class ApiConfigurationNotifier extends StateNotifier<ApiConfigurationState> {
  SupabaseClient get _supabase => Supabase.instance.client;

  ApiConfigurationNotifier() : super(ApiConfigurationState());

  // Buscar configuração específica
  ApiConfiguration? getApiConfiguration(String apiName) {
    try {
      return state.apiConfigurations.firstWhere((config) => config.apiName == apiName);
    } catch (e) {
      return null;
    }
  }

  // Buscar configuração da FlightAware
  ApiConfiguration? get flightawareConfig => getApiConfiguration('flightaware');

  // Carregar todas as configurações de API
  Future<void> loadApiConfigurations() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      debugPrint('Carregando configurações de API...');
      
      final response = await _supabase
          .from('api_configuration')
          .select('*')
          .order('api_name');

      debugPrint('Resposta do Supabase: $response');

      final configurations = (response as List)
          .map((json) {
            debugPrint('Processando JSON: $json');
            return ApiConfiguration.fromJson(json);
          })
          .toList();

      debugPrint('Configurações carregadas: ${configurations.length}');

      state = state.copyWith(
        apiConfigurations: configurations,
        isLoading: false,
      );

    } catch (e, stackTrace) {
      debugPrint('Erro ao carregar configurações de API: $e');
      debugPrint('Stack trace: $stackTrace');
      state = state.copyWith(
        error: 'Erro ao carregar configurações de API: $e',
        isLoading: false,
      );
    }
  }

  // Atualizar API key
  Future<bool> updateApiKey(String apiName, String apiKey) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await _supabase
          .from('api_configuration')
          .update({
            'api_key_encrypted': apiKey,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('api_name', apiName)
          .select();

      if (response.isNotEmpty) {
        // Atualizar a lista local
        await loadApiConfigurations();
        return true;
      }

      return false;
    } catch (e) {
      state = state.copyWith(
        error: 'Erro ao atualizar API key: $e',
        isLoading: false,
      );
      debugPrint('Erro ao atualizar API key: $e');
      return false;
    }
  }

  // Atualizar API key da FlightAware
  Future<bool> updateFlightawareApiKey(String apiKey) async {
    return await updateApiKey('flightaware', apiKey);
  }

  // Testar conexão com a API
  Future<bool> testApiConnection(String apiName) async {
    try {
      final config = getApiConfiguration(apiName);
      if (config == null || !config.isConfigured) {
        state = state.copyWith(error: 'API não configurada');
        return false;
      }

      // Aqui você pode implementar um teste específico para cada API
      // Por exemplo, para FlightAware, fazer uma requisição de teste
      if (apiName == 'flightaware') {
        return await _testFlightawareConnection(config);
      }

      return true;
    } catch (e) {
      state = state.copyWith(error: 'Erro ao testar conexão: $e');
      return false;
    }
  }

  // Testar conexão específica da FlightAware
  Future<bool> _testFlightawareConnection(ApiConfiguration config) async {
    try {
      // Fazer uma requisição de teste para a FlightAware
      // Por exemplo, buscar informações de um voo conhecido
      final response = await _supabase
          .rpc('test_flightaware_connection', params: {
            'api_key': config.apiKeyEncrypted,
          });

      return response == true;
    } catch (e) {
      debugPrint('Erro ao testar conexão FlightAware: $e');
      return false;
    }
  }

  // Ativar/desativar API
  Future<bool> toggleApiStatus(String apiName, bool isActive) async {
    try {
      final response = await _supabase
          .from('api_configuration')
          .update({
            'is_active': isActive,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('api_name', apiName)
          .select();

      if (response.isNotEmpty) {
        await loadApiConfigurations();
        return true;
      }

      return false;
    } catch (e) {
      state = state.copyWith(error: 'Erro ao alterar status da API: $e');
      return false;
    }
  }

  // Limpar erro
  void clearError() {
    state = state.copyWith(error: null);
  }
}

class ApiConfigurationState {
  final List<ApiConfiguration> apiConfigurations;
  final bool isLoading;
  final String? error;

  ApiConfigurationState({
    this.apiConfigurations = const [],
    this.isLoading = false,
    this.error,
  });

  ApiConfigurationState copyWith({
    List<ApiConfiguration>? apiConfigurations,
    bool? isLoading,
    String? error,
  }) {
    return ApiConfigurationState(
      apiConfigurations: apiConfigurations ?? this.apiConfigurations,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// Provider do Riverpod
final apiConfigurationProvider = StateNotifierProvider<ApiConfigurationNotifier, ApiConfigurationState>((ref) {
  return ApiConfigurationNotifier();
}); 

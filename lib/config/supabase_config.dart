import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

class SupabaseConfig {
  // ========================================
  // CONFIGURAÇÕES DO SUPABASE
  // ========================================
  // ATENÇÃO: As configurações agora são carregadas do arquivo .env
  
  // URL do seu projeto Supabase
  static String get supabaseUrl {
    final url = dotenv.env['SUPABASE_URL'];
    if (url == null || url.isEmpty) {
      if (kDebugMode) {
        return 'https://sup.axioscode.com';
      }
      throw Exception('SUPABASE_URL ausente no .env');
    }
    return url;
  }
  
  // Chave anônima (anon key) do seu projeto Supabase
  // Você pode encontrar esta chave no painel do Supabase em:
  // Settings > API > Project API keys > anon public
  static String get supabaseAnonKey {
    final key = dotenv.env['SUPABASE_ANON_KEY'];
    if (key == null || key.isEmpty) {
      if (kDebugMode) {
        return 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJzdXBhYmFzZSIsImlhdCI6MTc1MjU5MDI4MCwiZXhwIjo0OTA4MjYzODgwLCJyb2xlIjoiYW5vbiJ9.nnCYUuqOTv_ZFZXy6u7-gDQc_VMCc9veZDrQ0rDWJhA';
      }
      throw Exception('SUPABASE_ANON_KEY ausente no .env');
    }
    return key;
  }
  
  // ========================================
  // MÉTODOS AUXILIARES
  // ========================================
  
  /// Retorna a instância do cliente Supabase
  static SupabaseClient get client => Supabase.instance.client;
  
  /// Inicializa o Supabase com as configurações definidas
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }
  
  /// Verifica se o Supabase está inicializado
  static bool get isInitialized {
    try {
      Supabase.instance.client;
      return true;
    } catch (_) {
      return false;
    }
  }
  
  /// Retorna informações de debug sobre a configuração
  static Map<String, String> get debugInfo => {
    'url': supabaseUrl,
    'anonKey': (dotenv.env['SUPABASE_ANON_KEY']?.isNotEmpty ?? false)
        ? '${supabaseAnonKey.substring(0, 20)}...'
        : (kDebugMode ? 'dev-fallback' : 'missing'),
    'isInitialized': isInitialized.toString(),
  };
}


import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Importação condicional para web
import 'environment_web.dart' if (dart.library.io) 'environment_io.dart';

/// Classe para acessar variáveis de ambiente de forma multiplataforma
/// - Mobile/Desktop: usa flutter_dotenv (.env file)
/// - Web: usa window.ENV (definido no index.html)
class Environment {
  /// Obtém uma variável de ambiente
  static String? get(String key) {
    if (kIsWeb) {
      // Web: lê de window.ENV (definido no index.html)
      final value = getWebEnv(key);
      if (kDebugMode) {
        print('🌐 ENV[$key] = ${value != null ? "${value.substring(0, 10)}..." : "null"}');
      }
      return value;
    } else {
      // Mobile/Desktop: lê do .env via flutter_dotenv
      return dotenv.env[key];
    }
  }

  /// Obtém variável com valor padrão
  static String getOrDefault(String key, String defaultValue) {
    final value = get(key);
    if (value == null || value.isEmpty || value.startsWith('{{')) {
      // Se for placeholder {{ KEY }}, usa default
      if (kDebugMode) {
        print('⚠️ ENV[$key] vazio ou placeholder, usando default');
      }
      return defaultValue;
    }
    return value;
  }

  /// Chave da API OpenAI
  static String get openAiApiKey {
    final key = get('OPENAI_API_KEY') ?? '';
    if (key.isEmpty || key.startsWith('{{')) {
      if (kDebugMode) {
        print('❌ OPENAI_API_KEY não configurada!');
        print('   - Dev: Execute ./use_dev_env.sh');
        print('   - Prod: Configure backend proxy (veja SECURITY_GUIDE_WEB.md)');
      }
      return '';
    }
    return key;
  }

  /// Organization da OpenAI
  static String get openAiOrganization {
    return get('OPENAI_ORGANIZATION') ?? '';
  }

  /// URL do Supabase
  static String get supabaseUrl {
    return getOrDefault('SUPABASE_URL', 'https://sup.axioscode.com');
  }

  /// Chave anônima do Supabase
  static String get supabaseAnonKey {
    return getOrDefault('SUPABASE_ANON_KEY', 
      'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJzdXBhYmFzZSIsImlhdCI6MTc1MjU5MDI4MCwiZXhwIjo0OTA4MjYzODgwLCJyb2xlIjoiYW5vbiJ9.nnCYUuqOTv_ZFZXy6u7-gDQc_VMCc9veZDrQ0rDWJhA');
  }
}

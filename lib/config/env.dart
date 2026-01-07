import 'package:envied/envied.dart';

part 'env.g.dart';

/// Configuração de variáveis de ambiente usando envied
/// Funciona em TODAS as plataformas incluindo web!
/// 
/// Para gerar o arquivo .g.dart:
/// ```
/// flutter pub run build_runner build --delete-conflicting-outputs
/// ```
@Envied(path: '.env')
abstract class Env {
  @EnviedField(varName: 'OPENAI_API_KEY', defaultValue: '')
  static const String openAiApiKey = _Env.openAiApiKey;
  
  @EnviedField(varName: 'OPENAI_ORGANIZATION', defaultValue: '')
  static const String openAiOrganization = _Env.openAiOrganization;
  
  @EnviedField(varName: 'SUPABASE_URL', defaultValue: 'https://sup.axioscode.com')
  static const String supabaseUrl = _Env.supabaseUrl;
  
  @EnviedField(varName: 'SUPABASE_ANON_KEY', defaultValue: 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJzdXBhYmFzZSIsImlhdCI6MTc1MjU5MDI4MCwiZXhwIjo0OTA4MjYzODgwLCJyb2xlIjoiYW5vbiJ9.nnCYUuqOTv_ZFZXy6u7-gDQc_VMCc9veZDrQ0rDWJhA')
  static const String supabaseAnonKey = _Env.supabaseAnonKey;
}

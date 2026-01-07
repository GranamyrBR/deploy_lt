// Web implementation
import 'dart:js' as js;

/// Obtém variável de ambiente do window.ENV no navegador
String? getWebEnv(String key) {
  try {
    // Acessa window.ENV[key]
    final env = js.context['ENV'];
    if (env != null) {
      final value = env[key];
      return value?.toString();
    }
    return null;
  } catch (e) {
    print('❌ Erro ao acessar window.ENV["$key"]: $e');
    return null;
  }
}

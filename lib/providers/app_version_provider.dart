import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Modelo de versão do app
class AppVersion {
  final String version;
  final String buildHash;
  final int buildTime;
  final DateTime timestamp;
  final String fullVersion;

  AppVersion({
    required this.version,
    required this.buildHash,
    required this.buildTime,
    required this.timestamp,
    required this.fullVersion,
  });

  factory AppVersion.fromJson(Map<String, dynamic> json) {
    return AppVersion(
      version: json['version'] ?? '1.0.0',
      buildHash: json['buildHash'] ?? 'unknown',
      buildTime: json['buildTime'] ?? 0,
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      fullVersion: json['fullVersion'] ?? json['version'] ?? '1.0.0',
    );
  }

  @override
  String toString() => 'v$version ($buildHash)';
}

/// Provider que busca a versão atual do app
final appVersionProvider = FutureProvider<AppVersion>((ref) async {
  try {
    final response = await http.get(
      Uri.parse('/version.json'),
      headers: {'Cache-Control': 'no-cache'},
    ).timeout(const Duration(seconds: 5));
    
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return AppVersion.fromJson(json);
    }
  } catch (e) {
    print('⚠️ Erro ao buscar versão do servidor: $e');
  }
  
  // Versão de fallback (compilada no app via dart-define)
  return AppVersion(
    version: const String.fromEnvironment('APP_VERSION', defaultValue: '1.0.0'),
    buildHash: 'local',
    buildTime: 0,
    timestamp: DateTime.now(),
    fullVersion: const String.fromEnvironment('APP_VERSION', defaultValue: '1.0.0'),
  );
});

/// Provider que verifica periodicamente se há nova versão
final versionCheckProvider = StreamProvider<bool>((ref) async* {
  // Versão inicial (carregada no boot)
  final initialVersion = await ref.read(appVersionProvider.future);
  bool lastCheckHadUpdate = false;
  
  while (true) {
    // Aguarda 30 minutos antes de verificar novamente
    await Future.delayed(const Duration(minutes: 30));
    
    try {
      final response = await http.get(
        Uri.parse('/version.json'),
        headers: {'Cache-Control': 'no-cache'},
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final serverVersion = AppVersion.fromJson(json);
        
        // Nova versão disponível?
        final hasUpdate = serverVersion.buildTime > initialVersion.buildTime;
        
        // Só notifica se o estado mudou (evita spam do banner)
        if (hasUpdate && !lastCheckHadUpdate) {
          print('🎉 Nova versão detectada!');
          print('   Atual: ${initialVersion.fullVersion}');
          print('   Nova: ${serverVersion.fullVersion}');
          lastCheckHadUpdate = true;
          yield hasUpdate;
        } else if (!hasUpdate && lastCheckHadUpdate) {
          // Versão foi atualizada, reseta flag
          lastCheckHadUpdate = false;
          yield hasUpdate;
        }
        // Se nada mudou, não emite nada (não atualiza o banner)
      }
    } catch (e) {
      print('⚠️ Erro ao verificar atualização: $e');
      // Não emite nada em caso de erro (mantém estado anterior)
    }
  }
});

/// Provider para forçar reload da página (atualizar para nova versão)
final reloadAppProvider = Provider((ref) {
  return () {
    // Web: recarrega a página
    // ignore: avoid_web_libraries_in_flutter
    try {
      // ignore: undefined_prefixed_name
      // dart:html é usado aqui
      // html.window.location.reload();
      
      // Alternativa universal que funciona em web
      // ignore: avoid_print
      print('🔄 Recarregando aplicação...');
      // Esta linha será substituída por implementação específica da plataforma
    } catch (e) {
      print('❌ Erro ao recarregar: $e');
    }
  };
});

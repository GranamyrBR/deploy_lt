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

  /// Compara versões semanticamente (v1.0.0 vs v1.1.0)
  /// Retorna true se outra versão é maior que esta
  bool isNewerThan(AppVersion other) {
    final thisParts = version.split('.');
    final otherParts = other.version.split('.');
    
    for (int i = 0; i < 3; i++) {
      final thisNum = int.tryParse(thisParts.length > i ? thisParts[i] : '0') ?? 0;
      final otherNum = int.tryParse(otherParts.length > i ? otherParts[i] : '0') ?? 0;
      
      if (thisNum > otherNum) return true;
      if (thisNum < otherNum) return false;
    }
    
    return false; // Versões são iguais
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
/// DESABILITADO - Deploy manual, não precisa de verificação automática
final versionCheckProvider = StreamProvider<bool>((ref) async* {
  // Provider desabilitado - sempre retorna false (sem atualização)
  yield false;
  
  // Não faz mais verificações periódicas
  // Para reabilitar, descomente o código abaixo:
  
  /*
  final initialVersion = await ref.read(appVersionProvider.future);
  bool lastCheckHadUpdate = false;
  
  while (true) {
    await Future.delayed(const Duration(minutes: 30));
    
    try {
      final response = await http.get(
        Uri.parse('/version.json'),
        headers: {'Cache-Control': 'no-cache'},
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final serverVersion = AppVersion.fromJson(json);
        
        final hasUpdate = serverVersion.isNewerThan(initialVersion);
        
        if (hasUpdate && !lastCheckHadUpdate) {
          print('🎉 Nova versão detectada!');
          print('   Versão atual: ${initialVersion.version}');
          print('   Nova versão: ${serverVersion.version}');
          lastCheckHadUpdate = true;
          yield hasUpdate;
        } else if (!hasUpdate && lastCheckHadUpdate) {
          lastCheckHadUpdate = false;
          yield hasUpdate;
        }
      }
    } catch (e) {
      print('⚠️ Erro ao verificar atualização: $e');
    }
  }
  */
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

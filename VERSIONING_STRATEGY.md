# 🔄 Estratégia de Versionamento e Rollback

## 📋 Objetivo

Implementar sistema de versões para permitir rollback instantâneo caso algo quebre.

Baseado em: [Flutter Web Strategy - Lukas Nevosad](https://lukasnevosad.medium.com/our-flutter-web-strategy-for-deferred-loading-instant-updates-happy-users-45ed90a7727c)

---

## 🏗️ Arquitetura Proposta

### Estrutura de Diretórios no Deploy:

```
/web/
├── current/           # Symlink → v1.2.3 (versão ativa)
├── v1.2.3/           # Build atual
│   ├── index.html
│   ├── main.dart.js
│   └── ...
├── v1.2.2/           # Build anterior (rollback)
│   ├── index.html
│   ├── main.dart.js
│   └── ...
├── v1.2.1/           # Build anterior-anterior
└── version.json      # Metadata de versões
```

### Caddy/Nginx serve de `current/`:

```caddyfile
:8080 {
    root * /web/current
    encode zstd gzip
    file_server
    
    # API de versão
    handle /api/version {
        respond `{"version": "1.2.3", "build": "abc123", "timestamp": "2026-01-08T12:00:00Z"}`
    }
}
```

---

## 🔧 Implementação

### 1. Modificar Dockerfile para Multi-Versão

```dockerfile
# ============================================
# Dockerfile com Versionamento
# ============================================
FROM caddy:2-alpine

RUN addgroup -g 1001 -S caddy && \
    adduser -S -D -H -u 1001 -s /sbin/nologin -G caddy caddy || true
RUN apk add --no-cache curl

# Build version (ARG from CI/CD)
ARG BUILD_VERSION=1.0.0
ARG BUILD_HASH=unknown

# Criar estrutura de versões
RUN mkdir -p /web/versions

# Copiar build para diretório versionado
COPY build/web /web/versions/${BUILD_VERSION}

# Criar symlink para 'current'
RUN ln -sfn /web/versions/${BUILD_VERSION} /web/current

# Criar version.json
RUN echo "{\"version\":\"${BUILD_VERSION}\",\"hash\":\"${BUILD_HASH}\",\"timestamp\":\"$(date -Iseconds)\"}" > /web/versions/${BUILD_VERSION}/version.json

# Copiar version.json para raiz também
RUN cp /web/versions/${BUILD_VERSION}/version.json /web/version.json

COPY Caddyfile /etc/caddy/Caddyfile

RUN chown -R caddy:caddy /etc/caddy /web

USER caddy
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -fs http://localhost:8080/ || exit 1

CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]
```

### 2. Script de Build com Versão

```bash
#!/bin/bash
# build-versioned.sh

set -e

# Obter versão do pubspec.yaml
VERSION=$(grep "version:" pubspec.yaml | sed 's/version: //' | tr -d ' ')
BUILD_HASH=$(git rev-parse --short HEAD 2>/dev/null || echo "local")
BUILD_TIME=$(date +%s)
FULL_VERSION="${VERSION}+${BUILD_HASH}.${BUILD_TIME}"

echo "🏗️  Building version: $FULL_VERSION"

# Build Flutter Web
flutter build web --release \
    --pwa-strategy=offline-first \
    --base-href="/" \
    --dart-define=APP_VERSION=$FULL_VERSION

# Criar version.json
cat > build/web/version.json << EOF
{
  "version": "$VERSION",
  "buildHash": "$BUILD_HASH",
  "buildTime": "$BUILD_TIME",
  "fullVersion": "$FULL_VERSION",
  "timestamp": "$(date -Iseconds)"
}
EOF

echo "✅ Build completo: $FULL_VERSION"
echo "📦 Arquivos em: build/web/"
```

### 3. Provider Flutter para Verificar Versão

```dart
// lib/providers/app_version_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AppVersion {
  final String version;
  final String buildHash;
  final int buildTime;
  final DateTime timestamp;

  AppVersion({
    required this.version,
    required this.buildHash,
    required this.buildTime,
    required this.timestamp,
  });

  factory AppVersion.fromJson(Map<String, dynamic> json) {
    return AppVersion(
      version: json['version'],
      buildHash: json['buildHash'],
      buildTime: json['buildTime'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

final appVersionProvider = FutureProvider<AppVersion>((ref) async {
  try {
    final response = await http.get(Uri.parse('/version.json'));
    if (response.statusCode == 200) {
      return AppVersion.fromJson(json.decode(response.body));
    }
  } catch (e) {
    print('❌ Erro ao buscar versão: $e');
  }
  
  // Versão de fallback (compilada no app)
  return AppVersion(
    version: const String.fromEnvironment('APP_VERSION', defaultValue: '1.0.0'),
    buildHash: 'unknown',
    buildTime: 0,
    timestamp: DateTime.now(),
  );
});

// Verificar se há nova versão
final versionCheckProvider = StreamProvider<bool>((ref) async* {
  while (true) {
    await Future.delayed(Duration(minutes: 5));
    
    try {
      final response = await http.get(Uri.parse('/version.json'));
      if (response.statusCode == 200) {
        final serverVersion = AppVersion.fromJson(json.decode(response.body));
        final currentVersion = await ref.read(appVersionProvider.future);
        
        // Nova versão disponível?
        if (serverVersion.buildTime > currentVersion.buildTime) {
          yield true;
        }
      }
    } catch (e) {
      print('❌ Erro ao verificar versão: $e');
    }
  }
});
```

### 4. Widget de Notificação de Atualização

```dart
// lib/widgets/update_banner.dart
class UpdateBanner extends ConsumerWidget {
  const UpdateBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasUpdate = ref.watch(versionCheckProvider);
    
    return hasUpdate.when(
      data: (hasNewVersion) {
        if (!hasNewVersion) return SizedBox.shrink();
        
        return MaterialBanner(
          backgroundColor: Colors.blue,
          leading: Icon(Icons.system_update, color: Colors.white),
          content: Text(
            '🎉 Nova versão disponível! Clique para atualizar.',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Recarregar página
                html.window.location.reload();
              },
              child: Text(
                'ATUALIZAR',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            TextButton(
              onPressed: () {
                // Dispensar (depois)
              },
              child: Text('DEPOIS', style: TextStyle(color: Colors.white70)),
            ),
          ],
        );
      },
      loading: () => SizedBox.shrink(),
      error: (_, __) => SizedBox.shrink(),
    );
  }
}
```

---

## 🔄 Rollback Strategy

### Opção 1: Manual (Supabase/Server)

```bash
# No servidor (via SSH ou Coolify console)
cd /web
rm current
ln -s versions/v1.2.2 current

# Restart Caddy (se necessário)
docker restart <container-id>
```

### Opção 2: Script Automatizado

```bash
#!/bin/bash
# rollback.sh

CURRENT_VERSION=$(readlink /web/current | xargs basename)
echo "Versão atual: $CURRENT_VERSION"

# Listar versões disponíveis
echo "Versões disponíveis:"
ls -1 /web/versions/ | grep -v $CURRENT_VERSION

read -p "Rollback para qual versão? " TARGET_VERSION

if [ -d "/web/versions/$TARGET_VERSION" ]; then
  echo "🔄 Fazendo rollback: $CURRENT_VERSION → $TARGET_VERSION"
  
  # Backup do current
  cp -r /web/current /web/backup-$CURRENT_VERSION-$(date +%s)
  
  # Trocar symlink
  rm /web/current
  ln -s /web/versions/$TARGET_VERSION /web/current
  
  echo "✅ Rollback completo!"
  echo "🌐 Usuários verão v$TARGET_VERSION no próximo reload"
else
  echo "❌ Versão $TARGET_VERSION não encontrada!"
fi
```

### Opção 3: API de Rollback (avançado)

```dart
// Endpoint no backend para rollback remoto
// POST /api/admin/rollback
// Body: {"version": "1.2.2"}
```

---

## 📊 Monitoramento

### Logs de Versão

```dart
// Em main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final version = await fetchAppVersion();
  print('🚀 App Version: ${version.version} (${version.buildHash})');
  print('📅 Build Time: ${version.timestamp}');
  
  // Analytics
  FirebaseAnalytics.instance.logAppOpen();
  FirebaseAnalytics.instance.setUserProperty(
    name: 'app_version',
    value: version.version,
  );
  
  runApp(MyApp());
}
```

### Dashboard de Versões

```sql
-- Supabase table para tracking
CREATE TABLE app_versions (
  id BIGSERIAL PRIMARY KEY,
  version TEXT NOT NULL,
  build_hash TEXT NOT NULL,
  deployed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deployed_by TEXT,
  is_active BOOLEAN DEFAULT true,
  rollback_from TEXT -- Se foi rollback, de qual versão veio
);
```

---

## ✅ Vantagens

1. **Rollback Instantâneo** - Segundos para voltar
2. **Zero Downtime** - Symlink troca sem parar servidor
3. **Histórico Completo** - Todas versões salvas
4. **Testing Fácil** - Pode testar v1.2.3 antes de ativar
5. **Auditoria** - Sabe quem deployou o que e quando

---

## 🎯 Próximos Passos

1. Implementar `build-versioned.sh`
2. Modificar Dockerfile para suportar versões
3. Adicionar `app_version_provider.dart`
4. Adicionar `UpdateBanner` no app
5. Testar deploy com versão
6. Testar rollback

**Quer que eu crie esses arquivos prontos?** 🚀

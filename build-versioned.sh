#!/bin/bash
# ============================================
# Build Versionado com Cache Busting
# ============================================

set -e

echo "🏗️  Iniciando build versionado..."

# Obter versão do pubspec.yaml
VERSION=$(grep "version:" pubspec.yaml | sed 's/version: //' | sed 's/ *$//' | cut -d'+' -f1)
BUILD_HASH=$(git rev-parse --short HEAD 2>/dev/null || echo "local")
BUILD_TIME=$(date +%s)
FULL_VERSION="${VERSION}+${BUILD_HASH}.${BUILD_TIME}"

echo "📦 Versão: $VERSION"
echo "🔖 Hash: $BUILD_HASH"
echo "⏰ Timestamp: $BUILD_TIME"
echo "🎯 Versão Completa: $FULL_VERSION"

# Limpar build anterior
echo "🧹 Limpando build anterior..."
rm -rf build/web

# Gerar código (todos os .g.dart necessários)
echo "⚙️  Gerando código com build_runner..."
flutter pub run build_runner build --delete-conflicting-outputs || true

# Build Flutter Web
echo "📱 Buildando Flutter Web..."
flutter build web \
    --release \
    --pwa-strategy=offline-first \
    --base-href="/" \
    --dart-define=FLUTTER_WEB_USE_SKIA=false \
    --dart-define=APP_VERSION=$FULL_VERSION \
    --no-tree-shake-icons

# Aplicar cache busting nos arquivos
echo "🏷️  Aplicando cache busting..."
cd build/web

# Atualizar index.html com versão
if grep -q "{{APP_VERSION}}" index.html 2>/dev/null; then
    sed -i.bak "s|{{APP_VERSION}}|${FULL_VERSION}|g" index.html
    rm -f index.html.bak
fi

# Adicionar version query string aos JS
sed -i.bak "s|main\.dart\.js|main.dart.js?v=${BUILD_TIME}|g" index.html
sed -i.bak "s|flutter_service_worker\.js|flutter_service_worker.js?v=${BUILD_TIME}|g" index.html
rm -f index.html.bak

# Criar version.json na raiz do build
cat > version.json << EOF
{
  "version": "$VERSION",
  "buildHash": "$BUILD_HASH",
  "buildTime": $BUILD_TIME,
  "fullVersion": "$FULL_VERSION",
  "timestamp": "$(date -Iseconds)",
  "gitBranch": "$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'unknown')",
  "buildDate": "$(date '+%Y-%m-%d %H:%M:%S')"
}
EOF

# Adicionar comentário de versão no service worker
if [ -f "flutter_service_worker.js" ]; then
    sed -i.bak "1i// Version: ${FULL_VERSION} - Built: $(date '+%Y-%m-%d %H:%M:%S')" flutter_service_worker.js
    rm -f flutter_service_worker.js.bak
fi

cd ../..

echo ""
echo "✅ Build completo!"
echo "📦 Arquivos em: build/web/"
echo "📄 Version file: build/web/version.json"
echo ""
echo "🎯 Versão: $FULL_VERSION"
echo ""
echo "📋 Próximos passos:"
echo "   1. Testar localmente: cd build/web && python3 -m http.server 8000"
echo "   2. Commit e push para deploy"
echo "   3. Verificar version.json no servidor"
echo ""

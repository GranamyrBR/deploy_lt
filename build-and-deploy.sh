#!/bin/bash
# ============================================
# Script para Build Local e Deploy
# ============================================

set -e  # Para em caso de erro

echo "🚀 Iniciando build local..."

# 1. Limpar build anterior
echo "🧹 Limpando build anterior..."
rm -rf build/web

# 2. Gerar código necessário (env.g.dart)
echo "⚙️  Gerando código (env.g.dart)..."
flutter pub run build_runner build --delete-conflicting-outputs --build-filter="lib/config/env.g.dart"

# 3. Build Flutter Web
echo "📦 Buildando Flutter Web..."
flutter build web \
    --release \
    --pwa-strategy=offline-first \
    --base-href="/" \
    --dart-define=FLUTTER_WEB_USE_SKIA=false \
    --no-tree-shake-icons

# 4. Aplicar cache busting
echo "🏷️  Aplicando cache busting..."
cd build/web
BUILD_VERSION=$(date +%s)
BUILD_HASH=$(git rev-parse --short HEAD 2>/dev/null || echo "local")
VERSION="${BUILD_HASH}-${BUILD_VERSION}"

echo "   Versão: ${VERSION}"

# Update index.html com version
sed -i.bak "s|main\.dart\.js|main.dart.js?v=${VERSION}|g" index.html
sed -i.bak "s|flutter_service_worker\.js|flutter_service_worker.js?v=${VERSION}|g" index.html
rm -f index.html.bak

# Criar arquivo de versão
echo "${VERSION}" > version.txt

cd ../..

echo ""
echo "✅ Build completo!"
echo ""
echo "📤 Próximos passos:"
echo "   1. git add build/web"
echo "   2. git commit -m 'build: add pre-built web files for deployment'"
echo "   3. git push origin deploy/pre-built-web"
echo ""
echo "🌐 No Coolify:"
echo "   - Use Dockerfile.prebuilt"
echo "   - Deploy será instantâneo (apenas copia arquivos)"

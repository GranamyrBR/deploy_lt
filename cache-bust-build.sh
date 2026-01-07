#!/bin/bash
# ============================================
# Script de Build com Cache Busting Automático
# Baseado na estratégia do Lukas Nevosad
# ============================================

set -e

echo "🚀 Iniciando build com cache busting..."

# 1. Build Flutter Web
echo "📦 Building Flutter Web..."
flutter build web \
    --release \
    --pwa-strategy=offline-first \
    --base-href="/" \
    --dart-define=FLUTTER_WEB_USE_SKIA=false \
    --web-renderer=canvaskit

# 2. Gerar timestamp/hash para versionamento
BUILD_VERSION=$(date +%s)
BUILD_HASH=$(git rev-parse --short HEAD 2>/dev/null || echo "local")
VERSION="${BUILD_HASH}-${BUILD_VERSION}"

echo "📌 Version: ${VERSION}"

# 3. Criar diretório de build se não existir
BUILD_DIR="build/web"

# 4. Adicionar versão aos assets JavaScript
echo "🔧 Adicionando cache busting aos JS files..."
cd ${BUILD_DIR}

# Renomear main.dart.js para incluir versão
if [ -f "main.dart.js" ]; then
    mv main.dart.js "main.dart.js?v=${VERSION}"
    echo "✅ main.dart.js versionado"
fi

# 5. Atualizar index.html com versão
echo "📝 Atualizando index.html com versão ${VERSION}..."

# Substituir referências no index.html
sed -i.bak "s|main\.dart\.js|main.dart.js?v=${VERSION}|g" index.html
sed -i.bak "s|flutter_service_worker\.js|flutter_service_worker.js?v=${VERSION}|g" index.html
sed -i.bak "s|{{flutter_service_worker_version}}|${VERSION}|g" index.html

# Adicionar meta tag com versão
sed -i.bak "s|</head>|<meta name=\"app-version\" content=\"${VERSION}\">\n  </head>|" index.html

# 6. Criar arquivo de versão
echo "${VERSION}" > version.txt
echo "✅ Versão salva em version.txt"

# 7. Atualizar Service Worker com versão
if [ -f "flutter_service_worker.js" ]; then
    sed -i.bak "1i// Version: ${VERSION}" flutter_service_worker.js
    echo "✅ Service Worker versionado"
fi

# 8. Limpar backups
rm -f *.bak

# 9. Estatísticas do build
echo ""
echo "📊 Build Statistics:"
echo "   Version: ${VERSION}"
echo "   Build size: $(du -sh . | cut -f1)"
echo "   Main JS size: $(ls -lh main.dart.js* 2>/dev/null | awk '{print $5}' || echo 'N/A')"
echo ""
echo "✅ Build completo com cache busting!"
echo "🌐 Deploy: Suba os arquivos de ${BUILD_DIR} para produção"

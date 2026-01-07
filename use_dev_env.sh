#!/bin/bash
# Script para usar index.dev.html em desenvolvimento local

echo "🔧 Configurando ambiente de DESENVOLVIMENTO..."

# Fazer backup do index.html original
if [ ! -f web/index.html.bak ]; then
    cp web/index.html web/index.html.bak
    echo "✅ Backup criado: web/index.html.bak"
fi

# Copiar index.dev.html para index.html
cp web/index.dev.html web/index.html
echo "✅ Usando web/index.dev.html (com chaves reais)"

echo ""
echo "⚠️  ATENÇÃO:"
echo "   - Este ambiente é APENAS para localhost"
echo "   - As chaves da OpenAI estão EXPOSTAS no código do navegador"
echo "   - NÃO fazer commit do index.html com chaves reais"
echo "   - Para produção, usar backend proxy (veja SECURITY_GUIDE_WEB.md)"
echo ""
echo "🚀 Execute: flutter run -d chrome"

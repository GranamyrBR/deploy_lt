#!/bin/bash
# Script para restaurar index.html para produção

echo "🔒 Configurando ambiente de PRODUÇÃO..."

# Restaurar backup
if [ -f web/index.html.bak ]; then
    cp web/index.html.bak web/index.html
    echo "✅ Restaurado: web/index.html (placeholders, sem chaves)"
else
    echo "⚠️  Backup não encontrado. Manualmente remova chaves do index.html"
fi

echo ""
echo "✅ Ambiente configurado para produção"
echo ""
echo "📋 CHECKLIST PRÉ-DEPLOY:"
echo "   [ ] Chaves removidas do index.html"
echo "   [ ] Backend proxy implementado"
echo "   [ ] Rate limiting configurado"
echo "   [ ] Testes de segurança realizados"
echo ""
echo "📚 Veja: SECURITY_GUIDE_WEB.md"

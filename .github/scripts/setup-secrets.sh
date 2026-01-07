#!/bin/bash
# Script auxiliar para configurar secrets via GitHub CLI
# Uso: bash .github/scripts/setup-secrets.sh

set -e

echo "╔══════════════════════════════════════════════════════════════════════╗"
echo "║         🔐 CONFIGURAÇÃO DE SECRETS DO GITHUB - Lecotour             ║"
echo "╚══════════════════════════════════════════════════════════════════════╝"
echo ""

# Verificar se gh CLI está instalado
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI não está instalado!"
    echo ""
    echo "Instale com:"
    echo "  macOS:   brew install gh"
    echo "  Windows: winget install GitHub.cli"
    echo "  Linux:   https://github.com/cli/cli#installation"
    echo ""
    exit 1
fi

# Verificar se está autenticado
if ! gh auth status &> /dev/null; then
    echo "❌ Você não está autenticado no GitHub CLI!"
    echo ""
    echo "Execute primeiro: gh auth login"
    echo ""
    exit 1
fi

echo "✅ GitHub CLI instalado e autenticado"
echo ""

# Verificar se tem arquivo .env local (NÃO usar em produção!)
if [ -f ".env" ]; then
    echo "⚠️  Arquivo .env encontrado localmente"
    echo ""
    read -p "Deseja usar valores do .env local? (s/N): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        source .env
        echo "✅ Variáveis carregadas do .env"
    fi
else
    echo "ℹ️  Nenhum .env local encontrado. Vamos configurar manualmente."
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 CONFIGURAÇÃO DOS SECRETS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Função para adicionar secret
add_secret() {
    local secret_name=$1
    local secret_value=$2
    local is_optional=$3
    
    if [ -z "$secret_value" ]; then
        read -p "Digite o valor para $secret_name${is_optional:+ (opcional, Enter para pular)}: " secret_value
        
        if [ -z "$secret_value" ] && [ -n "$is_optional" ]; then
            echo "⏭️  $secret_name pulado (opcional)"
            return
        fi
    fi
    
    if [ -n "$secret_value" ]; then
        echo "$secret_value" | gh secret set "$secret_name"
        echo "✅ $secret_name configurado"
    else
        echo "⚠️  $secret_name não configurado (valor vazio)"
    fi
}

# 1. SUPABASE_URL
echo "1️⃣  SUPABASE_URL"
echo "   Exemplo: https://seu-projeto.supabase.co"
add_secret "SUPABASE_URL" "${SUPABASE_URL:-}"

echo ""

# 2. SUPABASE_ANON_KEY
echo "2️⃣  SUPABASE_ANON_KEY"
echo "   Encontre em: Supabase Dashboard > Settings > API"
add_secret "SUPABASE_ANON_KEY" "${SUPABASE_ANON_KEY:-}"

echo ""

# 3. FIREBASE_API_KEY (opcional)
echo "3️⃣  FIREBASE_API_KEY (opcional)"
echo "   Encontre em: Firebase Console > Project Settings"
add_secret "FIREBASE_API_KEY" "${FIREBASE_API_KEY:-}" "optional"

echo ""

# 4. FIREBASE_PROJECT_ID (opcional)
echo "4️⃣  FIREBASE_PROJECT_ID (opcional)"
add_secret "FIREBASE_PROJECT_ID" "${FIREBASE_PROJECT_ID:-}" "optional"

echo ""

# 5. FIREBASE_SERVICE_ACCOUNT (para deploy)
echo "5️⃣  FIREBASE_SERVICE_ACCOUNT (para deploy automático)"
echo "   ⚠️  Este é um JSON grande. Use arquivo: gh secret set FIREBASE_SERVICE_ACCOUNT < service-account.json"
echo ""
read -p "Você tem o arquivo service-account.json? (s/N): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Ss]$ ]]; then
    read -p "Digite o caminho do arquivo: " service_account_path
    if [ -f "$service_account_path" ]; then
        gh secret set FIREBASE_SERVICE_ACCOUNT < "$service_account_path"
        echo "✅ FIREBASE_SERVICE_ACCOUNT configurado"
    else
        echo "❌ Arquivo não encontrado: $service_account_path"
    fi
else
    echo "⏭️  FIREBASE_SERVICE_ACCOUNT pulado (configure manualmente depois)"
fi

echo ""

# 6. WHATSAPP_API_TOKEN (opcional)
echo "6️⃣  WHATSAPP_API_TOKEN (opcional)"
add_secret "WHATSAPP_API_TOKEN" "${WHATSAPP_API_TOKEN:-}" "optional"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ CONFIGURAÇÃO CONCLUÍDA!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📊 Para ver os secrets configurados:"
echo "   gh secret list"
echo ""
echo "🌐 Ou acesse:"
echo "   https://github.com/GranamyrBR/deploy_lt/settings/secrets/actions"
echo ""
echo "🧪 Para testar, execute um workflow manualmente:"
echo "   https://github.com/GranamyrBR/deploy_lt/actions"
echo ""

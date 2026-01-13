#!/bin/bash

# =====================================================
# Script para aplicar migration contact_task
# =====================================================

echo "🚀 Aplicando migration: contact_task"
echo "===================================="
echo ""

# Verificar se o arquivo .env existe
if [ ! -f .env ]; then
    echo "❌ Erro: Arquivo .env não encontrado!"
    echo "   Crie um arquivo .env com as variáveis:"
    echo "   SUPABASE_URL=https://seu-projeto.supabase.co"
    echo "   SUPABASE_SERVICE_KEY=sua_service_role_key"
    exit 1
fi

# Carregar variáveis do .env
export $(cat .env | grep -v '^#' | xargs)

if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_SERVICE_KEY" ]; then
    echo "❌ Erro: SUPABASE_URL ou SUPABASE_SERVICE_KEY não definidos no .env"
    exit 1
fi

echo "📡 Conectando ao Supabase..."
echo "   URL: $SUPABASE_URL"
echo ""

# Ler o SQL da migration
SQL_FILE="supabase/migrations/2025-01-13_create_contact_task.sql"

if [ ! -f "$SQL_FILE" ]; then
    echo "❌ Erro: Migration não encontrada: $SQL_FILE"
    exit 1
fi

echo "📄 Lendo migration: $SQL_FILE"
SQL_CONTENT=$(cat "$SQL_FILE")

# Executar via API REST do Supabase
echo "⚡ Executando migration..."
echo ""

RESPONSE=$(curl -s -X POST \
  "${SUPABASE_URL}/rest/v1/rpc/exec_sql" \
  -H "apikey: ${SUPABASE_SERVICE_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_SERVICE_KEY}" \
  -H "Content-Type: application/json" \
  -d "{\"query\": $(echo "$SQL_CONTENT" | jq -Rs .)}")

# Verificar se deu erro
if echo "$RESPONSE" | grep -q "error"; then
    echo "❌ Erro ao executar migration:"
    echo "$RESPONSE" | jq .
    exit 1
fi

echo "✅ Migration aplicada com sucesso!"
echo ""
echo "📊 Verificando tabela criada..."

# Verificar se a tabela foi criada
VERIFY=$(curl -s -X GET \
  "${SUPABASE_URL}/rest/v1/contact_task?limit=0" \
  -H "apikey: ${SUPABASE_SERVICE_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_SERVICE_KEY}")

if echo "$VERIFY" | grep -q "error"; then
    echo "⚠️  Aviso: Não foi possível verificar a tabela"
    echo "   Verifique manualmente no Dashboard do Supabase"
else
    echo "✅ Tabela contact_task criada e acessível!"
fi

echo ""
echo "🎉 Migração concluída!"
echo ""
echo "Próximos passos:"
echo "1. Teste o sistema de follow-up no app"
echo "2. Crie o modal de criar/editar tarefas"
echo ""

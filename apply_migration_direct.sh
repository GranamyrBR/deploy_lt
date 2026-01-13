#!/bin/bash

# =====================================================
# Script para aplicar migration contact_task via psql
# =====================================================

echo "🚀 Aplicando migration: contact_task"
echo "===================================="
echo ""

# Verificar se psql está instalado
if ! command -v psql &> /dev/null; then
    echo "❌ Erro: psql não está instalado!"
    echo ""
    echo "📋 ALTERNATIVA: Copie e cole o SQL no Supabase Dashboard"
    echo ""
    echo "1. Acesse: https://supabase.com/dashboard"
    echo "2. Vá em SQL Editor"
    echo "3. Cole o conteúdo abaixo:"
    echo ""
    echo "────────────────────────────────────────────"
    cat supabase/migrations/2025-01-13_create_contact_task.sql
    echo "────────────────────────────────────────────"
    echo ""
    exit 1
fi

# Verificar se tem DATABASE_URL no .env
if [ -f .env ]; then
    export $(cat .env | grep DATABASE_URL | xargs)
fi

if [ -z "$DATABASE_URL" ]; then
    echo "❌ Erro: DATABASE_URL não encontrada no .env"
    echo ""
    echo "Adicione no .env:"
    echo "DATABASE_URL=postgresql://postgres:[senha]@db.[projeto].supabase.co:5432/postgres"
    echo ""
    exit 1
fi

echo "📡 Conectando ao banco de dados..."
echo ""

# Executar migration
psql "$DATABASE_URL" -f supabase/migrations/2025-01-13_create_contact_task.sql

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Migration aplicada com sucesso!"
    echo ""
    echo "🎉 Tabela contact_task criada!"
else
    echo ""
    echo "❌ Erro ao aplicar migration"
    exit 1
fi

-- =====================================================
-- CORREÇÃO DO SCHEMA DA TABELA CONTACT
-- =====================================================
-- Este script adiciona as colunas faltantes na tabela contact
-- que são referenciadas no código mas não existem no banco

-- NOTA: agency_id é na verdade account_id (que já existe na tabela)
-- A coluna account_id já existe e referencia a tabela account

-- Adicionar coluna is_vip (status VIP do cliente)
ALTER TABLE public.contact 
ADD COLUMN IF NOT EXISTS is_vip BOOLEAN DEFAULT FALSE;

-- NOTA: account_type_id foi removido pois account_category pertence a account
-- O tipo de conta pode ser acessado via: contact.account_id -> account.chave_id -> account_category.account_type
-- Não é necessário duplicar essa informação na tabela contact

-- Verificar se as colunas foram adicionadas
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'contact' 
  AND column_name IN ('account_id', 'is_vip', 'account_type_id')
ORDER BY column_name;

-- Verificar estrutura completa da tabela contact
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'contact' 
ORDER BY ordinal_position;
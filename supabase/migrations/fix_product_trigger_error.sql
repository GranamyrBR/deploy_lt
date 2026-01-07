-- =====================================================
-- CORREÇÃO DO ERRO DE TRIGGER NA TABELA PRODUCT
-- =====================================================
-- 
-- PROBLEMA: Trigger tentando atualizar updated_at na tabela product que não tem essa coluna
-- ERRO: ERROR: 42703: record "new" has no field "updated_at"
-- SOLUÇÃO: Remover o trigger da tabela product

-- =====================================================
-- 1. VERIFICAR SE O TRIGGER EXISTE
-- =====================================================

SELECT 
    trigger_name,
    event_object_table as table_name,
    action_statement
FROM information_schema.triggers 
WHERE trigger_schema = 'public' 
    AND event_object_table = 'product'
    AND action_statement LIKE '%update_updated_at_column%';

-- =====================================================
-- 2. REMOVER O TRIGGER PROBLEMÁTICO
-- =====================================================

-- Remover trigger da tabela product (que não tem updated_at)
DROP TRIGGER IF EXISTS update_product_updated_at ON product;

-- =====================================================
-- 3. VERIFICAÇÃO FINAL
-- =====================================================

-- Verificar se o trigger foi removido
SELECT 
    trigger_name,
    event_object_table as table_name
FROM information_schema.triggers 
WHERE trigger_schema = 'public' 
    AND event_object_table = 'product'
    AND action_statement LIKE '%update_updated_at_column%';

-- Se não retornar nenhum resultado, o trigger foi removido com sucesso

SELECT '✅ Trigger problemático da tabela product removido!' as status;

-- =====================================================
-- 4. OPCIONAL: ADICIONAR CAMPO UPDATED_AT À TABELA PRODUCT
-- =====================================================
-- 
-- Se você quiser adicionar o campo updated_at à tabela product,
-- descomente as linhas abaixo:
--
-- ALTER TABLE public.product 
-- ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
--
-- -- Recriar o trigger após adicionar o campo
-- CREATE TRIGGER update_product_updated_at 
--     BEFORE UPDATE ON product
--     FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
--
-- SELECT '✅ Campo updated_at adicionado à tabela product e trigger recriado!' as status;
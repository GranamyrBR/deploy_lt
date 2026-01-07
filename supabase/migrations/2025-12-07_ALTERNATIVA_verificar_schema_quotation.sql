-- ============================================================================
-- Script: Verificação do Schema da tabela quotation
-- Data: 2025-12-07
-- Descrição: Verifica todas as colunas da tabela quotation
-- ============================================================================

-- 1. Verificar todas as colunas da tabela quotation
SELECT 
    column_name,
    data_type,
    character_maximum_length,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
AND table_name = 'quotation'
ORDER BY ordinal_position;

-- 2. Verificar se client_document existe
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'quotation' 
            AND column_name = 'client_document'
        ) THEN 'EXISTE - Nenhuma ação necessária'
        ELSE 'NÃO EXISTE - Execute o script de migração'
    END AS status_client_document;

-- 3. Verificar constraints e foreign keys
SELECT
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
LEFT JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.table_schema = 'public'
AND tc.table_name = 'quotation'
ORDER BY tc.constraint_type, tc.constraint_name;

-- 4. Verificar índices existentes
SELECT
    indexname,
    indexdef
FROM pg_indexes
WHERE tablename = 'quotation'
AND schemaname = 'public'
ORDER BY indexname;

-- ============================================================================
-- INSTRUÇÕES DE USO:
-- ============================================================================
-- 1. Execute este script primeiro para verificar o estado atual
-- 2. Se client_document NÃO EXISTIR, execute:
--    2025-12-07_add_client_document_to_quotation.sql
-- 3. Se client_document JÁ EXISTIR, o problema é no código Flutter
-- ============================================================================

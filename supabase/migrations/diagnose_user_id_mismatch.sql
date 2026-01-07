-- 🔍 DIAGNÓSTICO DO USER ID - EXECUTAR NO SUPABASE DASHBOARD
-- Verificar se há mismatch entre IDs

-- ==============================================
-- 1. VERIFICAR ESTRUTURA DA TABELA USER
-- ==============================================
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'user'
ORDER BY ordinal_position;

-- ==============================================
-- 2. VERIFICAR TIPOS DE DADOS DAS COLUNAS DE REFERÊNCIA
-- ==============================================
SELECT 
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name,
    c.data_type
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu ON ccu.constraint_name = tc.constraint_name
JOIN information_schema.columns AS c ON c.table_name = tc.table_name AND c.column_name = kcu.column_name
WHERE tc.constraint_type = 'FOREIGN KEY' 
AND (tc.table_name LIKE 'ai_%' OR tc.table_name = 'user')
ORDER BY tc.table_name, kcu.column_name;

-- ==============================================
-- 3. VERIFICAR DADOS REAIS
-- ==============================================
-- Ver alguns usuários reais
SELECT id, username, email, created_at 
FROM "user" 
LIMIT 5;

-- Ver se há algum dado nas tabelas AI
SELECT 
    'ai_interactions' as table_name,
    COUNT(*) as total_records
FROM ai_interactions
UNION ALL
SELECT 
    'ai_errors' as table_name,
    COUNT(*) as total_records
FROM ai_errors;

-- Verificar se há problemas de tipo de dados
SELECT 
    table_name,
    column_name,
    data_type,
    udt_name
FROM information_schema.columns 
WHERE table_name LIKE 'ai_%' AND column_name = 'user_id';
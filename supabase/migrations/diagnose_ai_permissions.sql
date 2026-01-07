-- 🔍 DIAGNÓSTICO COMPLETO DAS PERMISSÕES AI
-- Executar no Supabase Dashboard para identificar o problema

-- ==============================================
-- 1. VERIFICAR STATUS DAS TABELAS AI
-- ==============================================
SELECT 
    schemaname,
    tablename,
    tableowner,
    rowsecurity,
    (CASE WHEN rowsecurity THEN 'RLS ATIVADO' ELSE 'RLS DESATIVADO' END) as rls_status
FROM pg_tables 
WHERE tablename LIKE 'ai_%'
ORDER BY tablename;

-- ==============================================
-- 2. VERIFICAR PERMISSÕES ATUAIS DETALHADAS
-- ==============================================
SELECT 
    table_name,
    grantee,
    privilege_type,
    is_grantable,
    CASE 
        WHEN grantee = 'authenticated' THEN '✅ Usuários autenticados'
        WHEN grantee = 'anon' THEN '⚠️  Usuários anônimos'
        WHEN grantee = 'postgres' THEN '🔧 Administrador'
        ELSE grantee
    END as grantee_type
FROM information_schema.role_table_grants 
WHERE table_name LIKE 'ai_%'
ORDER BY table_name, grantee, privilege_type;

-- ==============================================
-- 3. VERIFICAR POLÍTICAS RLS EXISTENTES
-- ==============================================
SELECT 
    schemaname,
    tablename,
    policyname,
    cmd,
    roles,
    qual,
    with_check
FROM pg_policies 
WHERE schemaname = 'public' AND tablename LIKE 'ai_%'
ORDER BY tablename, policyname;

-- ==============================================
-- 4. TESTE DE ACESSO DIRETO COM USUÁRIO ATUAL
-- ==============================================
SELECT current_user, current_role;

-- Testar select direto
SELECT COUNT(*) as test_select FROM ai_errors LIMIT 1;

-- Testar insert direto (com valor seguro)
INSERT INTO ai_errors (user_id, error_message, error_type, conversation_id) 
VALUES (
    (SELECT id FROM "user" LIMIT 1),
    'Teste diagnostico',
    'diagnostic_test',
    'diag-123'
);

-- Verificar se o insert funcionou
SELECT COUNT(*) as test_insert FROM ai_errors WHERE error_type = 'diagnostic_test';

-- Limpar teste
DELETE FROM ai_errors WHERE error_type = 'diagnostic_test';

-- ==============================================
-- 5. VERIFICAR ERROS RECENTES NO BANCO
-- ==============================================
SELECT 
    error_message,
    error_type,
    created_at,
    user_id
FROM ai_errors 
WHERE created_at > NOW() - INTERVAL '1 hour'
ORDER BY created_at DESC
LIMIT 10;

-- ==============================================
-- 6. VERIFICAR CONFIGURAÇÃO DE ROLES
-- ==============================================
SELECT 
    rolname,
    rolsuper,
    rolcreaterole,
    rolcreatedb,
    rolcanlogin
FROM pg_roles 
WHERE rolname IN ('authenticated', 'anon', 'postgres')
ORDER BY rolname;

-- ==============================================
-- 7. VERIFICAR SEQUÊNCIAS DAS TABELAS AI
-- ==============================================
SELECT 
    schemaname,
    sequencename,
    sequenceowner,
    data_type
FROM pg_sequences 
WHERE schemaname = 'public' AND sequencename LIKE 'ai_%'
ORDER BY sequencename;

-- ==============================================
-- RELATÓRIO DE DIAGNÓSTICO
-- ==============================================
SELECT '=== RELATÓRIO DE DIAGNÓSTICO ===' as report;
SELECT 'Se algum teste acima falhar, o problema será identificado' as info;
SELECT 'Verifique especialmente as permissões para authenticated e anon' as recommendation;

-- Se tudo estiver correto, mas ainda houver erro, o problema pode ser:
-- 1. A conexão do Flutter não está usando authenticated corretamente
-- 2. O usuário não está logado no momento da chamada
-- 3. Há algum trigger ou RLS residual que não foi removido
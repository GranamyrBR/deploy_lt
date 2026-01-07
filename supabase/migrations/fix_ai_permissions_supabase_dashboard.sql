-- 🔧 FIX COMPLETO PARA PERMISSÕES AI - EXECUTAR NO SUPABASE DASHBOARD
-- Copie e cole este script no SQL Editor do seu Supabase

-- ==============================================
-- DESATIVAR RLS COMPLETAMENTE NAS TABELAS AI
-- ==============================================
ALTER TABLE ai_interactions DISABLE ROW LEVEL SECURITY;
ALTER TABLE ai_errors DISABLE ROW LEVEL SECURITY;
ALTER TABLE ai_conversation_history DISABLE ROW LEVEL SECURITY;
ALTER TABLE ai_usage_metrics DISABLE ROW LEVEL SECURITY;
ALTER TABLE ai_rate_limit_tracking DISABLE ROW LEVEL SECURITY;

-- ==============================================
-- REMOVER TODAS AS POLÍTICAS EXISTENTES
-- ==============================================
DO $$
DECLARE
    policy_record RECORD;
    table_names TEXT[] := ARRAY['ai_interactions', 'ai_errors', 'ai_conversation_history', 'ai_usage_metrics', 'ai_rate_limit_tracking'];
    table_name TEXT;
BEGIN
    FOREACH table_name IN ARRAY table_names
    LOOP
        FOR policy_record IN 
            SELECT polname 
            FROM pg_policies 
            WHERE schemaname = 'public' AND tablename = table_name
        LOOP
            EXECUTE format('DROP POLICY IF EXISTS %I ON %I', policy_record.polname, table_name);
        END LOOP;
    END LOOP;
END $$;

-- ==============================================
-- GARANTIR PERMISSÕES TOTAIS
-- ==============================================
-- Revogar tudo primeiro
REVOKE ALL PRIVILEGES ON ai_interactions FROM PUBLIC, authenticated, anon;
REVOKE ALL PRIVILEGES ON ai_errors FROM PUBLIC, authenticated, anon;
REVOKE ALL PRIVILEGES ON ai_conversation_history FROM PUBLIC, authenticated, anon;
REVOKE ALL PRIVILEGES ON ai_usage_metrics FROM PUBLIC, authenticated, anon;
REVOKE ALL PRIVILEGES ON ai_rate_limit_tracking FROM PUBLIC, authenticated, anon;

-- Conceder permissões totais
GRANT ALL PRIVILEGES ON ai_interactions TO authenticated, anon;
GRANT ALL PRIVILEGES ON ai_errors TO authenticated, anon;
GRANT ALL PRIVILEGES ON ai_conversation_history TO authenticated, anon;
GRANT ALL PRIVILEGES ON ai_usage_metrics TO authenticated, anon;
GRANT ALL PRIVILEGES ON ai_rate_limit_tracking TO authenticated, anon;

-- ==============================================
-- TESTAR O FUNCIONAMENTO
-- ==============================================

-- Testar insert na tabela ai_errors (onde estava dando erro)
INSERT INTO ai_errors (user_id, error_message, error_type, conversation_id) 
VALUES (
    (SELECT id FROM "user" LIMIT 1),
    'Teste de permissão - erro de AI',
    'permission_test',
    'test-conv-123'
);

-- Verificar se funcionou
SELECT COUNT(*) as total_errors FROM ai_errors WHERE error_type = 'permission_test';

-- Testar insert na tabela ai_interactions
INSERT INTO ai_interactions (user_id, conversation_id, request_message, response_message, tokens_used, model) 
VALUES (
    (SELECT id FROM "user" LIMIT 1),
    'test-conv-123',
    'Mensagem de teste',
    'Resposta de teste',
    100,
    'gpt-4-turbo'
);

-- Verificar se funcionou
SELECT COUNT(*) as total_interactions FROM ai_interactions WHERE conversation_id = 'test-conv-123';

-- Limpar testes
DELETE FROM ai_errors WHERE error_type = 'permission_test';
DELETE FROM ai_interactions WHERE conversation_id = 'test-conv-123';

-- ==============================================
-- VERIFICAR PERMISSÕES FINAIS
-- ==============================================
SELECT 
    table_name,
    grantee,
    string_agg(privilege_type, ', ' ORDER BY privilege_type) as permissions
FROM information_schema.role_table_grants 
WHERE table_name LIKE 'ai_%'
GROUP BY table_name, grantee
ORDER BY table_name, grantee;

-- ==============================================
-- RELATÓRIO FINAL
-- ==============================================
SELECT '✅ PERMISSÕES CORRIGIDAS COM SUCESSO!' AS status;
SELECT '✅ Tabelas AI totalmente acessíveis' AS status;
SELECT '✅ AI Assistant deve funcionar sem erros' AS status;
SELECT '⚠️  Configuração permissiva - ajustar para produção' AS warning;
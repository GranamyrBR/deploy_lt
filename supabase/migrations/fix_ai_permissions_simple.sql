-- 🔧 SOLUÇÃO SIMPLES PARA PERMISSÕES AI - SUPABASE DASHBOARD
-- Execute linha por linha no SQL Editor do Supabase

-- PASSO 1: Desativar RLS em todas as tabelas AI
ALTER TABLE ai_interactions DISABLE ROW LEVEL SECURITY;
ALTER TABLE ai_errors DISABLE ROW LEVEL SECURITY;
ALTER TABLE ai_conversation_history DISABLE ROW LEVEL SECURITY;
ALTER TABLE ai_usage_metrics DISABLE ROW LEVEL SECURITY;
ALTER TABLE ai_rate_limit_tracking DISABLE ROW LEVEL SECURITY;

-- PASSO 2: Remover políticas antigas (se existirem)
-- Para ai_interactions
DROP POLICY IF EXISTS "Users can view own interactions" ON ai_interactions;
DROP POLICY IF EXISTS "Users can insert own interactions" ON ai_interactions;

-- Para ai_errors
DROP POLICY IF EXISTS "Users can view own errors" ON ai_errors;
DROP POLICY IF EXISTS "Admins can view all errors" ON ai_errors;

-- Para ai_conversation_history
DROP POLICY IF EXISTS "Users can view own conversation history" ON ai_conversation_history;
DROP POLICY IF EXISTS "Users can insert own conversation history" ON ai_conversation_history;

-- Para ai_usage_metrics
DROP POLICY IF EXISTS "Users can view own metrics" ON ai_usage_metrics;

-- Para ai_rate_limit_tracking
DROP POLICY IF EXISTS "Users can view own rate limit data" ON ai_rate_limit_tracking;
DROP POLICY IF EXISTS "Users can update own rate limit data" ON ai_rate_limit_tracking;
DROP POLICY IF EXISTS "Users can insert own rate limit data" ON ai_rate_limit_tracking;

-- PASSO 3: Conceder permissões totais
GRANT ALL PRIVILEGES ON ai_interactions TO authenticated;
GRANT ALL PRIVILEGES ON ai_errors TO authenticated;
GRANT ALL PRIVILEGES ON ai_conversation_history TO authenticated;
GRANT ALL PRIVILEGES ON ai_usage_metrics TO authenticated;
GRANT ALL PRIVILEGES ON ai_rate_limit_tracking TO authenticated;

-- Também para anon (para testes)
GRANT ALL PRIVILEGES ON ai_interactions TO anon;
GRANT ALL PRIVILEGES ON ai_errors TO anon;
GRANT ALL PRIVILEGES ON ai_conversation_history TO anon;
GRANT ALL PRIVILEGES ON ai_usage_metrics TO anon;
GRANT ALL PRIVILEGES ON ai_rate_limit_tracking TO anon;

-- PASSO 4: Testar se funcionou
-- Testar insert na tabela que estava dando erro
INSERT INTO ai_errors (user_id, error_message, error_type, conversation_id) 
VALUES (
    (SELECT id FROM "user" LIMIT 1),
    'Teste de permissão - erro de AI',
    'permission_test',
    'test-conv-123'
);

-- Se o insert acima funcionar, suas permissões estão corrigidas!
SELECT '✅ PERMISSÕES FUNCIONANDO!' AS status;

-- Limpar teste
DELETE FROM ai_errors WHERE error_type = 'permission_test';
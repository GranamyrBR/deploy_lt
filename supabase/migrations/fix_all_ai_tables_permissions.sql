-- 🔧 Fix completo para permissões de todas as tabelas AI
-- Garantir acesso total para testes e debugging

-- ==============================================
-- DESATIVAR RLS em todas as tabelas AI temporariamente
-- ==============================================
ALTER TABLE ai_interactions DISABLE ROW LEVEL SECURITY;
ALTER TABLE ai_errors DISABLE ROW LEVEL SECURITY;
ALTER TABLE ai_conversation_history DISABLE ROW LEVEL SECURITY;
ALTER TABLE ai_usage_metrics DISABLE ROW LEVEL SECURITY;
ALTER TABLE ai_rate_limit_tracking DISABLE ROW LEVEL SECURITY;

-- ==============================================
-- GARANTIR PERMISSÕES COMPLETAS
-- ==============================================
-- Permissões para authenticated
GRANT ALL PRIVILEGES ON ai_interactions TO authenticated;
GRANT ALL PRIVILEGES ON ai_errors TO authenticated;
GRANT ALL PRIVILEGES ON ai_conversation_history TO authenticated;
GRANT ALL PRIVILEGES ON ai_usage_metrics TO authenticated;
GRANT ALL PRIVILEGES ON ai_rate_limit_tracking TO authenticated;

-- Permissões para anon (para testes)
GRANT ALL PRIVILEGES ON ai_interactions TO anon;
GRANT ALL PRIVILEGES ON ai_errors TO anon;
GRANT ALL PRIVILEGES ON ai_conversation_history TO anon;
GRANT ALL PRIVILEGES ON ai_usage_metrics TO anon;
GRANT ALL PRIVILEGES ON ai_rate_limit_tracking TO anon;

-- ==============================================
-- REMOVER POLÍTICAS ANTIGAS
-- ==============================================
-- Remover todas as políticas existentes
DROP POLICY IF EXISTS "Users can view own interactions" ON ai_interactions;
DROP POLICY IF EXISTS "Users can insert own interactions" ON ai_interactions;
DROP POLICY IF EXISTS "Users can view own errors" ON ai_errors;
DROP POLICY IF EXISTS "Admins can view all errors" ON ai_errors;
DROP POLICY IF EXISTS "Users can view own conversation history" ON ai_conversation_history;
DROP POLICY IF EXISTS "Users can insert own conversation history" ON ai_conversation_history;
DROP POLICY IF EXISTS "Users can view own metrics" ON ai_usage_metrics;
DROP POLICY IF EXISTS "Users can view own rate limit data" ON ai_rate_limit_tracking;
DROP POLICY IF EXISTS "Users can update own rate limit data" ON ai_rate_limit_tracking;
DROP POLICY IF EXISTS "Users can insert own rate limit data" ON ai_rate_limit_tracking;
DROP POLICY IF EXISTS "Allow all operations on ai_errors" ON ai_errors;

-- ==============================================
-- CRIAR POLÍTICAS PERMISSIVAS ÚNICAS
-- ==============================================
-- Política única para cada tabela que permite tudo
CREATE POLICY "Allow all operations" ON ai_interactions FOR ALL USING (true);
CREATE POLICY "Allow all operations" ON ai_errors FOR ALL USING (true);
CREATE POLICY "Allow all operations" ON ai_conversation_history FOR ALL USING (true);
CREATE POLICY "Allow all operations" ON ai_usage_metrics FOR ALL USING (true);
CREATE POLICY "Allow all operations" ON ai_rate_limit_tracking FOR ALL USING (true);

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
SELECT '✅ RLS desativado em todas as tabelas AI' AS status;
SELECT '✅ Permissões totais concedidas para authenticated e anon' AS status;
SELECT '✅ Políticas permissivas únicas criadas' AS status;
SELECT '✅ Todas as tabelas AI agora totalmente acessíveis' AS status;

-- Nota: Esta configuração é para testes. Em produção, devemos reativar RLS com políticas mais restritivas
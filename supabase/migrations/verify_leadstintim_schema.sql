-- ============================================
-- Verificar schema atual da tabela leadstintim
-- ============================================

-- 1. Ver estrutura da tabela
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'leadstintim'
ORDER BY ordinal_position;

-- 2. Ver constraints
SELECT
    con.conname AS constraint_name,
    con.contype AS constraint_type,
    pg_get_constraintdef(con.oid) AS constraint_definition
FROM pg_constraint con
JOIN pg_class rel ON rel.oid = con.conrelid
WHERE rel.relname = 'leadstintim';

-- 3. Testar insert sem phone
-- (descomente para testar)
-- INSERT INTO leadstintim (name, source, message, from_me, created_at)
-- VALUES ('Teste Lead', 'WhatsApp', 'Mensagem teste', false, NOW())
-- RETURNING *;

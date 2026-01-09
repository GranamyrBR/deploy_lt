-- ============================================
-- Verificar constraints finais da tabela leadstintim
-- ============================================

SELECT 
    con.conname AS constraint_name,
    con.contype AS constraint_type,
    pg_get_constraintdef(con.oid) AS constraint_definition
FROM pg_constraint con
JOIN pg_class rel ON rel.oid = con.conrelid
WHERE rel.relname = 'leadstintim'
ORDER BY con.contype, con.conname;

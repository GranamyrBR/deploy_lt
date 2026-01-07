-- =====================================================
-- SCRIPT: Executar Migração from_me (VERSÃO DIRETA)
-- DATA: 2025-01-06
-- OBJETIVO: Popular coluna from_me COM AUTO-COMMIT
-- =====================================================

-- ⚠️ Este script executa IMEDIATAMENTE (sem precisar descomentar COMMIT)

-- =====================================================
-- PASSO 1: CRIAR BACKUP
-- =====================================================

DROP TABLE IF EXISTS leadstintim_backup_20250106;
CREATE TABLE leadstintim_backup_20250106 AS SELECT * FROM leadstintim;

SELECT 
    '✅ BACKUP CRIADO' AS status,
    COUNT(*) AS registros_backup
FROM leadstintim_backup_20250106;

-- =====================================================
-- PASSO 2: ANÁLISE ANTES DA MIGRAÇÃO
-- =====================================================

SELECT 
    'ANTES: Registros com from_me no body' AS momento,
    COUNT(*) AS quantidade
FROM leadstintim
WHERE body::text LIKE '%"from_me"%';

-- =====================================================
-- PASSO 3: EXECUTAR UPDATE
-- =====================================================

UPDATE leadstintim
SET from_me = 
    CASE 
        WHEN body::jsonb->>'from_me' = 'true' THEN 'true'
        WHEN body::jsonb->>'from_me' = 'false' THEN 'false'
        ELSE from_me
    END
WHERE body::text LIKE '%"from_me"%';

-- =====================================================
-- PASSO 4: VALIDAÇÃO IMEDIATA
-- =====================================================

SELECT 
    'DEPOIS: from_me = true' AS status,
    COUNT(*) AS quantidade
FROM leadstintim
WHERE from_me = 'true'
UNION ALL
SELECT 
    'DEPOIS: from_me = false',
    COUNT(*)
FROM leadstintim
WHERE from_me = 'false'
UNION ALL
SELECT 
    'DEPOIS: from_me NULL (mensagens antigas)',
    COUNT(*)
FROM leadstintim
WHERE from_me IS NULL;

-- =====================================================
-- PASSO 5: VERIFICAR ALGUNS EXEMPLOS
-- =====================================================

SELECT 
    id,
    from_me AS coluna_from_me,
    body::jsonb->>'from_me' AS body_from_me,
    body::jsonb->>'message' AS mensagem,
    created_at
FROM leadstintim
WHERE body::text LIKE '%"from_me"%'
LIMIT 10;

-- =====================================================
-- ✅ MIGRAÇÃO EXECUTADA COM SUCESSO!
-- =====================================================

SELECT '🎉 MIGRAÇÃO CONCLUÍDA!' AS resultado;

-- =====================================================
-- ROLLBACK (se necessário)
-- =====================================================
/*
-- Se precisar desfazer:
TRUNCATE leadstintim;
INSERT INTO leadstintim SELECT * FROM leadstintim_backup_20250106;
SELECT '⏪ ROLLBACK EXECUTADO' AS status;
*/

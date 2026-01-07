-- =====================================================
-- SCRIPT: Limpar from_me do campo body (EXECUTAR APÓS VALIDAÇÃO)
-- DATA: 2025-01-06
-- OBJETIVO: Remover duplicação de from_me no JSON body
-- =====================================================

-- ⚠️ ATENÇÃO: 
-- 1. Execute APENAS após validar que migrate_from_me_from_body_to_column.sql funcionou
-- 2. Confirme que a aplicação está usando o campo from_me corretamente
-- 3. Mantenha o backup por alguns dias antes de dropar

BEGIN;

-- =====================================================
-- VALIDAÇÃO ANTES DE LIMPAR
-- =====================================================

-- Verificar se a coluna from_me está populada
DO $$ 
DECLARE
    column_count INTEGER;
    body_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO column_count 
    FROM leadstintim 
    WHERE from_me IS NOT NULL;
    
    SELECT COUNT(*) INTO body_count 
    FROM leadstintim 
    WHERE body::text LIKE '%"from_me"%';
    
    RAISE NOTICE 'Registros com from_me na coluna: %', column_count;
    RAISE NOTICE 'Registros com from_me no body: %', body_count;
    
    IF column_count = 0 THEN
        RAISE EXCEPTION '❌ ERRO: Coluna from_me está vazia! Execute primeiro migrate_from_me_from_body_to_column.sql';
    END IF;
    
    IF body_count = 0 THEN
        RAISE NOTICE '✅ Body já está limpo, nada a fazer';
    END IF;
END $$;

-- =====================================================
-- BACKUP ADICIONAL (APENAS REGISTROS A SEREM ALTERADOS)
-- =====================================================

DROP TABLE IF EXISTS leadstintim_body_backup_20250106;

CREATE TABLE leadstintim_body_backup_20250106 AS 
SELECT id, body, from_me
FROM leadstintim
WHERE body::text LIKE '%"from_me"%';

SELECT 
    'Backup de registros com from_me no body' AS info,
    COUNT(*) AS quantidade
FROM leadstintim_body_backup_20250106;

-- =====================================================
-- REMOVER from_me DO CAMPO BODY
-- =====================================================

-- Método 1: Remover chave from_me do JSONB raiz
UPDATE leadstintim
SET body = (body::jsonb - 'from_me')::text
WHERE body::text LIKE '%"from_me"%'
AND body::jsonb ? 'from_me'; -- Apenas se from_me existe no nível raiz

-- Verificar resultado
SELECT 
    'Registros ainda com from_me no body após limpeza' AS status,
    COUNT(*) AS quantidade
FROM leadstintim
WHERE body::text LIKE '%"from_me"%';

-- =====================================================
-- VALIDAÇÃO FINAL
-- =====================================================

-- Confirmar que from_me ainda está na coluna
SELECT 
    'Coluna from_me = true' AS metrica,
    COUNT(*) AS quantidade
FROM leadstintim
WHERE from_me = 'true'
UNION ALL
SELECT 
    'Coluna from_me = false',
    COUNT(*)
FROM leadstintim
WHERE from_me = 'false'
UNION ALL
SELECT 
    'Coluna from_me NULL',
    COUNT(*)
FROM leadstintim
WHERE from_me IS NULL;

-- Mostrar exemplos de registros limpos
SELECT 
    id,
    from_me AS coluna_from_me,
    body::jsonb ? 'from_me' AS ainda_tem_no_body,
    LEFT(body, 100) AS body_preview
FROM leadstintim
WHERE from_me IS NOT NULL
LIMIT 5;

-- =====================================================
-- COMMIT OU ROLLBACK
-- =====================================================

-- ⚠️ REVISE OS RESULTADOS ACIMA!
-- DESCOMENTE UMA DAS LINHAS:

-- COMMIT; -- ✅ Confirmar limpeza
-- ROLLBACK; -- ❌ Desfazer

-- =====================================================
-- ESTATÍSTICAS DE ECONOMIA DE ESPAÇO
-- =====================================================

/*
-- Após commitar, execute para ver economia de espaço:

SELECT 
    pg_size_pretty(pg_total_relation_size('leadstintim')) AS tamanho_total,
    pg_size_pretty(pg_relation_size('leadstintim')) AS tamanho_dados,
    pg_size_pretty(pg_total_relation_size('leadstintim') - pg_relation_size('leadstintim')) AS tamanho_indices;

-- Reindexar para recuperar espaço
REINDEX TABLE leadstintim;
VACUUM ANALYZE leadstintim;
*/

-- =====================================================
-- ROLLBACK MANUAL (se necessário)
-- =====================================================

/*
BEGIN;

-- Restaurar body original
UPDATE leadstintim l
SET body = b.body
FROM leadstintim_body_backup_20250106 b
WHERE l.id = b.id;

COMMIT;
*/

-- =====================================================
-- ✅ SCRIPT CONCLUÍDO
-- =====================================================

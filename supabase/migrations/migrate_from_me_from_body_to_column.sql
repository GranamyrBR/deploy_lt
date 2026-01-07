-- =====================================================
-- SCRIPT: Migrar from_me do campo body para coluna dedicada
-- DATA: 2025-01-06
-- OBJETIVO: Extrair from_me do JSON body e popular coluna from_me
-- =====================================================

-- ⚠️ ATENÇÃO: Execute este script em horário de baixo tráfego
-- Tempo estimado: ~1-5 minutos dependendo do volume de dados

BEGIN;

-- =====================================================
-- PASSO 1: CRIAR BACKUP DA TABELA
-- =====================================================

DROP TABLE IF EXISTS leadstintim_backup_20250106;

CREATE TABLE leadstintim_backup_20250106 AS 
SELECT * FROM leadstintim;

-- Verificar backup
DO $$ 
DECLARE
    original_count INTEGER;
    backup_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO original_count FROM leadstintim;
    SELECT COUNT(*) INTO backup_count FROM leadstintim_backup_20250106;
    
    IF original_count != backup_count THEN
        RAISE EXCEPTION 'ERRO: Backup falhou! Original: %, Backup: %', original_count, backup_count;
    END IF;
    
    RAISE NOTICE '✅ Backup criado com sucesso: % registros', backup_count;
END $$;

-- =====================================================
-- PASSO 2: ANÁLISE PRÉVIA DOS DADOS
-- =====================================================

-- Verificar quantos registros têm from_me no body
SELECT 
    'Registros com from_me no body' AS metrica,
    COUNT(*) AS quantidade
FROM leadstintim
WHERE body::text LIKE '%"from_me"%'
UNION ALL
SELECT 
    'Registros SEM from_me no body',
    COUNT(*)
FROM leadstintim
WHERE body::text NOT LIKE '%"from_me"%'
UNION ALL
SELECT 
    'Total de registros',
    COUNT(*)
FROM leadstintim;

-- Exemplos de valores encontrados
SELECT 
    'Exemplo from_me = true' AS tipo,
    body::jsonb->>'from_me' AS valor,
    COUNT(*) AS quantidade
FROM leadstintim
WHERE body::jsonb->>'from_me' = 'true'
GROUP BY body::jsonb->>'from_me'
UNION ALL
SELECT 
    'Exemplo from_me = false',
    body::jsonb->>'from_me',
    COUNT(*)
FROM leadstintim
WHERE body::jsonb->>'from_me' = 'false'
GROUP BY body::jsonb->>'from_me';

-- =====================================================
-- PASSO 3: ATUALIZAR COLUNA from_me COM VALOR DO BODY
-- =====================================================

-- Atualizar registros onde body contém from_me
UPDATE leadstintim
SET from_me = 
    CASE 
        WHEN body::jsonb->>'from_me' = 'true' THEN 'true'
        WHEN body::jsonb->>'from_me' = 'false' THEN 'false'
        ELSE from_me -- Manter valor atual se não encontrar no body
    END
WHERE body::text LIKE '%"from_me"%';

-- Verificar atualização
DO $$ 
DECLARE
    updated_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO updated_count 
    FROM leadstintim 
    WHERE from_me IS NOT NULL;
    
    RAISE NOTICE '✅ Registros com from_me preenchido: %', updated_count;
END $$;

-- =====================================================
-- PASSO 4: REMOVER from_me DO CAMPO BODY (OPCIONAL)
-- =====================================================

-- ⚠️ CUIDADO: Esta operação remove a chave from_me do JSON
-- Descomente as linhas abaixo se quiser limpar o body

/*
UPDATE leadstintim
SET body = (body::jsonb - 'from_me')::text
WHERE body::text LIKE '%"from_me"%';

RAISE NOTICE '✅ Campo from_me removido do body';
*/

-- =====================================================
-- PASSO 5: VALIDAÇÃO FINAL
-- =====================================================

-- Comparar antes e depois
SELECT 
    'Registros com from_me = true' AS metrica,
    COUNT(*) AS quantidade
FROM leadstintim
WHERE from_me = 'true'
UNION ALL
SELECT 
    'Registros com from_me = false',
    COUNT(*)
FROM leadstintim
WHERE from_me = 'false'
UNION ALL
SELECT 
    'Registros com from_me NULL',
    COUNT(*)
FROM leadstintim
WHERE from_me IS NULL;

-- Validar integridade
DO $$ 
DECLARE
    body_count INTEGER;
    column_count INTEGER;
BEGIN
    -- Contar from_me no body
    SELECT COUNT(*) INTO body_count
    FROM leadstintim_backup_20250106
    WHERE body::text LIKE '%"from_me"%';
    
    -- Contar from_me na coluna (excluindo NULLs)
    SELECT COUNT(*) INTO column_count
    FROM leadstintim
    WHERE from_me IS NOT NULL;
    
    IF column_count < body_count THEN
        RAISE WARNING '⚠️ Alguns registros podem não ter sido migrados. Body: %, Coluna: %', body_count, column_count;
    ELSE
        RAISE NOTICE '✅ Migração validada com sucesso!';
    END IF;
END $$;

-- =====================================================
-- PASSO 6: COMMIT OU ROLLBACK
-- =====================================================

-- ⚠️ IMPORTANTE: Revise os resultados acima antes de commitar!
-- Se algo estiver errado, execute: ROLLBACK;
-- Se tudo estiver certo, execute: COMMIT;

-- DESCOMENTE UMA DAS LINHAS ABAIXO:
-- COMMIT; -- ✅ Confirmar mudanças
-- ROLLBACK; -- ❌ Desfazer mudanças

-- =====================================================
-- INSTRUÇÕES DE ROLLBACK MANUAL (se necessário)
-- =====================================================

/*
-- Se já commitou e precisa reverter:

BEGIN;

-- Restaurar dados do backup
TRUNCATE leadstintim;

INSERT INTO leadstintim 
SELECT * FROM leadstintim_backup_20250106;

COMMIT;

-- Verificar
SELECT COUNT(*) FROM leadstintim;
SELECT COUNT(*) FROM leadstintim_backup_20250106;
*/

-- =====================================================
-- LIMPEZA (EXECUTAR APÓS CONFIRMAR QUE TUDO ESTÁ OK)
-- =====================================================

/*
-- Manter backup por alguns dias antes de dropar
-- DROP TABLE leadstintim_backup_20250106;
*/

-- =====================================================
-- ✅ SCRIPT CONCLUÍDO
-- =====================================================
-- Próximos passos:
-- 1. Revisar os SELECTs de validação acima
-- 2. Se tudo OK: executar COMMIT;
-- 3. Se houver problema: executar ROLLBACK;
-- 4. Testar a aplicação Flutter
-- 5. Manter backup por 7 dias
-- 6. Depois de 7 dias: dropar tabela de backup
-- =====================================================

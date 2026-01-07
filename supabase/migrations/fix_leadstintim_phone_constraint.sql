-- ╔════════════════════════════════════════════════════════════════╗
-- ║  FIX: Constraint para telefone obrigatório em leadstintim      ║
-- ╚════════════════════════════════════════════════════════════════╝
-- 
-- Problema: Automação N8N está salvando registros duplicados sem telefone
-- (apenas body preenchido, outros campos NULL)
--
-- Solução SIMPLES:
-- 1. Deletar todos registros sem telefone (são duplicatas inúteis)
-- 2. Adicionar constraint NOT NULL no campo phone
-- 3. Isso forçará o N8N a sempre enviar o telefone

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 0️⃣  BACKUP (SEMPRE!)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CREATE TABLE IF NOT EXISTS leadstintim_backup_phone_fix AS
SELECT * FROM leadstintim;

-- Verificar backup
SELECT COUNT(*) AS total_backup FROM leadstintim_backup_phone_fix;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 1️⃣  ANÁLISE: Identificar registros problemáticos
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Contar registros sem telefone
SELECT 
    'Registros SEM telefone' AS tipo,
    COUNT(*) AS total
FROM leadstintim
WHERE phone IS NULL OR phone = '';

-- Contar registros com body mas sem dados principais
SELECT 
    'Registros apenas com body' AS tipo,
    COUNT(*) AS total
FROM leadstintim
WHERE (phone IS NULL OR phone = '')
  AND body IS NOT NULL
  AND body::text != '{}';

-- Ver exemplos de registros problemáticos
SELECT 
    id,
    phone,
    name,
    LEFT(body, 100) AS body_preview
FROM leadstintim
WHERE (phone IS NULL OR phone = '')
  AND body IS NOT NULL
ORDER BY id DESC
LIMIT 10;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 2️⃣  LIMPEZA DIRETA: Deletar todos registros sem telefone
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 
-- Não tentamos recuperar nada do body. São apenas duplicatas do N8N.
-- Deletamos diretamente.

BEGIN;

-- Ver quantos serão deletados
SELECT 
    'Registros SEM telefone (serão deletados)' AS aviso,
    COUNT(*) AS total
FROM leadstintim
WHERE phone IS NULL OR phone = '';

-- Deletar TODOS registros sem telefone (são duplicatas do N8N)
DELETE FROM leadstintim
WHERE phone IS NULL OR phone = '';

-- Verificar resultado
SELECT 
    'Status após limpeza' AS resultado,
    COUNT(*) AS total_registros,
    COUNT(CASE WHEN phone IS NULL OR phone = '' THEN 1 END) AS sem_telefone
FROM leadstintim;

COMMIT;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 4️⃣  CONSTRAINT: Adicionar NOT NULL no campo phone
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Verificar se ainda há algum phone NULL
SELECT COUNT(*) AS telefones_null
FROM leadstintim
WHERE phone IS NULL OR phone = '';

-- Se o resultado acima for 0, adicionar a constraint:
ALTER TABLE leadstintim
ALTER COLUMN phone SET NOT NULL;

-- Adicionar check constraint para garantir que phone não seja vazio
ALTER TABLE leadstintim
ADD CONSTRAINT leadstintim_phone_not_empty 
CHECK (phone IS NOT NULL AND phone != '');

-- Verificar constraints
SELECT 
    conname AS constraint_name,
    contype AS constraint_type,
    pg_get_constraintdef(oid) AS constraint_definition
FROM pg_constraint
WHERE conrelid = 'leadstintim'::regclass
  AND conname LIKE '%phone%';

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 5️⃣  NÃO É NECESSÁRIO TRIGGER
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 
-- O N8N deve ser corrigido para SEMPRE enviar o phone.
-- A constraint NOT NULL forçará isso.
-- Se o N8N tentar inserir sem phone, receberá erro e você saberá
-- que precisa corrigir o workflow N8N.

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 6️⃣  TESTE: Verificar constraint
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Teste: Tentar inserir sem phone (deve dar erro)
DO $$
BEGIN
    INSERT INTO leadstintim (body, datefirst, datelast)
    VALUES (
        '{"message": "teste"}',  -- VARCHAR, não JSONB
        NOW(),
        NOW()
    );
    RAISE EXCEPTION 'ERRO: Insert sem phone NÃO deveria ter funcionado!';
EXCEPTION
    WHEN not_null_violation THEN
        RAISE NOTICE 'OK: Constraint funcionando! Erro esperado ao tentar inserir sem phone.';
END $$;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 7️⃣  VERIFICAÇÃO FINAL
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Estatísticas finais
SELECT 
    'Estatísticas finais' AS info,
    COUNT(*) AS total_registros,
    COUNT(CASE WHEN phone IS NULL OR phone = '' THEN 1 END) AS sem_telefone,
    COUNT(CASE WHEN phone IS NOT NULL AND phone != '' THEN 1 END) AS com_telefone
FROM leadstintim;

-- Listar constraints ativas
SELECT 
    'Constraints ativas' AS info,
    conname AS constraint_name
FROM pg_constraint
WHERE conrelid = 'leadstintim'::regclass;

-- Listar triggers ativos
SELECT 
    'Triggers ativos' AS info,
    tgname AS trigger_name,
    pg_get_triggerdef(oid) AS trigger_definition
FROM pg_trigger
WHERE tgrelid = 'leadstintim'::regclass
  AND tgisinternal = false;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 8️⃣  ROLLBACK (Se algo der errado)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/*
-- Para restaurar o backup:
BEGIN;

TRUNCATE leadstintim;

INSERT INTO leadstintim
SELECT * FROM leadstintim_backup_phone_fix;

-- Remover constraints se necessário
ALTER TABLE leadstintim ALTER COLUMN phone DROP NOT NULL;
ALTER TABLE leadstintim DROP CONSTRAINT IF EXISTS leadstintim_phone_not_empty;

-- Remover trigger se necessário
DROP TRIGGER IF EXISTS trigger_extract_leadstintim_from_body ON leadstintim;
DROP FUNCTION IF EXISTS extract_leadstintim_from_body();

COMMIT;
*/

-- Limpar backup após confirmar que está tudo OK (executar depois de alguns dias)
-- DROP TABLE IF EXISTS leadstintim_backup_phone_fix;

-- ╔════════════════════════════════════════════════════════════════╗
-- ║  FIX: Constraint para telefone obrigatório em leadstintim      ║
-- ╚════════════════════════════════════════════════════════════════╝
-- 
-- Problema: Automação N8N está salvando registros duplicados sem telefone
-- Solução: Deletar registros sem phone + ADD CONSTRAINT NOT NULL

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 0️⃣  BACKUP (SEMPRE!)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CREATE TABLE IF NOT EXISTS leadstintim_backup_phone_fix AS
SELECT * FROM leadstintim;

SELECT COUNT(*) AS total_backup FROM leadstintim_backup_phone_fix;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 1️⃣  ANÁLISE: Ver quantos registros serão afetados
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

SELECT 
    'Registros SEM telefone' AS tipo,
    COUNT(*) AS total
FROM leadstintim
WHERE phone IS NULL OR phone = '';

-- Ver exemplos
SELECT 
    id,
    phone,
    name,
    message,
    SUBSTRING(body, 1, 50) AS body_preview
FROM leadstintim
WHERE phone IS NULL OR phone = ''
ORDER BY id DESC
LIMIT 5;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 2️⃣  LIMPEZA: Deletar registros sem telefone
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

BEGIN;

DELETE FROM leadstintim
WHERE phone IS NULL OR phone = '';

-- Verificar
SELECT 
    'Após limpeza' AS status,
    COUNT(*) AS total_registros,
    COUNT(CASE WHEN phone IS NULL OR phone = '' THEN 1 END) AS sem_telefone
FROM leadstintim;

COMMIT;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 3️⃣  CONSTRAINT: phone NOT NULL
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Verificar se não há mais phones NULL
SELECT COUNT(*) AS telefones_null
FROM leadstintim
WHERE phone IS NULL OR phone = '';

-- Adicionar constraint
ALTER TABLE leadstintim
ALTER COLUMN phone SET NOT NULL;

-- Adicionar check para evitar string vazia
ALTER TABLE leadstintim
ADD CONSTRAINT leadstintim_phone_not_empty 
CHECK (phone IS NOT NULL AND phone != '');

-- Verificar constraints criadas
SELECT 
    conname AS constraint_name,
    pg_get_constraintdef(oid) AS constraint_definition
FROM pg_constraint
WHERE conrelid = 'leadstintim'::regclass
  AND conname LIKE '%phone%';

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 4️⃣  TESTE: Tentar inserir sem phone (deve dar erro)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

DO $$
BEGIN
    INSERT INTO leadstintim (name, message, datefirst, datelast)
    VALUES ('Teste', 'Mensagem teste', NOW(), NOW());
    
    RAISE EXCEPTION 'ERRO: Insert sem phone deveria ter falhado!';
EXCEPTION
    WHEN not_null_violation THEN
        RAISE NOTICE 'OK: Constraint funcionando! Insert sem phone foi bloqueado.';
    WHEN check_violation THEN
        RAISE NOTICE 'OK: Constraint funcionando! Insert sem phone foi bloqueado.';
END $$;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 5️⃣  VERIFICAÇÃO FINAL
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

SELECT 
    'Status final' AS info,
    COUNT(*) AS total_registros,
    COUNT(CASE WHEN phone IS NOT NULL AND phone != '' THEN 1 END) AS com_telefone_valido
FROM leadstintim;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 6️⃣  ROLLBACK (se necessário)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/*
BEGIN;

-- Restaurar backup
TRUNCATE leadstintim;
INSERT INTO leadstintim SELECT * FROM leadstintim_backup_phone_fix;

-- Remover constraints
ALTER TABLE leadstintim ALTER COLUMN phone DROP NOT NULL;
ALTER TABLE leadstintim DROP CONSTRAINT IF EXISTS leadstintim_phone_not_empty;

COMMIT;
*/

-- Limpar backup (depois de confirmar que está OK)
-- DROP TABLE IF EXISTS leadstintim_backup_phone_fix;

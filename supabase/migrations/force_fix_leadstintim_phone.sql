-- ============================================
-- Fix FORÇADO: Tornar phone nullable (com mais segurança)
-- ============================================

-- 1. Verificar se a constraint existe e remover
DO $$ 
BEGIN
    -- Remover constraint NOT NULL se existir
    ALTER TABLE leadstintim ALTER COLUMN phone DROP NOT NULL;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Constraint NOT NULL já removida ou não existe';
END $$;

-- 2. Remover todas as CHECK constraints relacionadas a phone
DO $$ 
DECLARE
    constraint_rec RECORD;
BEGIN
    FOR constraint_rec IN 
        SELECT con.conname
        FROM pg_constraint con
        JOIN pg_class rel ON rel.oid = con.conrelid
        WHERE rel.relname = 'leadstintim' 
        AND con.contype = 'c'
        AND pg_get_constraintdef(con.oid) LIKE '%phone%'
    LOOP
        EXECUTE format('ALTER TABLE leadstintim DROP CONSTRAINT IF EXISTS %I', constraint_rec.conname);
        RAISE NOTICE 'Constraint % removida', constraint_rec.conname;
    END LOOP;
END $$;

-- 3. Adicionar nova CHECK constraint flexível
ALTER TABLE leadstintim 
ADD CONSTRAINT leadstintim_phone_check 
CHECK (phone IS NULL OR (phone <> ''::text AND length(phone) >= 8));

-- 4. Verificar resultado
SELECT 
    column_name,
    is_nullable,
    data_type
FROM information_schema.columns
WHERE table_name = 'leadstintim' AND column_name = 'phone';

-- 5. Mensagem de sucesso
DO $$ 
BEGIN
    RAISE NOTICE '✅ Coluna phone agora aceita NULL!';
END $$;

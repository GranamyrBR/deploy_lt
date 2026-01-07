-- =====================================================
-- EXECUTAR NO SQL EDITOR DO SUPABASE
-- =====================================================
-- Este script adiciona o valor 'agency' ao enum user_type_enum
-- Execute este código diretamente no SQL Editor do Supabase Dashboard

-- Verificar e adicionar o valor 'agency' ao enum
DO $$
BEGIN
    -- Verificar se o enum user_type_enum existe
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_type_enum') THEN
        -- Criar o enum se não existir
        CREATE TYPE user_type_enum AS ENUM ('normal', 'driver', 'employee', 'agency');
        RAISE NOTICE 'Enum user_type_enum criado com todos os valores';
    ELSE
        -- Verificar se o valor 'agency' já existe
        IF NOT EXISTS (
            SELECT 1 FROM pg_enum 
            WHERE enumlabel = 'agency' 
            AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'user_type_enum')
        ) THEN
            -- Adicionar o novo valor 'agency' ao enum existente
            ALTER TYPE user_type_enum ADD VALUE 'agency';
            RAISE NOTICE 'Valor agency adicionado ao enum user_type_enum';
        ELSE
            RAISE NOTICE 'Valor agency já existe no enum user_type_enum';
        END IF;
    END IF;
END $$;

-- Verificar os valores do enum após a execução
SELECT 
    'Valores do enum user_type_enum:' as info,
    enumlabel as valor
FROM pg_enum 
WHERE enumtypid = (SELECT oid FROM pg_type WHERE typname = 'user_type_enum')
ORDER BY enumsortorder;

-- Verificar a estrutura da coluna user_type na tabela contact
SELECT 
    'Estrutura da coluna user_type:' as info,
    column_name, 
    data_type, 
    is_nullable, 
    column_default
FROM information_schema.columns 
WHERE table_name = 'contact' 
  AND column_name = 'user_type'
ORDER BY column_name;

-- Testar inserção de um valor 'agency' (opcional)
-- UPDATE contact SET user_type = 'agency' WHERE id = 1;

SELECT '✅ Script executado com sucesso! O tipo agency foi adicionado ao enum.' as resultado;

-- =====================================================
-- INSTRUÇÕES:
-- 1. Copie todo este código
-- 2. Cole no SQL Editor do Supabase Dashboard
-- 3. Execute o script
-- 4. Verifique se aparece a mensagem de sucesso
-- =====================================================
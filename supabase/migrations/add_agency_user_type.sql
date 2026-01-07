-- =====================================================
-- ADICIONAR TIPO 'AGENCY' AO ENUM USER_TYPE
-- =====================================================
-- Este script adiciona o valor 'agency' ao enum user_type_enum existente

-- Verificar se o valor 'agency' já existe no enum
DO $$
BEGIN
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
END $$;

-- Verificar se o valor foi adicionado
SELECT enumlabel 
FROM pg_enum 
WHERE enumtypid = (SELECT oid FROM pg_type WHERE typname = 'user_type_enum')
ORDER BY enumsortorder;

-- Verificar a estrutura da coluna
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'contact' 
  AND column_name = 'user_type'
ORDER BY column_name;

SELECT 'Tipo agency adicionado com sucesso ao enum user_type_enum!' as resultado;

-- =====================================================
-- RESUMO:
-- 1. Adicionado valor 'agency' ao enum user_type_enum
-- 2. Estrutura verificada e validada
-- =====================================================
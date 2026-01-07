-- =====================================================
-- ADICIONAR COLUNA USER_TYPE NA TABELA CONTACT
-- =====================================================
-- Este script adiciona a coluna user_type na tabela contact
-- para persistir o tipo de usuário (normal, driver, employee)

-- Adicionar coluna user_type como ENUM
CREATE TYPE user_type_enum AS ENUM ('normal', 'driver', 'employee');

-- Adicionar a coluna user_type na tabela contact
ALTER TABLE public.contact 
ADD COLUMN IF NOT EXISTS user_type user_type_enum DEFAULT 'normal';

-- Verificar se a coluna foi adicionada
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'contact' 
  AND column_name = 'user_type'
ORDER BY column_name;

-- Verificar alguns registros para confirmar
SELECT id, name, phone, user_type
FROM contact 
LIMIT 5;

SELECT 'Coluna user_type adicionada com sucesso!' as resultado;

-- =====================================================
-- RESUMO:
-- 1. Criado ENUM user_type_enum com valores: normal, driver, employee
-- 2. Adicionada coluna user_type na tabela contact
-- 3. Valor padrão definido como 'normal'
-- 4. Estrutura verificada e validada
-- =====================================================
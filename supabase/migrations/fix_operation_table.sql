-- Script para verificar e corrigir a estrutura da tabela operation
-- Este script verifica se as colunas já existem antes de tentar adicioná-las

-- Verificar e adicionar product_id se não existir
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'operation' AND column_name = 'product_id') THEN
        ALTER TABLE public.operation ADD COLUMN product_id integer;
        RAISE NOTICE 'Coluna product_id adicionada à tabela operation';
    ELSE
        RAISE NOTICE 'Coluna product_id já existe na tabela operation';
    END IF;
END $$;

-- Verificar e adicionar product_value_usd se não existir
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'operation' AND column_name = 'product_value_usd') THEN
        ALTER TABLE public.operation ADD COLUMN product_value_usd numeric;
        RAISE NOTICE 'Coluna product_value_usd adicionada à tabela operation';
    ELSE
        RAISE NOTICE 'Coluna product_value_usd já existe na tabela operation';
    END IF;
END $$;

-- Verificar e adicionar quantity se não existir
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'operation' AND column_name = 'quantity') THEN
        ALTER TABLE public.operation ADD COLUMN quantity integer;
        RAISE NOTICE 'Coluna quantity adicionada à tabela operation';
    ELSE
        RAISE NOTICE 'Coluna quantity já existe na tabela operation';
    END IF;
END $$;

-- Verificar e adicionar foreign key constraint para product_id se não existir
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE constraint_name = 'operation_product_id_fkey') THEN
        ALTER TABLE public.operation 
        ADD CONSTRAINT operation_product_id_fkey 
        FOREIGN KEY (product_id) REFERENCES public.product(product_id);
        RAISE NOTICE 'Foreign key constraint operation_product_id_fkey adicionada';
    ELSE
        RAISE NOTICE 'Foreign key constraint operation_product_id_fkey já existe';
    END IF;
END $$;

-- Verificar e modificar service_id para permitir NULL
DO $$
BEGIN
    -- Primeiro, verificar se service_id já permite NULL
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'operation' AND column_name = 'service_id' AND is_nullable = 'NO') THEN
        -- Remover a constraint NOT NULL se existir
        ALTER TABLE public.operation ALTER COLUMN service_id DROP NOT NULL;
        RAISE NOTICE 'Constraint NOT NULL removida de service_id';
    ELSE
        RAISE NOTICE 'service_id já permite valores NULL';
    END IF;
END $$;

-- Verificar e modificar scheduled_date para permitir NULL
DO $$
BEGIN
    -- Verificar se scheduled_date já permite NULL
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'operation' AND column_name = 'scheduled_date' AND is_nullable = 'NO') THEN
        -- Remover a constraint NOT NULL se existir
        ALTER TABLE public.operation ALTER COLUMN scheduled_date DROP NOT NULL;
        RAISE NOTICE 'Constraint NOT NULL removida de scheduled_date';
    ELSE
        RAISE NOTICE 'scheduled_date já permite valores NULL';
    END IF;
END $$;

-- Verificar e adicionar constraint de verificação se não existir
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE constraint_name = 'operation_service_or_product_check') THEN
        ALTER TABLE public.operation 
        ADD CONSTRAINT operation_service_or_product_check 
        CHECK (
          (service_id IS NOT NULL AND product_id IS NULL) OR 
          (service_id IS NULL AND product_id IS NOT NULL)
        );
        RAISE NOTICE 'Constraint operation_service_or_product_check adicionada';
    ELSE
        RAISE NOTICE 'Constraint operation_service_or_product_check já existe';
    END IF;
END $$;

-- Verificar e adicionar índice se não existir
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes 
                   WHERE indexname = 'idx_operation_product_id') THEN
        CREATE INDEX idx_operation_product_id ON public.operation(product_id) WHERE product_id IS NOT NULL;
        RAISE NOTICE 'Índice idx_operation_product_id criado';
    ELSE
        RAISE NOTICE 'Índice idx_operation_product_id já existe';
    END IF;
END $$;

-- Adicionar comentários se não existirem
DO $$
BEGIN
    -- Verificar se os comentários já existem é mais complexo, então vamos apenas aplicá-los
    COMMENT ON COLUMN public.operation.product_id IS 'ID do produto para operações de produtos. Mutuamente exclusivo com service_id.';
    COMMENT ON COLUMN public.operation.product_value_usd IS 'Valor do produto em USD para operações de produtos.';
    COMMENT ON COLUMN public.operation.quantity IS 'Quantidade do produto para operações de produtos.';
    COMMENT ON CONSTRAINT operation_service_or_product_check ON public.operation IS 'Garante que uma operação tenha ou service_id ou product_id, mas não ambos.';
    RAISE NOTICE 'Comentários adicionados às colunas e constraints';
    RAISE NOTICE 'Script de correção da tabela operation executado com sucesso!';
END $$;
-- Script complementar para resolver problemas não abordados no fix_all_missing_foreign_keys.sql
-- Este script aborda: FKs adicionais, campos NOT NULL, nomenclatura e auditoria

-- ==============================================
-- 1. ADICIONAR FKs AUSENTES ADICIONAIS
-- ==============================================

-- 1.1 FK para sale.customer_id -> contact.id
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'sale_customer_id_fkey' 
        AND conrelid = 'public.sale'::regclass
    ) THEN
        ALTER TABLE public.sale 
        ADD CONSTRAINT sale_customer_id_fkey 
        FOREIGN KEY (customer_id) 
        REFERENCES public.contact(id);
        RAISE NOTICE 'Added constraint: sale_customer_id_fkey';
    ELSE
        RAISE NOTICE 'Constraint sale_customer_id_fkey already exists';
    END IF;
END $$;

-- 1.2 FK para invoice.sale_id -> sale.id
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'invoice_sale_id_fkey' 
        AND conrelid = 'public.invoice'::regclass
    ) THEN
        ALTER TABLE public.invoice 
        ADD CONSTRAINT invoice_sale_id_fkey 
        FOREIGN KEY (sale_id) 
        REFERENCES public.sale(id);
        RAISE NOTICE 'Added constraint: invoice_sale_id_fkey';
    ELSE
        RAISE NOTICE 'Constraint invoice_sale_id_fkey already exists';
    END IF;
END $$;

-- 1.3 FK para invoice.customer_id -> contact.id
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'invoice_customer_id_fkey' 
        AND conrelid = 'public.invoice'::regclass
    ) THEN
        ALTER TABLE public.invoice 
        ADD CONSTRAINT invoice_customer_id_fkey 
        FOREIGN KEY (customer_id) 
        REFERENCES public.contact(id);
        RAISE NOTICE 'Added constraint: invoice_customer_id_fkey';
    ELSE
        RAISE NOTICE 'Constraint invoice_customer_id_fkey already exists';
    END IF;
END $$;

-- ==============================================
-- 2. ALTERAR CAMPOS NULLABLE PARA NOT NULL
-- ==============================================

-- ANTES de alterar para NOT NULL, precisamos garantir que não há valores NULL
-- Vamos criar uma função auxiliar para verificar e corrigir dados

-- 2.1 Verificar e corrigir dados antes de tornar NOT NULL
DO $$
DECLARE
    null_count INTEGER;
BEGIN
    -- Verificar sale.customer_id
    SELECT COUNT(*) INTO null_count FROM public.sale WHERE customer_id IS NULL;
    IF null_count > 0 THEN
        RAISE WARNING 'Found % sale records with NULL customer_id. These need to be fixed before making NOT NULL.', null_count;
        -- Opcional: criar registro padrão ou excluir vendas inválidas
        -- DELETE FROM public.sale WHERE customer_id IS NULL;
        -- OU: UPDATE public.sale SET customer_id = (SELECT id FROM public.contact LIMIT 1) WHERE customer_id IS NULL;
    END IF;

    -- Verificar sale.user_id
    SELECT COUNT(*) INTO null_count FROM public.sale WHERE user_id IS NULL;
    IF null_count > 0 THEN
        RAISE WARNING 'Found % sale records with NULL user_id. These need to be fixed before making NOT NULL.', null_count;
    END IF;

    -- Verificar sale.currency_id
    SELECT COUNT(*) INTO null_count FROM public.sale WHERE currency_id IS NULL;
    IF null_count > 0 THEN
        RAISE WARNING 'Found % sale records with NULL currency_id. These need to be fixed before making NOT NULL.', null_count;
    END IF;

    -- Verificar sale_item.service_id
    SELECT COUNT(*) INTO null_count FROM public.sale_item WHERE service_id IS NULL;
    IF null_count > 0 THEN
        RAISE WARNING 'Found % sale_item records with NULL service_id. These need to be fixed before making NOT NULL.', null_count;
    END IF;
END $$;

-- 2.2 Tornar campos NOT NULL (após correção dos dados)
-- DESCOMENTE estas linhas após corrigir os dados NULL existentes

-- ALTER TABLE public.sale ALTER COLUMN customer_id SET NOT NULL;
-- ALTER TABLE public.sale ALTER COLUMN user_id SET NOT NULL;
-- ALTER TABLE public.sale ALTER COLUMN currency_id SET NOT NULL;
-- ALTER TABLE public.sale_item ALTER COLUMN service_id SET NOT NULL;

-- ==============================================
-- 3. PADRONIZAR NOMENCLATURA (sales_id vs sale_id)
-- ==============================================

-- Nota: Esta é uma mudança delicada que pode quebrar o código existente
-- Requer análise cuidadosa e atualização do código correspondente

-- 3.1 Criar view compatível para facilitar transição
CREATE OR REPLACE VIEW public.sale_item_standardized AS
SELECT 
    sales_item_id,
    sales_id AS sale_id,  -- Padronizar para sale_id
    service_id,
    unit_price_at_sale,
    quantity,
    discount_percentage,
    surcharge_percentage,
    tax_percentage,
    item_total,
    currency_id,
    product_id,
    created_at,
    updated_at
FROM public.sale_item;

-- 3.2 Criar view para sale_payment
CREATE OR REPLACE VIEW public.sale_payment_standardized AS
SELECT 
    payment_id,
    sales_id AS sale_id,  -- Padronizar para sale_id
    payment_method_id,
    amount,
    amount_in_usd AS amount_usd,
    currency_id,
    exchange_rate_to_usd AS exchange_rate_at_payment,
    processed_by_user_id,
    payment_date AS processed_at,
    notes,
    created_at,
    updated_at
FROM public.sale_payment;

-- ==============================================
-- 4. ADICIONAR CAMPOS DE AUDITORIA
-- ==============================================

-- 4.1 Verificar tabelas que não têm campos de auditoria
DO $$
DECLARE
    tbl_name TEXT;
    audit_tables TEXT[] := ARRAY['sale', 'sale_item', 'sale_payment', 'invoice', 'contact', 'service'];
BEGIN
    FOREACH tbl_name IN ARRAY audit_tables
    LOOP
        -- Verificar se created_at existe
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = tbl_name 
            AND column_name = 'created_at'
        ) THEN
            EXECUTE format('ALTER TABLE public.%I ADD COLUMN created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;', tbl_name);
            RAISE NOTICE 'Added created_at to table %', tbl_name;
        END IF;

        -- Verificar se updated_at existe
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = tbl_name 
            AND column_name = 'updated_at'
        ) THEN
            EXECUTE format('ALTER TABLE public.%I ADD COLUMN updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;', tbl_name);
            RAISE NOTICE 'Added updated_at to table %', tbl_name;
        END IF;

        -- Verificar se created_by existe
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = tbl_name 
            AND column_name = 'created_by'
        ) THEN
            EXECUTE format('ALTER TABLE public.%I ADD COLUMN created_by INTEGER;', tbl_name);
            RAISE NOTICE 'Added created_by to table %', tbl_name;
        END IF;

        -- Verificar se updated_by existe
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = tbl_name 
            AND column_name = 'updated_by'
        ) THEN
            EXECUTE format('ALTER TABLE public.%I ADD COLUMN updated_by INTEGER;', tbl_name);
            RAISE NOTICE 'Added updated_by to table %', tbl_name;
        END IF;
    END LOOP;
END $$;

-- ==============================================
-- 5. CRIAR TRIGGERS PARA AUDITORIA AUTOMÁTICA
-- ==============================================

-- Função genérica para atualizar updated_at
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Criar triggers para tabelas principais
DO $$
DECLARE
    table_name TEXT;
    audit_tables TEXT[] := ARRAY['sale', 'sale_item', 'sale_payment', 'invoice'];
BEGIN
    FOREACH table_name IN ARRAY audit_tables
    LOOP
        -- Criar trigger apenas se não existir
        IF NOT EXISTS (
            SELECT 1 FROM pg_trigger 
            WHERE tgname = format('update_%I_updated_at', table_name)
            AND tgrelid = format('public.%I', table_name)::regclass
        ) THEN
            EXECUTE format('
                CREATE TRIGGER update_%I_updated_at
                    BEFORE UPDATE ON public.%I
                    FOR EACH ROW
                    EXECUTE FUNCTION public.update_updated_at_column();
            ', table_name, table_name);
            RAISE NOTICE 'Created trigger for table %', table_name;
        END IF;
    END LOOP;
END $$;

-- ==============================================
-- 6. VALIDAÇÃO FINAL
-- ==============================================

-- Query para verificar todas as constraints existentes
SELECT 
    tc.table_name, 
    tc.constraint_name, 
    tc.constraint_type,
    kcu.column_name, 
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM 
    information_schema.table_constraints AS tc
    JOIN information_schema.key_column_usage AS kcu
      ON tc.constraint_name = kcu.constraint_name
      AND tc.table_schema = kcu.table_schema
    JOIN information_schema.constraint_column_usage AS ccu
      ON ccu.constraint_name = tc.constraint_name
      AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
AND tc.table_schema = 'public'
ORDER BY tc.table_name, tc.constraint_name;

-- Query para verificar campos NOT NULL
SELECT 
    table_name,
    column_name,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
AND (table_name, column_name) IN 
    (('sale', 'customer_id'), ('sale', 'user_id'), ('sale', 'currency_id'), ('sale_item', 'service_id'))
ORDER BY table_name, column_name;
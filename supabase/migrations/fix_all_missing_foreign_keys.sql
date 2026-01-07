-- Comprehensive Fix: Add all missing foreign key constraints
-- This script addresses the missing foreign key relationships identified in the database schema
-- Uses IF NOT EXISTS logic to avoid duplicate constraint errors

-- 1. Add foreign key constraint for currency_id in sale table (if not exists)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'sale_currency_id_fkey' 
        AND conrelid = 'public.sale'::regclass
    ) THEN
        ALTER TABLE public.sale 
        ADD CONSTRAINT sale_currency_id_fkey 
        FOREIGN KEY (currency_id) 
        REFERENCES public.currency(currency_id);
        RAISE NOTICE 'Added constraint: sale_currency_id_fkey';
    ELSE
        RAISE NOTICE 'Constraint sale_currency_id_fkey already exists';
    END IF;
END $$;

-- 2. Add foreign key constraint for sales_id in sale_item table (if not exists)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'sale_item_sales_id_fkey' 
        AND conrelid = 'public.sale_item'::regclass
    ) THEN
        ALTER TABLE public.sale_item 
        ADD CONSTRAINT sale_item_sales_id_fkey 
        FOREIGN KEY (sales_id) 
        REFERENCES public.sale(id);
        RAISE NOTICE 'Added constraint: sale_item_sales_id_fkey';
    ELSE
        RAISE NOTICE 'Constraint sale_item_sales_id_fkey already exists';
    END IF;
END $$;

-- 3. Add foreign key constraint for sales_id in sale_payment table (if not exists)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'sale_payment_sales_id_fkey' 
        AND conrelid = 'public.sale_payment'::regclass
    ) THEN
        ALTER TABLE public.sale_payment 
        ADD CONSTRAINT sale_payment_sales_id_fkey 
        FOREIGN KEY (sales_id) 
        REFERENCES public.sale(id);
        RAISE NOTICE 'Added constraint: sale_payment_sales_id_fkey';
    ELSE
        RAISE NOTICE 'Constraint sale_payment_sales_id_fkey already exists';
    END IF;
END $$;

-- 4. Add foreign key constraint for service_id in sale_item table (if not exists)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'sale_item_service_id_fkey' 
        AND conrelid = 'public.sale_item'::regclass
    ) THEN
        ALTER TABLE public.sale_item 
        ADD CONSTRAINT sale_item_service_id_fkey 
        FOREIGN KEY (service_id) 
        REFERENCES public.service(id);
        RAISE NOTICE 'Added constraint: sale_item_service_id_fkey';
    ELSE
        RAISE NOTICE 'Constraint sale_item_service_id_fkey already exists';
    END IF;
END $$;

-- Verification queries to check if constraints were added successfully:
-- SELECT conname, conrelid::regclass, confrelid::regclass 
-- FROM pg_constraint 
-- WHERE conname IN (
--     'sale_currency_id_fkey', 
--     'sale_item_sales_id_fkey', 
--     'sale_payment_sales_id_fkey',
--     'sale_item_service_id_fkey'
-- );

-- Note: Before running this script, ensure that:
-- 1. All existing data in these tables has valid references
-- 2. No orphaned records exist that would violate the foreign key constraints
-- 3. Consider running data validation queries first to identify any problematic records
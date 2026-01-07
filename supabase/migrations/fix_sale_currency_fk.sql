-- Fix: Add missing foreign key constraint for currency_id in sale table
-- This script adds the missing foreign key relationship between sale.currency_id and currency.currency_id

-- Add foreign key constraint for currency_id in sale table
ALTER TABLE public.sale 
ADD CONSTRAINT sale_currency_id_fkey 
FOREIGN KEY (currency_id) 
REFERENCES public.currency(currency_id);

-- Verify the constraint was added successfully
-- You can run this query to check:
-- SELECT conname, conrelid::regclass, confrelid::regclass 
-- FROM pg_constraint 
-- WHERE conname = 'sale_currency_id_fkey';
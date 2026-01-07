-- Fix: Add missing foreign key constraints for sales_id in sale_item and sale_payment tables
-- This script adds the missing foreign key relationships between sale_item.sales_id -> sale.id and sale_payment.sales_id -> sale.id

-- Add foreign key constraint for sales_id in sale_item table
ALTER TABLE public.sale_item 
ADD CONSTRAINT sale_item_sales_id_fkey 
FOREIGN KEY (sales_id) 
REFERENCES public.sale(id);

-- Add foreign key constraint for sales_id in sale_payment table
ALTER TABLE public.sale_payment 
ADD CONSTRAINT sale_payment_sales_id_fkey 
FOREIGN KEY (sales_id) 
REFERENCES public.sale(id);

-- Verify the constraints were added successfully
-- You can run these queries to check:
-- SELECT conname, conrelid::regclass, confrelid::regclass 
-- FROM pg_constraint 
-- WHERE conname IN ('sale_item_sales_id_fkey', 'sale_payment_sales_id_fkey');
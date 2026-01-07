-- Script para corrigir o problema de constraints NOT NULL na tabela operation
-- Este script resolve o erro: null value in column "sale_id" violates not-null constraint

-- OPÇÃO 1: Modificar as constraints para permitir NULL (Recomendado para produtos/eventos)
-- Esta abordagem é mais adequada para produtos de ingressos e eventos
-- onde as operações podem existir independentemente de vendas específicas

ALTER TABLE public.operation 
ALTER COLUMN sale_id DROP NOT NULL;

ALTER TABLE public.operation 
ALTER COLUMN sale_item_id DROP NOT NULL;

ALTER TABLE public.operation 
ALTER COLUMN customer_id DROP NOT NULL;

-- Adicionar comentários explicativos
COMMENT ON COLUMN public.operation.sale_id IS 'ID da venda (opcional para operações de eventos/ingressos)';
COMMENT ON COLUMN public.operation.sale_item_id IS 'ID do item de venda (opcional para operações de eventos/ingressos)';
COMMENT ON COLUMN public.operation.customer_id IS 'ID do cliente (opcional para operações programadas)';

-- OPÇÃO 2: Criar valores padrão para as constraints (Alternativa)
-- Descomente as linhas abaixo se preferir manter as constraints NOT NULL
-- e usar valores padrão

/*
-- Criar um cliente padrão para operações sem cliente específico
INSERT INTO public.contact (
    name,
    email,
    phone,
    contact_type
) VALUES 
(
    'Cliente Padrão - Sistema',
    'sistema@lecotour.com',
    '+1-000-0000',
    'system'
)
ON CONFLICT (email) DO NOTHING;

-- Criar uma venda padrão para operações sem venda específica
INSERT INTO public.sale (
    customer_id,
    total_amount_usd,
    status,
    sale_date
) VALUES 
(
    (SELECT id FROM public.contact WHERE email = 'sistema@lecotour.com' LIMIT 1),
    0.00,
    'system',
    now()
)
ON CONFLICT DO NOTHING;

-- Criar um item de venda padrão
INSERT INTO public.sale_item (
    sale_id,
    product_id,
    quantity,
    unit_price_usd,
    total_price_usd
) VALUES 
(
    (SELECT id FROM public.sale WHERE total_amount_usd = 0.00 AND status = 'system' LIMIT 1),
    1, -- Assumindo que existe pelo menos um produto
    0,
    0.00,
    0.00
)
ON CONFLICT DO NOTHING;
*/

-- Verificar se as alterações foram aplicadas
SELECT 
    column_name,
    is_nullable,
    data_type
FROM information_schema.columns 
WHERE table_name = 'operation' 
    AND table_schema = 'public'
    AND column_name IN ('sale_id', 'sale_item_id', 'customer_id')
ORDER BY column_name;

-- Script concluído
-- Agora o script example_operations_with_dates.sql pode ser executado sem erros
-- ou você pode inserir operações simples como:
/*
INSERT INTO public.operation (
    product_id,
    scheduled_date,
    status,
    priority,
    special_instructions,
    service_value_usd
) VALUES 
(
    (SELECT product_id FROM public.product WHERE name LIKE '%Hamilton%' LIMIT 1),
    '2024-12-25 19:30:00-05:00',
    'pending',
    'high',
    'Musical Hamilton - Sessão de Natal',
    0.00
);
*/
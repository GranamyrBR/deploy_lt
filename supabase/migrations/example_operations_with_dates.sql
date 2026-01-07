-- Script de exemplo para inserir operações com datas específicas
-- Este script demonstra como usar o campo scheduled_date da tabela operation
-- para armazenar as datas dos produtos/eventos

-- IMPORTANTE: Este script requer que existam registros nas tabelas:
-- - sale (vendas)
-- - sale_item (itens de venda)
-- - contact (clientes)
-- - product (produtos)

-- Primeiro, vamos criar dados de exemplo necessários para as operações

-- Inserir um cliente de exemplo (se não existir)
INSERT INTO public.contact (
    name,
    email,
    phone,
    contact_type
) VALUES 
(
    'Cliente Exemplo - Ingressos',
    'cliente.ingressos@example.com',
    '+1-555-0123',
    'customer'
)
ON CONFLICT (email) DO NOTHING;

-- Inserir uma venda de exemplo
INSERT INTO public.sale (
    customer_id,
    total_amount_usd,
    status,
    sale_date
) VALUES 
(
    (SELECT id FROM public.contact WHERE email = 'cliente.ingressos@example.com' LIMIT 1),
    250.00,
    'confirmed',
    now()
);

-- Obter o ID da venda recém-criada
-- Inserir itens de venda de exemplo
INSERT INTO public.sale_item (
    sale_id,
    product_id,
    quantity,
    unit_price_usd,
    total_price_usd
) VALUES 
(
    (SELECT id FROM public.sale ORDER BY created_at DESC LIMIT 1),
    (SELECT product_id FROM public.product WHERE name LIKE '%Hamilton%' LIMIT 1),
    2,
    125.00,
    250.00
);

-- Agora inserir as operações com todas as informações obrigatórias
-- Exemplo 1: Hamilton - Musical Broadway
INSERT INTO public.operation (
    product_id,
    sale_id,
    sale_item_id,
    customer_id,
    scheduled_date,
    status,
    priority,
    special_instructions,
    service_value_usd,
    quantity
) VALUES 
(
    (SELECT product_id FROM public.product WHERE name LIKE '%Hamilton%' LIMIT 1),
    (SELECT id FROM public.sale ORDER BY created_at DESC LIMIT 1),
    (SELECT sales_item_id FROM public.sale_item ORDER BY created_at DESC LIMIT 1),
    (SELECT id FROM public.contact WHERE email = 'cliente.ingressos@example.com' LIMIT 1),
    '2024-12-25 19:30:00-05:00', -- Data e horário do show (timezone EST)
    'pending',
    'high',
    'Musical Hamilton - Sessão de Natal',
    250.00,
    2
);

-- Exemplo 2: Adicionar mais operações para outros produtos (opcional)
-- Para adicionar mais operações, repita o padrão acima:
-- 1. Crie novos itens de venda para outros produtos
-- 2. Insira as operações com todas as informações obrigatórias

-- Exemplo de como adicionar uma segunda operação para The Lion King:
/*
INSERT INTO public.sale_item (
    sale_id,
    product_id,
    quantity,
    unit_price_usd,
    total_price_usd
) VALUES 
(
    (SELECT id FROM public.sale ORDER BY created_at DESC LIMIT 1),
    (SELECT product_id FROM public.product WHERE name LIKE '%Rei Leão%' OR name LIKE '%Lion King%' LIMIT 1),
    2,
    133.00,
    266.00
);

INSERT INTO public.operation (
    product_id,
    sale_id,
    sale_item_id,
    customer_id,
    scheduled_date,
    status,
    priority,
    special_instructions,
    service_value_usd,
    quantity
) VALUES 
(
    (SELECT product_id FROM public.product WHERE name LIKE '%Rei Leão%' OR name LIKE '%Lion King%' LIMIT 1),
    (SELECT id FROM public.sale ORDER BY created_at DESC LIMIT 1),
    (SELECT sales_item_id FROM public.sale_item ORDER BY created_at DESC LIMIT 1),
    (SELECT id FROM public.contact WHERE email = 'cliente.ingressos@example.com' LIMIT 1),
    '2024-12-26 20:00:00-05:00',
    'pending',
    'high',
    'Musical The Lion King - Sessão noturna',
    266.00,
    2
);
*/

-- Query de exemplo para visualizar produtos com suas datas de operação
SELECT 
    p.name as produto,
    p.venue_name as local,
    o.scheduled_date as data_evento,
    o.status as status_operacao,
    o.special_instructions as detalhes,
    p.booking_url as url_reserva
FROM public.product p
INNER JOIN public.operation o ON p.product_id = o.product_id
WHERE p.active_for_sale = true
ORDER BY o.scheduled_date;

-- Query para buscar operações por data específica
SELECT 
    p.name as produto,
    p.venue_name as local,
    o.scheduled_date as data_evento,
    EXTRACT(HOUR FROM o.scheduled_date) as hora,
    EXTRACT(MINUTE FROM o.scheduled_date) as minuto
FROM public.product p
INNER JOIN public.operation o ON p.product_id = o.product_id
WHERE DATE(o.scheduled_date) = '2024-12-25'
ORDER BY o.scheduled_date;

-- Query para buscar operações em um período
SELECT 
    p.name as produto,
    p.venue_name as local,
    o.scheduled_date as data_evento,
    p.price_per_unit as preco
FROM public.product p
INNER JOIN public.operation o ON p.product_id = o.product_id
WHERE o.scheduled_date BETWEEN '2024-12-01' AND '2024-12-31'
ORDER BY o.scheduled_date;
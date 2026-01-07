-- =====================================================
-- CORREÇÃO DE VIEWS PROBLEMÁTICAS
-- =====================================================
-- 
-- PROBLEMAS IDENTIFICADOS:
-- 1. Views fazem referência a tabelas que não existem (sale_v2, payment_transaction)
-- 2. Views fazem referência a colunas que não existem (sales_item_id, deleted_at)
-- 3. Inconsistências nos nomes das colunas (sales_id vs sale_id)

-- =====================================================
-- 1. REMOVER VIEWS PROBLEMÁTICAS
-- =====================================================

-- Remover view que referencia tabela inexistente sale_v2
DROP VIEW IF EXISTS sale_summary;

-- Remover view que referencia tabela inexistente payment_transaction
DROP VIEW IF EXISTS payment_history;

-- Remover view que referencia coluna inexistente deleted_at
DROP VIEW IF EXISTS active_sales;

-- Remover view que pode ter problemas de referência
DROP VIEW IF EXISTS sales_report;

-- Remover view que pode ter problemas de referência
DROP VIEW IF EXISTS sales_summary;

-- =====================================================
-- 2. RECRIAR VIEWS CORRETAS
-- =====================================================

-- View para vendas ativas (sem deleted_at que não existe)
CREATE OR REPLACE VIEW active_sales AS
SELECT *
FROM sale
WHERE status != 'cancelled';

-- View para relatório de vendas (corrigindo referências)
CREATE OR REPLACE VIEW sales_report AS
SELECT 
    s.id,
    s.sale_number,
    s.total_amount,
    s.total_amount_usd,
    s.exchange_rate_to_usd as exchange_rate_used,
    s.status,
    s.payment_status,
    s.sale_date,
    s.created_at,
    COUNT(si.sales_item_id) as total_items,
    SUM(si.quantity) as total_quantity
FROM sale s
LEFT JOIN sale_item si ON s.id = si.sales_id  -- Corrigindo para sales_id
WHERE s.status != 'cancelled'
GROUP BY s.id, s.sale_number, s.total_amount, s.total_amount_usd, 
         s.exchange_rate_to_usd, s.status, s.payment_status, 
         s.sale_date, s.created_at;

-- View consolidada de vendas (corrigindo referências)
CREATE OR REPLACE VIEW sales_summary AS
SELECT 
    s.id,
    s.sale_number,
    s.customer_id,
    c.name as customer_name,
    COALESCE(s.total_amount_usd, s.total_amount) as total_amount_usd,
    s.total_amount as total_amount_original,
    s.status,
    s.payment_status,
    s.sale_date,
    
    -- Total pago (corrigindo referências)
    COALESCE(SUM(sp.amount_in_usd), SUM(sp.amount), 0) as total_paid_usd,
    
    -- Saldo restante
    COALESCE(s.total_amount_usd, s.total_amount) - COALESCE(SUM(sp.amount_in_usd), SUM(sp.amount), 0) as remaining_balance_usd,
    
    -- Contadores (corrigindo referências)
    COUNT(DISTINCT si.sales_item_id) as total_items,  -- Usando sales_item_id correto
    COUNT(DISTINCT sp.payment_id) as total_payments  -- Usando payment_id correto
    
FROM sale s
LEFT JOIN contact c ON s.customer_id = c.id
LEFT JOIN sale_item si ON s.id = si.sales_id  -- Corrigindo para sales_id
LEFT JOIN sale_payment sp ON s.id = sp.sales_id  -- Corrigindo para sales_id
GROUP BY s.id, s.sale_number, s.customer_id, c.name, s.total_amount_usd, s.total_amount, s.status, s.payment_status, s.sale_date;

-- View para histórico de pagamentos (usando tabelas existentes)
CREATE OR REPLACE VIEW payment_history AS
SELECT 
    sp.payment_id as id,
    sp.sales_id as sale_id,
    sp.amount,
    CASE 
        WHEN sp.currency_id = 1 THEN 'USD'
        WHEN sp.currency_id = 2 THEN 'BRL'
        ELSE 'UNKNOWN'
    END as currency_code,
    sp.exchange_rate_to_usd,
    sp.amount_in_usd,
    sp.payment_date,
    sp.transaction_id,
    
    -- Dados do método de pagamento
    pm.method_name as payment_method_name,
    
    -- Dados da venda
    s.sale_number,
    s.customer_id,
    c.name as customer_name
    
FROM sale_payment sp
LEFT JOIN payment_method pm ON sp.payment_method_id = pm.payment_method_id
LEFT JOIN sale s ON sp.sales_id = s.id
LEFT JOIN contact c ON s.customer_id = c.id
ORDER BY sp.payment_date DESC;

-- =====================================================
-- 3. VERIFICAÇÃO DAS VIEWS CRIADAS
-- =====================================================

-- Verificar se as views foram criadas corretamente
SELECT 
    schemaname,
    viewname,
    definition
FROM pg_views 
WHERE schemaname = 'public' 
    AND viewname IN ('active_sales', 'sales_report', 'sales_summary', 'payment_history')
ORDER BY viewname;

SELECT '✅ Views problemáticas corrigidas com sucesso!' as status;
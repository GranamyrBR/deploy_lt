-- Script para corrigir exchange_rate_to_usd incorretos no banco de dados
-- O problema: exchange_rate_to_usd estava sendo salvo como a taxa USD->BRL
-- quando deveria ser BRL->USD (1/taxa)

-- Identificar registros com exchange_rate_to_usd incorreto (maior que 1.0 para pagamentos em BRL)
SELECT 
    payment_id,
    sales_id,
    amount,
    currency_id,
    exchange_rate_to_usd,
    amount_in_brl,
    amount_in_usd,
    CASE 
        WHEN currency_id = 2 AND exchange_rate_to_usd > 1.0 THEN 1.0 / exchange_rate_to_usd
        ELSE exchange_rate_to_usd
    END as corrected_exchange_rate_to_usd,
    CASE 
        WHEN currency_id = 2 AND exchange_rate_to_usd > 1.0 THEN amount / exchange_rate_to_usd
        ELSE amount_in_usd
    END as corrected_amount_in_usd
FROM sale_payment 
WHERE currency_id = 2 AND exchange_rate_to_usd > 1.0;

-- Corrigir os registros identificados
UPDATE sale_payment 
SET 
    exchange_rate_to_usd = 1.0 / exchange_rate_to_usd,
    amount_in_usd = amount / exchange_rate_to_usd
WHERE currency_id = 2 AND exchange_rate_to_usd > 1.0;

-- Verificar se as correções foram aplicadas
SELECT 
    payment_id,
    sales_id,
    amount,
    currency_id,
    exchange_rate_to_usd,
    amount_in_brl,
    amount_in_usd,
    created_at
FROM sale_payment 
WHERE sales_id IN (33, 34, 35, 36)
ORDER BY sales_id, payment_id;
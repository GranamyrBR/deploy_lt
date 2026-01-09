-- ============================================
-- Adicionar + na frente do whatsapp_normalizado
-- Formato correto para WhatsApp: +5511984239118
-- ============================================

-- Atualizar whatsapp_normalizado adicionando + na frente
UPDATE leadstintim
SET
    whatsapp_normalizado = '+' || REGEXP_REPLACE(phone, '[^0-9]', '', 'g')
WHERE 
    id BETWEEN 83243 AND 83381
    AND phone IS NOT NULL
    AND phone != '';

-- Verificar resultado
SELECT 
    COUNT(*) as total_registros,
    COUNT(CASE WHEN whatsapp_normalizado LIKE '+%' THEN 1 END) as com_plus,
    COUNT(CASE WHEN LENGTH(whatsapp_normalizado) >= 13 THEN 1 END) as tamanho_valido,
    AVG(LENGTH(whatsapp_normalizado)) as tamanho_medio
FROM leadstintim
WHERE id BETWEEN 83243 AND 83381;

-- Exemplos dos registros corrigidos
SELECT 
    id,
    name,
    phone,
    whatsapp_normalizado,
    LENGTH(whatsapp_normalizado) as tamanho
FROM leadstintim
WHERE id BETWEEN 83243 AND 83381
AND phone IS NOT NULL
ORDER BY id DESC
LIMIT 20;

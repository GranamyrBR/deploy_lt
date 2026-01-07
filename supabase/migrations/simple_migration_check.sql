-- =====================================================
-- VERIFICAÇÃO SUPER SIMPLES DE MIGRAÇÃO
-- =====================================================
-- Script minimalista para verificações básicas sem risco de timeout

-- 1. Contagens básicas
SELECT COUNT(*) as total_leadstintim FROM leadstintim;
SELECT COUNT(*) as total_contact FROM contact;
SELECT COUNT(*) as contact_whatsapp FROM contact WHERE source_id = 13;

-- 2. Últimos registros de leadstintim
SELECT 
  id, phone, name, datelast
FROM leadstintim 
ORDER BY id DESC 
LIMIT 10;

-- 3. Últimos registros de contact
SELECT 
  id, phone, name, created_at
FROM contact 
ORDER BY id DESC 
LIMIT 10;

-- 4. Verificar se telefones específicos existem em ambas as tabelas
WITH sample_phones AS (
  SELECT phone FROM leadstintim 
  WHERE phone IS NOT NULL 
  ORDER BY id DESC 
  LIMIT 5
)
SELECT 
  sp.phone,
  CASE WHEN l.phone IS NOT NULL THEN 'SIM' ELSE 'NÃO' END as existe_leadstintim,
  CASE WHEN c.phone IS NOT NULL THEN 'SIM' ELSE 'NÃO' END as existe_contact
FROM sample_phones sp
LEFT JOIN leadstintim l ON l.phone = sp.phone
LEFT JOIN contact c ON c.phone = sp.phone;

-- 5. Contagem de registros por data (últimos 30 dias)
SELECT 
  DATE(datelast) as data,
  COUNT(*) as registros_leadstintim
FROM leadstintim 
WHERE datelast >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY DATE(datelast)
ORDER BY data DESC
LIMIT 10;

SELECT '✅ VERIFICAÇÃO SIMPLES CONCLUÍDA!' as status;
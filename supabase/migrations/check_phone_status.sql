-- =====================================================
-- SCRIPT PARA VERIFICAR STATUS DOS TELEFONES NO DB
-- =====================================================
-- Este script verifica se as máscaras foram aplicadas
-- e identifica telefones sem formatação

-- Verificar telefones por país
SELECT 
  country,
  COUNT(*) as total_contatos,
  COUNT(CASE WHEN phone IS NOT NULL AND phone != '' THEN 1 END) as com_telefone
FROM contact 
GROUP BY country
ORDER BY total_contatos DESC;

-- Verificar telefones brasileiros
SELECT 
  'Telefones brasileiros:' as info,
  COUNT(*) as total,
  COUNT(CASE WHEN phone LIKE '+55 (%) %-%' THEN 1 END) as com_mascara_completa,
  COUNT(CASE WHEN phone LIKE '(%) %-%' THEN 1 END) as com_mascara_sem_codigo,
  COUNT(CASE WHEN phone NOT LIKE '+55 (%) %-%' AND phone NOT LIKE '(%) %-%' AND phone IS NOT NULL AND phone != '' THEN 1 END) as sem_mascara
FROM contact 
WHERE country = 'Brasil' AND phone IS NOT NULL AND phone != '';

-- Verificar telefones americanos
SELECT 
  'Telefones americanos:' as info,
  COUNT(*) as total,
  COUNT(CASE WHEN phone LIKE '+1 (%) %-%' THEN 1 END) as com_mascara_completa,
  COUNT(CASE WHEN phone LIKE '(%) %-%' THEN 1 END) as com_mascara_sem_codigo,
  COUNT(CASE WHEN phone NOT LIKE '+1 (%) %-%' AND phone NOT LIKE '(%) %-%' AND phone IS NOT NULL AND phone != '' THEN 1 END) as sem_mascara
FROM contact 
WHERE country = 'Estados Unidos' AND phone IS NOT NULL AND phone != '';

-- Verificar telefones europeus
SELECT 
  'Telefones europeus:' as info,
  country,
  COUNT(*) as total,
  COUNT(CASE WHEN 
    phone LIKE '+351 % % %' OR 
    phone LIKE '+34 % % %' OR 
    phone LIKE '+33 % % % % %' OR 
    phone LIKE '+49 % %' OR 
    phone LIKE '+44 % % %' OR 
    phone LIKE '+39 % % %'
  THEN 1 END) as com_mascara,
  COUNT(CASE WHEN 
    phone NOT LIKE '+351 % % %' AND 
    phone NOT LIKE '+34 % % %' AND 
    phone NOT LIKE '+33 % % % % %' AND 
    phone NOT LIKE '+49 % %' AND 
    phone NOT LIKE '+44 % % %' AND 
    phone NOT LIKE '+39 % % %' AND 
    phone IS NOT NULL AND phone != ''
  THEN 1 END) as sem_mascara
FROM contact 
WHERE country IN ('Portugal', 'Espanha', 'França', 'Alemanha', 'Reino Unido', 'Itália')
  AND phone IS NOT NULL AND phone != ''
GROUP BY country
ORDER BY total DESC;

-- Mostrar exemplos de telefones sem máscara
SELECT 
  'Exemplos de telefones sem máscara:' as info;

SELECT 
  country,
  phone,
  COUNT(*) as quantidade
FROM contact 
WHERE phone IS NOT NULL 
  AND phone != ''
  AND phone NOT LIKE '+% %'
  AND phone NOT LIKE '(%) %-%'
GROUP BY country, phone
ORDER BY quantidade DESC, country
LIMIT 20;

-- Verificar se existem telefones com códigos internacionais não formatados
SELECT 
  'Telefones com códigos internacionais não formatados:' as info;

SELECT 
  country,
  phone,
  LENGTH(phone) as tamanho
FROM contact 
WHERE phone IS NOT NULL 
  AND phone != ''
  AND (phone LIKE '351%' OR phone LIKE '34%' OR phone LIKE '33%' OR phone LIKE '49%' OR phone LIKE '44%' OR phone LIKE '39%')
  AND phone NOT LIKE '+%'
LIMIT 10;
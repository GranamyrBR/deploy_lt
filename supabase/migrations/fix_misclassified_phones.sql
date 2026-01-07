-- =====================================================
-- SCRIPT PARA CORRIGIR TELEFONES MAL CLASSIFICADOS
-- =====================================================
-- Este script corrige telefones que foram classificados
-- com país errado baseado no código internacional
-- e aplica as máscaras corretas

-- Função para detectar país pelo código do telefone
CREATE OR REPLACE FUNCTION detect_country_from_phone(phone_number TEXT)
RETURNS TEXT AS $$
DECLARE
  clean_phone TEXT;
BEGIN
  IF phone_number IS NULL OR phone_number = '' THEN
    RETURN NULL;
  END IF;
  
  -- Remove tudo exceto números
  clean_phone := REGEXP_REPLACE(phone_number, '[^0-9]', '', 'g');
  
  -- Detecta país pelo código internacional
  IF clean_phone LIKE '351%' THEN
    RETURN 'Portugal';
  ELSIF clean_phone LIKE '34%' AND LENGTH(clean_phone) >= 11 THEN
    RETURN 'Espanha';
  ELSIF clean_phone LIKE '33%' AND LENGTH(clean_phone) >= 11 THEN
    RETURN 'França';
  ELSIF clean_phone LIKE '49%' AND LENGTH(clean_phone) >= 11 THEN
    RETURN 'Alemanha';
  ELSIF clean_phone LIKE '44%' AND LENGTH(clean_phone) >= 11 THEN
    RETURN 'Reino Unido';
  ELSIF clean_phone LIKE '39%' AND LENGTH(clean_phone) >= 11 THEN
    RETURN 'Itália';
  ELSIF clean_phone LIKE '55%' AND LENGTH(clean_phone) >= 12 THEN
    RETURN 'Brasil';
  ELSIF clean_phone LIKE '1%' AND LENGTH(clean_phone) = 11 THEN
    RETURN 'Estados Unidos';
  ELSE
    RETURN NULL;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Função para formatar telefone português
CREATE OR REPLACE FUNCTION format_portuguese_phone(phone_number TEXT)
RETURNS TEXT AS $$
DECLARE
  clean_phone TEXT;
BEGIN
  IF phone_number IS NULL OR phone_number = '' THEN
    RETURN phone_number;
  END IF;
  
  clean_phone := REGEXP_REPLACE(phone_number, '[^0-9]', '', 'g');
  
  -- Remove código do país se presente
  IF clean_phone LIKE '351%' AND LENGTH(clean_phone) = 12 THEN
    clean_phone := SUBSTRING(clean_phone FROM 4);
  END IF;
  
  -- Aplica máscara portuguesa: +351 XXX XXX XXX
  IF LENGTH(clean_phone) = 9 THEN
    RETURN '+351 ' || SUBSTRING(clean_phone FROM 1 FOR 3) || ' ' || 
           SUBSTRING(clean_phone FROM 4 FOR 3) || ' ' || 
           SUBSTRING(clean_phone FROM 7 FOR 3);
  ELSE
    RETURN phone_number;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Função para formatar telefone do Reino Unido
CREATE OR REPLACE FUNCTION format_uk_phone(phone_number TEXT)
RETURNS TEXT AS $$
DECLARE
  clean_phone TEXT;
BEGIN
  IF phone_number IS NULL OR phone_number = '' THEN
    RETURN phone_number;
  END IF;
  
  clean_phone := REGEXP_REPLACE(phone_number, '[^0-9]', '', 'g');
  
  -- Remove código do país se presente
  IF clean_phone LIKE '44%' AND LENGTH(clean_phone) = 12 THEN
    clean_phone := SUBSTRING(clean_phone FROM 3);
  END IF;
  
  -- Aplica máscara do Reino Unido: +44 XXXX XXX XXX
  IF LENGTH(clean_phone) = 10 THEN
    RETURN '+44 ' || SUBSTRING(clean_phone FROM 1 FOR 4) || ' ' || 
           SUBSTRING(clean_phone FROM 5 FOR 3) || ' ' || 
           SUBSTRING(clean_phone FROM 8 FOR 3);
  ELSE
    RETURN phone_number;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Verificar telefones mal classificados antes da correção
SELECT 
  'Telefones mal classificados encontrados:' as info;

SELECT 
  country as pais_atual,
  detect_country_from_phone(phone) as pais_correto,
  phone,
  COUNT(*) as quantidade
FROM contact 
WHERE phone IS NOT NULL 
  AND phone != ''
  AND country != detect_country_from_phone(phone)
  AND detect_country_from_phone(phone) IS NOT NULL
GROUP BY country, detect_country_from_phone(phone), phone
ORDER BY quantidade DESC;

-- Corrigir país dos telefones portugueses mal classificados
UPDATE contact 
SET country = 'Portugal',
    phone = format_portuguese_phone(phone),
    updated_at = NOW()
WHERE phone LIKE '351%'
  AND country != 'Portugal'
  AND phone IS NOT NULL 
  AND phone != '';

-- Corrigir país dos telefones do Reino Unido mal classificados
UPDATE contact 
SET country = 'Reino Unido',
    phone = format_uk_phone(phone),
    updated_at = NOW()
WHERE phone LIKE '44%'
  AND country != 'Reino Unido'
  AND phone IS NOT NULL 
  AND phone != '';

-- Corrigir país dos telefones espanhóis mal classificados
UPDATE contact 
SET country = 'Espanha',
    updated_at = NOW()
WHERE phone LIKE '34%'
  AND country != 'Espanha'
  AND phone IS NOT NULL 
  AND phone != ''
  AND LENGTH(REGEXP_REPLACE(phone, '[^0-9]', '', 'g')) >= 11;

-- Corrigir país dos telefones franceses mal classificados
UPDATE contact 
SET country = 'França',
    updated_at = NOW()
WHERE phone LIKE '33%'
  AND country != 'França'
  AND phone IS NOT NULL 
  AND phone != ''
  AND LENGTH(REGEXP_REPLACE(phone, '[^0-9]', '', 'g')) >= 11;

-- Corrigir país dos telefones alemães mal classificados
UPDATE contact 
SET country = 'Alemanha',
    updated_at = NOW()
WHERE phone LIKE '49%'
  AND country != 'Alemanha'
  AND phone IS NOT NULL 
  AND phone != ''
  AND LENGTH(REGEXP_REPLACE(phone, '[^0-9]', '', 'g')) >= 11;

-- Corrigir país dos telefones italianos mal classificados
UPDATE contact 
SET country = 'Itália',
    updated_at = NOW()
WHERE phone LIKE '39%'
  AND country != 'Itália'
  AND phone IS NOT NULL 
  AND phone != ''
  AND LENGTH(REGEXP_REPLACE(phone, '[^0-9]', '', 'g')) >= 11;

-- Verificar resultado após correção
SELECT 
  'Resultado após correção de países:' as info;

SELECT 
  country,
  COUNT(*) as total_contatos,
  COUNT(CASE WHEN phone LIKE '+%' THEN 1 END) as com_mascara_internacional,
  COUNT(CASE WHEN phone NOT LIKE '+%' AND phone IS NOT NULL AND phone != '' THEN 1 END) as sem_mascara
FROM contact 
WHERE phone IS NOT NULL AND phone != ''
GROUP BY country
ORDER BY total_contatos DESC;

-- Mostrar exemplos de telefones corrigidos
SELECT 
  'Exemplos de telefones corrigidos:' as info;

SELECT 
  country,
  phone,
  updated_at
FROM contact 
WHERE phone LIKE '+351%' OR phone LIKE '+44%'
ORDER BY updated_at DESC
LIMIT 10;

-- Verificar se ainda há telefones mal classificados
SELECT 
  'Telefones ainda mal classificados:' as info;

SELECT 
  country as pais_atual,
  detect_country_from_phone(phone) as pais_correto,
  phone,
  COUNT(*) as quantidade
FROM contact 
WHERE phone IS NOT NULL 
  AND phone != ''
  AND country != detect_country_from_phone(phone)
  AND detect_country_from_phone(phone) IS NOT NULL
GROUP BY country, detect_country_from_phone(phone), phone
ORDER BY quantidade DESC
LIMIT 10;

-- Limpar funções auxiliares
DROP FUNCTION IF EXISTS detect_country_from_phone(TEXT);
DROP FUNCTION IF EXISTS format_portuguese_phone(TEXT);
DROP FUNCTION IF EXISTS format_uk_phone(TEXT);

-- Para executar este script no servidor Supabase:
-- Execute diretamente no SQL Editor do Supabase Dashboard
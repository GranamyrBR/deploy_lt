-- =====================================================
-- SCRIPT PARA APLICAR MÁSCARAS DE TELEFONE
-- =====================================================
-- Este script aplica máscaras de formatação aos telefones
-- já existentes na tabela contact

-- Função para aplicar máscara brasileira
CREATE OR REPLACE FUNCTION format_brazilian_phone(phone_number TEXT)
RETURNS TEXT AS $$
DECLARE
  clean_phone TEXT;
  has_country_code BOOLEAN := FALSE;
BEGIN
  IF phone_number IS NULL OR phone_number = '' THEN
    RETURN phone_number;
  END IF;
  
  -- Remove tudo exceto números
  clean_phone := REGEXP_REPLACE(phone_number, '[^0-9]', '', 'g');
  
  -- Verifica se tem código do país brasileiro (55)
  IF clean_phone LIKE '55%' AND LENGTH(clean_phone) > 11 THEN
    has_country_code := TRUE;
    clean_phone := SUBSTRING(clean_phone FROM 3);
  END IF;
  
  -- Aplica máscara para telefones brasileiros
  IF LENGTH(clean_phone) = 11 THEN
    -- Celular: +55 (XX) XXXXX-XXXX ou (XX) XXXXX-XXXX
    IF has_country_code THEN
      RETURN '+55 (' || SUBSTRING(clean_phone FROM 1 FOR 2) || ') ' || 
             SUBSTRING(clean_phone FROM 3 FOR 5) || '-' || 
             SUBSTRING(clean_phone FROM 8 FOR 4);
    ELSE
      RETURN '(' || SUBSTRING(clean_phone FROM 1 FOR 2) || ') ' || 
             SUBSTRING(clean_phone FROM 3 FOR 5) || '-' || 
             SUBSTRING(clean_phone FROM 8 FOR 4);
    END IF;
  ELSIF LENGTH(clean_phone) = 10 THEN
    -- Fixo: +55 (XX) XXXX-XXXX ou (XX) XXXX-XXXX
    IF has_country_code THEN
      RETURN '+55 (' || SUBSTRING(clean_phone FROM 1 FOR 2) || ') ' || 
             SUBSTRING(clean_phone FROM 3 FOR 4) || '-' || 
             SUBSTRING(clean_phone FROM 7 FOR 4);
    ELSE
      RETURN '(' || SUBSTRING(clean_phone FROM 1 FOR 2) || ') ' || 
             SUBSTRING(clean_phone FROM 3 FOR 4) || '-' || 
             SUBSTRING(clean_phone FROM 7 FOR 4);
    END IF;
  ELSE
    -- Retorna sem formatação se não for padrão brasileiro
    RETURN phone_number;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Função para aplicar máscara americana
CREATE OR REPLACE FUNCTION format_american_phone(phone_number TEXT)
RETURNS TEXT AS $$
DECLARE
  clean_phone TEXT;
  has_country_code BOOLEAN := FALSE;
BEGIN
  IF phone_number IS NULL OR phone_number = '' THEN
    RETURN phone_number;
  END IF;
  
  -- Remove tudo exceto números
  clean_phone := REGEXP_REPLACE(phone_number, '[^0-9]', '', 'g');
  
  -- Verifica se tem código do país americano (1)
  IF clean_phone LIKE '1%' AND LENGTH(clean_phone) = 11 THEN
    has_country_code := TRUE;
    clean_phone := SUBSTRING(clean_phone FROM 2);
  END IF;
  
  -- Aplica máscara americana: +1 XXX-XXX-XXXX ou XXX-XXX-XXXX
  IF LENGTH(clean_phone) = 10 THEN
    IF has_country_code THEN
      RETURN '+1 ' || SUBSTRING(clean_phone FROM 1 FOR 3) || '-' || 
             SUBSTRING(clean_phone FROM 4 FOR 3) || '-' || 
             SUBSTRING(clean_phone FROM 7 FOR 4);
    ELSE
      RETURN SUBSTRING(clean_phone FROM 1 FOR 3) || '-' || 
             SUBSTRING(clean_phone FROM 4 FOR 3) || '-' || 
             SUBSTRING(clean_phone FROM 7 FOR 4);
    END IF;
  ELSE
    -- Retorna sem formatação se não for padrão americano
    RETURN phone_number;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Verificar quantos contatos serão atualizados
SELECT 
  'Contatos brasileiros sem máscara:' as info,
  COUNT(*) as total
FROM contact 
WHERE country = 'Brasil' 
  AND phone IS NOT NULL 
  AND phone != ''
  AND phone NOT LIKE '(%)%-%'
  AND phone NOT LIKE '+55 (%)%-%';

SELECT 
  'Contatos americanos sem máscara:' as info,
  COUNT(*) as total
FROM contact 
WHERE country = 'Estados Unidos' 
  AND phone IS NOT NULL 
  AND phone != ''
  AND phone NOT LIKE '%-%-%'
  AND phone NOT LIKE '+1 %-%-%';

-- Aplicar máscaras aos telefones brasileiros
UPDATE contact 
SET phone = format_brazilian_phone(phone),
    updated_at = NOW()
WHERE country = 'Brasil' 
  AND phone IS NOT NULL 
  AND phone != ''
  AND phone NOT LIKE '(%)%-%'
  AND phone NOT LIKE '+55 (%)%-%';

-- Aplicar máscaras aos telefones americanos
UPDATE contact 
SET phone = format_american_phone(phone),
    updated_at = NOW()
WHERE country = 'Estados Unidos' 
  AND phone IS NOT NULL 
  AND phone != ''
  AND phone NOT LIKE '%-%-%'
  AND phone NOT LIKE '+1 %-%-%';

-- Verificar resultado
SELECT 
  'Telefones brasileiros formatados:' as info;

SELECT 
  id,
  name,
  phone,
  country,
  state
FROM contact 
WHERE country = 'Brasil' 
  AND phone IS NOT NULL
ORDER BY updated_at DESC
LIMIT 10;

SELECT 
  'Telefones americanos formatados:' as info;

SELECT 
  id,
  name,
  phone,
  country,
  state
FROM contact 
WHERE country = 'Estados Unidos' 
  AND phone IS NOT NULL
ORDER BY updated_at DESC
LIMIT 10;

-- Estatísticas finais
SELECT 
  country,
  COUNT(*) as total_contatos,
  COUNT(CASE WHEN phone LIKE '(%)%-%' OR phone LIKE '%-%-%' OR phone LIKE '+55 (%)%-%' OR phone LIKE '+1 %-%-%' THEN 1 END) as com_mascara,
  COUNT(CASE WHEN phone NOT LIKE '(%)%-%' AND phone NOT LIKE '%-%-%' AND phone NOT LIKE '+55 (%)%-%' AND phone NOT LIKE '+1 %-%-%' AND phone IS NOT NULL AND phone != '' THEN 1 END) as sem_mascara
FROM contact 
WHERE phone IS NOT NULL AND phone != ''
GROUP BY country
ORDER BY total_contatos DESC;

-- Limpar funções auxiliares
DROP FUNCTION format_brazilian_phone(TEXT);
DROP FUNCTION format_american_phone(TEXT);

-- Para executar este script:
-- psql -h localhost -U seu_usuario -d sua_database -f apply_phone_masks.sql
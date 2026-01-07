-- =====================================================
-- SCRIPT CORRIGIDO PARA APLICAR TODAS AS MÁSCARAS DE TELEFONE
-- =====================================================
-- Este script aplica máscaras de formatação a todos os telefones
-- brasileiros, americanos e europeus na tabela contact
-- Para execução no servidor Supabase externo

-- Função para formatar telefone brasileiro
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
  IF clean_phone LIKE '55%' AND LENGTH(clean_phone) > 10 THEN
    has_country_code := TRUE;
    clean_phone := SUBSTRING(clean_phone FROM 3);
  END IF;
  
  -- Aplica máscara brasileira
  IF LENGTH(clean_phone) = 11 THEN
    -- Celular: (XX) 9XXXX-XXXX
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
    -- Fixo: (XX) XXXX-XXXX
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
    RETURN phone_number;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Função para formatar telefone americano
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
  
  -- Aplica máscara americana: (XXX) XXX-XXXX
  IF LENGTH(clean_phone) = 10 THEN
    IF has_country_code THEN
      RETURN '+1 (' || SUBSTRING(clean_phone FROM 1 FOR 3) || ') ' || 
             SUBSTRING(clean_phone FROM 4 FOR 3) || '-' || 
             SUBSTRING(clean_phone FROM 7 FOR 4);
    ELSE
      RETURN '(' || SUBSTRING(clean_phone FROM 1 FOR 3) || ') ' || 
             SUBSTRING(clean_phone FROM 4 FOR 3) || '-' || 
             SUBSTRING(clean_phone FROM 7 FOR 4);
    END IF;
  ELSE
    RETURN phone_number;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Função para formatar telefone português
CREATE OR REPLACE FUNCTION format_portuguese_phone(phone_number TEXT)
RETURNS TEXT AS $$
DECLARE
  clean_phone TEXT;
  has_country_code BOOLEAN := FALSE;
BEGIN
  IF phone_number IS NULL OR phone_number = '' THEN
    RETURN phone_number;
  END IF;
  
  clean_phone := REGEXP_REPLACE(phone_number, '[^0-9]', '', 'g');
  
  IF clean_phone LIKE '351%' AND LENGTH(clean_phone) > 9 THEN
    has_country_code := TRUE;
    clean_phone := SUBSTRING(clean_phone FROM 4);
  END IF;
  
  IF LENGTH(clean_phone) = 9 THEN
    IF has_country_code THEN
      RETURN '+351 ' || SUBSTRING(clean_phone FROM 1 FOR 3) || ' ' || 
             SUBSTRING(clean_phone FROM 4 FOR 3) || ' ' || 
             SUBSTRING(clean_phone FROM 7 FOR 3);
    ELSE
      RETURN SUBSTRING(clean_phone FROM 1 FOR 3) || ' ' || 
             SUBSTRING(clean_phone FROM 4 FOR 3) || ' ' || 
             SUBSTRING(clean_phone FROM 7 FOR 3);
    END IF;
  ELSE
    RETURN phone_number;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Função para formatar telefone espanhol
CREATE OR REPLACE FUNCTION format_spanish_phone(phone_number TEXT)
RETURNS TEXT AS $$
DECLARE
  clean_phone TEXT;
  has_country_code BOOLEAN := FALSE;
BEGIN
  IF phone_number IS NULL OR phone_number = '' THEN
    RETURN phone_number;
  END IF;
  
  clean_phone := REGEXP_REPLACE(phone_number, '[^0-9]', '', 'g');
  
  IF clean_phone LIKE '34%' AND LENGTH(clean_phone) > 9 THEN
    has_country_code := TRUE;
    clean_phone := SUBSTRING(clean_phone FROM 3);
  END IF;
  
  IF LENGTH(clean_phone) = 9 THEN
    IF has_country_code THEN
      RETURN '+34 ' || SUBSTRING(clean_phone FROM 1 FOR 3) || ' ' || 
             SUBSTRING(clean_phone FROM 4 FOR 3) || ' ' || 
             SUBSTRING(clean_phone FROM 7 FOR 3);
    ELSE
      RETURN SUBSTRING(clean_phone FROM 1 FOR 3) || ' ' || 
             SUBSTRING(clean_phone FROM 4 FOR 3) || ' ' || 
             SUBSTRING(clean_phone FROM 7 FOR 3);
    END IF;
  ELSE
    RETURN phone_number;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Verificar status atual dos telefones
SELECT 'Status atual dos telefones:' as info;

SELECT 
  country,
  COUNT(*) as total_contatos,
  COUNT(CASE WHEN phone IS NOT NULL AND phone != '' THEN 1 END) as com_telefone,
  COUNT(CASE WHEN phone LIKE '+%' OR phone LIKE '(%)%' THEN 1 END) as com_mascara
FROM contact 
WHERE phone IS NOT NULL AND phone != ''
GROUP BY country
ORDER BY total_contatos DESC;

-- Aplicar máscaras aos telefones brasileiros
UPDATE contact 
SET phone = format_brazilian_phone(phone),
    updated_at = NOW()
WHERE country = 'Brasil' 
  AND phone IS NOT NULL 
  AND phone != ''
  AND phone NOT LIKE '+55 (%) %-%'
  AND phone NOT LIKE '(%) %-%';

-- Aplicar máscaras aos telefones americanos
UPDATE contact 
SET phone = format_american_phone(phone),
    updated_at = NOW()
WHERE country = 'Estados Unidos' 
  AND phone IS NOT NULL 
  AND phone != ''
  AND phone NOT LIKE '+1 (%) %-%'
  AND phone NOT LIKE '(%) %-%';

-- Aplicar máscaras aos telefones portugueses
UPDATE contact 
SET phone = format_portuguese_phone(phone),
    updated_at = NOW()
WHERE country = 'Portugal' 
  AND phone IS NOT NULL 
  AND phone != ''
  AND phone NOT LIKE '+351 % % %'
  AND phone NOT LIKE '% % %';

-- Aplicar máscaras aos telefones espanhóis
UPDATE contact 
SET phone = format_spanish_phone(phone),
    updated_at = NOW()
WHERE country = 'Espanha' 
  AND phone IS NOT NULL 
  AND phone != ''
  AND phone NOT LIKE '+34 % % %'
  AND phone NOT LIKE '% % %';

-- Verificar resultado final
SELECT 'Resultado após aplicação das máscaras:' as info;

SELECT 
  country,
  COUNT(*) as total_contatos,
  COUNT(CASE WHEN phone IS NOT NULL AND phone != '' THEN 1 END) as com_telefone,
  COUNT(CASE WHEN phone LIKE '+%' OR phone LIKE '(%)%' THEN 1 END) as com_mascara,
  COUNT(CASE WHEN phone NOT LIKE '+%' AND phone NOT LIKE '(%)%' AND phone IS NOT NULL AND phone != '' THEN 1 END) as sem_mascara
FROM contact 
WHERE phone IS NOT NULL AND phone != ''
GROUP BY country
ORDER BY total_contatos DESC;

-- Mostrar exemplos de telefones formatados
SELECT 'Exemplos de telefones formatados:' as info;

SELECT 
  country,
  phone,
  updated_at
FROM contact 
WHERE phone IS NOT NULL 
  AND phone != ''
  AND (phone LIKE '+%' OR phone LIKE '(%)%')
ORDER BY updated_at DESC
LIMIT 10;

-- Limpar funções auxiliares
DROP FUNCTION IF EXISTS format_brazilian_phone(TEXT);
DROP FUNCTION IF EXISTS format_american_phone(TEXT);
DROP FUNCTION IF EXISTS format_portuguese_phone(TEXT);
DROP FUNCTION IF EXISTS format_spanish_phone(TEXT);

-- Para executar este script no servidor Supabase:
-- Execute diretamente no SQL Editor do Supabase Dashboard
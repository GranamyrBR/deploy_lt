-- =====================================================
-- SCRIPT PARA APLICAR MÁSCARAS DE TELEFONE EUROPEUS
-- =====================================================
-- Este script aplica máscaras de formatação aos telefones
-- europeus já existentes na tabela contact
-- Para execução no servidor Supabase externo

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
  
  -- Remove tudo exceto números
  clean_phone := REGEXP_REPLACE(phone_number, '[^0-9]', '', 'g');
  
  -- Verifica se tem código do país português (351)
  IF clean_phone LIKE '351%' AND LENGTH(clean_phone) > 9 THEN
    has_country_code := TRUE;
    clean_phone := SUBSTRING(clean_phone FROM 4);
  END IF;
  
  -- Aplica máscara portuguesa: +351 XXX XXX XXX
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
    -- Retorna sem formatação se não for padrão português
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
  
  -- Remove tudo exceto números
  clean_phone := REGEXP_REPLACE(phone_number, '[^0-9]', '', 'g');
  
  -- Verifica se tem código do país espanhol (34)
  IF clean_phone LIKE '34%' AND LENGTH(clean_phone) > 9 THEN
    has_country_code := TRUE;
    clean_phone := SUBSTRING(clean_phone FROM 3);
  END IF;
  
  -- Aplica máscara espanhola: +34 XXX XXX XXX
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
    -- Retorna sem formatação se não for padrão espanhol
    RETURN phone_number;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Função para formatar telefone francês
CREATE OR REPLACE FUNCTION format_french_phone(phone_number TEXT)
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
  
  -- Verifica se tem código do país francês (33)
  IF clean_phone LIKE '33%' AND LENGTH(clean_phone) > 10 THEN
    has_country_code := TRUE;
    clean_phone := SUBSTRING(clean_phone FROM 3);
  END IF;
  
  -- Aplica máscara francesa: +33 X XX XX XX XX
  IF LENGTH(clean_phone) = 10 THEN
    IF has_country_code THEN
      RETURN '+33 ' || SUBSTRING(clean_phone FROM 1 FOR 1) || ' ' || 
             SUBSTRING(clean_phone FROM 2 FOR 2) || ' ' || 
             SUBSTRING(clean_phone FROM 4 FOR 2) || ' ' || 
             SUBSTRING(clean_phone FROM 6 FOR 2) || ' ' || 
             SUBSTRING(clean_phone FROM 8 FOR 2);
    ELSE
      RETURN SUBSTRING(clean_phone FROM 1 FOR 2) || ' ' || 
             SUBSTRING(clean_phone FROM 3 FOR 2) || ' ' || 
             SUBSTRING(clean_phone FROM 5 FOR 2) || ' ' || 
             SUBSTRING(clean_phone FROM 7 FOR 2) || ' ' || 
             SUBSTRING(clean_phone FROM 9 FOR 2);
    END IF;
  ELSE
    -- Retorna sem formatação se não for padrão francês
    RETURN phone_number;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Função para formatar telefone alemão
CREATE OR REPLACE FUNCTION format_german_phone(phone_number TEXT)
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
  
  -- Verifica se tem código do país alemão (49)
  IF clean_phone LIKE '49%' AND LENGTH(clean_phone) > 10 THEN
    has_country_code := TRUE;
    clean_phone := SUBSTRING(clean_phone FROM 3);
  END IF;
  
  -- Aplica máscara alemã: +49 XXX XXXXXXX (formato simplificado)
  IF LENGTH(clean_phone) BETWEEN 10 AND 12 THEN
    IF has_country_code THEN
      RETURN '+49 ' || SUBSTRING(clean_phone FROM 1 FOR 3) || ' ' || 
             SUBSTRING(clean_phone FROM 4);
    ELSE
      RETURN SUBSTRING(clean_phone FROM 1 FOR 3) || ' ' || 
             SUBSTRING(clean_phone FROM 4);
    END IF;
  ELSE
    -- Retorna sem formatação se não for padrão alemão
    RETURN phone_number;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Função para formatar telefone do Reino Unido
CREATE OR REPLACE FUNCTION format_uk_phone(phone_number TEXT)
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
  
  -- Verifica se tem código do país do Reino Unido (44)
  IF clean_phone LIKE '44%' AND LENGTH(clean_phone) > 10 THEN
    has_country_code := TRUE;
    clean_phone := SUBSTRING(clean_phone FROM 3);
  END IF;
  
  -- Aplica máscara do Reino Unido: +44 XXXX XXX XXX
  IF LENGTH(clean_phone) = 10 THEN
    IF has_country_code THEN
      RETURN '+44 ' || SUBSTRING(clean_phone FROM 1 FOR 4) || ' ' || 
             SUBSTRING(clean_phone FROM 5 FOR 3) || ' ' || 
             SUBSTRING(clean_phone FROM 8 FOR 3);
    ELSE
      RETURN SUBSTRING(clean_phone FROM 1 FOR 4) || ' ' || 
             SUBSTRING(clean_phone FROM 5 FOR 3) || ' ' || 
             SUBSTRING(clean_phone FROM 8 FOR 3);
    END IF;
  ELSE
    -- Retorna sem formatação se não for padrão do Reino Unido
    RETURN phone_number;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Função para formatar telefone italiano
CREATE OR REPLACE FUNCTION format_italian_phone(phone_number TEXT)
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
  
  -- Verifica se tem código do país italiano (39)
  IF clean_phone LIKE '39%' AND LENGTH(clean_phone) > 10 THEN
    has_country_code := TRUE;
    clean_phone := SUBSTRING(clean_phone FROM 3);
  END IF;
  
  -- Aplica máscara italiana: +39 XXX XXX XXXX
  IF LENGTH(clean_phone) = 10 THEN
    IF has_country_code THEN
      RETURN '+39 ' || SUBSTRING(clean_phone FROM 1 FOR 3) || ' ' || 
             SUBSTRING(clean_phone FROM 4 FOR 3) || ' ' || 
             SUBSTRING(clean_phone FROM 7 FOR 4);
    ELSE
      RETURN SUBSTRING(clean_phone FROM 1 FOR 3) || ' ' || 
             SUBSTRING(clean_phone FROM 4 FOR 3) || ' ' || 
             SUBSTRING(clean_phone FROM 7 FOR 4);
    END IF;
  ELSE
    -- Retorna sem formatação se não for padrão italiano
    RETURN phone_number;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Verificar quantos contatos europeus serão atualizados
SELECT 
  'Contatos portugueses sem máscara:' as info,
  COUNT(*) as total
FROM contact 
WHERE country = 'Portugal' 
  AND phone IS NOT NULL 
  AND phone != ''
  AND phone NOT LIKE '+351 % % %'
  AND phone NOT LIKE '% % %';

SELECT 
  'Contatos espanhóis sem máscara:' as info,
  COUNT(*) as total
FROM contact 
WHERE country = 'Espanha' 
  AND phone IS NOT NULL 
  AND phone != ''
  AND phone NOT LIKE '+34 % % %'
  AND phone NOT LIKE '% % %';

SELECT 
  'Contatos franceses sem máscara:' as info,
  COUNT(*) as total
FROM contact 
WHERE country = 'França' 
  AND phone IS NOT NULL 
  AND phone != ''
  AND phone NOT LIKE '+33 % % % % %'
  AND phone NOT LIKE '% % % % %';

SELECT 
  'Contatos alemães sem máscara:' as info,
  COUNT(*) as total
FROM contact 
WHERE country = 'Alemanha' 
  AND phone IS NOT NULL 
  AND phone != ''
  AND phone NOT LIKE '+49 % %'
  AND phone NOT LIKE '% %';

SELECT 
  'Contatos do Reino Unido sem máscara:' as info,
  COUNT(*) as total
FROM contact 
WHERE country = 'Reino Unido' 
  AND phone IS NOT NULL 
  AND phone != ''
  AND phone NOT LIKE '+44 % % %'
  AND phone NOT LIKE '% % %';

SELECT 
  'Contatos italianos sem máscara:' as info,
  COUNT(*) as total
FROM contact 
WHERE country = 'Itália' 
  AND phone IS NOT NULL 
  AND phone != ''
  AND phone NOT LIKE '+39 % % %'
  AND phone NOT LIKE '% % %';

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

-- Aplicar máscaras aos telefones franceses
UPDATE contact 
SET phone = format_french_phone(phone),
    updated_at = NOW()
WHERE country = 'França' 
  AND phone IS NOT NULL 
  AND phone != ''
  AND phone NOT LIKE '+33 % % % % %'
  AND phone NOT LIKE '% % % % %';

-- Aplicar máscaras aos telefones alemães
UPDATE contact 
SET phone = format_german_phone(phone),
    updated_at = NOW()
WHERE country = 'Alemanha' 
  AND phone IS NOT NULL 
  AND phone != ''
  AND phone NOT LIKE '+49 % %'
  AND phone NOT LIKE '% %';

-- Aplicar máscaras aos telefones do Reino Unido
UPDATE contact 
SET phone = format_uk_phone(phone),
    updated_at = NOW()
WHERE country = 'Reino Unido' 
  AND phone IS NOT NULL 
  AND phone != ''
  AND phone NOT LIKE '+44 % % %'
  AND phone NOT LIKE '% % %';

-- Aplicar máscaras aos telefones italianos
UPDATE contact 
SET phone = format_italian_phone(phone),
    updated_at = NOW()
WHERE country = 'Itália' 
  AND phone IS NOT NULL 
  AND phone != ''
  AND phone NOT LIKE '+39 % % %'
  AND phone NOT LIKE '% % %';

-- Verificar resultado
SELECT 
  'Telefones portugueses formatados:' as info;

SELECT 
  id,
  name,
  phone,
  country
FROM contact 
WHERE country = 'Portugal' 
  AND phone IS NOT NULL
ORDER BY updated_at DESC
LIMIT 5;

SELECT 
  'Telefones espanhóis formatados:' as info;

SELECT 
  id,
  name,
  phone,
  country
FROM contact 
WHERE country = 'Espanha' 
  AND phone IS NOT NULL
ORDER BY updated_at DESC
LIMIT 5;

SELECT 
  'Telefones franceses formatados:' as info;

SELECT 
  id,
  name,
  phone,
  country
FROM contact 
WHERE country = 'França' 
  AND phone IS NOT NULL
ORDER BY updated_at DESC
LIMIT 5;

SELECT 
  'Telefones alemães formatados:' as info;

SELECT 
  id,
  name,
  phone,
  country
FROM contact 
WHERE country = 'Alemanha' 
  AND phone IS NOT NULL
ORDER BY updated_at DESC
LIMIT 5;

SELECT 
  'Telefones do Reino Unido formatados:' as info;

SELECT 
  id,
  name,
  phone,
  country
FROM contact 
WHERE country = 'Reino Unido' 
  AND phone IS NOT NULL
ORDER BY updated_at DESC
LIMIT 5;

SELECT 
  'Telefones italianos formatados:' as info;

SELECT 
  id,
  name,
  phone,
  country
FROM contact 
WHERE country = 'Itália' 
  AND phone IS NOT NULL
ORDER BY updated_at DESC
LIMIT 5;

-- Estatísticas finais por país europeu
SELECT 
  country,
  COUNT(*) as total_contatos,
  COUNT(CASE WHEN phone LIKE '+351 % % %' OR phone LIKE '+34 % % %' OR phone LIKE '+33 % % % % %' OR phone LIKE '+49 % %' OR phone LIKE '+44 % % %' OR phone LIKE '+39 % % %' THEN 1 END) as com_mascara,
  COUNT(CASE WHEN phone NOT LIKE '+351 % % %' AND phone NOT LIKE '+34 % % %' AND phone NOT LIKE '+33 % % % % %' AND phone NOT LIKE '+49 % %' AND phone NOT LIKE '+44 % % %' AND phone NOT LIKE '+39 % % %' AND phone IS NOT NULL AND phone != '' THEN 1 END) as sem_mascara
FROM contact 
WHERE country IN ('Portugal', 'Espanha', 'França', 'Alemanha', 'Reino Unido', 'Itália')
  AND phone IS NOT NULL AND phone != ''
GROUP BY country
ORDER BY total_contatos DESC;

-- Limpar funções auxiliares
DROP FUNCTION format_portuguese_phone(TEXT);
DROP FUNCTION format_spanish_phone(TEXT);
DROP FUNCTION format_french_phone(TEXT);
DROP FUNCTION format_german_phone(TEXT);
DROP FUNCTION format_uk_phone(TEXT);
DROP FUNCTION format_italian_phone(TEXT);

-- Para executar este script no servidor Supabase:
-- psql -h db.your-project.supabase.co -U postgres -d postgres -f apply_european_phone_masks.sql
-- Ou execute diretamente no SQL Editor do Supabase Dashboard
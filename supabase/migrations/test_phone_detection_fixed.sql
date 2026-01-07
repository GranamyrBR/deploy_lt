-- =====================================================
-- TESTE DAS FUNÇÕES CORRIGIDAS DE DETECÇÃO
-- =====================================================
-- Este script testa as funções corrigidas para garantir
-- que telefones EUA e Espanha não sejam mais detectados
-- incorretamente como Brasil

-- ETAPA 1: CRIAR FUNÇÕES DE TESTE
SELECT 'CRIANDO FUNÇÕES DE TESTE...' as info;

-- Função CORRIGIDA para detectar país do telefone
CREATE OR REPLACE FUNCTION get_country_from_phone_test(phone_number TEXT)
RETURNS TEXT AS $$
DECLARE
  clean_phone TEXT;
BEGIN
  IF phone_number IS NULL OR TRIM(phone_number) = '' THEN
    RETURN NULL;
  END IF;
  
  -- Remove espaços, parênteses, hífens e outros caracteres, mantendo apenas números e +
  clean_phone := REGEXP_REPLACE(phone_number, '[^0-9+]', '', 'g');
  
  -- Detectar país baseado em códigos internacionais CORRETOS
  -- Estados Unidos: +1 seguido de exatamente 10 dígitos
  IF clean_phone ~ '^\+1\d{10}$' OR (clean_phone ~ '^1\d{10}$' AND LENGTH(clean_phone) = 11) THEN
    RETURN 'Estados Unidos';
  -- Brasil: +55 seguido de 10 ou 11 dígitos
  ELSIF clean_phone ~ '^\+55\d{10,11}$' OR (clean_phone ~ '^55\d{10,11}$' AND LENGTH(clean_phone) BETWEEN 12 AND 13) THEN
    RETURN 'Brasil';
  -- Portugal: +351 seguido de 9 dígitos
  ELSIF clean_phone ~ '^\+351\d{9}$' OR (clean_phone ~ '^351\d{9}$' AND LENGTH(clean_phone) = 12) THEN
    RETURN 'Portugal';
  -- Espanha: +34 seguido de 9 dígitos
  ELSIF clean_phone ~ '^\+34\d{9}$' OR (clean_phone ~ '^34\d{9}$' AND LENGTH(clean_phone) = 11) THEN
    RETURN 'Espanha';
  -- França: +33 seguido de 9 dígitos
  ELSIF clean_phone ~ '^\+33\d{9}$' OR (clean_phone ~ '^33\d{9}$' AND LENGTH(clean_phone) = 11) THEN
    RETURN 'França';
  -- Argentina: +54 seguido de 10 dígitos
  ELSIF clean_phone ~ '^\+54\d{10}$' OR (clean_phone ~ '^54\d{10}$' AND LENGTH(clean_phone) = 12) THEN
    RETURN 'Argentina';
  -- Verificar se é telefone brasileiro sem código de país (padrão brasileiro)
  ELSIF clean_phone ~ '^\d{10,11}$' AND LENGTH(clean_phone) BETWEEN 10 AND 11 THEN
    -- Verificar se o primeiro dígito é válido para celular brasileiro (8 ou 9)
    IF SUBSTRING(clean_phone FROM 3 FOR 1) IN ('8', '9') OR LENGTH(clean_phone) = 10 THEN
      RETURN 'Brasil';
    ELSE
      RETURN 'Outros';
    END IF;
  -- Outros países
  ELSE
    RETURN 'Outros';
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Função CORRIGIDA para extrair estado do telefone (apenas Brasil)
CREATE OR REPLACE FUNCTION get_state_from_phone_test(phone_number TEXT)
RETURNS TEXT AS $$
DECLARE
  clean_phone TEXT;
  area_code TEXT;
  detected_country TEXT;
BEGIN
  IF phone_number IS NULL OR TRIM(phone_number) = '' THEN
    RETURN NULL;
  END IF;
  
  -- Verificar se é telefone brasileiro usando a função de detecção de país
  detected_country := get_country_from_phone_test(phone_number);
  IF detected_country != 'Brasil' THEN
    RETURN NULL;
  END IF;
  
  -- Remove espaços, parênteses, hífens e outros caracteres, mantendo apenas números e +
  clean_phone := REGEXP_REPLACE(phone_number, '[^0-9+]', '', 'g');
  
  -- Extrair código de área de telefone brasileiro
  IF clean_phone ~ '^\+55\d{10,11}$' THEN
    -- Telefone com +55: extrair os 2 dígitos após o 55
    area_code := SUBSTRING(clean_phone FROM 4 FOR 2);
  ELSIF clean_phone ~ '^55\d{10,11}$' AND LENGTH(clean_phone) BETWEEN 12 AND 13 THEN
    -- Telefone com 55: extrair os 2 dígitos após o 55
    area_code := SUBSTRING(clean_phone FROM 3 FOR 2);
  ELSIF clean_phone ~ '^\d{10,11}$' AND LENGTH(clean_phone) BETWEEN 10 AND 11 THEN
    -- Telefone brasileiro sem código de país: primeiros 2 dígitos
    area_code := SUBSTRING(clean_phone FROM 1 FOR 2);
  ELSE
    RETURN NULL;
  END IF;
  
  -- Mapear código de área para estado
  CASE area_code
    WHEN '11', '12', '13', '14', '15', '16', '17', '18', '19' THEN RETURN 'São Paulo';
    WHEN '21', '22', '24' THEN RETURN 'Rio de Janeiro';
    WHEN '27', '28' THEN RETURN 'Espírito Santo';
    WHEN '31', '32', '33', '34', '35', '37', '38' THEN RETURN 'Minas Gerais';
    WHEN '41', '42', '43', '44', '45', '46' THEN RETURN 'Paraná';
    WHEN '47', '48', '49' THEN RETURN 'Santa Catarina';
    WHEN '51', '53', '54', '55' THEN RETURN 'Rio Grande do Sul';
    WHEN '61' THEN RETURN 'Distrito Federal';
    WHEN '62', '64' THEN RETURN 'Goiás';
    WHEN '63' THEN RETURN 'Tocantins';
    WHEN '65', '66' THEN RETURN 'Mato Grosso';
    WHEN '67' THEN RETURN 'Mato Grosso do Sul';
    WHEN '68' THEN RETURN 'Acre';
    WHEN '69' THEN RETURN 'Rondônia';
    WHEN '71', '73', '74', '75', '77' THEN RETURN 'Bahia';
    WHEN '79' THEN RETURN 'Sergipe';
    WHEN '81', '87' THEN RETURN 'Pernambuco';
    WHEN '82' THEN RETURN 'Alagoas';
    WHEN '83' THEN RETURN 'Paraíba';
    WHEN '84' THEN RETURN 'Rio Grande do Norte';
    WHEN '85', '88' THEN RETURN 'Ceará';
    WHEN '86', '89' THEN RETURN 'Piauí';
    WHEN '91', '93', '94' THEN RETURN 'Pará';
    WHEN '92', '97' THEN RETURN 'Amazonas';
    WHEN '95' THEN RETURN 'Roraima';
    WHEN '96' THEN RETURN 'Amapá';
    WHEN '98', '99' THEN RETURN 'Maranhão';
    ELSE RETURN NULL;
  END CASE;
END;
$$ LANGUAGE plpgsql;

SELECT 'Funções de teste criadas!' as resultado;

-- ETAPA 2: TESTES ESPECÍFICOS DOS PROBLEMAS REPORTADOS
SELECT 'TESTANDO CASOS PROBLEMÁTICOS...' as info;

-- Teste 1: Telefones EUA que estavam sendo detectados como Brasil/SP
SELECT 
  'TESTE 1 - Telefones EUA (problema: detectados como Brasil/SP)' as teste,
  phone,
  get_country_from_phone_test(phone) as pais_detectado,
  get_state_from_phone_test(phone) as estado_detectado,
  CASE 
    WHEN get_country_from_phone_test(phone) = 'Estados Unidos' THEN '✅ CORRETO'
    WHEN get_country_from_phone_test(phone) = 'Brasil' THEN '❌ ERRO - Ainda detectando como Brasil'
    ELSE '⚠️ OUTRO RESULTADO'
  END as status
FROM (
  VALUES 
    ('1234567890'),        -- EUA sem +
    ('+1234567890'),       -- EUA com +
    ('12345678901'),       -- EUA 11 dígitos
    ('+12345678901'),      -- EUA com + 11 dígitos
    ('1555123456'),        -- EUA formato curto
    ('+1555123456'),       -- EUA com + formato curto
    ('15551234567'),       -- EUA 11 dígitos sem +
    ('+15551234567')       -- EUA 11 dígitos com +
) AS test_phones(phone);

-- Teste 2: Telefones Espanha que estavam sendo detectados como Brasil/MG
SELECT 
  'TESTE 2 - Telefones Espanha (problema: detectados como Brasil/MG)' as teste,
  phone,
  get_country_from_phone_test(phone) as pais_detectado,
  get_state_from_phone_test(phone) as estado_detectado,
  CASE 
    WHEN get_country_from_phone_test(phone) = 'Espanha' THEN '✅ CORRETO'
    WHEN get_country_from_phone_test(phone) = 'Brasil' THEN '❌ ERRO - Ainda detectando como Brasil'
    ELSE '⚠️ OUTRO RESULTADO'
  END as status
FROM (
  VALUES 
    ('34123456789'),       -- Espanha sem +
    ('+34123456789'),      -- Espanha com +
    ('34987654321'),       -- Espanha outro número
    ('+34987654321'),      -- Espanha com + outro número
    ('34612345678'),       -- Espanha celular
    ('+34612345678')       -- Espanha celular com +
) AS test_phones(phone);

-- Teste 3: Telefones Brasil que devem continuar sendo detectados corretamente
SELECT 
  'TESTE 3 - Telefones Brasil (devem continuar corretos)' as teste,
  phone,
  get_country_from_phone_test(phone) as pais_detectado,
  get_state_from_phone_test(phone) as estado_detectado,
  CASE 
    WHEN get_country_from_phone_test(phone) = 'Brasil' AND get_state_from_phone_test(phone) IS NOT NULL THEN '✅ CORRETO'
    WHEN get_country_from_phone_test(phone) = 'Brasil' AND get_state_from_phone_test(phone) IS NULL THEN '⚠️ PAÍS OK, ESTADO NULL'
    WHEN get_country_from_phone_test(phone) != 'Brasil' THEN '❌ ERRO - País incorreto'
    ELSE '⚠️ OUTRO RESULTADO'
  END as status
FROM (
  VALUES 
    ('11999999999'),       -- SP celular
    ('1133334444'),        -- SP fixo
    ('21987654321'),       -- RJ celular
    ('2133334444'),        -- RJ fixo
    ('31999999999'),       -- MG celular
    ('3433334444'),        -- MG fixo
    ('5511999999999'),     -- SP com 55
    ('+5511999999999'),    -- SP com +55
    ('5521987654321'),     -- RJ com 55
    ('+5521987654321'),    -- RJ com +55
    ('5531999999999'),     -- MG com 55
    ('+5531999999999')     -- MG com +55
) AS test_phones(phone);

-- Teste 4: Outros países europeus
SELECT 
  'TESTE 4 - Outros países europeus' as teste,
  phone,
  get_country_from_phone_test(phone) as pais_detectado,
  get_state_from_phone_test(phone) as estado_detectado,
  CASE 
    WHEN phone LIKE '+351%' AND get_country_from_phone_test(phone) = 'Portugal' THEN '✅ CORRETO'
    WHEN phone LIKE '+33%' AND get_country_from_phone_test(phone) = 'França' THEN '✅ CORRETO'
    WHEN get_country_from_phone_test(phone) = 'Brasil' THEN '❌ ERRO - Detectando como Brasil'
    ELSE '⚠️ OUTRO RESULTADO'
  END as status
FROM (
  VALUES 
    ('351123456789'),      -- Portugal sem +
    ('+351123456789'),     -- Portugal com +
    ('33123456789'),       -- França sem +
    ('+33123456789')       -- França com +
) AS test_phones(phone);

-- ETAPA 3: TESTE COM DADOS REAIS DO LEADSTINTIM
SELECT 'TESTANDO COM DADOS REAIS DO LEADSTINTIM...' as info;

-- Verificar se há telefones problemáticos no leadstintim
SELECT 
  'Análise de telefones no leadstintim:' as analise,
  phone,
  get_country_from_phone_test(phone) as pais_detectado,
  get_state_from_phone_test(phone) as estado_detectado,
  CASE 
    WHEN phone ~ '^1\d{10}' AND get_country_from_phone_test(phone) != 'Estados Unidos' THEN '❌ POSSÍVEL ERRO EUA'
    WHEN phone ~ '^34\d{9}' AND get_country_from_phone_test(phone) != 'Espanha' THEN '❌ POSSÍVEL ERRO ESPANHA'
    WHEN phone ~ '^\+1\d{10}' AND get_country_from_phone_test(phone) != 'Estados Unidos' THEN '❌ POSSÍVEL ERRO EUA'
    WHEN phone ~ '^\+34\d{9}' AND get_country_from_phone_test(phone) != 'Espanha' THEN '❌ POSSÍVEL ERRO ESPANHA'
    ELSE '✅ OK'
  END as status
FROM leadstintim 
WHERE phone IS NOT NULL 
  AND TRIM(phone) != ''
  AND (phone ~ '^1\d{10}' OR phone ~ '^34\d{9}' OR phone ~ '^\+1\d{10}' OR phone ~ '^\+34\d{9}')
LIMIT 20;

-- ETAPA 4: RESUMO DOS TESTES
SELECT 'RESUMO DOS TESTES:' as info;

-- Contagem de resultados por país nos testes
WITH test_data AS (
  SELECT phone, get_country_from_phone_test(phone) as country
  FROM (
    VALUES 
      ('1234567890'), ('+1234567890'), ('15551234567'),
      ('34123456789'), ('+34123456789'), ('34612345678'),
      ('11999999999'), ('5511999999999'), ('+5511999999999'),
      ('351123456789'), ('+351123456789'),
      ('33123456789'), ('+33123456789')
  ) AS phones(phone)
)
SELECT 
  country,
  COUNT(*) as quantidade,
  ARRAY_AGG(phone) as exemplos
FROM test_data
GROUP BY country
ORDER BY quantidade DESC;

SELECT 'TESTES CONCLUÍDOS!' as resultado_final;

-- =====================================================
-- INSTRUÇÕES PARA ANÁLISE:
-- 
-- ✅ SUCESSO: Telefones EUA devem aparecer como "Estados Unidos"
-- ✅ SUCESSO: Telefones Espanha devem aparecer como "Espanha"
-- ✅ SUCESSO: Telefones Brasil devem aparecer como "Brasil" com estado
-- ❌ ERRO: Se algum telefone EUA/Espanha aparecer como "Brasil"
-- 
-- Se todos os testes passarem, o script de migração está pronto!
-- =====================================================
-- =====================================================
-- SCRIPT DE EXECUÇÃO - MIGRAÇÃO WHATSAPP PARA CONTATOS
-- =====================================================
-- Execute este script diretamente no PostgreSQL
-- psql -h localhost -U seu_usuario -d sua_database -f execute_migration.sql

-- === INICIANDO MIGRAÇÃO DE LEADS DO WHATSAPP ===

-- Verificar quantos leads únicos temos no WhatsApp
-- Verificando leads únicos do WhatsApp...
SELECT COUNT(DISTINCT phone) as total_phones_unicos
FROM leadstintim 
WHERE phone IS NOT NULL 
  AND phone != '' 
  AND TRIM(phone) != '';

-- Verificar se já existem contatos com esses telefones
-- Verificando telefones que já existem na tabela contact...
SELECT COUNT(*) as telefones_ja_existem
FROM contact c
WHERE EXISTS (
  SELECT 1 FROM leadstintim l 
  WHERE l.phone = c.phone 
    AND l.phone IS NOT NULL 
    AND l.phone != '' 
    AND TRIM(l.phone) != ''
);

-- Criar função para extrair país do telefone
-- Criando função get_country_from_phone...
CREATE OR REPLACE FUNCTION get_country_from_phone(phone_number TEXT)
RETURNS TEXT AS $$
BEGIN
  IF phone_number IS NULL OR phone_number = '' THEN
    RETURN NULL;
  END IF;
  
  -- Remove espaços e caracteres especiais
  phone_number := REGEXP_REPLACE(phone_number, '[^0-9+]', '', 'g');
  
  -- Verifica códigos de país comuns
  IF phone_number LIKE '+55%' OR phone_number LIKE '55%' THEN
    RETURN 'Brasil';
  ELSIF phone_number LIKE '+1%' OR (phone_number LIKE '1%' AND LENGTH(phone_number) = 11) THEN
    RETURN 'Estados Unidos';
  ELSIF phone_number LIKE '+351%' THEN
    RETURN 'Portugal';
  ELSIF phone_number LIKE '+34%' THEN
    RETURN 'Espanha';
  ELSIF phone_number LIKE '+33%' THEN
    RETURN 'França';
  ELSIF phone_number LIKE '+49%' THEN
    RETURN 'Alemanha';
  ELSIF phone_number LIKE '+44%' THEN
    RETURN 'Reino Unido';
  ELSIF phone_number LIKE '+39%' THEN
    RETURN 'Itália';
  ELSE
    RETURN 'Brasil';
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Criar função para extrair estado do telefone (Brasil e EUA)
-- Criando função get_state_from_phone...
CREATE OR REPLACE FUNCTION get_state_from_phone(phone_number TEXT)
RETURNS TEXT AS $$
DECLARE
  area_code TEXT;
BEGIN
  IF phone_number IS NULL OR phone_number = '' THEN
    RETURN NULL;
  END IF;
  
  -- Remove espaços e caracteres especiais
  phone_number := REGEXP_REPLACE(phone_number, '[^0-9]', '', 'g');
  
  -- TELEFONES BRASILEIROS
  IF phone_number LIKE '55%' AND LENGTH(phone_number) > 11 THEN
    -- Remove código do país brasileiro (55)
    phone_number := SUBSTRING(phone_number FROM 3);
  END IF;
  
  -- Verifica se é telefone brasileiro (10-11 dígitos)
  IF LENGTH(phone_number) >= 10 AND LENGTH(phone_number) <= 11 AND 
     NOT (phone_number LIKE '1%' AND LENGTH(phone_number) = 11) THEN
    -- Mapeia DDD para estados brasileiros
    CASE SUBSTRING(phone_number FROM 1 FOR 2)
      WHEN '11', '12', '13', '14', '15', '16', '17', '18', '19' THEN RETURN 'SP';
      WHEN '21', '22', '24' THEN RETURN 'RJ';
      WHEN '27', '28' THEN RETURN 'ES';
      WHEN '31', '32', '33', '34', '35', '37', '38' THEN RETURN 'MG';
      WHEN '41', '42', '43', '44', '45', '46' THEN RETURN 'PR';
      WHEN '47', '48', '49' THEN RETURN 'SC';
      WHEN '51', '53', '54', '55' THEN RETURN 'RS';
      WHEN '61' THEN RETURN 'DF';
      WHEN '62', '64' THEN RETURN 'GO';
      WHEN '63' THEN RETURN 'TO';
      WHEN '65', '66' THEN RETURN 'MT';
      WHEN '67' THEN RETURN 'MS';
      WHEN '68' THEN RETURN 'AC';
      WHEN '69' THEN RETURN 'RO';
      WHEN '71', '73', '74', '75', '77' THEN RETURN 'BA';
      WHEN '79' THEN RETURN 'SE';
      WHEN '81', '87' THEN RETURN 'PE';
      WHEN '82' THEN RETURN 'AL';
      WHEN '83' THEN RETURN 'PB';
      WHEN '84' THEN RETURN 'RN';
      WHEN '85', '88' THEN RETURN 'CE';
      WHEN '86', '89' THEN RETURN 'PI';
      WHEN '91', '93', '94' THEN RETURN 'PA';
      WHEN '92', '97' THEN RETURN 'AM';
      WHEN '95' THEN RETURN 'RR';
      WHEN '96' THEN RETURN 'AP';
      WHEN '98', '99' THEN RETURN 'MA';
      ELSE RETURN NULL;
    END CASE;
  END IF;
  
  -- TELEFONES AMERICANOS
  IF (phone_number LIKE '1%' AND LENGTH(phone_number) = 11) OR 
     (LENGTH(phone_number) = 10) THEN
    -- Remove código do país americano (1) se presente
    IF phone_number LIKE '1%' AND LENGTH(phone_number) = 11 THEN
      phone_number := SUBSTRING(phone_number FROM 2);
    END IF;
    
    -- Extrai area code (3 primeiros dígitos)
    area_code := SUBSTRING(phone_number FROM 1 FOR 3);
    
    -- Mapeia area codes para estados americanos (principais)
    CASE area_code
      WHEN '212', '315', '347', '516', '518', '585', '607', '631', '646', '716', '718', '845', '914', '917', '929', '934' THEN RETURN 'NY';
      WHEN '213', '310', '323', '408', '415', '510', '530', '559', '562', '619', '626', '650', '661', '707', '714', '760', '805', '818', '831', '858', '909', '916', '925', '949', '951' THEN RETURN 'CA';
      WHEN '214', '254', '281', '409', '430', '432', '469', '512', '713', '737', '806', '817', '832', '903', '915', '936', '940', '956', '972', '979' THEN RETURN 'TX';
      WHEN '239', '305', '321', '352', '386', '407', '561', '727', '754', '772', '786', '813', '850', '863', '904', '941', '954' THEN RETURN 'FL';
      WHEN '217', '224', '309', '312', '331', '618', '630', '708', '773', '815', '847', '872' THEN RETURN 'IL';
      WHEN '215', '267', '412', '484', '570', '610', '717', '724', '814', '878' THEN RETURN 'PA';
      WHEN '216', '234', '330', '419', '440', '513', '567', '614', '740', '937' THEN RETURN 'OH';
      WHEN '229', '404', '470', '478', '678', '706', '762', '770', '912' THEN RETURN 'GA';
      WHEN '231', '248', '269', '313', '517', '586', '616', '734', '810', '906', '947', '989' THEN RETURN 'MI';
      WHEN '201', '551', '609', '732', '848', '856', '862', '908', '973' THEN RETURN 'NJ';
      WHEN '252', '336', '704', '828', '910', '919', '980', '984' THEN RETURN 'NC';
      WHEN '206', '253', '360', '425', '509', '564' THEN RETURN 'WA';
      WHEN '240', '301', '410', '443', '667' THEN RETURN 'MD';
      WHEN '317', '463', '574', '765', '812', '930' THEN RETURN 'IN';
      WHEN '314', '417', '573', '636', '660', '816' THEN RETURN 'MO';
      WHEN '251', '256', '334', '938' THEN RETURN 'AL';
      WHEN '303', '719', '720', '970' THEN RETURN 'CO';
      WHEN '203', '475', '860', '959' THEN RETURN 'CT';
      WHEN '225', '318', '337', '504', '985' THEN RETURN 'LA';
      WHEN '207' THEN RETURN 'ME';
      WHEN '339', '351', '413', '508', '617', '774', '781', '857', '978' THEN RETURN 'MA';
      WHEN '228', '601', '662', '769' THEN RETURN 'MS';
      WHEN '406' THEN RETURN 'MT';
      WHEN '308', '402', '531' THEN RETURN 'NE';
      WHEN '702', '725', '775' THEN RETURN 'NV';
      WHEN '603' THEN RETURN 'NH';
      WHEN '505', '575' THEN RETURN 'NM';
      WHEN '701' THEN RETURN 'ND';
      WHEN '405', '539', '580', '918' THEN RETURN 'OK';
      WHEN '503', '541', '971' THEN RETURN 'OR';
      WHEN '401' THEN RETURN 'RI';
      WHEN '803', '843', '854', '864' THEN RETURN 'SC';
      WHEN '605' THEN RETURN 'SD';
      WHEN '423', '615', '629', '731', '865', '901', '931' THEN RETURN 'TN';
      WHEN '435', '801', '385' THEN RETURN 'UT';
      WHEN '802' THEN RETURN 'VT';
      WHEN '276', '434', '540', '571', '703', '757', '804' THEN RETURN 'VA';
      WHEN '304', '681' THEN RETURN 'WV';
      WHEN '262', '414', '534', '608', '715', '920' THEN RETURN 'WI';
      WHEN '307' THEN RETURN 'WY';
      WHEN '907' THEN RETURN 'AK';
      WHEN '808' THEN RETURN 'HI';
      ELSE RETURN NULL;
    END CASE;
  END IF;
  
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Executar migração
-- Executando migração de leads do WhatsApp para tabela contact...
INSERT INTO contact (
  name,
  phone,
  country,
  state,
  source_id,
  contact_category_id,
  created_at,
  updated_at
)
SELECT DISTINCT ON (l.phone)
  COALESCE(NULLIF(TRIM(l.name), ''), 'Contato WhatsApp') as name,
  l.phone,
  get_country_from_phone(l.phone) as country,
  get_state_from_phone(l.phone) as state,
  13 as source_id, -- WhatsApp
  12 as contact_category_id, -- Lead
  COALESCE(l.datefirst, NOW()) as created_at,
  COALESCE(l.datelast, NOW()) as updated_at
FROM leadstintim l
WHERE l.phone IS NOT NULL 
  AND l.phone != '' 
  AND TRIM(l.phone) != ''
  AND NOT EXISTS (
    SELECT 1 FROM contact c 
    WHERE c.phone = l.phone
  )
ORDER BY l.phone, l.datelast DESC NULLS LAST;

-- Verificar resultado da migração
-- Verificando resultado da migração...
SELECT 'Contatos migrados do WhatsApp:' as info, COUNT(*) as total_migrados
FROM contact 
WHERE source_id = 13;

-- Mostrar exemplos dos contatos migrados
-- Exemplos de contatos migrados:
SELECT 
  id,
  name,
  phone,
  country,
  state,
  created_at
FROM contact 
WHERE source_id = 13
ORDER BY created_at DESC
LIMIT 10;

-- Verificar distribuição por país
-- Distribuição por país:
SELECT 
  country,
  COUNT(*) as total
FROM contact 
WHERE source_id = 13
GROUP BY country
ORDER BY total DESC;

-- Verificar distribuição por estado (Brasil)
-- Distribuição por estado (Brasil):
SELECT 
  state,
  COUNT(*) as total
FROM contact 
WHERE source_id = 13 
  AND country = 'Brasil'
GROUP BY state
ORDER BY total DESC;

-- === MIGRAÇÃO CONCLUÍDA ===
-- Para executar este script:
-- psql -h localhost -U seu_usuario -d sua_database -f execute_migration.sql
--
-- Para limpar as funções criadas (opcional):
-- DROP FUNCTION IF EXISTS get_country_from_phone(TEXT);
-- DROP FUNCTION IF EXISTS get_state_from_phone(TEXT);
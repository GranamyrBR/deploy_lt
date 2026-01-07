-- =====================================================
-- SCRIPT PARA LIMPAR E CORRIGIR MIGRAÇÃO
-- =====================================================
-- Este script remove os contatos migrados do leadstintim e
-- corrige a lógica de detecção de país/estado

-- === LIMPEZA DOS DADOS MIGRADOS ===

-- Verificar quantos contatos serão removidos
SELECT 
  'Contatos que serão removidos (source_id = 13):' as info,
  COUNT(*) as total
FROM contact 
WHERE source_id = 13;

-- Remover contatos migrados do WhatsApp (leadstintim)
DELETE FROM contact 
WHERE source_id = 13;

-- Verificar se a limpeza foi bem-sucedida
SELECT 
  'Contatos restantes após limpeza:' as info,
  COUNT(*) as total
FROM contact;

-- === FUNÇÕES CORRIGIDAS ===

-- Função corrigida para extrair país do telefone
CREATE OR REPLACE FUNCTION get_country_from_phone(phone_number TEXT)
RETURNS TEXT AS $$
BEGIN
  IF phone_number IS NULL OR phone_number = '' THEN
    RETURN NULL;
  END IF;
  
  -- Remove espaços e caracteres especiais
  phone_number := REGEXP_REPLACE(phone_number, '[^0-9+]', '', 'g');
  
  -- PRIORIDADE: Verificar códigos de país explícitos primeiro
  IF phone_number LIKE '+55%' THEN
    RETURN 'Brasil';
  ELSIF phone_number LIKE '+1%' THEN
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
  END IF;
  
  -- Para números sem + explícito, analisar o padrão
  -- Telefones americanos: 11 dígitos começando com 1 E com area code americano válido, ou 10 dígitos com area codes específicos
  IF (phone_number LIKE '1%' AND LENGTH(phone_number) = 11 AND 
      SUBSTRING(phone_number FROM 2 FOR 3) IN (
        '201','202','203','205','206','207','208','209','210','212','213','214','215','216','217','218','219',
        '224','225','228','229','231','234','239','240','248','251','252','253','254','256','260','262','267',
        '269','270','276','281','301','302','303','304','305','307','308','309','310','312','313','314','315',
        '316','317','318','319','320','321','323','325','330','331','334','336','337','339','347','351','352',
        '360','361','386','401','402','404','405','406','407','408','409','410','412','413','414','415','417',
        '419','423','424','425','430','432','434','435','440','443','463','469','470','475','478','479','480',
        '484','501','502','503','504','505','507','508','509','510','512','513','515','516','517','518','520',
        '530','540','541','551','559','561','562','563','564','567','570','571','573','574','575','580','585',
        '586','601','602','603','605','606','607','608','609','610','612','614','615','616','617','618','619',
        '620','623','626','630','631','636','641','646','650','651','660','661','662','667','678','682','701',
        '702','703','704','706','707','708','712','713','714','715','716','717','718','719','720','724','725',
        '727','731','732','734','737','740','754','757','760','762','763','765','770','772','773','774','775',
        '781','785','786','801','802','803','804','805','806','808','810','812','813','814','815','816','817',
        '818','828','830','831','832','843','845','847','848','850','856','857','858','859','860','862','863',
        '864','865','870','872','878','901','903','904','906','907','908','909','910','912','913','914','915',
        '916','917','918','919','920','925','928','929','931','934','936','937','940','941','947','949','951',
        '952','954','956','970','971','972','973','978','979','980','984','985','989'
      )) OR 
     (LENGTH(phone_number) = 10 AND 
      SUBSTRING(phone_number FROM 1 FOR 3) IN (
        '201','202','203','205','206','207','208','209','210','212','213','214','215','216','217','218','219',
        '224','225','228','229','231','234','239','240','248','251','252','253','254','256','260','262','267',
        '269','270','276','281','301','302','303','304','305','307','308','309','310','312','313','314','315',
        '316','317','318','319','320','321','323','325','330','331','334','336','337','339','347','351','352',
        '360','361','386','401','402','404','405','406','407','408','409','410','412','413','414','415','417',
        '419','423','424','425','430','432','434','435','440','443','463','469','470','475','478','479','480',
        '484','501','502','503','504','505','507','508','509','510','512','513','515','516','517','518','520',
        '530','540','541','551','559','561','562','563','564','567','570','571','573','574','575','580','585',
        '586','601','602','603','605','606','607','608','609','610','612','614','615','616','617','618','619',
        '620','623','626','630','631','636','641','646','650','651','660','661','662','667','678','682','701',
        '702','703','704','706','707','708','712','713','714','715','716','717','718','719','720','724','725',
        '727','731','732','734','737','740','754','757','760','762','763','765','770','772','773','774','775',
        '781','785','786','801','802','803','804','805','806','808','810','812','813','814','815','816','817',
        '818','828','830','831','832','843','845','847','848','850','856','857','858','859','860','862','863',
        '864','865','870','872','878','901','903','904','906','907','908','909','910','912','913','914','915',
        '916','917','918','919','920','925','928','929','931','934','936','937','940','941','947','949','951',
        '952','954','956','970','971','972','973','978','979','980','984','985','989'
      )) THEN
    RETURN 'Estados Unidos';
  -- Telefones brasileiros com código 55
  ELSIF phone_number LIKE '55%' AND LENGTH(phone_number) BETWEEN 12 AND 13 THEN
    RETURN 'Brasil';
  -- Telefones brasileiros sem código de país (10-11 dígitos)
  -- Agora só exclui se foi identificado como americano acima
  ELSIF LENGTH(phone_number) BETWEEN 10 AND 11 AND 
        SUBSTRING(phone_number FROM 1 FOR 2) IN (
          '11','12','13','14','15','16','17','18','19','21','22','24','27','28',
          '31','32','33','34','35','37','38','41','42','43','44','45','46','47',
          '48','49','51','53','54','55','61','62','63','64','65','66','67','68',
          '69','71','73','74','75','77','79','81','82','83','84','85','86','87',
          '88','89','91','92','93','94','95','96','97','98','99'
        ) THEN
    RETURN 'Brasil';
  ELSE
    -- Default para Brasil se não conseguir identificar
    RETURN 'Brasil';
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Função corrigida para extrair estado do telefone
CREATE OR REPLACE FUNCTION get_state_from_phone(phone_number TEXT)
RETURNS TEXT AS $$
DECLARE
  area_code TEXT;
  clean_phone TEXT;
BEGIN
  IF phone_number IS NULL OR phone_number = '' THEN
    RETURN NULL;
  END IF;
  
  -- Remove espaços e caracteres especiais
  clean_phone := REGEXP_REPLACE(phone_number, '[^0-9]', '', 'g');
  
  -- VERIFICAR SE É PAÍS INTERNACIONAL (exceto EUA e Brasil)
  -- Se tem código de país que não seja +1 ou +55, retorna NULL
  IF phone_number LIKE '+351%' OR phone_number LIKE '+34%' OR 
     phone_number LIKE '+33%' OR phone_number LIKE '+49%' OR 
     phone_number LIKE '+44%' OR phone_number LIKE '+39%' THEN
    RETURN NULL;
  END IF;
  
  -- TELEFONES AMERICANOS (prioridade)
  -- Telefones com +1 explícito ou padrão americano específico
  IF phone_number LIKE '+1%' OR 
     (clean_phone LIKE '1%' AND LENGTH(clean_phone) = 11 AND 
      SUBSTRING(clean_phone FROM 2 FOR 3) IN (
        '201','202','203','205','206','207','208','209','210','212','213','214','215','216','217','218','219',
        '224','225','228','229','231','234','239','240','248','251','252','253','254','256','260','262','267',
        '269','270','276','281','301','302','303','304','305','307','308','309','310','312','313','314','315',
        '316','317','318','319','320','321','323','325','330','331','334','336','337','339','347','351','352',
        '360','361','386','401','402','404','405','406','407','408','409','410','412','413','414','415','417',
        '419','423','424','425','430','432','434','435','440','443','463','469','470','475','478','479','480',
        '484','501','502','503','504','505','507','508','509','510','512','513','515','516','517','518','520',
        '530','540','541','551','559','561','562','563','564','567','570','571','573','574','575','580','585',
        '586','601','602','603','605','606','607','608','609','610','612','614','615','616','617','618','619',
        '620','623','626','630','631','636','641','646','650','651','660','661','662','667','678','682','701',
        '702','703','704','706','707','708','712','713','714','715','716','717','718','719','720','724','725',
        '727','731','732','734','737','740','754','757','760','762','763','765','770','772','773','774','775',
        '781','785','786','801','802','803','804','805','806','808','810','812','813','814','815','816','817',
        '818','828','830','831','832','843','845','847','848','850','856','857','858','859','860','862','863',
        '864','865','870','872','878','901','903','904','906','907','908','909','910','912','913','914','915',
        '916','917','918','919','920','925','928','929','931','934','936','937','940','941','947','949','951',
        '952','954','956','970','971','972','973','978','979','980','984','985','989'
      )) THEN
    -- Remove código do país americano (1) se presente
    IF clean_phone LIKE '1%' AND LENGTH(clean_phone) = 11 THEN
      clean_phone := SUBSTRING(clean_phone FROM 2);
    END IF;
    
    -- Extrai area code (3 primeiros dígitos)
    area_code := SUBSTRING(clean_phone FROM 1 FOR 3);
    
    -- Mapeia area codes para estados americanos
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
  
  -- TELEFONES BRASILEIROS
  -- Remove código do país brasileiro (55) se presente
  IF clean_phone LIKE '55%' AND LENGTH(clean_phone) > 11 THEN
    clean_phone := SUBSTRING(clean_phone FROM 3);
  END IF;
  
  -- Verifica se é telefone brasileiro (10-11 dígitos)
  -- Agora só exclui se foi identificado como americano acima
  IF LENGTH(clean_phone) >= 10 AND LENGTH(clean_phone) <= 11 THEN
    
    -- Mapeia DDD para estados brasileiros
    CASE SUBSTRING(clean_phone FROM 1 FOR 2)
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
  
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

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
  
  -- Remove espaços e caracteres especiais, mantém apenas números e +
  clean_phone := REGEXP_REPLACE(phone_number, '[^0-9+]', '', 'g');
  
  -- Verifica se tem código de país
  IF clean_phone LIKE '+55%' OR clean_phone LIKE '55%' THEN
    has_country_code := TRUE;
    -- Remove código do país para formatação
    clean_phone := REGEXP_REPLACE(clean_phone, '^(\+?55)', '', 'g');
  END IF;
  
  -- Verifica se o número tem o tamanho correto (10 ou 11 dígitos)
  IF LENGTH(clean_phone) = 11 THEN
    -- Formato: (XX) XXXXX-XXXX
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
    -- Formato: (XX) XXXX-XXXX
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
    -- Retorna o número original se não conseguir formatar
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
  
  -- Remove espaços e caracteres especiais, mantém apenas números e +
  clean_phone := REGEXP_REPLACE(phone_number, '[^0-9+]', '', 'g');
  
  -- Verifica se tem código de país
  IF clean_phone LIKE '+1%' OR (clean_phone LIKE '1%' AND LENGTH(clean_phone) = 11) THEN
    has_country_code := TRUE;
    -- Remove código do país para formatação
    clean_phone := REGEXP_REPLACE(clean_phone, '^(\+?1)', '', 'g');
  END IF;
  
  -- Verifica se o número tem o tamanho correto (10 dígitos)
  IF LENGTH(clean_phone) = 10 THEN
    -- Formato: XXX-XXX-XXXX
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
    -- Retorna o número original se não conseguir formatar
    RETURN phone_number;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- === NOVA MIGRAÇÃO COM LÓGICA CORRIGIDA ===

-- Verificar quantos leads únicos temos no WhatsApp
SELECT COUNT(DISTINCT phone) as total_phones_unicos
FROM leadstintim 
WHERE phone IS NOT NULL 
  AND phone != '' 
  AND TRIM(phone) != '';

-- Executar migração com lógica corrigida
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
  CASE 
    WHEN get_country_from_phone(l.phone) = 'Brasil' THEN format_brazilian_phone(l.phone)
    WHEN get_country_from_phone(l.phone) = 'Estados Unidos' THEN format_american_phone(l.phone)
    ELSE l.phone
  END as phone,
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

-- Verificar resultado da migração corrigida
SELECT 'Contatos migrados do WhatsApp:' as info, COUNT(*) as total_migrados
FROM contact 
WHERE source_id = 13;

-- Verificar distribuição por país
SELECT 
  country,
  COUNT(*) as total
FROM contact 
WHERE source_id = 13
GROUP BY country
ORDER BY total DESC;

-- Verificar distribuição por estado (Brasil)
SELECT 
  'Estados do Brasil:' as info;
SELECT 
  state,
  COUNT(*) as total
FROM contact 
WHERE source_id = 13 
  AND country = 'Brasil'
GROUP BY state
ORDER BY total DESC;

-- Verificar distribuição por estado (EUA)
SELECT 
  'Estados dos EUA:' as info;
SELECT 
  state,
  COUNT(*) as total
FROM contact 
WHERE source_id = 13 
  AND country = 'Estados Unidos'
GROUP BY state
ORDER BY total DESC;

-- Mostrar exemplos dos contatos migrados
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
LIMIT 15;

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

-- Limpar funções auxiliares
DROP FUNCTION format_brazilian_phone(TEXT);
DROP FUNCTION format_american_phone(TEXT);

-- === MIGRAÇÃO CORRIGIDA CONCLUÍDA ===
-- Para executar este script:
-- psql -h localhost -U seu_usuario -d sua_database -f cleanup_and_fix_migration.sql
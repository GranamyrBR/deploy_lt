-- =====================================================
-- SCRIPT DE TESTE PARA LÓGICA DE TELEFONES
-- =====================================================
-- Este script testa a lógica corrigida de detecção de país e estado

-- Criar as funções de teste (mesma lógica do script principal)
CREATE OR REPLACE FUNCTION test_get_country_from_phone(phone_number TEXT)
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

CREATE OR REPLACE FUNCTION test_get_state_from_phone(phone_number TEXT)
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
    
    -- Mapeia area codes para estados americanos (apenas alguns exemplos)
    CASE area_code
      WHEN '212', '315', '347', '516', '518', '585', '607', '631', '646', '716', '718', '845', '914', '917', '929', '934' THEN RETURN 'NY';
      WHEN '213', '310', '323', '408', '415', '510', '530', '559', '562', '619', '626', '650', '661', '707', '714', '760', '805', '818', '831', '858', '909', '916', '925', '949', '951' THEN RETURN 'CA';
      WHEN '214', '254', '281', '409', '430', '432', '469', '512', '713', '737', '806', '817', '832', '903', '915', '936', '940', '956', '972', '979' THEN RETURN 'TX';
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
      ELSE RETURN NULL;
    END CASE;
  END IF;
  
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- === TESTES ===

-- Teste com telefones brasileiros de SP
SELECT 
  'Telefones de SP (DDD 11):' as teste;

SELECT 
  phone,
  test_get_country_from_phone(phone) as country,
  test_get_state_from_phone(phone) as state
FROM (
  VALUES 
    ('11987654321'),
    ('(11) 98765-4321'),
    ('11 98765-4321'),
    ('1198765-4321'),
    ('+5511987654321')
) AS test_phones(phone);

-- Teste com telefones americanos
SELECT 
  'Telefones americanos:' as teste;

SELECT 
  phone,
  test_get_country_from_phone(phone) as country,
  test_get_state_from_phone(phone) as state
FROM (
  VALUES 
    ('12125551234'),  -- NY
    ('13105551234'),  -- CA
    ('12145551234'),  -- TX
    ('+12125551234'), -- NY com +1
    ('1 212 555 1234') -- NY formatado
) AS test_phones(phone);

-- Teste com telefones brasileiros de outros estados
SELECT 
  'Telefones de outros estados do Brasil:' as teste;

SELECT 
  phone,
  test_get_country_from_phone(phone) as country,
  test_get_state_from_phone(phone) as state
FROM (
  VALUES 
    ('21987654321'),  -- RJ
    ('31987654321'),  -- MG
    ('41987654321'),  -- PR
    ('51987654321'),  -- RS
    ('+5521987654321') -- RJ com +55
) AS test_phones(phone);

-- Limpar funções de teste
DROP FUNCTION test_get_country_from_phone(TEXT);
DROP FUNCTION test_get_state_from_phone(TEXT);

-- Para executar este teste:
-- psql -h localhost -U seu_usuario -d sua_database -f test_phone_logic.sql
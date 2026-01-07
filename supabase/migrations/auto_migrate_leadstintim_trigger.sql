-- =====================================================
-- TRIGGER AUTOMÁTICO: MIGRAÇÃO LEADSTINTIM PARA CONTACT
-- =====================================================
-- Este script cria um trigger que migra automaticamente
-- dados da tabela leadstintim para contact sempre que
-- houver INSERT ou UPDATE na tabela leadstintim
--
-- CONFIGURAÇÕES:
-- - source_id: 13 (WhatsApp)
-- - account_id: 179 (Lecotour)
-- - contact_category_id: 12 (Lead)
-- - Nomes nulos preenchidos com "Contato WhatsApp"

-- ETAPA 1: CRIAR FUNÇÕES AUXILIARES PERMANENTES
SELECT 'CRIANDO FUNÇÕES AUXILIARES PARA MIGRAÇÃO AUTOMÁTICA...' as info;

-- Função para detectar país do telefone
CREATE OR REPLACE FUNCTION get_country_from_phone_auto(phone_number TEXT)
RETURNS TEXT AS $$
DECLARE
  clean_phone TEXT;
BEGIN
  IF phone_number IS NULL OR TRIM(phone_number) = '' THEN
    RETURN NULL;
  END IF;
  
  -- Remove espaços, parênteses, hífens e outros caracteres, mantendo apenas números e +
  clean_phone := REGEXP_REPLACE(phone_number, '[^0-9+]', '', 'g');
  
  -- Detectar país baseado em códigos internacionais
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
  -- Reino Unido: +44 seguido de 10 dígitos
  ELSIF clean_phone ~ '^\+44\d{10}$' OR (clean_phone ~ '^44\d{10}$' AND LENGTH(clean_phone) = 12) THEN
    RETURN 'Reino Unido';
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

-- Função para detectar estado do telefone (Brasil e EUA)
CREATE OR REPLACE FUNCTION get_state_from_phone_auto(phone_number TEXT)
RETURNS TEXT AS $$
DECLARE
  clean_phone TEXT;
  area_code TEXT;
  detected_country TEXT;
BEGIN
  IF phone_number IS NULL OR TRIM(phone_number) = '' THEN
    RETURN NULL;
  END IF;
  
  -- Verificar país do telefone
  detected_country := get_country_from_phone_auto(phone_number);
  
  -- Remove espaços, parênteses, hífens e outros caracteres, mantendo apenas números e +
  clean_phone := REGEXP_REPLACE(phone_number, '[^0-9+]', '', 'g');
  
  -- TELEFONES BRASILEIROS
  IF detected_country = 'Brasil' THEN
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
    
    -- Mapear código de área para estado brasileiro
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
  
  -- TELEFONES AMERICANOS
  ELSIF detected_country = 'Estados Unidos' THEN
    -- Extrair area code americano
    IF clean_phone ~ '^\+1\d{10}$' THEN
      -- Telefone com +1: extrair os 3 dígitos após o 1
      area_code := SUBSTRING(clean_phone FROM 3 FOR 3);
    ELSIF clean_phone ~ '^1\d{10}$' AND LENGTH(clean_phone) = 11 THEN
      -- Telefone com 1: extrair os 3 dígitos após o 1
      area_code := SUBSTRING(clean_phone FROM 2 FOR 3);
    ELSIF clean_phone ~ '^\d{10}$' AND LENGTH(clean_phone) = 10 THEN
      -- Telefone americano sem código de país: primeiros 3 dígitos
      area_code := SUBSTRING(clean_phone FROM 1 FOR 3);
    ELSE
      RETURN NULL;
    END IF;
    
    -- Mapear area codes para estados americanos (principais)
    CASE area_code
      WHEN '212', '315', '347', '516', '518', '585', '607', '631', '646', '716', '718', '845', '914', '917', '929', '934' THEN RETURN 'NY';
      WHEN '213', '310', '323', '408', '415', '510', '530', '559', '562', '619', '626', '650', '661', '707', '714', '760', '805', '818', '831', '858', '909', '916', '925', '949', '951' THEN RETURN 'CA';
      WHEN '214', '254', '281', '409', '430', '432', '469', '512', '713', '737', '806', '817', '832', '903', '915', '936', '940', '956', '972', '979' THEN RETURN 'TX';
      WHEN '239', '305', '321', '352', '386', '407', '561', '727', '754', '772', '786', '813', '850', '863', '904', '941', '954' THEN RETURN 'FL';
      WHEN '217', '224', '309', '312', '331', '618', '630', '708', '773', '815', '847', '872' THEN RETURN 'IL';
      ELSE RETURN NULL;
    END CASE;
  
  ELSE
    RETURN NULL;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Função para formatar telefone brasileiro
CREATE OR REPLACE FUNCTION format_brazilian_phone_auto(phone_number TEXT)
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
CREATE OR REPLACE FUNCTION format_american_phone_auto(phone_number TEXT)
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

-- ETAPA 2: CRIAR FUNÇÃO DO TRIGGER
CREATE OR REPLACE FUNCTION auto_migrate_leadstintim_to_contact()
RETURNS TRIGGER AS $$
DECLARE
  formatted_phone TEXT;
  detected_country TEXT;
  detected_state TEXT;
  final_name TEXT;
BEGIN
  -- Validar se o telefone é válido
  IF NEW.phone IS NULL OR TRIM(NEW.phone) = '' OR LENGTH(TRIM(NEW.phone)) < 10 THEN
    RETURN NEW;
  END IF;
  
  -- Validar se o telefone contém apenas caracteres válidos
  IF NEW.phone !~ '^[+]?[0-9\(\)\s\-]+$' THEN
    RETURN NEW;
  END IF;
  
  -- Detectar país e estado
  detected_country := get_country_from_phone_auto(NEW.phone);
  detected_state := get_state_from_phone_auto(NEW.phone);
  
  -- Formatar telefone baseado no país detectado
  CASE detected_country
    WHEN 'Brasil' THEN
      formatted_phone := format_brazilian_phone_auto(NEW.phone);
    WHEN 'Estados Unidos' THEN
      formatted_phone := format_american_phone_auto(NEW.phone);
    ELSE
      formatted_phone := NEW.phone;
  END CASE;
  
  -- Definir nome final
  IF NEW.name IS NOT NULL AND TRIM(NEW.name) != '' AND TRIM(NEW.name) != 'null' THEN
    final_name := TRIM(NEW.name);
  ELSE
    final_name := 'Contato WhatsApp';
  END IF;
  
  -- Inserir ou atualizar na tabela contact
  INSERT INTO contact (
    phone,
    name,
    country,
    state,
    source_id,
    account_id,
    contact_category_id,
    created_at,
    updated_at
  )
  VALUES (
    formatted_phone,
    final_name,
    detected_country,
    detected_state,
    13, -- WhatsApp
    179, -- Lecotour
    12, -- Lead
    COALESCE(NEW.created_at, NOW()),
    NOW()
  )
  ON CONFLICT (phone) DO UPDATE SET
    name = CASE 
      WHEN EXCLUDED.name != 'Contato WhatsApp' AND (contact.name = 'Contato WhatsApp' OR contact.name IS NULL)
      THEN EXCLUDED.name
      ELSE contact.name
    END,
    source_id = CASE 
      WHEN contact.source_id = 15 OR contact.source_id IS NULL -- 'Não rastreada'
      THEN EXCLUDED.source_id
      ELSE contact.source_id
    END,
    account_id = CASE 
      WHEN contact.account_id IS NULL
      THEN EXCLUDED.account_id
      ELSE contact.account_id
    END,
    contact_category_id = CASE 
      WHEN contact.contact_category_id IS NULL
      THEN EXCLUDED.contact_category_id
      ELSE contact.contact_category_id
    END,
    country = CASE 
      WHEN contact.country IS NULL OR contact.country = '' OR contact.country = 'Outros'
      THEN EXCLUDED.country
      ELSE contact.country
    END,
    state = CASE 
      WHEN contact.state IS NULL OR contact.state = ''
      THEN EXCLUDED.state
      ELSE contact.state
    END,
    updated_at = NOW();
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ETAPA 3: CRIAR O TRIGGER
DROP TRIGGER IF EXISTS trigger_auto_migrate_leadstintim ON leadstintim;

CREATE TRIGGER trigger_auto_migrate_leadstintim
  AFTER INSERT OR UPDATE ON leadstintim
  FOR EACH ROW
  EXECUTE FUNCTION auto_migrate_leadstintim_to_contact();

-- ETAPA 4: GARANTIR REGISTROS NECESSÁRIOS
-- Garantir que existe o source WhatsApp (id 13)
INSERT INTO source (id, name, created_at, updated_at, is_active)
SELECT 13, 'WhatsApp', NOW(), NOW(), true
WHERE NOT EXISTS (SELECT 1 FROM source WHERE id = 13);

SELECT 'TRIGGER DE MIGRAÇÃO AUTOMÁTICA CRIADO COM SUCESSO!' as resultado;
SELECT 'Agora todos os dados inseridos ou atualizados na tabela leadstintim serão automaticamente migrados para a tabela contact.' as info;

-- =====================================================
-- RESUMO DO TRIGGER AUTOMÁTICO:
-- ✅ Trigger criado para INSERT e UPDATE na tabela leadstintim
-- ✅ Migração automática para tabela contact
-- ✅ Detecção automática de país e estado
-- ✅ Formatação automática de telefones (Brasil, EUA)
-- ✅ Source configurado como WhatsApp (id 13)
-- ✅ Account configurado como Lecotour (id 179)
-- ✅ Contact Category configurado como Lead (id 12)
-- ✅ Nomes nulos preenchidos com "Contato WhatsApp"
-- ✅ UPSERT para evitar duplicatas
-- ✅ Preserva dados existentes mais específicos
-- =====================================================

-- PARA DESABILITAR O TRIGGER (se necessário):
-- DROP TRIGGER IF EXISTS trigger_auto_migrate_leadstintim ON leadstintim;
-- DROP FUNCTION IF EXISTS auto_migrate_leadstintim_to_contact();

-- PARA REMOVER AS FUNÇÕES AUXILIARES (se necessário):
-- DROP FUNCTION IF EXISTS get_country_from_phone_auto(TEXT);
-- DROP FUNCTION IF EXISTS get_state_from_phone_auto(TEXT);
-- DROP FUNCTION IF EXISTS format_brazilian_phone_auto(TEXT);
-- DROP FUNCTION IF EXISTS format_american_phone_auto(TEXT);
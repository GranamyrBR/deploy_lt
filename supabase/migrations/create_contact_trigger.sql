-- =====================================================
-- TRIGGER PARA FORMATAÇÃO AUTOMÁTICA DE NOVOS CONTATOS
-- =====================================================
-- Este trigger será executado automaticamente sempre que
-- um novo contato for inserido na tabela contact

-- =====================================================
-- 1. CRIAR FUNÇÕES DE DETECÇÃO E FORMATAÇÃO
-- =====================================================

-- Função para detectar país do telefone
CREATE OR REPLACE FUNCTION detect_country_from_phone(phone_number TEXT)
RETURNS TEXT AS $$
BEGIN
  IF phone_number IS NULL OR phone_number = '' THEN
    RETURN 'Brasil';
  END IF;
  
  -- Remove espaços e caracteres especiais
  phone_number := REGEXP_REPLACE(phone_number, '[^0-9+]', '', 'g');
  
  -- Verifica códigos de país
  IF phone_number LIKE '+55%' OR (phone_number LIKE '55%' AND LENGTH(phone_number) >= 12) THEN
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

-- Função para detectar estado brasileiro do telefone
CREATE OR REPLACE FUNCTION detect_state_from_phone(phone_number TEXT)
RETURNS TEXT AS $$
DECLARE
  clean_phone TEXT;
  area_code TEXT;
BEGIN
  IF phone_number IS NULL OR phone_number = '' THEN
    RETURN NULL;
  END IF;
  
  -- Remove caracteres especiais e espaços
  clean_phone := REGEXP_REPLACE(phone_number, '[^0-9]', '', 'g');
  
  -- Remove código do país se presente
  IF clean_phone LIKE '55%' AND LENGTH(clean_phone) >= 12 THEN
    clean_phone := SUBSTRING(clean_phone FROM 3);
  END IF;
  
  -- Extrai código de área (primeiros 2 dígitos)
  area_code := SUBSTRING(clean_phone FROM 1 FOR 2);
  
  -- Mapeia código de área para estado
  CASE area_code
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
END;
$$ LANGUAGE plpgsql;

-- Função para formatar telefone brasileiro
CREATE OR REPLACE FUNCTION format_brazilian_phone(phone_number TEXT)
RETURNS TEXT AS $$
DECLARE
  clean_phone TEXT;
BEGIN
  IF phone_number IS NULL OR phone_number = '' THEN
    RETURN phone_number;
  END IF;
  
  -- Remove caracteres especiais
  clean_phone := REGEXP_REPLACE(phone_number, '[^0-9]', '', 'g');
  
  -- Remove código do país se presente
  IF clean_phone LIKE '55%' AND LENGTH(clean_phone) >= 12 THEN
    clean_phone := SUBSTRING(clean_phone FROM 3);
  END IF;
  
  -- Formatar telefone brasileiro
  IF LENGTH(clean_phone) = 11 THEN
    -- Celular: (XX) 9XXXX-XXXX
    RETURN '+55 (' || SUBSTRING(clean_phone FROM 1 FOR 2) || ') ' || 
           SUBSTRING(clean_phone FROM 3 FOR 5) || '-' || 
           SUBSTRING(clean_phone FROM 8 FOR 4);
  ELSIF LENGTH(clean_phone) = 10 THEN
    -- Fixo: (XX) XXXX-XXXX
    RETURN '+55 (' || SUBSTRING(clean_phone FROM 1 FOR 2) || ') ' || 
           SUBSTRING(clean_phone FROM 3 FOR 4) || '-' || 
           SUBSTRING(clean_phone FROM 7 FOR 4);
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
BEGIN
  IF phone_number IS NULL OR phone_number = '' THEN
    RETURN phone_number;
  END IF;
  
  -- Remove caracteres especiais
  clean_phone := REGEXP_REPLACE(phone_number, '[^0-9]', '', 'g');
  
  -- Remove código do país se presente
  IF clean_phone LIKE '1%' AND LENGTH(clean_phone) = 11 THEN
    clean_phone := SUBSTRING(clean_phone FROM 2);
  END IF;
  
  -- Formatar telefone americano
  IF LENGTH(clean_phone) = 10 THEN
    RETURN '+1 (' || SUBSTRING(clean_phone FROM 1 FOR 3) || ') ' || 
           SUBSTRING(clean_phone FROM 4 FOR 3) || '-' || 
           SUBSTRING(clean_phone FROM 7 FOR 4);
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
BEGIN
  IF phone_number IS NULL OR phone_number = '' THEN
    RETURN phone_number;
  END IF;
  
  clean_phone := REGEXP_REPLACE(phone_number, '[^0-9]', '', 'g');
  
  IF clean_phone LIKE '351%' AND LENGTH(clean_phone) >= 12 THEN
    clean_phone := SUBSTRING(clean_phone FROM 4);
  END IF;
  
  IF LENGTH(clean_phone) = 9 THEN
    RETURN '+351 ' || SUBSTRING(clean_phone FROM 1 FOR 3) || ' ' || 
           SUBSTRING(clean_phone FROM 4 FOR 3) || ' ' || 
           SUBSTRING(clean_phone FROM 7 FOR 3);
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
BEGIN
  IF phone_number IS NULL OR phone_number = '' THEN
    RETURN phone_number;
  END IF;
  
  clean_phone := REGEXP_REPLACE(phone_number, '[^0-9]', '', 'g');
  
  IF clean_phone LIKE '34%' AND LENGTH(clean_phone) >= 11 THEN
    clean_phone := SUBSTRING(clean_phone FROM 3);
  END IF;
  
  IF LENGTH(clean_phone) = 9 THEN
    RETURN '+34 ' || SUBSTRING(clean_phone FROM 1 FOR 3) || ' ' || 
           SUBSTRING(clean_phone FROM 4 FOR 3) || ' ' || 
           SUBSTRING(clean_phone FROM 7 FOR 3);
  ELSE
    RETURN phone_number;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Função para formatar telefone francês
CREATE OR REPLACE FUNCTION format_french_phone(phone_number TEXT)
RETURNS TEXT AS $$
DECLARE
  clean_phone TEXT;
BEGIN
  IF phone_number IS NULL OR phone_number = '' THEN
    RETURN phone_number;
  END IF;
  
  clean_phone := REGEXP_REPLACE(phone_number, '[^0-9]', '', 'g');
  
  IF clean_phone LIKE '33%' AND LENGTH(clean_phone) >= 11 THEN
    clean_phone := SUBSTRING(clean_phone FROM 3);
  END IF;
  
  IF LENGTH(clean_phone) = 9 THEN
    RETURN '+33 ' || SUBSTRING(clean_phone FROM 1 FOR 1) || ' ' || 
           SUBSTRING(clean_phone FROM 2 FOR 2) || ' ' || 
           SUBSTRING(clean_phone FROM 4 FOR 2) || ' ' || 
           SUBSTRING(clean_phone FROM 6 FOR 2) || ' ' || 
           SUBSTRING(clean_phone FROM 8 FOR 2);
  ELSE
    RETURN phone_number;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Função para formatar telefone alemão
CREATE OR REPLACE FUNCTION format_german_phone(phone_number TEXT)
RETURNS TEXT AS $$
DECLARE
  clean_phone TEXT;
BEGIN
  IF phone_number IS NULL OR phone_number = '' THEN
    RETURN phone_number;
  END IF;
  
  clean_phone := REGEXP_REPLACE(phone_number, '[^0-9]', '', 'g');
  
  IF clean_phone LIKE '49%' AND LENGTH(clean_phone) >= 11 THEN
    clean_phone := SUBSTRING(clean_phone FROM 3);
  END IF;
  
  IF LENGTH(clean_phone) >= 10 THEN
    RETURN '+49 ' || SUBSTRING(clean_phone FROM 1 FOR 3) || ' ' || 
           SUBSTRING(clean_phone FROM 4);
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
  
  IF clean_phone LIKE '44%' AND LENGTH(clean_phone) >= 12 THEN
    clean_phone := SUBSTRING(clean_phone FROM 3);
  END IF;
  
  IF LENGTH(clean_phone) = 10 THEN
    RETURN '+44 ' || SUBSTRING(clean_phone FROM 1 FOR 4) || ' ' || 
           SUBSTRING(clean_phone FROM 5 FOR 3) || ' ' || 
           SUBSTRING(clean_phone FROM 8 FOR 3);
  ELSE
    RETURN phone_number;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Função para formatar telefone italiano
CREATE OR REPLACE FUNCTION format_italian_phone(phone_number TEXT)
RETURNS TEXT AS $$
DECLARE
  clean_phone TEXT;
BEGIN
  IF phone_number IS NULL OR phone_number = '' THEN
    RETURN phone_number;
  END IF;
  
  clean_phone := REGEXP_REPLACE(phone_number, '[^0-9]', '', 'g');
  
  IF clean_phone LIKE '39%' AND LENGTH(clean_phone) >= 11 THEN
    clean_phone := SUBSTRING(clean_phone FROM 3);
  END IF;
  
  IF LENGTH(clean_phone) >= 9 THEN
    RETURN '+39 ' || SUBSTRING(clean_phone FROM 1 FOR 3) || ' ' || 
           SUBSTRING(clean_phone FROM 4 FOR 3) || ' ' || 
           SUBSTRING(clean_phone FROM 7);
  ELSE
    RETURN phone_number;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 2. CRIAR FUNÇÃO DO TRIGGER
-- =====================================================

CREATE OR REPLACE FUNCTION format_new_contact()
RETURNS TRIGGER AS $$
DECLARE
  detected_country TEXT;
BEGIN
  -- Detectar país se não foi fornecido
  IF NEW.country IS NULL OR NEW.country = '' THEN
    detected_country := detect_country_from_phone(NEW.phone);
    NEW.country := detected_country;
  ELSE
    detected_country := NEW.country;
  END IF;
  
  -- Detectar estado para telefones brasileiros
  IF detected_country = 'Brasil' AND (NEW.state IS NULL OR NEW.state = '') THEN
    NEW.state := detect_state_from_phone(NEW.phone);
  END IF;
  
  -- Aplicar formatação do telefone baseada no país
  IF NEW.phone IS NOT NULL AND NEW.phone != '' THEN
    CASE detected_country
      WHEN 'Brasil' THEN
        NEW.phone := format_brazilian_phone(NEW.phone);
      WHEN 'Estados Unidos' THEN
        NEW.phone := format_american_phone(NEW.phone);
      WHEN 'Portugal' THEN
        NEW.phone := format_portuguese_phone(NEW.phone);
      WHEN 'Espanha' THEN
        NEW.phone := format_spanish_phone(NEW.phone);
      WHEN 'França' THEN
        NEW.phone := format_french_phone(NEW.phone);
      WHEN 'Alemanha' THEN
        NEW.phone := format_german_phone(NEW.phone);
      WHEN 'Reino Unido' THEN
        NEW.phone := format_uk_phone(NEW.phone);
      WHEN 'Itália' THEN
        NEW.phone := format_italian_phone(NEW.phone);
      ELSE
        -- Manter telefone original para países não mapeados
        NULL;
    END CASE;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 3. CRIAR O TRIGGER
-- =====================================================

-- Remover trigger existente se houver
DROP TRIGGER IF EXISTS format_contact_on_insert ON contact;

-- Criar novo trigger
CREATE TRIGGER format_contact_on_insert
  BEFORE INSERT ON contact
  FOR EACH ROW
  EXECUTE FUNCTION format_new_contact();

-- =====================================================
-- 4. VERIFICAÇÃO
-- =====================================================

SELECT '✅ Trigger criado com sucesso!' as status;

-- Verificar se o trigger foi criado
SELECT 
  trigger_name,
  event_object_table,
  action_timing,
  event_manipulation
FROM information_schema.triggers 
WHERE trigger_schema = 'public' 
  AND event_object_table = 'contact'
  AND trigger_name = 'format_contact_on_insert';

-- =====================================================
-- 5. TESTE DO TRIGGER (OPCIONAL)
-- =====================================================

-- Para testar o trigger, você pode inserir um contato de teste:
-- INSERT INTO contact (name, phone, email) 
-- VALUES ('Teste Trigger', '+351912345678', 'teste@email.com');
-- 
-- SELECT name, phone, country, state FROM contact WHERE name = 'Teste Trigger';
-- 
-- DELETE FROM contact WHERE name = 'Teste Trigger';

SELECT '🎯 Trigger configurado! Novos contatos serão formatados automaticamente.' as info;
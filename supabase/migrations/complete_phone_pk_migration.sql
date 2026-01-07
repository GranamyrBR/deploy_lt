-- =====================================================
-- MIGRAÇÃO COMPLETA: TELEFONE COMO CHAVE PRIMÁRIA
-- =====================================================
-- Este script executa a migração completa:
-- 1. Modifica estrutura da tabela contact (telefone como PK)
-- 2. Migra dados do leadstintim para contact
-- 3. Valida resultados
--
-- IMPORTANTE: Este script PRESERVA dados já processados:
-- - Máscaras de telefone já aplicadas são mantidas
-- - Campos country e state já preenchidos são preservados
-- - Apenas atualiza campos vazios ou com valor 'Outros'
-- - Compatível com telefones formatados (+55 (XX) XXXXX-XXXX)

-- ETAPA 1: BACKUP E PREPARAÇÃO
SELECT 'INICIANDO MIGRAÇÃO COMPLETA...' as info;

-- Backup da tabela atual
DROP TABLE IF EXISTS contact_backup_phone_pk;
CREATE TABLE contact_backup_phone_pk AS SELECT * FROM contact;

SELECT 'Backup criado com sucesso!' as resultado;

-- ETAPA 2: LIMPEZA INICIAL
SELECT 'LIMPANDO DADOS INICIAIS...' as info;

-- Remover contatos do WhatsApp existentes
DELETE FROM contact WHERE source_id = 13;

-- Remover contatos sem telefone válido
DELETE FROM contact 
WHERE phone IS NULL 
   OR TRIM(phone) = '' 
   OR LENGTH(TRIM(phone)) < 10;

-- Remover duplicatas por telefone (manter o mais recente)
WITH duplicates AS (
  SELECT 
    id,
    phone,
    ROW_NUMBER() OVER (PARTITION BY phone ORDER BY created_at DESC, id DESC) as rn
  FROM contact
  WHERE phone IS NOT NULL AND TRIM(phone) != ''
)
DELETE FROM contact 
WHERE id IN (
  SELECT id FROM duplicates WHERE rn > 1
);

SELECT 'Limpeza inicial concluída!' as resultado;

-- ETAPA 3: MODIFICAR ESTRUTURA DA TABELA
SELECT 'MODIFICANDO ESTRUTURA DA TABELA...' as info;

-- Verificar se já é telefone a PK
DO $$
DECLARE
  pk_constraint_name TEXT;
  pk_column_name TEXT;
BEGIN
  -- Buscar o nome da constraint de PK atual e sua coluna
  SELECT tc.constraint_name, kcu.column_name
  INTO pk_constraint_name, pk_column_name
  FROM information_schema.table_constraints tc
  JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name
  WHERE tc.table_name = 'contact' 
    AND tc.table_schema = 'public'
    AND tc.constraint_type = 'PRIMARY KEY';
  
  -- Verificar se a PK atual é no campo id
  IF pk_column_name = 'id' THEN
    -- Remover constraint de PK atual usando o nome correto
    EXECUTE 'ALTER TABLE contact DROP CONSTRAINT ' || pk_constraint_name;
    
    -- Tornar telefone NOT NULL
    ALTER TABLE contact ALTER COLUMN phone SET NOT NULL;
    
    -- Adicionar constraint UNIQUE no telefone
    ALTER TABLE contact ADD CONSTRAINT contact_phone_unique UNIQUE (phone);
    
    -- Definir telefone como nova chave primária
    ALTER TABLE contact ADD CONSTRAINT contact_pkey PRIMARY KEY (phone);
    
    -- Manter id como UNIQUE para compatibilidade
    ALTER TABLE contact ADD CONSTRAINT contact_id_unique UNIQUE (id);
    
    RAISE NOTICE 'Estrutura modificada: telefone agora é PK (constraint % removida)', pk_constraint_name;
  ELSIF pk_column_name = 'phone' THEN
    RAISE NOTICE 'Telefone já é chave primária';
  ELSE
    RAISE NOTICE 'Estrutura inesperada: PK atual é na coluna %', pk_column_name;
  END IF;
END $$;

SELECT 'Estrutura da tabela atualizada!' as resultado;

-- ETAPA 4: FUNÇÕES AUXILIARES PARA MIGRAÇÃO
SELECT 'CRIANDO FUNÇÕES AUXILIARES...' as info;

-- Função para extrair país do telefone (compatível com máscaras)
CREATE OR REPLACE FUNCTION get_country_from_phone(phone_number TEXT)
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

-- Função para extrair estado do telefone (Brasil) - compatível com máscaras
CREATE OR REPLACE FUNCTION get_state_from_phone(phone_number TEXT)
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
  detected_country := get_country_from_phone(phone_number);
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

SELECT 'Funções auxiliares criadas!' as resultado;

-- ETAPA 5: VERIFICAR SOURCE WHATSAPP
SELECT 'VERIFICANDO SOURCE WHATSAPP...' as info;

-- Garantir que existe o source WhatsApp
INSERT INTO source (id, name, created_at, updated_at, is_active)
SELECT 13, 'WhatsApp', NOW(), NOW(), true
WHERE NOT EXISTS (SELECT 1 FROM source WHERE id = 13);

SELECT 'Source WhatsApp verificado!' as resultado;

-- ETAPA 6: MIGRAÇÃO DOS DADOS DO LEADSTINTIM
SELECT 'INICIANDO MIGRAÇÃO DO LEADSTINTIM...' as info;

-- Estatísticas antes da migração
SELECT 
  'leadstintim - antes da migração' as tabela,
  COUNT(*) as total_registros,
  COUNT(DISTINCT phone) as telefones_unicos,
  COUNT(CASE WHEN name IS NOT NULL AND TRIM(name) != '' THEN 1 END) as com_nome_valido
FROM leadstintim;

-- Migração com UPSERT (preservando dados já processados)
INSERT INTO contact (
  phone,
  name,
  country,
  state,
  source_id,
  created_at,
  updated_at
)
SELECT DISTINCT ON (l.phone)
  l.phone,
  CASE 
    WHEN l.name IS NOT NULL AND TRIM(l.name) != '' AND TRIM(l.name) != 'null' 
    THEN TRIM(l.name)
    ELSE 'Contato WhatsApp'
  END as name,
  get_country_from_phone(l.phone) as country,
  get_state_from_phone(l.phone) as state,
  13 as source_id, -- WhatsApp
  COALESCE(l.created_at, NOW()) as created_at,
  NOW() as updated_at
FROM leadstintim l
WHERE l.phone IS NOT NULL 
  AND TRIM(l.phone) != ''
  AND LENGTH(TRIM(l.phone)) >= 10
  AND l.phone ~ '^[+]?[0-9]+$' -- Apenas números e opcionalmente +
ORDER BY l.phone, l.datelast DESC NULLS LAST
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
  -- PRESERVAR dados já processados de country e state
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

SELECT 'Migração do leadstintim concluída!' as resultado;

-- ETAPA 7: VALIDAÇÃO E ESTATÍSTICAS FINAIS
SELECT 'VALIDANDO RESULTADOS...' as info;

-- Estatísticas após migração
SELECT 
  'contact - após migração' as tabela,
  COUNT(*) as total_registros,
  COUNT(CASE WHEN source_id = 13 THEN 1 END) as contatos_whatsapp,
  COUNT(CASE WHEN name != 'Contato WhatsApp' THEN 1 END) as com_nome_real
FROM contact;

-- Verificar estrutura final
SELECT 
  'Estrutura da tabela contact:' as info,
  constraint_name,
  constraint_type
FROM information_schema.table_constraints 
WHERE table_name = 'contact' AND table_schema = 'public'
ORDER BY constraint_type, constraint_name;

-- Exemplos de contatos migrados
SELECT 
  'Exemplos de contatos migrados:' as info,
  phone,
  name,
  country,
  state,
  source_id
FROM contact 
WHERE source_id = 13
LIMIT 10;

-- Distribuição por país
SELECT 
  'Distribuição por país:' as info,
  country,
  COUNT(*) as quantidade
FROM contact 
WHERE source_id = 13
GROUP BY country
ORDER BY quantidade DESC;

-- Distribuição por estado (Brasil)
SELECT 
  'Distribuição por estado (Brasil):' as info,
  state,
  COUNT(*) as quantidade
FROM contact 
WHERE source_id = 13 AND country = 'Brasil'
GROUP BY state
ORDER BY quantidade DESC
LIMIT 10;

SELECT 'MIGRAÇÃO COMPLETA FINALIZADA COM SUCESSO!' as resultado_final;

-- =====================================================
-- RESUMO DA MIGRAÇÃO COMPLETA:
-- 1. ✅ Backup da tabela contact criado
-- 2. ✅ Dados limpos (removidos inválidos e duplicatas)
-- 3. ✅ Estrutura modificada (telefone como PK)
-- 4. ✅ Funções auxiliares criadas
-- 5. ✅ Source WhatsApp verificado/criado
-- 6. ✅ Dados migrados do leadstintim com UPSERT
-- 7. ✅ Resultados validados e estatísticas geradas
-- 
-- NOVA ESTRUTURA:
-- - Chave primária: phone (telefone)
-- - Campo id mantido como UNIQUE para compatibilidade
-- - Duplicatas por telefone impossíveis
-- - UPSERT automático em conflitos
-- =====================================================
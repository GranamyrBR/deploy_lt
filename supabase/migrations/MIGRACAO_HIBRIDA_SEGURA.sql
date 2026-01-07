-- =====================================================
-- MIGRAÇÃO HÍBRIDA SEGURA - PRESERVANDO LEADSTINTIM
-- =====================================================
-- Estratégia que mantém leadstintim para webhooks/APIs
-- e implementa contact_unified para o app Flutter
--
-- AUTOR: AI Assistant - Especialista em Modelagem de Dados
-- DATA: 2024
-- VERSÃO: 1.0 - Migração Segura

-- =====================================================
-- ANÁLISE DO PROBLEMA
-- =====================================================
/*
PROBLEMA IDENTIFICADO:
- leadstintim recebe webhooks do N8N
- leadstintim é usado por outras APIs
- Não podemos alterar/remover leadstintim sem quebrar integrações

SOLUÇÃO HÍBRIDA:
1. Manter leadstintim intacta (webhooks/APIs continuam funcionando)
2. Criar contact_unified para o app Flutter
3. Sincronização automática via triggers
4. Migração gradual e reversível
*/

-- =====================================================
-- FASE 1: CRIAÇÃO DA TABELA UNIFICADA
-- =====================================================

SELECT 'INICIANDO MIGRAÇÃO HÍBRIDA SEGURA...' as info;

-- Criar contact_unified sem afetar leadstintim
CREATE TABLE IF NOT EXISTS public.contact_unified (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  phone VARCHAR(20) NOT NULL UNIQUE, -- Chave de negócio
  name VARCHAR(255),
  email VARCHAR(255),
  country VARCHAR(100),
  state VARCHAR(100),
  city VARCHAR(100),
  address TEXT,
  postal_code VARCHAR(20),
  gender VARCHAR(20),
  
  -- Metadados de lead
  user_type user_type_enum DEFAULT 'normal',
  is_vip BOOLEAN DEFAULT false,
  lead_score INTEGER DEFAULT 0,
  lead_status VARCHAR(50) DEFAULT 'new', -- new, qualified, converted, lost
  
  -- Relacionamentos
  account_id INTEGER REFERENCES account(id),
  source_id INTEGER REFERENCES source(id) DEFAULT 13, -- WhatsApp
  contact_category_id INTEGER REFERENCES contact_category(id) DEFAULT 12, -- Lead
  
  -- Timestamps
  first_contact_at TIMESTAMP WITH TIME ZONE,
  last_contact_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Rastreamento de origem
  migrated_from_contact BOOLEAN DEFAULT false,
  migrated_from_leadstintim BOOLEAN DEFAULT false,
  last_sync_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices essenciais
CREATE INDEX IF NOT EXISTS idx_contact_unified_phone ON contact_unified(phone);
CREATE INDEX IF NOT EXISTS idx_contact_unified_user_type ON contact_unified(user_type);
CREATE INDEX IF NOT EXISTS idx_contact_unified_last_sync ON contact_unified(last_sync_at DESC);

SELECT 'CONTACT_UNIFIED CRIADA COM SUCESSO' as info;

-- =====================================================
-- FASE 2: MIGRAÇÃO INICIAL DOS DADOS
-- =====================================================

-- Migrar dados da tabela contact primeiro
INSERT INTO contact_unified (
  phone, name, email, country, state, city, address, postal_code, gender,
  user_type, account_id, source_id, contact_category_id,
  created_at, updated_at, migrated_from_contact
)
SELECT DISTINCT
  phone,
  name,
  email,
  country,
  state,
  city,
  address,
  postal_code,
  gender,
  COALESCE(user_type, 'normal'::user_type_enum),
  account_id,
  COALESCE(source_id, 13), -- WhatsApp como padrão
  COALESCE(contact_category_id, 12), -- Lead como padrão
  created_at,
  updated_at,
  true
FROM contact
WHERE phone IS NOT NULL 
  AND TRIM(phone) != ''
ON CONFLICT (phone) DO NOTHING;

SELECT 'DADOS DA TABELA CONTACT MIGRADOS' as info;

-- Migrar dados únicos da leadstintim (que não existem em contact)
INSERT INTO contact_unified (
  phone, name, account_id, source_id, contact_category_id,
  first_contact_at, last_contact_at, created_at, migrated_from_leadstintim
)
SELECT DISTINCT
  phone,
  COALESCE(NULLIF(TRIM(name), ''), 'Contato WhatsApp'),
  1, -- Lecotour account_id
  13, -- WhatsApp source_id
  12, -- Lead contact_category_id
  MIN(created_at) as first_contact_at,
  MAX(created_at) as last_contact_at,
  MIN(created_at) as created_at,
  true
FROM leadstintim
WHERE phone IS NOT NULL 
  AND TRIM(phone) != ''
  AND phone NOT IN (SELECT phone FROM contact_unified)
GROUP BY phone, name
ON CONFLICT (phone) DO NOTHING;

SELECT 'DADOS ÚNICOS DA LEADSTINTIM MIGRADOS' as info;

-- =====================================================
-- FASE 3: TRIGGERS DE SINCRONIZAÇÃO AUTOMÁTICA
-- =====================================================

-- Função para sincronizar leadstintim -> contact_unified
CREATE OR REPLACE FUNCTION sync_leadstintim_to_unified()
RETURNS TRIGGER AS $$
BEGIN
  -- Inserir ou atualizar em contact_unified
  INSERT INTO contact_unified (
    phone, name, account_id, source_id, contact_category_id,
    last_contact_at, updated_at, migrated_from_leadstintim, last_sync_at
  )
  VALUES (
    NEW.phone,
    COALESCE(NULLIF(TRIM(NEW.name), ''), 'Contato WhatsApp'),
    1, -- Lecotour
    13, -- WhatsApp
    12, -- Lead
    NEW.created_at,
    NOW(),
    true,
    NOW()
  )
  ON CONFLICT (phone) DO UPDATE SET
    last_contact_at = GREATEST(contact_unified.last_contact_at, NEW.created_at),
    updated_at = NOW(),
    last_sync_at = NOW();
    
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para sincronização automática
DROP TRIGGER IF EXISTS trigger_sync_leadstintim_to_unified ON leadstintim;
CREATE TRIGGER trigger_sync_leadstintim_to_unified
  AFTER INSERT OR UPDATE ON leadstintim
  FOR EACH ROW
  EXECUTE FUNCTION sync_leadstintim_to_unified();

SELECT 'TRIGGERS DE SINCRONIZAÇÃO CRIADOS' as info;

-- =====================================================
-- FASE 4: FUNÇÃO DE BUSCA OTIMIZADA
-- =====================================================

-- Função para buscar contatos na tabela unificada
CREATE OR REPLACE FUNCTION search_contact_by_phone_unified(phone_input TEXT)
RETURNS TABLE(
  id BIGINT,
  phone VARCHAR(20),
  name VARCHAR(255),
  email VARCHAR(255),
  user_type user_type_enum,
  country VARCHAR(100),
  state VARCHAR(100),
  created_at TIMESTAMP WITH TIME ZONE
) AS $$
DECLARE
  normalized_phone TEXT;
  phone_variations TEXT[];
BEGIN
  -- Normalizar telefone de entrada
  normalized_phone := REGEXP_REPLACE(phone_input, '[^0-9]', '', 'g');
  
  -- Criar variações do telefone
  phone_variations := ARRAY[
    normalized_phone,
    '+55' || normalized_phone,
    '55' || normalized_phone
  ];
  
  -- Busca exata primeiro
  RETURN QUERY
  SELECT cu.id, cu.phone, cu.name, cu.email, cu.user_type, cu.country, cu.state, cu.created_at
  FROM contact_unified cu
  WHERE REGEXP_REPLACE(cu.phone, '[^0-9]', '', 'g') = ANY(phone_variations)
  LIMIT 1;
  
  -- Se não encontrou, busca flexível
  IF NOT FOUND THEN
    RETURN QUERY
    SELECT cu.id, cu.phone, cu.name, cu.email, cu.user_type, cu.country, cu.state, cu.created_at
    FROM contact_unified cu
    WHERE REGEXP_REPLACE(cu.phone, '[^0-9]', '', 'g') LIKE '%' || RIGHT(normalized_phone, 8) || '%'
    LIMIT 1;
  END IF;
END;
$$ LANGUAGE plpgsql;

SELECT 'FUNÇÃO DE BUSCA CRIADA' as info;

-- =====================================================
-- FASE 5: VIEWS DE COMPATIBILIDADE (OPCIONAL)
-- =====================================================

-- View para manter compatibilidade com queries antigas da tabela contact
CREATE OR REPLACE VIEW contact_legacy_view AS
SELECT 
  id,
  phone,
  name,
  email,
  country,
  state,
  city,
  address,
  postal_code,
  gender,
  user_type,
  account_id,
  source_id,
  contact_category_id,
  created_at,
  updated_at
FROM contact_unified
WHERE migrated_from_contact = true;

SELECT 'VIEWS DE COMPATIBILIDADE CRIADAS' as info;

-- =====================================================
-- FASE 6: VALIDAÇÃO E ESTATÍSTICAS
-- =====================================================

-- Estatísticas da migração
SELECT 
  'ESTATÍSTICAS DA MIGRAÇÃO' as info,
  (
    SELECT COUNT(*) FROM contact_unified WHERE migrated_from_contact = true
  ) as contatos_migrados_de_contact,
  (
    SELECT COUNT(*) FROM contact_unified WHERE migrated_from_leadstintim = true
  ) as contatos_migrados_de_leadstintim,
  (
    SELECT COUNT(*) FROM contact_unified
  ) as total_contact_unified,
  (
    SELECT COUNT(*) FROM contact
  ) as total_contact_original,
  (
    SELECT COUNT(*) FROM leadstintim
  ) as total_leadstintim_preservada;

-- =====================================================
-- PRÓXIMOS PASSOS
-- =====================================================
/*
PRÓXIMOS PASSOS PARA IMPLEMENTAÇÃO:

1. EXECUTAR ESTE SCRIPT:
   - Cria contact_unified
   - Migra dados existentes
   - Configura sincronização automática
   - leadstintim permanece intacta

2. ATUALIZAR FLUTTER APP:
   - ContactsService usa contact_unified
   - Webhooks continuam usando leadstintim
   - Sincronização automática via triggers

3. TESTES:
   - Verificar se webhooks funcionam normalmente
   - Testar app Flutter com contact_unified
   - Validar sincronização automática

4. ROLLBACK (SE NECESSÁRIO):
   - Reverter ContactsService para tabela contact
   - Remover triggers e contact_unified
   - Zero impacto nas integrações externas

VANTAGENS DESTA ABORDAGEM:
✅ leadstintim preservada (webhooks/APIs funcionam)
✅ contact_unified otimizada para Flutter
✅ Sincronização automática
✅ Migração reversível
✅ Zero downtime
✅ Implementação gradual
*/

SELECT 'MIGRAÇÃO HÍBRIDA CONCLUÍDA COM SUCESSO!' as info;
SELECT 'leadstintim PRESERVADA - Webhooks e APIs continuam funcionando' as info;
SELECT 'contact_unified CRIADA - App Flutter otimizado' as info;
SELECT 'Sincronização automática ATIVA' as info;
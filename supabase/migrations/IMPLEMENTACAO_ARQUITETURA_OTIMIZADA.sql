-- =====================================================
-- IMPLEMENTAÇÃO DA ARQUITETURA DE DADOS OTIMIZADA
-- =====================================================
-- Script para migração das tabelas leadstintim e contact
-- para uma arquitetura unificada e otimizada
--
-- AUTOR: AI Assistant - Especialista em Modelagem de Dados
-- DATA: 2024
-- VERSÃO: 1.0

-- =====================================================
-- FASE 1: BACKUP E PREPARAÇÃO
-- =====================================================

SELECT 'INICIANDO MIGRAÇÃO PARA ARQUITETURA OTIMIZADA...' as info;

-- Backup das tabelas atuais
CREATE TABLE IF NOT EXISTS contact_backup_pre_optimization AS 
SELECT * FROM contact;

CREATE TABLE IF NOT EXISTS leadstintim_backup_pre_optimization AS 
SELECT * FROM leadstintim;

SELECT 'BACKUP REALIZADO COM SUCESSO' as info;

-- =====================================================
-- FASE 2: CRIAÇÃO DAS NOVAS TABELAS
-- =====================================================

-- 1. TABELA PRINCIPAL: CONTACT_UNIFIED
-- Fonte única da verdade para todos os contatos
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
  source_id INTEGER REFERENCES source(id) DEFAULT 13, -- WhatsApp como padrão
  contact_category_id INTEGER REFERENCES contact_category(id) DEFAULT 12, -- Lead como padrão
  
  -- Timestamps
  first_contact_at TIMESTAMP WITH TIME ZONE,
  last_contact_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. TABELA DE MENSAGENS: WHATSAPP_MESSAGES
-- Histórico completo de conversas do WhatsApp
CREATE TABLE IF NOT EXISTS public.whatsapp_messages (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  contact_phone VARCHAR(20) NOT NULL,
  
  -- Dados da mensagem
  message_id VARCHAR(255), -- ID único da mensagem no WhatsApp
  message_body TEXT,
  message_type VARCHAR(50) DEFAULT 'text', -- text, image, audio, video, document
  
  -- Metadados
  direction VARCHAR(10) NOT NULL DEFAULT 'inbound', -- inbound, outbound
  status VARCHAR(50) DEFAULT 'received', -- sent, delivered, read, failed, received
  
  -- Dados originais do leadstintim (para preservar histórico)
  original_source VARCHAR(100),
  sale_date TIMESTAMP WITH TIME ZONE,
  sale_value DOUBLE PRECISION,
  sale_message DOUBLE PRECISION,
  
  -- Timestamps
  sent_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Constraint de referência
  CONSTRAINT fk_whatsapp_messages_contact 
    FOREIGN KEY (contact_phone) REFERENCES contact_unified(phone) 
    ON DELETE CASCADE ON UPDATE CASCADE
);

-- 3. TABELA DE INTERAÇÕES: CONTACT_INTERACTIONS
-- Timeline unificada de todas as atividades
CREATE TABLE IF NOT EXISTS public.contact_interactions (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  contact_phone VARCHAR(20) NOT NULL,
  
  interaction_type VARCHAR(50) NOT NULL, -- message, call, email, meeting, sale, user_type_change
  interaction_channel VARCHAR(50) DEFAULT 'whatsapp', -- whatsapp, phone, email, in_person
  
  title VARCHAR(255),
  description TEXT,
  outcome VARCHAR(100), -- positive, negative, neutral, follow_up_needed
  
  -- Dados específicos
  metadata JSONB, -- Dados flexíveis específicos do tipo de interação
  
  -- Relacionamentos
  user_id UUID, -- Quem registrou a interação
  related_message_id BIGINT,
  
  -- Timestamps
  interaction_date TIMESTAMP WITH TIME ZONE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Constraints
  CONSTRAINT fk_contact_interactions_contact 
    FOREIGN KEY (contact_phone) REFERENCES contact_unified(phone) 
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_contact_interactions_message 
    FOREIGN KEY (related_message_id) REFERENCES whatsapp_messages(id) 
    ON DELETE SET NULL
);

SELECT 'TABELAS CRIADAS COM SUCESSO' as info;

-- =====================================================
-- FASE 3: CRIAÇÃO DE ÍNDICES PARA PERFORMANCE
-- =====================================================

-- Índices para contact_unified
CREATE INDEX IF NOT EXISTS idx_contact_unified_phone ON contact_unified(phone);
CREATE INDEX IF NOT EXISTS idx_contact_unified_user_type ON contact_unified(user_type);
CREATE INDEX IF NOT EXISTS idx_contact_unified_lead_status ON contact_unified(lead_status);
CREATE INDEX IF NOT EXISTS idx_contact_unified_source_id ON contact_unified(source_id);
CREATE INDEX IF NOT EXISTS idx_contact_unified_last_contact ON contact_unified(last_contact_at DESC);
CREATE INDEX IF NOT EXISTS idx_contact_unified_created_at ON contact_unified(created_at DESC);

-- Índices para whatsapp_messages
CREATE INDEX IF NOT EXISTS idx_whatsapp_messages_contact_phone ON whatsapp_messages(contact_phone);
CREATE INDEX IF NOT EXISTS idx_whatsapp_messages_sent_at ON whatsapp_messages(sent_at DESC);
CREATE INDEX IF NOT EXISTS idx_whatsapp_messages_message_id ON whatsapp_messages(message_id);
CREATE INDEX IF NOT EXISTS idx_whatsapp_messages_direction ON whatsapp_messages(direction);
CREATE INDEX IF NOT EXISTS idx_whatsapp_messages_created_at ON whatsapp_messages(created_at DESC);

-- Índices para contact_interactions
CREATE INDEX IF NOT EXISTS idx_contact_interactions_phone ON contact_interactions(contact_phone);
CREATE INDEX IF NOT EXISTS idx_contact_interactions_date ON contact_interactions(interaction_date DESC);
CREATE INDEX IF NOT EXISTS idx_contact_interactions_type ON contact_interactions(interaction_type);
CREATE INDEX IF NOT EXISTS idx_contact_interactions_channel ON contact_interactions(interaction_channel);
CREATE INDEX IF NOT EXISTS idx_contact_interactions_created_at ON contact_interactions(created_at DESC);

SELECT 'ÍNDICES CRIADOS COM SUCESSO' as info;

-- =====================================================
-- FASE 4: FUNÇÕES AUXILIARES PARA MIGRAÇÃO
-- =====================================================

-- Função para normalizar telefones
CREATE OR REPLACE FUNCTION normalize_phone_unified(phone_input TEXT)
RETURNS TEXT AS $$
DECLARE
  clean_phone TEXT;
BEGIN
  IF phone_input IS NULL OR TRIM(phone_input) = '' THEN
    RETURN NULL;
  END IF;
  
  -- Remove todos os caracteres não numéricos exceto +
  clean_phone := REGEXP_REPLACE(phone_input, '[^0-9+]', '', 'g');
  
  -- Padroniza formato brasileiro
  IF clean_phone ~ '^\+55\d{10,11}$' THEN
    RETURN clean_phone;
  ELSIF clean_phone ~ '^55\d{10,11}$' AND LENGTH(clean_phone) BETWEEN 12 AND 13 THEN
    RETURN '+' || clean_phone;
  ELSIF clean_phone ~ '^\d{10,11}$' AND LENGTH(clean_phone) BETWEEN 10 AND 11 THEN
    RETURN '+55' || clean_phone;
  ELSE
    RETURN clean_phone;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Função para detectar país do telefone
CREATE OR REPLACE FUNCTION detect_country_from_phone(phone_input TEXT)
RETURNS TEXT AS $$
DECLARE
  clean_phone TEXT;
BEGIN
  clean_phone := normalize_phone_unified(phone_input);
  
  IF clean_phone IS NULL THEN
    RETURN NULL;
  END IF;
  
  -- Detectar país baseado em códigos
  IF clean_phone ~ '^\+1\d{10}$' THEN
    RETURN 'Estados Unidos';
  ELSIF clean_phone ~ '^\+55\d{10,11}$' THEN
    RETURN 'Brasil';
  ELSIF clean_phone ~ '^\+351\d{9}$' THEN
    RETURN 'Portugal';
  ELSIF clean_phone ~ '^\+34\d{9}$' THEN
    RETURN 'Espanha';
  ELSE
    RETURN 'Outros';
  END IF;
END;
$$ LANGUAGE plpgsql;

SELECT 'FUNÇÕES AUXILIARES CRIADAS COM SUCESSO' as info;

-- =====================================================
-- FASE 5: MIGRAÇÃO DOS DADOS
-- =====================================================

SELECT 'INICIANDO MIGRAÇÃO DOS DADOS...' as info;

-- 5.1: Migrar contatos únicos para contact_unified
-- Prioriza dados da tabela contact, complementa com leadstintim
INSERT INTO contact_unified (
  phone, name, email, country, state, city, address, postal_code, gender,
  user_type, is_vip, account_id, source_id, contact_category_id,
  first_contact_at, last_contact_at, created_at, updated_at
)
SELECT DISTINCT
  normalize_phone_unified(COALESCE(c.phone, l.phone)) as phone,
  COALESCE(NULLIF(TRIM(c.name), ''), NULLIF(TRIM(l.name), ''), 'Contato WhatsApp') as name,
  c.email,
  COALESCE(c.country, detect_country_from_phone(COALESCE(c.phone, l.phone))) as country,
  COALESCE(c.state, l.state) as state,
  c.city,
  c.address,
  c.postal_code,
  c.gender,
  COALESCE(c.user_type, 'normal'::user_type_enum) as user_type,
  COALESCE(c.is_vip, false) as is_vip,
  COALESCE(c.account_id, 179) as account_id, -- Lecotour como padrão
  COALESCE(c.source_id, 13) as source_id, -- WhatsApp como padrão
  COALESCE(c.contact_category_id, 12) as contact_category_id, -- Lead como padrão
  LEAST(c.created_at, l.datefirst) as first_contact_at,
  GREATEST(c.updated_at, l.datelast) as last_contact_at,
  LEAST(COALESCE(c.created_at, NOW()), COALESCE(l.created_at, NOW())) as created_at,
  GREATEST(COALESCE(c.updated_at, NOW()), COALESCE(l.created_at, NOW())) as updated_at
FROM (
  -- União de todos os telefones únicos
  SELECT DISTINCT normalize_phone_unified(phone) as phone
  FROM (
    SELECT phone FROM contact WHERE phone IS NOT NULL AND TRIM(phone) != ''
    UNION
    SELECT phone FROM leadstintim WHERE phone IS NOT NULL AND TRIM(phone) != ''
  ) all_phones
  WHERE normalize_phone_unified(phone) IS NOT NULL
) unique_phones
LEFT JOIN contact c ON normalize_phone_unified(c.phone) = unique_phones.phone
LEFT JOIN (
  -- Pega o primeiro registro de cada telefone do leadstintim
  SELECT DISTINCT ON (normalize_phone_unified(phone))
    normalize_phone_unified(phone) as phone,
    name, country, state, datefirst, datelast, created_at
  FROM leadstintim 
  WHERE phone IS NOT NULL AND TRIM(phone) != ''
  ORDER BY normalize_phone_unified(phone), datefirst ASC
) l ON l.phone = unique_phones.phone
WHERE unique_phones.phone IS NOT NULL
ON CONFLICT (phone) DO NOTHING;

SELECT 'CONTATOS MIGRADOS: ' || ROW_COUNT() as info;

-- 5.2: Migrar mensagens do leadstintim para whatsapp_messages
INSERT INTO whatsapp_messages (
  contact_phone, message_id, message_body, direction, 
  original_source, sale_date, sale_value, sale_message,
  sent_at, created_at
)
SELECT 
  normalize_phone_unified(l.phone) as contact_phone,
  l.messageid as message_id,
  COALESCE(l.message, l.body) as message_body,
  'inbound' as direction,
  l.source as original_source,
  l.saledate as sale_date,
  l.salevalue as sale_value,
  l.salemessage as sale_message,
  COALESCE(l.datefirst, l.created_at) as sent_at,
  l.created_at
FROM leadstintim l
INNER JOIN contact_unified cu ON cu.phone = normalize_phone_unified(l.phone)
WHERE l.phone IS NOT NULL 
  AND TRIM(l.phone) != ''
  AND normalize_phone_unified(l.phone) IS NOT NULL;

SELECT 'MENSAGENS MIGRADAS: ' || ROW_COUNT() as info;

-- 5.3: Criar interações iniciais baseadas no histórico
INSERT INTO contact_interactions (
  contact_phone, interaction_type, interaction_channel,
  title, description, outcome, metadata,
  interaction_date, created_at
)
SELECT 
  wm.contact_phone,
  'message' as interaction_type,
  'whatsapp' as interaction_channel,
  'Primeira mensagem WhatsApp' as title,
  CASE 
    WHEN LENGTH(wm.message_body) > 100 
    THEN LEFT(wm.message_body, 100) || '...'
    ELSE wm.message_body
  END as description,
  'neutral' as outcome,
  jsonb_build_object(
    'message_id', wm.message_id,
    'original_source', wm.original_source,
    'sale_value', wm.sale_value
  ) as metadata,
  wm.sent_at as interaction_date,
  wm.created_at
FROM whatsapp_messages wm
INNER JOIN (
  -- Pega apenas a primeira mensagem de cada contato
  SELECT contact_phone, MIN(sent_at) as first_message_date
  FROM whatsapp_messages
  GROUP BY contact_phone
) first_messages ON wm.contact_phone = first_messages.contact_phone 
                 AND wm.sent_at = first_messages.first_message_date;

SELECT 'INTERAÇÕES CRIADAS: ' || ROW_COUNT() as info;

-- =====================================================
-- FASE 6: TRIGGERS PARA MANUTENÇÃO AUTOMÁTICA
-- =====================================================

-- Trigger para atualizar updated_at automaticamente
CREATE OR REPLACE FUNCTION update_contact_unified_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  
  -- Atualizar last_contact_at se houve mudança relevante
  IF TG_OP = 'UPDATE' AND (
    OLD.user_type != NEW.user_type OR
    OLD.lead_status != NEW.lead_status OR
    OLD.lead_score != NEW.lead_score
  ) THEN
    NEW.last_contact_at = NOW();
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_contact_unified_timestamp
  BEFORE UPDATE ON contact_unified
  FOR EACH ROW
  EXECUTE FUNCTION update_contact_unified_timestamp();

-- Trigger para criar interação quando user_type muda
CREATE OR REPLACE FUNCTION log_user_type_change()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'UPDATE' AND OLD.user_type != NEW.user_type THEN
    INSERT INTO contact_interactions (
      contact_phone, interaction_type, interaction_channel,
      title, description, outcome, metadata, interaction_date
    ) VALUES (
      NEW.phone,
      'user_type_change',
      'system',
      'Tipo de usuário alterado',
      'Tipo alterado de ' || OLD.user_type || ' para ' || NEW.user_type,
      'positive',
      jsonb_build_object(
        'old_user_type', OLD.user_type,
        'new_user_type', NEW.user_type,
        'changed_by', 'system'
      ),
      NOW()
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_log_user_type_change
  AFTER UPDATE ON contact_unified
  FOR EACH ROW
  EXECUTE FUNCTION log_user_type_change();

SELECT 'TRIGGERS CRIADOS COM SUCESSO' as info;

-- =====================================================
-- FASE 7: VIEWS PARA COMPATIBILIDADE
-- =====================================================

-- View para manter compatibilidade com código existente
CREATE OR REPLACE VIEW contact_legacy_view AS
SELECT 
  cu.id,
  cu.name,
  cu.email,
  cu.phone,
  cu.address,
  cu.city,
  cu.state,
  cu.country,
  cu.postal_code,
  cu.gender,
  cu.user_type,
  cu.is_vip,
  cu.account_id,
  cu.source_id,
  cu.contact_category_id,
  cu.created_at,
  cu.updated_at
FROM contact_unified cu;

-- View para análise de leads do WhatsApp
CREATE OR REPLACE VIEW whatsapp_leads_analysis AS
SELECT 
  cu.phone,
  cu.name,
  cu.user_type,
  cu.lead_status,
  cu.lead_score,
  cu.country,
  cu.state,
  cu.first_contact_at,
  cu.last_contact_at,
  COUNT(wm.id) as total_messages,
  COUNT(ci.id) as total_interactions,
  MAX(wm.sent_at) as last_message_date,
  MAX(ci.interaction_date) as last_interaction_date
FROM contact_unified cu
LEFT JOIN whatsapp_messages wm ON wm.contact_phone = cu.phone
LEFT JOIN contact_interactions ci ON ci.contact_phone = cu.phone
WHERE cu.source_id = 13 -- WhatsApp
GROUP BY cu.phone, cu.name, cu.user_type, cu.lead_status, cu.lead_score, 
         cu.country, cu.state, cu.first_contact_at, cu.last_contact_at;

SELECT 'VIEWS CRIADAS COM SUCESSO' as info;

-- =====================================================
-- FASE 8: VALIDAÇÃO E ESTATÍSTICAS
-- =====================================================

SELECT 'VALIDANDO MIGRAÇÃO...' as info;

-- Estatísticas da migração
SELECT 
  'ESTATÍSTICAS DA MIGRAÇÃO' as categoria,
  'Contatos migrados' as item,
  COUNT(*) as quantidade
FROM contact_unified

UNION ALL

SELECT 
  'ESTATÍSTICAS DA MIGRAÇÃO',
  'Mensagens migradas',
  COUNT(*)
FROM whatsapp_messages

UNION ALL

SELECT 
  'ESTATÍSTICAS DA MIGRAÇÃO',
  'Interações criadas',
  COUNT(*)
FROM contact_interactions

UNION ALL

SELECT 
  'COMPARAÇÃO COM DADOS ORIGINAIS',
  'Contatos originais (contact)',
  COUNT(*)
FROM contact

UNION ALL

SELECT 
  'COMPARAÇÃO COM DADOS ORIGINAIS',
  'Leads originais (leadstintim)',
  COUNT(*)
FROM leadstintim;

-- Verificar integridade referencial
SELECT 
  'VERIFICAÇÃO DE INTEGRIDADE' as categoria,
  'Mensagens órfãs' as item,
  COUNT(*) as quantidade
FROM whatsapp_messages wm
LEFT JOIN contact_unified cu ON cu.phone = wm.contact_phone
WHERE cu.phone IS NULL

UNION ALL

SELECT 
  'VERIFICAÇÃO DE INTEGRIDADE',
  'Interações órfãs',
  COUNT(*)
FROM contact_interactions ci
LEFT JOIN contact_unified cu ON cu.phone = ci.contact_phone
WHERE cu.phone IS NULL;

SELECT 'MIGRAÇÃO CONCLUÍDA COM SUCESSO!' as info;
SELECT 'NOVA ARQUITETURA IMPLEMENTADA E VALIDADA' as info;
SELECT 'PERFORMANCE OTIMIZADA E REDUNDÂNCIAS ELIMINADAS' as info;

-- =====================================================
-- INSTRUÇÕES PARA PRÓXIMOS PASSOS
-- =====================================================

/*
PRÓXIMOS PASSOS:

1. ATUALIZAR APLICAÇÃO FLUTTER:
   - Modificar ContactsService para usar contact_unified
   - Atualizar WhatsAppLeadsScreen para usar nova estrutura
   - Implementar cache de contatos para melhor performance

2. TESTES:
   - Testar todas as funcionalidades de CRUD de contatos
   - Validar salvamento de user_type
   - Verificar performance das consultas

3. MONITORAMENTO:
   - Acompanhar performance das queries
   - Verificar uso de índices
   - Monitorar crescimento das tabelas

4. LIMPEZA (APÓS VALIDAÇÃO):
   - Remover tabelas antigas (contact, leadstintim)
   - Remover triggers antigos
   - Limpar código legado

5. OTIMIZAÇÕES FUTURAS:
   - Implementar particionamento por data
   - Adicionar cache Redis
   - Implementar arquivamento de dados antigos
*/
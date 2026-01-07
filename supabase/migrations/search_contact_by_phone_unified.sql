-- =====================================================
-- FUNÇÃO DE BUSCA OTIMIZADA PARA CONTACT_UNIFIED
-- =====================================================
-- Função para buscar contatos por telefone usando normalização
-- e múltiplas estratégias de busca na nova tabela contact_unified
--
-- AUTOR: AI Assistant - Especialista em Modelagem de Dados
-- DATA: 2024
-- VERSÃO: 1.0

-- Função principal de busca por telefone
CREATE OR REPLACE FUNCTION search_contact_by_phone_unified(phone_input TEXT)
RETURNS TABLE(
  id BIGINT,
  phone VARCHAR(20),
  name VARCHAR(255),
  email VARCHAR(255),
  country VARCHAR(100),
  state VARCHAR(100),
  city VARCHAR(100),
  address TEXT,
  postal_code VARCHAR(20),
  gender VARCHAR(20),
  user_type user_type_enum,
  is_vip BOOLEAN,
  lead_score INTEGER,
  lead_status VARCHAR(50),
  account_id INTEGER,
  source_id INTEGER,
  contact_category_id INTEGER,
  first_contact_at TIMESTAMP WITH TIME ZONE,
  last_contact_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE,
  updated_at TIMESTAMP WITH TIME ZONE
) AS $$
DECLARE
  normalized_phone TEXT;
  search_pattern TEXT;
BEGIN
  -- Validação de entrada
  IF phone_input IS NULL OR TRIM(phone_input) = '' THEN
    RETURN;
  END IF;
  
  -- Normaliza o telefone usando a função existente
  normalized_phone := normalize_phone_unified(phone_input);
  
  -- 1. BUSCA EXATA com telefone normalizado
  RETURN QUERY
  SELECT cu.id, cu.phone, cu.name, cu.email, cu.country, cu.state, cu.city, 
         cu.address, cu.postal_code, cu.gender, cu.user_type, cu.is_vip, 
         cu.lead_score, cu.lead_status, cu.account_id, cu.source_id, 
         cu.contact_category_id, cu.first_contact_at, cu.last_contact_at, 
         cu.created_at, cu.updated_at
  FROM contact_unified cu
  WHERE cu.phone = normalized_phone
  LIMIT 1;
  
  -- Se encontrou resultado, retorna
  IF FOUND THEN
    RETURN;
  END IF;
  
  -- 2. BUSCA FLEXÍVEL com variações de formato
  RETURN QUERY
  SELECT cu.id, cu.phone, cu.name, cu.email, cu.country, cu.state, cu.city, 
         cu.address, cu.postal_code, cu.gender, cu.user_type, cu.is_vip, 
         cu.lead_score, cu.lead_status, cu.account_id, cu.source_id, 
         cu.contact_category_id, cu.first_contact_at, cu.last_contact_at, 
         cu.created_at, cu.updated_at
  FROM contact_unified cu
  WHERE normalize_phone_unified(cu.phone) = normalized_phone
     OR cu.phone = phone_input
     OR cu.phone = REGEXP_REPLACE(phone_input, '[^0-9+]', '', 'g')
  LIMIT 1;
  
  -- Se encontrou resultado, retorna
  IF FOUND THEN
    RETURN;
  END IF;
  
  -- 3. BUSCA PARCIAL pelos últimos 8 dígitos
  search_pattern := REGEXP_REPLACE(phone_input, '[^0-9]', '', 'g');
  IF LENGTH(search_pattern) >= 8 THEN
    search_pattern := RIGHT(search_pattern, 8);
    
    RETURN QUERY
    SELECT cu.id, cu.phone, cu.name, cu.email, cu.country, cu.state, cu.city, 
           cu.address, cu.postal_code, cu.gender, cu.user_type, cu.is_vip, 
           cu.lead_score, cu.lead_status, cu.account_id, cu.source_id, 
           cu.contact_category_id, cu.first_contact_at, cu.last_contact_at, 
           cu.created_at, cu.updated_at
    FROM contact_unified cu
    WHERE REGEXP_REPLACE(cu.phone, '[^0-9]', '', 'g') LIKE '%' || search_pattern || '%'
    ORDER BY 
      CASE 
        WHEN REGEXP_REPLACE(cu.phone, '[^0-9]', '', 'g') LIKE '%' || search_pattern THEN 1
        ELSE 2
      END,
      cu.last_contact_at DESC NULLS LAST
    LIMIT 1;
  END IF;
  
  RETURN;
END;
$$ LANGUAGE plpgsql;

-- Comentário da função
COMMENT ON FUNCTION search_contact_by_phone_unified(TEXT) IS 
'Busca contatos por telefone usando múltiplas estratégias: busca exata normalizada, busca flexível com variações de formato, e busca parcial pelos últimos 8 dígitos. Otimizada para a tabela contact_unified.';

-- Exemplo de uso:
-- SELECT * FROM search_contact_by_phone_unified('+5511999887766');
-- SELECT * FROM search_contact_by_phone_unified('(11) 99988-7766');
-- SELECT * FROM search_contact_by_phone_unified('11999887766');

-- Teste da função
SELECT 'FUNÇÃO search_contact_by_phone_unified CRIADA COM SUCESSO' as info;
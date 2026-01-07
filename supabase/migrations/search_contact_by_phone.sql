-- Script para buscar contatos por telefone de forma flexível
-- Considera diferentes formatos de telefone que podem existir no banco

-- Função para normalizar telefone (remove caracteres especiais)
CREATE OR REPLACE FUNCTION normalize_phone(phone_input TEXT)
RETURNS TEXT AS $$
BEGIN
    -- Remove todos os caracteres que não são dígitos ou +
    RETURN regexp_replace(phone_input, '[^0-9+]', '', 'g');
END;
$$ LANGUAGE plpgsql;

-- Função para buscar contato por telefone flexível
CREATE OR REPLACE FUNCTION search_contact_by_phone(phone_input TEXT)
RETURNS TABLE(
    id INTEGER,
    name TEXT,
    phone TEXT,
    email TEXT,
    user_type TEXT,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
) AS $$
DECLARE
    normalized_input TEXT;
    clean_input TEXT;
BEGIN
    -- Normaliza o telefone de entrada
    normalized_input := normalize_phone(phone_input);
    
    -- Remove o + se existir para comparações adicionais
    clean_input := replace(normalized_input, '+', '');
    
    -- Busca por diferentes variações do telefone
    RETURN QUERY
    SELECT 
        c.id,
        c.name,
        c.phone,
        c.email,
        c.user_type,
        c.created_at,
        c.updated_at
    FROM contact c
    WHERE 
        -- Busca exata
        c.phone = phone_input
        OR
        -- Busca normalizada
        normalize_phone(c.phone) = normalized_input
        OR
        -- Busca sem + no início
        normalize_phone(c.phone) = clean_input
        OR
        -- Busca com + adicionado
        normalize_phone(c.phone) = '+' || clean_input
        OR
        -- Busca parcial (contém os dígitos)
        normalize_phone(c.phone) LIKE '%' || clean_input || '%'
        OR
        -- Busca reversa (o input contém o telefone do banco)
        clean_input LIKE '%' || normalize_phone(c.phone) || '%'
    ORDER BY 
        -- Prioriza matches exatos
        CASE 
            WHEN c.phone = phone_input THEN 1
            WHEN normalize_phone(c.phone) = normalized_input THEN 2
            WHEN normalize_phone(c.phone) = clean_input THEN 3
            ELSE 4
        END,
        c.name
    LIMIT 1;
END;
$$ LANGUAGE plpgsql;

-- Exemplo de uso:
-- SELECT * FROM search_contact_by_phone('19734181339');
-- SELECT * FROM search_contact_by_phone('+5519734181339');
-- SELECT * FROM search_contact_by_phone('(19) 7 3418-1339');

-- Script para testar a função com o telefone específico do erro
SELECT 
    'Testando busca por telefone: 19734181339' as teste;
    
SELECT * FROM search_contact_by_phone('19734181339');

-- Verificar se existem telefones similares no banco
SELECT 
    id,
    name,
    phone,
    normalize_phone(phone) as phone_normalized,
    user_type
FROM contact 
WHERE 
    normalize_phone(phone) LIKE '%734181339%'
    OR normalize_phone(phone) LIKE '%19734181339%'
ORDER BY phone;

-- Verificar todos os formatos de telefone existentes no banco
SELECT 
    DISTINCT normalize_phone(phone) as phone_format,
    COUNT(*) as count
FROM contact 
WHERE phone IS NOT NULL AND phone != ''
GROUP BY normalize_phone(phone)
ORDER BY count DESC
LIMIT 20;
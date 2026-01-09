-- ============================================
-- Corrigir trigger extract_leadstintim_from_body
-- Problema: body é TEXT, precisa cast para JSONB
-- ============================================

-- Recriar função com cast correto
CREATE OR REPLACE FUNCTION extract_leadstintim_from_body()
RETURNS TRIGGER AS $$
BEGIN
    -- Se body existe e campos estão vazios, extrair do body
    IF NEW.body IS NOT NULL AND NEW.body != '' THEN
        
        -- Tentar fazer cast para JSONB
        BEGIN
            -- Extrair name
            IF NEW.name IS NULL OR NEW.name = '' THEN
                NEW.name := (NEW.body::jsonb)->'lead'->>'name';
            END IF;
            
            -- Extrair phone
            IF NEW.phone IS NULL OR NEW.phone = '' THEN
                NEW.phone := (NEW.body::jsonb)->'lead'->>'phone';
            END IF;
            
            -- Extrair source
            IF NEW.source IS NULL OR NEW.source = '' THEN
                NEW.source := (NEW.body::jsonb)->'lead'->>'source';
            END IF;
            
            -- Extrair country
            IF NEW.country IS NULL OR NEW.country = '' THEN
                NEW.country := (NEW.body::jsonb)->'lead'->'location'->>'country';
            END IF;
            
            -- Extrair state
            IF NEW.state IS NULL OR NEW.state = '' THEN
                NEW.state := (NEW.body::jsonb)->'lead'->'location'->>'state';
            END IF;
            
            -- Extrair status
            IF NEW.status IS NULL OR NEW.status = '' THEN
                NEW.status := (NEW.body::jsonb)->'lead'->'status'->>'name';
            END IF;
            
            -- Extrair messageid se vazio
            IF NEW.messageid IS NULL OR NEW.messageid = '' THEN
                NEW.messageid := (NEW.body::jsonb)->'lead'->>'messageid';
            END IF;
            
            -- Definir from_me como false se null
            IF NEW.from_me IS NULL THEN
                NEW.from_me := COALESCE(((NEW.body::jsonb)->'lead'->>'from_me')::boolean::text, 'false');
            END IF;
            
        EXCEPTION
            WHEN OTHERS THEN
                -- Se falhar o cast, ignora (body pode não ser JSON válido)
                NULL;
        END;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Comentário
COMMENT ON FUNCTION extract_leadstintim_from_body() IS 
'Extrai automaticamente dados do campo body (TEXT→JSONB) para campos individuais quando inserido via webhook';

-- Verificar se trigger existe e está ativo
SELECT 
    tgname,
    tgenabled,
    tgtype
FROM pg_trigger
WHERE tgname = 'trigger_extract_leadstintim_body';

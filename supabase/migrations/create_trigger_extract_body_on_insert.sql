-- ============================================
-- Trigger para extrair dados do body automaticamente
-- Previne problema futuro do webhook
-- ============================================

-- Função para extrair dados do body
CREATE OR REPLACE FUNCTION extract_leadstintim_from_body()
RETURNS TRIGGER AS $$
BEGIN
    -- Se body existe e campos estão vazios, extrair do body
    IF NEW.body IS NOT NULL THEN
        -- Extrair name
        IF NEW.name IS NULL OR NEW.name = '' THEN
            NEW.name := NEW.body->'lead'->>'name';
        END IF;
        
        -- Extrair phone
        IF NEW.phone IS NULL OR NEW.phone = '' THEN
            NEW.phone := NEW.body->'lead'->>'phone';
        END IF;
        
        -- Extrair source
        IF NEW.source IS NULL OR NEW.source = '' THEN
            NEW.source := NEW.body->'lead'->>'source';
        END IF;
        
        -- Extrair country
        IF NEW.country IS NULL OR NEW.country = '' THEN
            NEW.country := NEW.body->'lead'->'location'->>'country';
        END IF;
        
        -- Extrair state
        IF NEW.state IS NULL OR NEW.state = '' THEN
            NEW.state := NEW.body->'lead'->'location'->>'state';
        END IF;
        
        -- Extrair status
        IF NEW.status IS NULL OR NEW.status = '' THEN
            NEW.status := NEW.body->'lead'->'status'->>'name';
        END IF;
        
        -- Extrair messageid se vazio
        IF NEW.messageid IS NULL OR NEW.messageid = '' THEN
            NEW.messageid := NEW.body->'lead'->>'messageid';
        END IF;
        
        -- Definir from_me como false se null
        IF NEW.from_me IS NULL THEN
            NEW.from_me := COALESCE((NEW.body->'lead'->>'from_me')::boolean, false);
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Remover trigger antigo se existir
DROP TRIGGER IF EXISTS trigger_extract_leadstintim_body ON leadstintim;

-- Criar trigger BEFORE INSERT
CREATE TRIGGER trigger_extract_leadstintim_body
    BEFORE INSERT ON leadstintim
    FOR EACH ROW
    EXECUTE FUNCTION extract_leadstintim_from_body();

-- Comentário
COMMENT ON FUNCTION extract_leadstintim_from_body() IS 
'Extrai automaticamente dados do campo body (JSON) para campos individuais quando inserido via webhook';

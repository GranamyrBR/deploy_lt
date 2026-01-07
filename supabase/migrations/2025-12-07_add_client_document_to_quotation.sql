-- Migration: Adicionar coluna client_document na tabela quotation
-- Data: 2025-12-07
-- Descricao: Corrige erro "column client_document does not exist"

DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'quotation' 
        AND column_name = 'client_document'
    ) THEN
        ALTER TABLE public.quotation 
        ADD COLUMN client_document TEXT;
        
        RAISE NOTICE 'Coluna client_document adicionada com sucesso!';
    ELSE
        RAISE NOTICE 'Coluna client_document ja existe!';
    END IF;
END $$;

COMMENT ON COLUMN public.quotation.client_document IS 'Documento do cliente (CPF, CNPJ, Passport, etc). Campo opcional.';

CREATE INDEX IF NOT EXISTS idx_quotation_client_document ON public.quotation(client_document) WHERE client_document IS NOT NULL;

SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'quotation' 
AND column_name = 'client_document';

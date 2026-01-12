-- ============================================================================
-- MIGRATION: Tornar campos opcionais na tabela quotation
-- Data: 2025-01-13
-- Descrição: Remove constraint NOT NULL de campos que não são obrigatórios
--            Campos obrigatórios: client_name, client_phone, travel_date
-- ============================================================================

-- client_name PERMANECE OBRIGATÓRIO (NOT NULL mantido)

-- Tornar client_email opcional
ALTER TABLE public.quotation 
  ALTER COLUMN client_email DROP NOT NULL;

-- client_phone já é opcional no schema atual (verificar se existe)

-- Tornar subtotal opcional (pode ser 0 ou NULL se não tiver itens)
ALTER TABLE public.quotation 
  ALTER COLUMN subtotal DROP NOT NULL;

-- Tornar total opcional (pode ser 0 ou NULL se não tiver itens)
ALTER TABLE public.quotation 
  ALTER COLUMN total DROP NOT NULL;

-- Comentários atualizados
COMMENT ON COLUMN public.quotation.client_name IS 
  'Nome do cliente (OBRIGATÓRIO)';

COMMENT ON COLUMN public.quotation.client_phone IS 
  'Telefone do cliente (OBRIGATÓRIO)';

COMMENT ON COLUMN public.quotation.client_email IS 
  'Email do cliente (opcional - pode ser preenchido depois)';

COMMENT ON COLUMN public.quotation.subtotal IS 
  'Subtotal da cotação (opcional - pode ser NULL se não tiver itens)';

COMMENT ON COLUMN public.quotation.total IS 
  'Total da cotação (opcional - pode ser NULL se não tiver itens)';

-- ============================================================================
-- CAMPOS OBRIGATÓRIOS MANTIDOS:
-- - quotation_number (identificador único)
-- - type (tipo da cotação)
-- - client_name (nome do cliente) ✅
-- - client_phone (telefone do cliente) ✅
-- - travel_date (data de ida) ✅
-- - return_date (data de volta) ✅
-- - status (status da cotação)
-- - created_by (quem criou)
-- - quotation_date (quando foi criada)
-- ============================================================================

-- FIM DA MIGRATION

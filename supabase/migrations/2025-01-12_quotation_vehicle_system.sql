-- ============================================================================
-- MIGRATION: Sistema de Veículos para Cotações
-- Data: 2025-01-12
-- Descrição: Cria tabela quotation_vehicle para persistir veículos selecionados
--            Similar à tabela quotation_luggage
-- ============================================================================

-- Criar tabela quotation_vehicle
CREATE TABLE IF NOT EXISTS public.quotation_vehicle (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  quotation_id bigint NOT NULL,
  vehicle_type text NOT NULL CHECK (
    vehicle_type = ANY (ARRAY[
      'suv'::text, 
      'van'::text, 
      'minibus'::text, 
      'bus'::text, 
      'sedan'::text, 
      'luxury'::text
    ])
  ),
  quantity integer NOT NULL CHECK (quantity > 0 AND quantity <= 99),
  max_passengers integer NOT NULL,
  created_at timestamp without time zone DEFAULT now(),
  updated_at timestamp without time zone DEFAULT now(),
  
  CONSTRAINT quotation_vehicle_pkey PRIMARY KEY (id),
  CONSTRAINT quotation_vehicle_quotation_id_fkey 
    FOREIGN KEY (quotation_id) 
    REFERENCES public.quotation(id) 
    ON DELETE CASCADE
);

-- Índice para melhorar performance de queries
CREATE INDEX IF NOT EXISTS idx_quotation_vehicle_quotation_id 
  ON public.quotation_vehicle(quotation_id);

CREATE INDEX IF NOT EXISTS idx_quotation_vehicle_type 
  ON public.quotation_vehicle(vehicle_type);

-- Comentários na tabela e colunas
COMMENT ON TABLE public.quotation_vehicle IS 
  'Armazena os veículos selecionados para cada cotação';

COMMENT ON COLUMN public.quotation_vehicle.id IS 
  'Identificador único do veículo na cotação';

COMMENT ON COLUMN public.quotation_vehicle.quotation_id IS 
  'Referência à cotação (FK para quotation.id)';

COMMENT ON COLUMN public.quotation_vehicle.vehicle_type IS 
  'Tipo do veículo: suv, van, minibus, bus, sedan, luxury';

COMMENT ON COLUMN public.quotation_vehicle.quantity IS 
  'Quantidade de veículos deste tipo (1-99)';

COMMENT ON COLUMN public.quotation_vehicle.max_passengers IS 
  'Capacidade máxima de passageiros do veículo';

-- Habilitar RLS (Row Level Security)
ALTER TABLE public.quotation_vehicle ENABLE ROW LEVEL SECURITY;

-- Remover políticas antigas se existirem
DROP POLICY IF EXISTS "Authenticated users can read quotation_vehicle" ON public.quotation_vehicle;
DROP POLICY IF EXISTS "Authenticated users can insert quotation_vehicle" ON public.quotation_vehicle;
DROP POLICY IF EXISTS "Authenticated users can update quotation_vehicle" ON public.quotation_vehicle;
DROP POLICY IF EXISTS "Authenticated users can delete quotation_vehicle" ON public.quotation_vehicle;

-- Política: Usuários autenticados podem ler
CREATE POLICY "Authenticated users can read quotation_vehicle"
  ON public.quotation_vehicle
  FOR SELECT
  TO authenticated
  USING (true);

-- Política: Usuários autenticados podem inserir
CREATE POLICY "Authenticated users can insert quotation_vehicle"
  ON public.quotation_vehicle
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Política: Usuários autenticados podem atualizar
CREATE POLICY "Authenticated users can update quotation_vehicle"
  ON public.quotation_vehicle
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Política: Usuários autenticados podem deletar
CREATE POLICY "Authenticated users can delete quotation_vehicle"
  ON public.quotation_vehicle
  FOR DELETE
  TO authenticated
  USING (true);

-- Atualizar tipos de bagagem para incluir novos itens especiais
ALTER TABLE public.quotation_luggage 
  DROP CONSTRAINT IF EXISTS quotation_luggage_luggage_type_check;

ALTER TABLE public.quotation_luggage 
  ADD CONSTRAINT quotation_luggage_luggage_type_check 
  CHECK (
    luggage_type = ANY (ARRAY[
      'carry_on'::text,       -- Bagagem de mão
      'checked'::text,        -- Bagagem despachada
      'large_checked'::text,  -- Bagagem grande
      'personal'::text,       -- Item pessoal
      'baby_seat'::text,      -- Cadeirinha de bebê
      'stroller'::text,       -- Carrinho de bebê
      'wheelchair'::text      -- Cadeira de rodas
    ])
  );

COMMENT ON CONSTRAINT quotation_luggage_luggage_type_check 
  ON public.quotation_luggage IS 
  'Tipos válidos de bagagem incluindo itens especiais (cadeirinha, carrinho, cadeira de rodas)';

-- ============================================================================
-- FIM DA MIGRATION
-- ============================================================================

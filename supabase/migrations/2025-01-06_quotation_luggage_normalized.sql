-- ============================================================
-- TABELA NORMALIZADA: quotation_luggage
-- Armazena bagagens de forma relacional (NÃO JSON)
-- ============================================================

-- Criar tabela de bagagens
CREATE TABLE IF NOT EXISTS public.quotation_luggage (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  quotation_id BIGINT NOT NULL,
  luggage_type TEXT NOT NULL CHECK (luggage_type IN ('carry_on', 'checked', 'large_checked', 'personal')),
  quantity INTEGER NOT NULL CHECK (quantity > 0 AND quantity <= 99),
  created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW(),
  
  -- Foreign key para quotation
  CONSTRAINT quotation_luggage_quotation_id_fkey 
    FOREIGN KEY (quotation_id) 
    REFERENCES public.quotation(id) 
    ON DELETE CASCADE,
  
  -- Único por quotation + tipo (não pode ter 2 linhas com mesmo tipo)
  CONSTRAINT quotation_luggage_unique_type_per_quotation 
    UNIQUE (quotation_id, luggage_type)
);

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_quotation_luggage_quotation_id 
  ON public.quotation_luggage(quotation_id);

CREATE INDEX IF NOT EXISTS idx_quotation_luggage_type 
  ON public.quotation_luggage(luggage_type);

-- Comentários para documentação
COMMENT ON TABLE public.quotation_luggage IS 
'Armazena informações de bagagens associadas a cotações de forma normalizada';

COMMENT ON COLUMN public.quotation_luggage.luggage_type IS 
'Tipo de bagagem: carry_on (mão), checked (despachada), large_checked (grande), personal (item pessoal)';

COMMENT ON COLUMN public.quotation_luggage.quantity IS 
'Quantidade de bagagens deste tipo (1-99)';

-- RLS (Row Level Security) - opcional, ajustar conforme suas políticas
ALTER TABLE public.quotation_luggage ENABLE ROW LEVEL SECURITY;

-- Política de leitura: qualquer usuário autenticado pode ler
CREATE POLICY "Users can view luggage"
  ON public.quotation_luggage
  FOR SELECT
  USING (true);

-- Política de inserção: qualquer usuário autenticado pode inserir
CREATE POLICY "Users can insert luggage"
  ON public.quotation_luggage
  FOR INSERT
  WITH CHECK (true);

-- Política de atualização: qualquer usuário autenticado pode atualizar
CREATE POLICY "Users can update luggage"
  ON public.quotation_luggage
  FOR UPDATE
  USING (true);

-- Política de deleção: qualquer usuário autenticado pode deletar
CREATE POLICY "Users can delete luggage"
  ON public.quotation_luggage
  FOR DELETE
  USING (true);

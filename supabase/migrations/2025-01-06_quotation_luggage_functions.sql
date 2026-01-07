-- ============================================================
-- FUNÇÕES AUXILIARES: Leitura de bagagens
-- ============================================================

-- Função para buscar bagagens de uma cotação
CREATE OR REPLACE FUNCTION public.get_quotation_luggage(p_quotation_id BIGINT)
RETURNS TABLE (
  id BIGINT,
  luggage_type TEXT,
  quantity INTEGER,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
)
LANGUAGE sql
STABLE
AS $$
  SELECT 
    id,
    luggage_type,
    quantity,
    created_at,
    updated_at
  FROM public.quotation_luggage
  WHERE quotation_id = p_quotation_id
  ORDER BY 
    CASE luggage_type
      WHEN 'carry_on' THEN 1
      WHEN 'checked' THEN 2
      WHEN 'large_checked' THEN 3
      WHEN 'personal' THEN 4
      ELSE 5
    END;
$$;

-- Função para calcular total de peças de bagagem
CREATE OR REPLACE FUNCTION public.get_total_luggage_pieces(p_quotation_id BIGINT)
RETURNS INTEGER
LANGUAGE sql
STABLE
AS $$
  SELECT COALESCE(SUM(quantity), 0)::INTEGER
  FROM public.quotation_luggage
  WHERE quotation_id = p_quotation_id;
$$;

-- View para facilitar consultas com labels amigáveis
CREATE OR REPLACE VIEW public.v_quotation_luggage_readable AS
SELECT 
  ql.id,
  ql.quotation_id,
  q.quotation_number,
  q.client_name,
  q.travel_date,
  ql.luggage_type,
  ql.quantity,
  CASE ql.luggage_type
    WHEN 'carry_on' THEN 'Bagagem de Mão'
    WHEN 'checked' THEN 'Bagagem Despachada'
    WHEN 'large_checked' THEN 'Bagagem Grande'
    WHEN 'personal' THEN 'Item Pessoal'
    ELSE 'Desconhecido'
  END as luggage_label,
  CASE ql.luggage_type
    WHEN 'carry_on' THEN 'Até 10kg - 55x40x20cm'
    WHEN 'checked' THEN '23kg - 158cm linear'
    WHEN 'large_checked' THEN 'Até 32kg - 203cm linear'
    WHEN 'personal' THEN 'Até 5kg - 40x30x15cm'
    ELSE ''
  END as luggage_specs,
  ql.created_at,
  ql.updated_at
FROM public.quotation_luggage ql
JOIN public.quotation q ON q.id = ql.quotation_id;

-- Comentários
COMMENT ON FUNCTION public.get_quotation_luggage(BIGINT) IS 
'Retorna todas as bagagens de uma cotação específica';

COMMENT ON FUNCTION public.get_total_luggage_pieces(BIGINT) IS 
'Retorna o total de peças de bagagem de uma cotação';

COMMENT ON VIEW public.v_quotation_luggage_readable IS 
'View com labels amigáveis para exibir bagagens';

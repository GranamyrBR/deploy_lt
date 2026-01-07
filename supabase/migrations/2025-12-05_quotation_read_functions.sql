-- ============================================================
-- FUNÇÕES DE LEITURA: get_quotation_full e search_quotations
-- ============================================================

CREATE OR REPLACE FUNCTION public.get_quotation_full(p_id bigint)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_result jsonb;
BEGIN
  SELECT jsonb_build_object(
    'quotation', row_to_json(q.*),
    'items', COALESCE(
      (SELECT jsonb_agg(row_to_json(qi.*))
       FROM public.quotation_item qi
       WHERE qi.quotation_id = q.id
      ), '[]'::jsonb
    ),
    'contact', (
      SELECT row_to_json(c.*)
      FROM public.contact c
      WHERE c.id = q.client_id
    ),
    'agency', (
      SELECT row_to_json(a.*)
      FROM public.account a
      WHERE a.id = q.agency_id
    )
  )
  INTO v_result
  FROM public.quotation q
  WHERE q.id = p_id;

  RETURN v_result;
END;
$$;

-- Função de busca com filtros
CREATE OR REPLACE FUNCTION public.search_quotations(
  p_id bigint DEFAULT NULL,
  p_client_id bigint DEFAULT NULL,
  p_status text DEFAULT NULL,
  p_from timestamp DEFAULT NULL,
  p_to timestamp DEFAULT NULL,
  p_limit int DEFAULT 50,
  p_offset int DEFAULT 0
)
RETURNS TABLE (
  id bigint,
  quotation_number text,
  type text,
  status text,
  client_id bigint,
  client_name text,
  client_email text,
  client_phone text,
  travel_date timestamp,
  return_date timestamp,
  destination text,
  hotel text,
  total numeric,
  currency text,
  quotation_date timestamp,
  expiration_date timestamp,
  created_at timestamp,
  updated_at timestamp
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    q.id,
    q.quotation_number,
    q.type,
    q.status,
    q.client_id,
    q.client_name,
    q.client_email,
    q.client_phone,
    q.travel_date,
    q.return_date,
    q.destination,
    q.hotel,
    q.total,
    q.currency,
    q.quotation_date,
    q.expiration_date,
    q.created_at,
    q.updated_at
  FROM public.quotation q
  WHERE 
    (p_id IS NULL OR q.id = p_id)
    AND (p_client_id IS NULL OR q.client_id = p_client_id)
    AND (p_status IS NULL OR q.status = p_status)
    AND (p_from IS NULL OR q.quotation_date >= p_from)
    AND (p_to IS NULL OR q.quotation_date <= p_to)
  ORDER BY q.created_at DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$;

-- Adicionar coluna tags se não existir
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'quotation' 
    AND column_name = 'tags'
  ) THEN
    ALTER TABLE public.quotation ADD COLUMN tags text[];
  END IF;
END $$;

-- Adicionar coluna follow_up_date se não existir
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'quotation' 
    AND column_name = 'follow_up_date'
  ) THEN
    ALTER TABLE public.quotation ADD COLUMN follow_up_date timestamp;
  END IF;
END $$;

-- Adicionar coluna last_follow_up_date se não existir
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'quotation' 
    AND column_name = 'last_follow_up_date'
  ) THEN
    ALTER TABLE public.quotation ADD COLUMN last_follow_up_date timestamp;
  END IF;
END $$;

-- Adicionar coluna follow_up_count se não existir
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'quotation' 
    AND column_name = 'follow_up_count'
  ) THEN
    ALTER TABLE public.quotation ADD COLUMN follow_up_count int DEFAULT 0;
  END IF;
END $$;

-- Criar tabela de follow-ups/timeline
CREATE TABLE IF NOT EXISTS public.quotation_timeline (
  id bigserial PRIMARY KEY,
  quotation_id bigint NOT NULL REFERENCES public.quotation(id) ON DELETE CASCADE,
  event_type text NOT NULL, -- 'created', 'sent', 'viewed', 'follow_up', 'status_change', 'note', 'email', 'whatsapp', 'call'
  title text NOT NULL,
  description text,
  created_by text,
  created_at timestamp DEFAULT NOW(),
  metadata jsonb
);

CREATE INDEX IF NOT EXISTS idx_quotation_timeline_quotation_id ON public.quotation_timeline(quotation_id);
CREATE INDEX IF NOT EXISTS idx_quotation_timeline_created_at ON public.quotation_timeline(created_at DESC);

-- Função para adicionar evento na timeline
CREATE OR REPLACE FUNCTION public.add_quotation_timeline_event(
  p_quotation_id bigint,
  p_event_type text,
  p_title text,
  p_description text DEFAULT NULL,
  p_created_by text DEFAULT NULL,
  p_metadata jsonb DEFAULT NULL
)
RETURNS bigint
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_event_id bigint;
BEGIN
  INSERT INTO public.quotation_timeline (
    quotation_id,
    event_type,
    title,
    description,
    created_by,
    metadata
  )
  VALUES (
    p_quotation_id,
    p_event_type,
    p_title,
    p_description,
    p_created_by,
    p_metadata
  )
  RETURNING id INTO v_event_id;

  RETURN v_event_id;
END;
$$;

-- Função para obter timeline de uma cotação
CREATE OR REPLACE FUNCTION public.get_quotation_timeline(p_quotation_id bigint)
RETURNS TABLE (
  id bigint,
  event_type text,
  title text,
  description text,
  created_by text,
  created_at timestamp,
  metadata jsonb
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    qt.id,
    qt.event_type,
    qt.title,
    qt.description,
    qt.created_by,
    qt.created_at,
    qt.metadata
  FROM public.quotation_timeline qt
  WHERE qt.quotation_id = p_quotation_id
  ORDER BY qt.created_at DESC;
END;
$$;

-- Trigger para criar evento de timeline quando cotação é criada
CREATE OR REPLACE FUNCTION public.quotation_created_trigger()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO public.quotation_timeline (
    quotation_id,
    event_type,
    title,
    description,
    created_by
  )
  VALUES (
    NEW.id,
    'created',
    'Cotação criada',
    'Cotação ' || NEW.quotation_number || ' foi criada',
    NEW.created_by
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS quotation_created_timeline ON public.quotation;
CREATE TRIGGER quotation_created_timeline
  AFTER INSERT ON public.quotation
  FOR EACH ROW
  EXECUTE FUNCTION public.quotation_created_trigger();

-- Trigger para criar evento quando status muda
CREATE OR REPLACE FUNCTION public.quotation_status_changed_trigger()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF OLD.status IS DISTINCT FROM NEW.status THEN
    INSERT INTO public.quotation_timeline (
      quotation_id,
      event_type,
      title,
      description,
      metadata
    )
    VALUES (
      NEW.id,
      'status_change',
      'Status alterado',
      'Status mudou de "' || OLD.status || '" para "' || NEW.status || '"',
      jsonb_build_object('old_status', OLD.status, 'new_status', NEW.status)
    );
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS quotation_status_changed_timeline ON public.quotation;
CREATE TRIGGER quotation_status_changed_timeline
  AFTER UPDATE ON public.quotation
  FOR EACH ROW
  EXECUTE FUNCTION public.quotation_status_changed_trigger();


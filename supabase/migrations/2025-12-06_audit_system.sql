-- ============================================================
-- SISTEMA DE AUDITORIA E RASTREAMENTO
-- Created: 2025-12-06
-- Purpose: Logs de atividades, follow-ups e comissões
-- ============================================================

-- ============================================================
-- 1. TABELA DE LOGS DE ATIVIDADES
-- ============================================================
CREATE TABLE IF NOT EXISTS public.activity_log (
  id BIGSERIAL PRIMARY KEY,
  user_id TEXT NOT NULL,
  user_name TEXT NOT NULL,
  user_email TEXT,
  
  -- Ação realizada
  action_type TEXT NOT NULL, -- 'create', 'update', 'delete', 'send_email', 'send_whatsapp', 'status_change', 'follow_up', 'view'
  entity_type TEXT NOT NULL, -- 'quotation', 'contact', 'lead', 'operation', etc.
  entity_id TEXT NOT NULL,
  entity_name TEXT,
  
  -- Detalhes da ação
  action_description TEXT NOT NULL,
  old_value JSONB,
  new_value JSONB,
  metadata JSONB, -- Dados extras: IP, dispositivo, localização, etc.
  
  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Índices para performance
  CONSTRAINT activity_log_action_type_check CHECK (action_type IN (
    'create', 'update', 'delete', 'send_email', 'send_whatsapp', 
    'status_change', 'follow_up', 'view', 'generate_pdf', 
    'add_service', 'add_product', 'remove_item', 'update_value'
  ))
);

-- Índices para busca rápida
CREATE INDEX IF NOT EXISTS idx_activity_log_user_id ON public.activity_log(user_id);
CREATE INDEX IF NOT EXISTS idx_activity_log_entity ON public.activity_log(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_activity_log_created_at ON public.activity_log(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_activity_log_action_type ON public.activity_log(action_type);

-- ============================================================
-- 2. TABELA DE FOLLOW-UPS
-- ============================================================
CREATE TABLE IF NOT EXISTS public.quotation_follow_up (
  id BIGSERIAL PRIMARY KEY,
  quotation_id BIGINT NOT NULL REFERENCES public.quotation(id) ON DELETE CASCADE,
  
  -- Responsável
  assigned_to TEXT NOT NULL, -- User ID do responsável
  assigned_name TEXT NOT NULL,
  assigned_email TEXT,
  
  -- Follow-up
  type TEXT NOT NULL, -- 'call', 'email', 'whatsapp', 'meeting', 'note'
  status TEXT NOT NULL DEFAULT 'pending', -- 'pending', 'completed', 'cancelled'
  priority TEXT NOT NULL DEFAULT 'medium', -- 'low', 'medium', 'high', 'urgent'
  
  scheduled_date TIMESTAMP WITH TIME ZONE NOT NULL,
  completed_date TIMESTAMP WITH TIME ZONE,
  
  title TEXT NOT NULL,
  description TEXT,
  notes TEXT,
  result TEXT, -- Resultado do follow-up após conclusão
  
  -- Auditoria
  created_by TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT follow_up_type_check CHECK (type IN ('call', 'email', 'whatsapp', 'meeting', 'note')),
  CONSTRAINT follow_up_status_check CHECK (status IN ('pending', 'completed', 'cancelled')),
  CONSTRAINT follow_up_priority_check CHECK (priority IN ('low', 'medium', 'high', 'urgent'))
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_follow_up_quotation ON public.quotation_follow_up(quotation_id);
CREATE INDEX IF NOT EXISTS idx_follow_up_assigned ON public.quotation_follow_up(assigned_to);
CREATE INDEX IF NOT EXISTS idx_follow_up_status ON public.quotation_follow_up(status);
CREATE INDEX IF NOT EXISTS idx_follow_up_scheduled ON public.quotation_follow_up(scheduled_date);

-- ============================================================
-- 3. ADICIONAR CAMPOS DE AUDITORIA NA TABELA QUOTATION
-- ============================================================
DO $$ 
BEGIN
  -- created_by (usuário que criou)
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'quotation' AND column_name = 'created_by_user_id'
  ) THEN
    ALTER TABLE public.quotation ADD COLUMN created_by_user_id TEXT;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'quotation' AND column_name = 'created_by_user_name'
  ) THEN
    ALTER TABLE public.quotation ADD COLUMN created_by_user_name TEXT;
  END IF;

  -- modified_by (último usuário que modificou)
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'quotation' AND column_name = 'modified_by_user_id'
  ) THEN
    ALTER TABLE public.quotation ADD COLUMN modified_by_user_id TEXT;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'quotation' AND column_name = 'modified_by_user_name'
  ) THEN
    ALTER TABLE public.quotation ADD COLUMN modified_by_user_name TEXT;
  END IF;

  -- assigned_to (vendedor responsável pela cotação)
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'quotation' AND column_name = 'assigned_to_user_id'
  ) THEN
    ALTER TABLE public.quotation ADD COLUMN assigned_to_user_id TEXT;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'quotation' AND column_name = 'assigned_to_user_name'
  ) THEN
    ALTER TABLE public.quotation ADD COLUMN assigned_to_user_name TEXT;
  END IF;

  -- commission_rate (comissão do vendedor)
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'quotation' AND column_name = 'commission_rate'
  ) THEN
    ALTER TABLE public.quotation ADD COLUMN commission_rate NUMERIC(5,2) DEFAULT 0.0;
  END IF;
END $$;

-- ============================================================
-- 4. FUNÇÃO PARA REGISTRAR ATIVIDADE
-- ============================================================
CREATE OR REPLACE FUNCTION public.log_activity(
  p_user_id TEXT,
  p_user_name TEXT,
  p_user_email TEXT,
  p_action_type TEXT,
  p_entity_type TEXT,
  p_entity_id TEXT,
  p_entity_name TEXT,
  p_action_description TEXT,
  p_old_value JSONB DEFAULT NULL,
  p_new_value JSONB DEFAULT NULL,
  p_metadata JSONB DEFAULT NULL
)
RETURNS BIGINT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_log_id BIGINT;
BEGIN
  INSERT INTO public.activity_log (
    user_id, user_name, user_email, action_type, entity_type,
    entity_id, entity_name, action_description, old_value, new_value, metadata
  )
  VALUES (
    p_user_id, p_user_name, p_user_email, p_action_type, p_entity_type,
    p_entity_id, p_entity_name, p_action_description, p_old_value, p_new_value, p_metadata
  )
  RETURNING id INTO v_log_id;
  
  RETURN v_log_id;
END;
$$;

-- ============================================================
-- 5. FUNÇÃO PARA BUSCAR LOGS DE UMA COTAÇÃO
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_quotation_activity_logs(
  p_quotation_id TEXT
)
RETURNS TABLE (
  id BIGINT,
  user_id TEXT,
  user_name TEXT,
  user_email TEXT,
  action_type TEXT,
  action_description TEXT,
  old_value JSONB,
  new_value JSONB,
  metadata JSONB,
  created_at TIMESTAMP WITH TIME ZONE
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    al.id,
    al.user_id,
    al.user_name,
    al.user_email,
    al.action_type,
    al.action_description,
    al.old_value,
    al.new_value,
    al.metadata,
    al.created_at
  FROM public.activity_log al
  WHERE al.entity_type = 'quotation' 
    AND al.entity_id = p_quotation_id
  ORDER BY al.created_at DESC;
END;
$$;

-- ============================================================
-- 6. FUNÇÃO PARA CRIAR FOLLOW-UP
-- ============================================================
CREATE OR REPLACE FUNCTION public.create_follow_up(
  p_quotation_id BIGINT,
  p_assigned_to TEXT,
  p_assigned_name TEXT,
  p_assigned_email TEXT,
  p_type TEXT,
  p_priority TEXT,
  p_scheduled_date TIMESTAMP WITH TIME ZONE,
  p_title TEXT,
  p_description TEXT,
  p_created_by TEXT
)
RETURNS BIGINT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_follow_up_id BIGINT;
BEGIN
  INSERT INTO public.quotation_follow_up (
    quotation_id, assigned_to, assigned_name, assigned_email,
    type, priority, scheduled_date, title, description, created_by
  )
  VALUES (
    p_quotation_id, p_assigned_to, p_assigned_name, p_assigned_email,
    p_type, p_priority, p_scheduled_date, p_title, p_description, p_created_by
  )
  RETURNING id INTO v_follow_up_id;
  
  -- Registra no log
  PERFORM public.log_activity(
    p_created_by,
    p_assigned_name,
    p_assigned_email,
    'follow_up',
    'quotation',
    p_quotation_id::TEXT,
    p_title,
    'Follow-up agendado: ' || p_title,
    NULL,
    jsonb_build_object(
      'scheduled_date', p_scheduled_date,
      'priority', p_priority,
      'type', p_type
    ),
    NULL
  );
  
  RETURN v_follow_up_id;
END;
$$;

-- ============================================================
-- 7. FUNÇÃO PARA BUSCAR FOLLOW-UPS
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_quotation_follow_ups(
  p_quotation_id BIGINT
)
RETURNS TABLE (
  id BIGINT,
  assigned_to TEXT,
  assigned_name TEXT,
  type TEXT,
  status TEXT,
  priority TEXT,
  scheduled_date TIMESTAMP WITH TIME ZONE,
  completed_date TIMESTAMP WITH TIME ZONE,
  title TEXT,
  description TEXT,
  result TEXT,
  created_by TEXT,
  created_at TIMESTAMP WITH TIME ZONE
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    f.id, f.assigned_to, f.assigned_name, f.type, f.status,
    f.priority, f.scheduled_date, f.completed_date, f.title,
    f.description, f.result, f.created_by, f.created_at
  FROM public.quotation_follow_up f
  WHERE f.quotation_id = p_quotation_id
  ORDER BY f.scheduled_date DESC;
END;
$$;

-- ============================================================
-- 8. FUNÇÃO PARA ATUALIZAR FOLLOW-UP
-- ============================================================
CREATE OR REPLACE FUNCTION public.complete_follow_up(
  p_follow_up_id BIGINT,
  p_result TEXT,
  p_completed_by TEXT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.quotation_follow_up
  SET 
    status = 'completed',
    completed_date = NOW(),
    result = p_result,
    updated_at = NOW()
  WHERE id = p_follow_up_id;
  
  -- Registra no log
  PERFORM public.log_activity(
    p_completed_by,
    p_completed_by,
    NULL,
    'follow_up',
    'quotation',
    (SELECT quotation_id::TEXT FROM public.quotation_follow_up WHERE id = p_follow_up_id),
    (SELECT title FROM public.quotation_follow_up WHERE id = p_follow_up_id),
    'Follow-up concluído',
    NULL,
    jsonb_build_object('result', p_result),
    NULL
  );
END;
$$;

-- ============================================================
-- 9. VIEW PARA RELATÓRIO DE COMISSÕES
-- ============================================================
CREATE OR REPLACE VIEW public.quotation_commissions AS
SELECT 
  q.id,
  q.quotation_number,
  q.assigned_to_user_id,
  q.assigned_to_user_name,
  q.created_by_user_id,
  q.created_by_user_name,
  q.client_name,
  q.status,
  q.total,
  q.commission_rate,
  (q.total * COALESCE(q.commission_rate, 0) / 100) AS commission_amount,
  q.quotation_date,
  q.accepted_date,
  CASE 
    WHEN q.status = 'accepted' THEN 'Comissão Devida'
    WHEN q.status = 'rejected' THEN 'Sem Comissão'
    ELSE 'Pendente'
  END AS commission_status
FROM public.quotation q
WHERE q.status IN ('accepted', 'rejected', 'sent', 'viewed')
ORDER BY q.quotation_date DESC;

-- ============================================================
-- 10. FUNÇÃO PARA BUSCAR ATIVIDADES DE UM USUÁRIO
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_user_activity_logs(
  p_user_id TEXT,
  p_limit INT DEFAULT 100
)
RETURNS TABLE (
  id BIGINT,
  action_type TEXT,
  entity_type TEXT,
  entity_id TEXT,
  entity_name TEXT,
  action_description TEXT,
  created_at TIMESTAMP WITH TIME ZONE
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    al.id,
    al.action_type,
    al.entity_type,
    al.entity_id,
    al.entity_name,
    al.action_description,
    al.created_at
  FROM public.activity_log al
  WHERE al.user_id = p_user_id
  ORDER BY al.created_at DESC
  LIMIT p_limit;
END;
$$;

-- ============================================================
-- 11. FUNÇÃO PARA ESTATÍSTICAS DE VENDEDOR
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_seller_stats(
  p_user_id TEXT,
  p_start_date TIMESTAMP DEFAULT NULL,
  p_end_date TIMESTAMP DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_stats JSONB;
BEGIN
  SELECT jsonb_build_object(
    'total_quotations', COUNT(*),
    'accepted_quotations', COUNT(*) FILTER (WHERE status = 'accepted'),
    'pending_quotations', COUNT(*) FILTER (WHERE status IN ('sent', 'viewed')),
    'rejected_quotations', COUNT(*) FILTER (WHERE status = 'rejected'),
    'total_value', COALESCE(SUM(total), 0),
    'accepted_value', COALESCE(SUM(total) FILTER (WHERE status = 'accepted'), 0),
    'total_commission', COALESCE(SUM(total * commission_rate / 100) FILTER (WHERE status = 'accepted'), 0),
    'conversion_rate', ROUND(
      (COUNT(*) FILTER (WHERE status = 'accepted')::NUMERIC / NULLIF(COUNT(*), 0) * 100),
      2
    ),
    'avg_quotation_value', ROUND(COALESCE(AVG(total), 0), 2),
    'follow_ups_completed', (
      SELECT COUNT(*) 
      FROM public.quotation_follow_up f
      JOIN public.quotation q ON q.id = f.quotation_id
      WHERE f.assigned_to = p_user_id 
        AND f.status = 'completed'
        AND (p_start_date IS NULL OR f.completed_date >= p_start_date)
        AND (p_end_date IS NULL OR f.completed_date <= p_end_date)
    ),
    'follow_ups_pending', (
      SELECT COUNT(*) 
      FROM public.quotation_follow_up f
      JOIN public.quotation q ON q.id = f.quotation_id
      WHERE f.assigned_to = p_user_id 
        AND f.status = 'pending'
    )
  )
  INTO v_stats
  FROM public.quotation
  WHERE (assigned_to_user_id = p_user_id OR created_by_user_id = p_user_id)
    AND (p_start_date IS NULL OR quotation_date >= p_start_date)
    AND (p_end_date IS NULL OR quotation_date <= p_end_date);
    
  RETURN v_stats;
END;
$$;

-- ============================================================
-- 12. TRIGGER PARA REGISTRAR MUDANÇAS NA COTAÇÃO
-- ============================================================
CREATE OR REPLACE FUNCTION public.log_quotation_changes()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Log de criação
  IF (TG_OP = 'INSERT') THEN
    INSERT INTO public.activity_log (
      user_id, user_name, user_email, action_type, entity_type,
      entity_id, entity_name, action_description, new_value
    )
    VALUES (
      COALESCE(NEW.created_by_user_id, 'system'),
      COALESCE(NEW.created_by_user_name, 'Sistema'),
      NULL,
      'create',
      'quotation',
      NEW.id::TEXT,
      NEW.quotation_number,
      'Cotação criada',
      jsonb_build_object(
        'client_name', NEW.client_name,
        'total', NEW.total,
        'status', NEW.status
      )
    );
  END IF;
  
  -- Log de mudança de status
  IF (TG_OP = 'UPDATE' AND OLD.status IS DISTINCT FROM NEW.status) THEN
    INSERT INTO public.activity_log (
      user_id, user_name, user_email, action_type, entity_type,
      entity_id, entity_name, action_description, old_value, new_value
    )
    VALUES (
      COALESCE(NEW.modified_by_user_id, 'system'),
      COALESCE(NEW.modified_by_user_name, 'Sistema'),
      NULL,
      'status_change',
      'quotation',
      NEW.id::TEXT,
      NEW.quotation_number,
      'Status alterado de ' || OLD.status || ' para ' || NEW.status,
      jsonb_build_object('status', OLD.status),
      jsonb_build_object('status', NEW.status)
    );
  END IF;
  
  -- Log de mudança de valor
  IF (TG_OP = 'UPDATE' AND OLD.total IS DISTINCT FROM NEW.total) THEN
    INSERT INTO public.activity_log (
      user_id, user_name, user_email, action_type, entity_type,
      entity_id, entity_name, action_description, old_value, new_value
    )
    VALUES (
      COALESCE(NEW.modified_by_user_id, 'system'),
      COALESCE(NEW.modified_by_user_name, 'Sistema'),
      NULL,
      'update_value',
      'quotation',
      NEW.id::TEXT,
      NEW.quotation_number,
      'Valor alterado',
      jsonb_build_object('total', OLD.total),
      jsonb_build_object('total', NEW.total)
    );
  END IF;
  
  RETURN NEW;
END;
$$;

-- Criar trigger
DROP TRIGGER IF EXISTS quotation_audit_trigger ON public.quotation;
CREATE TRIGGER quotation_audit_trigger
  AFTER INSERT OR UPDATE ON public.quotation
  FOR EACH ROW
  EXECUTE FUNCTION public.log_quotation_changes();

-- ============================================================
-- 13. POLÍTICAS RLS (Row Level Security)
-- ============================================================

-- Activity Log - todos podem ver seus próprios logs
ALTER TABLE public.activity_log ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS activity_log_select_own ON public.activity_log;
CREATE POLICY activity_log_select_own ON public.activity_log
  FOR SELECT
  USING (auth.uid()::TEXT = user_id OR auth.role() = 'authenticated');

-- Follow-ups - vendedores veem seus próprios follow-ups
ALTER TABLE public.quotation_follow_up ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS follow_up_select_assigned ON public.quotation_follow_up;
CREATE POLICY follow_up_select_assigned ON public.quotation_follow_up
  FOR SELECT
  USING (auth.uid()::TEXT = assigned_to OR auth.role() = 'authenticated');

DROP POLICY IF EXISTS follow_up_insert_auth ON public.quotation_follow_up;
CREATE POLICY follow_up_insert_auth ON public.quotation_follow_up
  FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

DROP POLICY IF EXISTS follow_up_update_assigned ON public.quotation_follow_up;
CREATE POLICY follow_up_update_assigned ON public.quotation_follow_up
  FOR UPDATE
  USING (auth.uid()::TEXT = assigned_to OR auth.role() = 'authenticated');

-- ============================================================
-- FIM DA MIGRATION
-- ============================================================
COMMENT ON TABLE public.activity_log IS 'Registro de todas as atividades dos usuários no sistema para auditoria';
COMMENT ON TABLE public.quotation_follow_up IS 'Follow-ups agendados para cotações com atribuição de responsável';
COMMENT ON VIEW public.quotation_commissions IS 'View para relatório de comissões de vendedores';


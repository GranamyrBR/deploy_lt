-- ╔════════════════════════════════════════════════════════════════╗
-- ║  FIX: Adicionar ORDER BY em funções com LIMIT                  ║
-- ╚════════════════════════════════════════════════════════════════╝
-- 
-- Corrige erro PGRST109 em stored functions do banco de dados
-- Execute no Supabase Dashboard > SQL Editor

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 1️⃣  suggest_services_by_history - Adicionar ORDER BY antes do LIMIT
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CREATE OR REPLACE FUNCTION public.suggest_services_by_history(p_client_id bigint)
RETURNS jsonb AS $$
DECLARE
  result jsonb;
BEGIN
  SELECT COALESCE(jsonb_agg(suggestion), '[]'::jsonb) INTO result
  FROM (
    SELECT 
      'service' as kind,
      s.id,
      s.name,
      s.price,
      COUNT(DISTINCT sale.id) as relevance_score,
      'Previously purchased' as reason
    FROM public.service s
    INNER JOIN public.sale_item si ON si.service_id = s.id
    INNER JOIN public.sale sale ON sale.id = si.sales_id
    WHERE sale.customer_id = p_client_id
      AND s.is_active = true
    GROUP BY s.id, s.name, s.price
    ORDER BY relevance_score DESC, s.id DESC  -- ✅ Adicionado s.id para garantir ordem determinística
    LIMIT 5
  ) suggestion;
  
  RETURN result;
END;
$$ LANGUAGE plpgsql;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 2️⃣  suggest_services_by_destination - Adicionar ORDER BY antes do LIMIT
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CREATE OR REPLACE FUNCTION public.suggest_services_by_destination(p_destination text)
RETURNS jsonb AS $$
DECLARE
  result jsonb;
BEGIN
  SELECT COALESCE(jsonb_agg(suggestion), '[]'::jsonb) INTO result
  FROM (
    SELECT 
      'service' as kind,
      s.id,
      s.name,
      s.price,
      'Popular in ' || p_destination as reason
    FROM public.service s
    WHERE s.is_active = true
      AND (
        s.name ILIKE '%' || p_destination || '%'
        OR s.description ILIKE '%' || p_destination || '%'
        OR s.name ILIKE '%tour%'
        OR s.name ILIKE '%transfer%'
      )
    ORDER BY s.price DESC, s.id DESC  -- ✅ Adicionado s.id para garantir ordem determinística
    LIMIT 5
  ) suggestion;
  
  RETURN result;
END;
$$ LANGUAGE plpgsql;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 3️⃣  get_smart_suggestions - Corrigir subquery com LIMIT
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CREATE OR REPLACE FUNCTION public.get_smart_suggestions(
  p_quotation_id bigint DEFAULT NULL,
  p_client_id bigint DEFAULT NULL,
  p_destination text DEFAULT NULL,
  p_hotel text DEFAULT NULL
)
RETURNS jsonb AS $$
DECLARE
  result jsonb := '[]'::jsonb;
  v_quotation record;
  v_history_suggestions jsonb;
  v_destination_suggestions jsonb;
  v_hotel_suggestions jsonb;
BEGIN
  -- Get quotation data if provided
  IF p_quotation_id IS NOT NULL THEN
    SELECT * INTO v_quotation FROM public.quotation WHERE id = p_quotation_id;
    IF FOUND THEN
      p_client_id := COALESCE(p_client_id, v_quotation.client_id);
      p_destination := COALESCE(p_destination, v_quotation.destination);
      p_hotel := COALESCE(p_hotel, v_quotation.hotel);
    END IF;
  END IF;
  
  -- Get suggestions by history
  IF p_client_id IS NOT NULL THEN
    SELECT public.suggest_services_by_history(p_client_id) INTO v_history_suggestions;
  END IF;
  
  -- Get suggestions by destination
  IF p_destination IS NOT NULL AND p_destination != '' THEN
    SELECT public.suggest_services_by_destination(p_destination) INTO v_destination_suggestions;
  END IF;
  
  -- Get hotel-based suggestions (transfers, city tours)
  IF p_hotel IS NOT NULL AND p_hotel != '' THEN
    SELECT COALESCE(jsonb_agg(s), '[]'::jsonb) INTO v_hotel_suggestions
    FROM (
      SELECT 'service' as kind, svc.id, svc.name, svc.price, 'Recommended for hotel guests' as reason
      FROM public.service svc
      WHERE svc.is_active = true 
        AND (svc.name ILIKE '%transfer%' OR svc.name ILIKE '%city%' OR svc.name ILIKE '%tour%')
      ORDER BY svc.id DESC  -- ✅ Adicionado ORDER BY
      LIMIT 3
    ) s;
  END IF;
  
  -- Combine all suggestions
  result := COALESCE(v_history_suggestions, '[]'::jsonb) || 
            COALESCE(v_destination_suggestions, '[]'::jsonb) || 
            COALESCE(v_hotel_suggestions, '[]'::jsonb);
  
  RETURN result;
END;
$$ LANGUAGE plpgsql;

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 4️⃣  get_pending_pre_trip_actions - Já tem ORDER BY ✅
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Esta função JÁ está correta com ORDER BY antes do LIMIT:
-- ORDER BY pta.scheduled_at ASC, pta.priority DESC

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 5️⃣  Outras funções em quotation_read_functions.sql
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Verificar se get_quotations_with_filters já tem ORDER BY
-- Se não tiver, adicione antes do LIMIT p_limit

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 6️⃣  Funções em audit_system.sql
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Verificar get_audit_logs - provavelmente precisa de ORDER BY

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 📋 VERIFICAÇÃO
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Testar as funções corrigidas
SELECT public.suggest_services_by_history(1);
SELECT public.suggest_services_by_destination('New York');
SELECT public.get_smart_suggestions(NULL, 1, 'New York', 'Hilton');

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- ✅ CONCLUSÃO
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Funções corrigidas:
-- 1. suggest_services_by_history
-- 2. suggest_services_by_destination  
-- 3. get_smart_suggestions (subquery hotel)

-- Próximo passo: verificar outras funções se necessário

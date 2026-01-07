-- ============================================================
-- QUOTATION SYSTEM ENHANCEMENTS
-- Version: 2.0
-- Date: 2025-12-05
-- Description: Performance indexes, audit columns, multi-currency,
--              enhanced business logic and suggestion engine
-- ============================================================

-- ============================================================
-- 1. PERFORMANCE INDEXES
-- ============================================================

-- Primary search indexes
CREATE INDEX IF NOT EXISTS idx_quotation_client_id ON public.quotation(client_id);
CREATE INDEX IF NOT EXISTS idx_quotation_agency_id ON public.quotation(agency_id);
CREATE INDEX IF NOT EXISTS idx_quotation_status ON public.quotation(status);
CREATE INDEX IF NOT EXISTS idx_quotation_date_desc ON public.quotation(quotation_date DESC);
CREATE INDEX IF NOT EXISTS idx_quotation_travel_date ON public.quotation(travel_date);

-- Composite index for common queries
CREATE INDEX IF NOT EXISTS idx_quotation_client_status_date 
  ON public.quotation(client_id, status, quotation_date DESC);

-- Index for expiring quotations (partial index for better performance)
CREATE INDEX IF NOT EXISTS idx_quotation_expiring 
  ON public.quotation(expiration_date) 
  WHERE status = 'sent' AND expiration_date IS NOT NULL;

-- Index for pending pre-trip actions
CREATE INDEX IF NOT EXISTS idx_pre_trip_action_pending 
  ON public.pre_trip_action(scheduled_at) 
  WHERE status = 'pending';

-- Quotation items index
CREATE INDEX IF NOT EXISTS idx_quotation_item_quotation_id 
  ON public.quotation_item(quotation_id);

-- Version history index
CREATE INDEX IF NOT EXISTS idx_quotation_version_quotation_id 
  ON public.quotation_version(quotation_id, version_number DESC);

-- ============================================================
-- 2. AUDIT AND TRACKING COLUMNS
-- ============================================================

-- Add audit columns to quotation
ALTER TABLE public.quotation 
  ADD COLUMN IF NOT EXISTS updated_by text,
  ADD COLUMN IF NOT EXISTS converted_to_sale_id bigint REFERENCES public.sale(id),
  ADD COLUMN IF NOT EXISTS converted_at timestamp without time zone,
  ADD COLUMN IF NOT EXISTS last_reminder_sent_at timestamp without time zone,
  ADD COLUMN IF NOT EXISTS reminder_count int DEFAULT 0,
  ADD COLUMN IF NOT EXISTS follow_up_date timestamp without time zone,
  ADD COLUMN IF NOT EXISTS assigned_to_user_id uuid REFERENCES public."user"(id);

-- ============================================================
-- 3. MULTI-CURRENCY SUPPORT
-- ============================================================

ALTER TABLE public.quotation 
  ADD COLUMN IF NOT EXISTS currency_id int REFERENCES public.currency(currency_id),
  ADD COLUMN IF NOT EXISTS exchange_rate_to_usd numeric DEFAULT 1.0,
  ADD COLUMN IF NOT EXISTS subtotal_in_brl numeric,
  ADD COLUMN IF NOT EXISTS subtotal_in_usd numeric,
  ADD COLUMN IF NOT EXISTS total_in_brl numeric,
  ADD COLUMN IF NOT EXISTS total_in_usd numeric;

-- Add multi-currency to quotation items
ALTER TABLE public.quotation_item
  ADD COLUMN IF NOT EXISTS currency_id int REFERENCES public.currency(currency_id),
  ADD COLUMN IF NOT EXISTS exchange_rate_to_usd numeric DEFAULT 1.0,
  ADD COLUMN IF NOT EXISTS value_in_brl numeric,
  ADD COLUMN IF NOT EXISTS value_in_usd numeric,
  ADD COLUMN IF NOT EXISTS total_in_brl numeric,
  ADD COLUMN IF NOT EXISTS total_in_usd numeric;

-- ============================================================
-- 4. ENHANCED PRE-TRIP ACTIONS
-- ============================================================

-- Add more fields to pre-trip actions
ALTER TABLE public.pre_trip_action
  ADD COLUMN IF NOT EXISTS executed_at timestamp without time zone,
  ADD COLUMN IF NOT EXISTS executed_by text,
  ADD COLUMN IF NOT EXISTS error_message text,
  ADD COLUMN IF NOT EXISTS retry_count int DEFAULT 0,
  ADD COLUMN IF NOT EXISTS max_retries int DEFAULT 3,
  ADD COLUMN IF NOT EXISTS priority int DEFAULT 1,
  ADD COLUMN IF NOT EXISTS notes text,
  ADD COLUMN IF NOT EXISTS contact_phone text,
  ADD COLUMN IF NOT EXISTS contact_email text;

-- ============================================================
-- 5. CUSTOMER PREFERENCES TABLE (for personalized suggestions)
-- ============================================================

CREATE TABLE IF NOT EXISTS public.customer_preference (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  client_id bigint NOT NULL REFERENCES public.contact(id) ON DELETE CASCADE,
  preference_type text NOT NULL CHECK (preference_type IN ('service_category','product_category','hotel_type','vehicle_type','destination','budget_range')),
  preference_value text NOT NULL,
  preference_score numeric DEFAULT 1.0,
  source text DEFAULT 'inferred' CHECK (source IN ('explicit','inferred','purchase_history')),
  created_at timestamp without time zone DEFAULT now(),
  updated_at timestamp without time zone DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_customer_preference_client 
  ON public.customer_preference(client_id);

ALTER TABLE public.customer_preference ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS customer_preference_select_auth ON public.customer_preference;
CREATE POLICY customer_preference_select_auth 
  ON public.customer_preference FOR SELECT USING (auth.uid() IS NOT NULL);
DROP POLICY IF EXISTS customer_preference_insert_auth ON public.customer_preference;
CREATE POLICY customer_preference_insert_auth 
  ON public.customer_preference FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
DROP POLICY IF EXISTS customer_preference_update_auth ON public.customer_preference;
CREATE POLICY customer_preference_update_auth 
  ON public.customer_preference FOR UPDATE USING (auth.uid() IS NOT NULL);

-- ============================================================
-- 6. QUOTATION TEMPLATE TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS public.quotation_template (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name text NOT NULL,
  description text,
  type text NOT NULL CHECK (type IN ('tourism','corporate','event','transfer','other')),
  default_items jsonb DEFAULT '[]'::jsonb,
  default_notes text,
  default_cancellation_policy text,
  default_payment_terms text,
  is_active boolean DEFAULT true,
  created_by text NOT NULL,
  created_at timestamp without time zone DEFAULT now(),
  updated_at timestamp without time zone DEFAULT now()
);

ALTER TABLE public.quotation_template ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS quotation_template_select_auth ON public.quotation_template;
CREATE POLICY quotation_template_select_auth 
  ON public.quotation_template FOR SELECT USING (auth.uid() IS NOT NULL);
DROP POLICY IF EXISTS quotation_template_insert_auth ON public.quotation_template;
CREATE POLICY quotation_template_insert_auth 
  ON public.quotation_template FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- ============================================================
-- 7. ENHANCED RPC FUNCTIONS
-- ============================================================

-- Get quotation with items and full details
CREATE OR REPLACE FUNCTION public.get_quotation_full(p_id bigint)
RETURNS jsonb AS $$
DECLARE
  result jsonb;
BEGIN
  SELECT jsonb_build_object(
    'quotation', to_jsonb(q),
    'items', COALESCE((
      SELECT jsonb_agg(to_jsonb(qi) ORDER BY qi.id)
      FROM public.quotation_item qi
      WHERE qi.quotation_id = q.id
    ), '[]'::jsonb),
    'versions', COALESCE((
      SELECT jsonb_agg(jsonb_build_object(
        'version_number', qv.version_number,
        'changed_by', qv.changed_by,
        'created_at', qv.created_at
      ) ORDER BY qv.version_number DESC)
      FROM public.quotation_version qv
      WHERE qv.quotation_id = q.id
    ), '[]'::jsonb),
    'pending_actions', COALESCE((
      SELECT jsonb_agg(to_jsonb(pa) ORDER BY pa.scheduled_at)
      FROM public.pre_trip_action pa
      WHERE pa.quotation_id = q.id AND pa.status = 'pending'
    ), '[]'::jsonb),
    'client', COALESCE((
      SELECT to_jsonb(c)
      FROM public.contact c
      WHERE c.id = q.client_id
    ), null),
    'agency', COALESCE((
      SELECT to_jsonb(a)
      FROM public.account a
      WHERE a.id = q.agency_id
    ), null)
  ) INTO result
  FROM public.quotation q
  WHERE q.id = p_id;
  
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Enhanced save quotation with multi-currency support
CREATE OR REPLACE FUNCTION public.save_quotation_v2(p_quotation jsonb) 
RETURNS jsonb AS $$
DECLARE
  qid bigint;
  v_exchange_rate numeric;
  v_currency_code text;
BEGIN
  IF p_quotation IS NULL THEN 
    RAISE EXCEPTION 'Quotation payload required'; 
  END IF;
  
  -- Get exchange rate
  v_currency_code := COALESCE(p_quotation->>'currency', 'USD');
  v_exchange_rate := COALESCE((p_quotation->>'exchangeRateToUsd')::numeric, 1.0);
  
  INSERT INTO public.quotation(
    quotation_number, type, status,
    client_id, client_name, client_email, client_phone,
    agency_id, agency_commission_rate,
    travel_date, return_date, passenger_count,
    origin, destination, hotel, room_type, nights, vehicle, driver,
    quotation_date, expiration_date, sent_date, viewed_date, accepted_date, rejected_date,
    subtotal, discount_amount, tax_rate, tax_amount, total, currency,
    exchange_rate_to_usd, subtotal_in_usd, total_in_usd, subtotal_in_brl, total_in_brl,
    notes, special_requests, cancellation_policy, payment_terms,
    created_by, created_at, assigned_to_user_id
  ) VALUES (
    p_quotation->>'quotationNumber', 
    COALESCE(p_quotation->>'type', 'tourism'), 
    COALESCE(p_quotation->>'status', 'draft'),
    (p_quotation->'clientContact'->>'id')::bigint, 
    p_quotation->>'clientName', 
    p_quotation->>'clientEmail', 
    p_quotation->>'clientPhone',
    (p_quotation->'agency'->>'id')::bigint, 
    (p_quotation->>'agencyCommissionRate')::numeric,
    (p_quotation->>'travelDate')::timestamp, 
    (p_quotation->>'returnDate')::timestamp, 
    COALESCE((p_quotation->>'passengerCount')::int, 1),
    p_quotation->>'origin', 
    p_quotation->>'destination', 
    p_quotation->>'hotel', 
    p_quotation->>'roomType', 
    (p_quotation->>'nights')::int, 
    p_quotation->>'vehicle', 
    p_quotation->>'driver',
    COALESCE((p_quotation->>'quotationDate')::timestamp, now()), 
    (p_quotation->>'expirationDate')::timestamp,
    (p_quotation->>'sentDate')::timestamp, 
    (p_quotation->>'viewedDate')::timestamp, 
    (p_quotation->>'acceptedDate')::timestamp, 
    (p_quotation->>'rejectedDate')::timestamp,
    COALESCE((p_quotation->>'subtotal')::numeric, 0),
    COALESCE((p_quotation->>'discountAmount')::numeric, 0),
    COALESCE((p_quotation->>'taxRate')::numeric, 0),
    COALESCE((p_quotation->>'taxAmount')::numeric, 0),
    COALESCE((p_quotation->>'total')::numeric, 0),
    v_currency_code,
    v_exchange_rate,
    CASE WHEN v_currency_code = 'USD' THEN (p_quotation->>'subtotal')::numeric 
         ELSE (p_quotation->>'subtotal')::numeric / NULLIF(v_exchange_rate, 0) END,
    CASE WHEN v_currency_code = 'USD' THEN (p_quotation->>'total')::numeric 
         ELSE (p_quotation->>'total')::numeric / NULLIF(v_exchange_rate, 0) END,
    CASE WHEN v_currency_code = 'BRL' THEN (p_quotation->>'subtotal')::numeric 
         ELSE (p_quotation->>'subtotal')::numeric * v_exchange_rate END,
    CASE WHEN v_currency_code = 'BRL' THEN (p_quotation->>'total')::numeric 
         ELSE (p_quotation->>'total')::numeric * v_exchange_rate END,
    p_quotation->>'notes', 
    p_quotation->>'specialRequests', 
    p_quotation->>'cancellationPolicy', 
    p_quotation->>'paymentTerms',
    COALESCE(p_quotation->>'createdBy', 'system'), 
    COALESCE((p_quotation->>'createdAt')::timestamp, now()),
    (p_quotation->>'assignedToUserId')::uuid
  ) RETURNING id INTO qid;

  -- Insert items with currency conversion
  INSERT INTO public.quotation_item(
    quotation_id, description, date, value, category, 
    service_id, product_id, quantity, discount, notes, 
    start_time, end_time, location, provider,
    exchange_rate_to_usd, value_in_usd, value_in_brl, total_in_usd, total_in_brl
  )
  SELECT 
    qid,
    item->>'description', 
    (item->>'date')::timestamp, 
    COALESCE((item->>'value')::numeric, 0),
    COALESCE(item->>'category', 'service'), 
    (item->>'serviceId')::bigint, 
    (item->>'productId')::bigint,
    COALESCE((item->>'quantity')::int, 1), 
    (item->>'discount')::numeric, 
    item->>'notes',
    (item->>'startTime')::timestamp, 
    (item->>'endTime')::timestamp, 
    item->>'location', 
    item->>'provider',
    v_exchange_rate,
    CASE WHEN v_currency_code = 'USD' THEN (item->>'value')::numeric 
         ELSE (item->>'value')::numeric / NULLIF(v_exchange_rate, 0) END,
    CASE WHEN v_currency_code = 'BRL' THEN (item->>'value')::numeric 
         ELSE (item->>'value')::numeric * v_exchange_rate END,
    CASE WHEN v_currency_code = 'USD' THEN (item->>'value')::numeric * COALESCE((item->>'quantity')::int, 1)
         ELSE ((item->>'value')::numeric * COALESCE((item->>'quantity')::int, 1)) / NULLIF(v_exchange_rate, 0) END,
    CASE WHEN v_currency_code = 'BRL' THEN (item->>'value')::numeric * COALESCE((item->>'quantity')::int, 1)
         ELSE ((item->>'value')::numeric * COALESCE((item->>'quantity')::int, 1)) * v_exchange_rate END
  FROM jsonb_array_elements(COALESCE(p_quotation->'items', '[]'::jsonb)) AS item;

  RETURN jsonb_build_object('id', qid, 'success', true);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Enhanced update quotation with full patch support
CREATE OR REPLACE FUNCTION public.update_quotation_v2(p_id bigint, p_patch jsonb, p_updated_by text DEFAULT 'system')
RETURNS jsonb AS $$
DECLARE
  v_old_status text;
  v_new_status text;
BEGIN
  -- Get old status for comparison
  SELECT status INTO v_old_status FROM public.quotation WHERE id = p_id;
  
  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Quotation not found');
  END IF;
  
  v_new_status := COALESCE(p_patch->>'status', v_old_status);
  
  UPDATE public.quotation SET
    status = v_new_status,
    notes = COALESCE(p_patch->>'notes', notes),
    special_requests = COALESCE(p_patch->>'specialRequests', special_requests),
    hotel = COALESCE(p_patch->>'hotel', hotel),
    vehicle = COALESCE(p_patch->>'vehicle', vehicle),
    driver = COALESCE(p_patch->>'driver', driver),
    passenger_count = COALESCE((p_patch->>'passengerCount')::int, passenger_count),
    travel_date = COALESCE((p_patch->>'travelDate')::timestamp, travel_date),
    return_date = COALESCE((p_patch->>'returnDate')::timestamp, return_date),
    expiration_date = COALESCE((p_patch->>'expirationDate')::timestamp, expiration_date),
    discount_amount = COALESCE((p_patch->>'discountAmount')::numeric, discount_amount),
    -- Status-specific dates
    sent_date = CASE WHEN v_new_status = 'sent' AND v_old_status != 'sent' THEN now() ELSE sent_date END,
    viewed_date = CASE WHEN v_new_status = 'viewed' AND v_old_status != 'viewed' THEN now() ELSE viewed_date END,
    accepted_date = CASE WHEN v_new_status = 'accepted' AND v_old_status != 'accepted' THEN now() ELSE accepted_date END,
    rejected_date = CASE WHEN v_new_status = 'rejected' AND v_old_status != 'rejected' THEN now() ELSE rejected_date END,
    updated_at = now(),
    updated_by = p_updated_by
  WHERE id = p_id;
  
  RETURN jsonb_build_object('success', true, 'old_status', v_old_status, 'new_status', v_new_status);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Duplicate quotation (create new based on existing)
CREATE OR REPLACE FUNCTION public.duplicate_quotation(p_id bigint, p_created_by text DEFAULT 'system')
RETURNS bigint AS $$
DECLARE
  new_qid bigint;
  new_number text;
BEGIN
  -- Generate new quotation number
  new_number := 'QT-' || to_char(now(), 'YYYY') || '-' || 
                LPAD(nextval('quotation_id_seq')::text, 6, '0');
  
  -- Copy quotation
  INSERT INTO public.quotation(
    quotation_number, type, status,
    client_id, client_name, client_email, client_phone,
    agency_id, agency_commission_rate,
    travel_date, return_date, passenger_count,
    origin, destination, hotel, room_type, nights, vehicle, driver,
    quotation_date, expiration_date,
    subtotal, discount_amount, tax_rate, tax_amount, total, currency,
    exchange_rate_to_usd, subtotal_in_usd, total_in_usd, subtotal_in_brl, total_in_brl,
    notes, special_requests, cancellation_policy, payment_terms,
    created_by, created_at
  )
  SELECT 
    new_number, type, 'draft',
    client_id, client_name, client_email, client_phone,
    agency_id, agency_commission_rate,
    travel_date, return_date, passenger_count,
    origin, destination, hotel, room_type, nights, vehicle, driver,
    now(), now() + interval '7 days',
    subtotal, discount_amount, tax_rate, tax_amount, total, currency,
    exchange_rate_to_usd, subtotal_in_usd, total_in_usd, subtotal_in_brl, total_in_brl,
    notes, special_requests, cancellation_policy, payment_terms,
    p_created_by, now()
  FROM public.quotation
  WHERE id = p_id
  RETURNING id INTO new_qid;
  
  -- Copy items
  INSERT INTO public.quotation_item(
    quotation_id, description, date, value, category,
    service_id, product_id, quantity, discount, notes,
    start_time, end_time, location, provider,
    exchange_rate_to_usd, value_in_usd, value_in_brl, total_in_usd, total_in_brl
  )
  SELECT 
    new_qid, description, date, value, category,
    service_id, product_id, quantity, discount, notes,
    start_time, end_time, location, provider,
    exchange_rate_to_usd, value_in_usd, value_in_brl, total_in_usd, total_in_brl
  FROM public.quotation_item
  WHERE quotation_id = p_id;
  
  RETURN new_qid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Convert quotation to sale
CREATE OR REPLACE FUNCTION public.convert_quotation_to_sale(
  p_quotation_id bigint,
  p_user_id uuid,
  p_payment_method text DEFAULT 'pending'
)
RETURNS bigint AS $$
DECLARE
  v_quotation record;
  v_sale_id bigint;
BEGIN
  -- Get quotation
  SELECT * INTO v_quotation FROM public.quotation WHERE id = p_quotation_id;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Quotation not found';
  END IF;
  
  IF v_quotation.status != 'accepted' THEN
    RAISE EXCEPTION 'Only accepted quotations can be converted to sales';
  END IF;
  
  IF v_quotation.converted_to_sale_id IS NOT NULL THEN
    RAISE EXCEPTION 'Quotation already converted to sale %', v_quotation.converted_to_sale_id;
  END IF;
  
  -- Create sale
  INSERT INTO public.sale(
    customer_id, user_id, currency_id,
    total_amount, total_amount_usd, total_amount_brl,
    exchange_rate_to_usd, payment_method, status,
    notes, sale_date, created_at
  ) VALUES (
    v_quotation.client_id,
    p_user_id,
    COALESCE(v_quotation.currency_id, 1),
    v_quotation.total,
    v_quotation.total_in_usd,
    v_quotation.total_in_brl,
    v_quotation.exchange_rate_to_usd,
    p_payment_method,
    'pending',
    'Converted from quotation ' || v_quotation.quotation_number,
    now(),
    now()
  ) RETURNING id INTO v_sale_id;
  
  -- Create sale items from quotation items
  INSERT INTO public.sale_item(
    sales_id, service_id, product_id, description,
    quantity, unit_price_at_sale, item_total,
    unit_price_in_usd, unit_price_in_brl,
    item_total_in_usd, item_total_in_brl,
    exchange_rate_to_usd, pax
  )
  SELECT 
    v_sale_id,
    qi.service_id,
    qi.product_id,
    qi.description,
    qi.quantity,
    qi.value,
    qi.value * qi.quantity,
    qi.value_in_usd,
    qi.value_in_brl,
    qi.total_in_usd,
    qi.total_in_brl,
    qi.exchange_rate_to_usd,
    v_quotation.passenger_count
  FROM public.quotation_item qi
  WHERE qi.quotation_id = p_quotation_id;
  
  -- Update quotation
  UPDATE public.quotation SET
    converted_to_sale_id = v_sale_id,
    converted_at = now(),
    updated_at = now()
  WHERE id = p_quotation_id;
  
  RETURN v_sale_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- 8. ENHANCED SUGGESTION ENGINE
-- ============================================================

-- Suggest services based on customer purchase history
CREATE OR REPLACE FUNCTION public.suggest_services_by_history(p_client_id bigint)
RETURNS jsonb AS $$
DECLARE
  result jsonb;
BEGIN
  SELECT COALESCE(jsonb_agg(suggestion), '[]'::jsonb) INTO result
  FROM (
    -- Get services similar to what client has bought before
    SELECT DISTINCT 
      'service' as kind,
      s.id,
      s.name,
      s.price,
      'Based on purchase history' as reason,
      COUNT(*) as relevance_score
    FROM public.service s
    INNER JOIN public.sale_item si ON si.service_id = s.id
    INNER JOIN public.sale sale ON sale.id = si.sales_id
    WHERE sale.customer_id = p_client_id
      AND s.is_active = true
    GROUP BY s.id, s.name, s.price
    ORDER BY relevance_score DESC
    LIMIT 5
  ) suggestion;
  
  RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Suggest services by destination
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
    ORDER BY s.price DESC
    LIMIT 5
  ) suggestion;
  
  RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Enhanced suggestion function combining multiple factors
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
      LIMIT 3
    ) s;
  END IF;
  
  -- Combine all suggestions
  result := jsonb_build_object(
    'by_history', COALESCE(v_history_suggestions, '[]'::jsonb),
    'by_destination', COALESCE(v_destination_suggestions, '[]'::jsonb),
    'by_hotel', COALESCE(v_hotel_suggestions, '[]'::jsonb)
  );
  
  RETURN result;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- 9. PRE-TRIP ACTION FUNCTIONS
-- ============================================================

-- Get pending pre-trip actions
CREATE OR REPLACE FUNCTION public.get_pending_pre_trip_actions(p_limit int DEFAULT 50)
RETURNS TABLE(
  id bigint,
  quotation_id bigint,
  action_type text,
  scheduled_at timestamp,
  client_name text,
  client_phone text,
  client_email text,
  travel_date timestamp,
  quotation_number text
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    pta.id,
    pta.quotation_id,
    pta.action_type,
    pta.scheduled_at,
    q.client_name,
    q.client_phone,
    q.client_email,
    q.travel_date,
    q.quotation_number
  FROM public.pre_trip_action pta
  INNER JOIN public.quotation q ON q.id = pta.quotation_id
  WHERE pta.status = 'pending'
    AND pta.scheduled_at <= now()
    AND q.status IN ('sent', 'viewed', 'accepted')
  ORDER BY pta.scheduled_at ASC, pta.priority DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- Mark action as done
CREATE OR REPLACE FUNCTION public.complete_pre_trip_action(
  p_action_id bigint,
  p_executed_by text DEFAULT 'system',
  p_notes text DEFAULT NULL
)
RETURNS boolean AS $$
BEGIN
  UPDATE public.pre_trip_action SET
    status = 'done',
    executed_at = now(),
    executed_by = p_executed_by,
    notes = COALESCE(p_notes, notes)
  WHERE id = p_action_id AND status = 'pending';
  
  RETURN FOUND;
END;
$$ LANGUAGE plpgsql;

-- Mark action as failed
CREATE OR REPLACE FUNCTION public.fail_pre_trip_action(
  p_action_id bigint,
  p_error_message text,
  p_retry boolean DEFAULT true
)
RETURNS boolean AS $$
DECLARE
  v_current_retries int;
  v_max_retries int;
BEGIN
  SELECT retry_count, max_retries INTO v_current_retries, v_max_retries
  FROM public.pre_trip_action WHERE id = p_action_id;
  
  IF p_retry AND v_current_retries < v_max_retries THEN
    -- Schedule retry in 1 hour
    UPDATE public.pre_trip_action SET
      retry_count = retry_count + 1,
      scheduled_at = now() + interval '1 hour',
      error_message = p_error_message
    WHERE id = p_action_id;
  ELSE
    -- Mark as permanently failed
    UPDATE public.pre_trip_action SET
      status = 'failed',
      error_message = p_error_message,
      executed_at = now()
    WHERE id = p_action_id;
  END IF;
  
  RETURN FOUND;
END;
$$ LANGUAGE plpgsql;

-- Enhanced trigger: create multiple pre-trip actions
CREATE OR REPLACE FUNCTION public.enqueue_pre_trip_actions_v2() 
RETURNS trigger AS $$
BEGIN
  -- Only for accepted quotations with travel date
  IF NEW.status = 'accepted' AND NEW.travel_date IS NOT NULL THEN
    -- 48h before: WhatsApp confirmation
    INSERT INTO public.pre_trip_action(
      quotation_id, action_type, scheduled_at, priority,
      contact_phone, contact_email
    ) VALUES (
      NEW.id, 'whatsapp', NEW.travel_date - interval '48 hours', 2,
      NEW.client_phone, NEW.client_email
    ) ON CONFLICT DO NOTHING;
    
    -- 24h before: Phone call
    INSERT INTO public.pre_trip_action(
      quotation_id, action_type, scheduled_at, priority,
      contact_phone, contact_email
    ) VALUES (
      NEW.id, 'call', NEW.travel_date - interval '24 hours', 1,
      NEW.client_phone, NEW.client_email
    ) ON CONFLICT DO NOTHING;
    
    -- 2h before: Final WhatsApp
    INSERT INTO public.pre_trip_action(
      quotation_id, action_type, scheduled_at, priority,
      contact_phone, contact_email
    ) VALUES (
      NEW.id, 'whatsapp', NEW.travel_date - interval '2 hours', 3,
      NEW.client_phone, NEW.client_email
    ) ON CONFLICT DO NOTHING;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Recreate trigger with new function
DROP TRIGGER IF EXISTS trg_pre_trip_enqueue ON public.quotation;
CREATE TRIGGER trg_pre_trip_enqueue
AFTER INSERT OR UPDATE OF status ON public.quotation
FOR EACH ROW 
WHEN (NEW.status = 'accepted')
EXECUTE FUNCTION public.enqueue_pre_trip_actions_v2();

-- ============================================================
-- 10. STATISTICS AND REPORTING
-- ============================================================

-- Quotation statistics
CREATE OR REPLACE FUNCTION public.get_quotation_stats(
  p_from_date timestamp DEFAULT NULL,
  p_to_date timestamp DEFAULT NULL,
  p_user_id text DEFAULT NULL
)
RETURNS jsonb AS $$
DECLARE
  result jsonb;
BEGIN
  SELECT jsonb_build_object(
    'total', COUNT(*),
    'by_status', jsonb_object_agg(status, cnt),
    'total_value_usd', SUM(total_in_usd),
    'avg_value_usd', AVG(total_in_usd),
    'conversion_rate', 
      ROUND(COUNT(*) FILTER (WHERE status = 'accepted')::numeric / 
            NULLIF(COUNT(*) FILTER (WHERE status IN ('sent','viewed','accepted','rejected')), 0) * 100, 2)
  ) INTO result
  FROM (
    SELECT status, COUNT(*) as cnt, total_in_usd
    FROM public.quotation
    WHERE (p_from_date IS NULL OR quotation_date >= p_from_date)
      AND (p_to_date IS NULL OR quotation_date <= p_to_date)
      AND (p_user_id IS NULL OR created_by = p_user_id)
    GROUP BY status, total_in_usd
  ) stats;
  
  RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Create sequence for quotation numbers if not exists
CREATE SEQUENCE IF NOT EXISTS quotation_number_seq START 1000;

COMMENT ON TABLE public.quotation IS 'Main quotation table with full audit trail and multi-currency support';
COMMENT ON TABLE public.quotation_item IS 'Line items for quotations with currency conversion';
COMMENT ON TABLE public.quotation_version IS 'Version history for quotation changes';
COMMENT ON TABLE public.pre_trip_action IS 'Queue of automated actions before trip date';
COMMENT ON TABLE public.customer_preference IS 'Customer preferences for personalized suggestions';
COMMENT ON TABLE public.quotation_template IS 'Reusable quotation templates';


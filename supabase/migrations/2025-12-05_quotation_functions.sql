-- ============================================================
-- QUOTATION SYSTEM - RPC FUNCTIONS
-- Part 2 of migration
-- ============================================================

-- ============================================================
-- BASIC RPC FUNCTIONS (Legacy compatibility)
-- ============================================================

-- RPC: save quotation with validation (legacy)
CREATE OR REPLACE FUNCTION public.save_quotation(p_quotation jsonb) RETURNS bigint AS $$
DECLARE
  qid bigint;
BEGIN
  IF p_quotation IS NULL THEN RAISE EXCEPTION 'Quotation payload required'; END IF;
  INSERT INTO public.quotation(
    quotation_number, type, status,
    client_id, client_name, client_email, client_phone,
    agency_id, agency_commission_rate,
    travel_date, return_date, passenger_count,
    origin, destination, hotel, room_type, nights, vehicle, driver,
    quotation_date, expiration_date, sent_date, viewed_date, accepted_date, rejected_date,
    subtotal, discount_amount, tax_rate, tax_amount, total, currency,
    notes, special_requests, cancellation_policy, payment_terms,
    created_by, created_at
  ) VALUES (
    p_quotation->>'quotationNumber', 
    COALESCE(p_quotation->>'type', 'tourism'),
    COALESCE(p_quotation->>'status','draft'),
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
    COALESCE(p_quotation->>'currency','USD'),
    p_quotation->>'notes', 
    p_quotation->>'specialRequests', 
    p_quotation->>'cancellationPolicy', 
    p_quotation->>'paymentTerms',
    COALESCE(p_quotation->>'createdBy', 'system'), 
    COALESCE((p_quotation->>'createdAt')::timestamp, now())
  ) RETURNING id INTO qid;

  -- items
  INSERT INTO public.quotation_item(quotation_id, description, date, value, category, service_id, product_id, quantity, discount, notes, start_time, end_time, location, provider)
  SELECT qid,
    (item->>'description'), 
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
    item->>'provider'
  FROM jsonb_array_elements(COALESCE(p_quotation->'items', '[]'::jsonb)) AS item;

  RETURN qid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RPC: Enhanced save quotation with multi-currency support
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
    CASE WHEN v_currency_code = 'USD' THEN COALESCE((p_quotation->>'subtotal')::numeric, 0)
         ELSE COALESCE((p_quotation->>'subtotal')::numeric, 0) / NULLIF(v_exchange_rate, 0) END,
    CASE WHEN v_currency_code = 'USD' THEN COALESCE((p_quotation->>'total')::numeric, 0)
         ELSE COALESCE((p_quotation->>'total')::numeric, 0) / NULLIF(v_exchange_rate, 0) END,
    CASE WHEN v_currency_code = 'BRL' THEN COALESCE((p_quotation->>'subtotal')::numeric, 0)
         ELSE COALESCE((p_quotation->>'subtotal')::numeric, 0) * v_exchange_rate END,
    CASE WHEN v_currency_code = 'BRL' THEN COALESCE((p_quotation->>'total')::numeric, 0)
         ELSE COALESCE((p_quotation->>'total')::numeric, 0) * v_exchange_rate END,
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
    CASE WHEN v_currency_code = 'USD' THEN COALESCE((item->>'value')::numeric, 0)
         ELSE COALESCE((item->>'value')::numeric, 0) / NULLIF(v_exchange_rate, 0) END,
    CASE WHEN v_currency_code = 'BRL' THEN COALESCE((item->>'value')::numeric, 0)
         ELSE COALESCE((item->>'value')::numeric, 0) * v_exchange_rate END,
    CASE WHEN v_currency_code = 'USD' THEN COALESCE((item->>'value')::numeric, 0) * COALESCE((item->>'quantity')::int, 1)
         ELSE (COALESCE((item->>'value')::numeric, 0) * COALESCE((item->>'quantity')::int, 1)) / NULLIF(v_exchange_rate, 0) END,
    CASE WHEN v_currency_code = 'BRL' THEN COALESCE((item->>'value')::numeric, 0) * COALESCE((item->>'quantity')::int, 1)
         ELSE (COALESCE((item->>'value')::numeric, 0) * COALESCE((item->>'quantity')::int, 1)) * v_exchange_rate END
  FROM jsonb_array_elements(COALESCE(p_quotation->'items', '[]'::jsonb)) AS item;

  RETURN jsonb_build_object('id', qid, 'success', true);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RPC: search quotations by criteria
CREATE OR REPLACE FUNCTION public.search_quotations(
  p_id bigint DEFAULT NULL, 
  p_client_id bigint DEFAULT NULL, 
  p_from timestamp DEFAULT NULL, 
  p_to timestamp DEFAULT NULL
) RETURNS SETOF public.quotation AS $$
BEGIN
  RETURN QUERY
  SELECT * FROM public.quotation q
  WHERE (p_id IS NULL OR q.id = p_id)
    AND (p_client_id IS NULL OR q.client_id = p_client_id)
    AND (p_from IS NULL OR q.quotation_date >= p_from)
    AND (p_to IS NULL OR q.quotation_date <= p_to)
  ORDER BY q.quotation_date DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RPC: update quotation (legacy)
CREATE OR REPLACE FUNCTION public.update_quotation(p_id bigint, p_patch jsonb) RETURNS void AS $$
BEGIN
  UPDATE public.quotation SET
    status = COALESCE(p_patch->>'status', status),
    notes = COALESCE(p_patch->>'notes', notes),
    updated_at = now()
  WHERE id = p_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RPC: Enhanced update quotation with full patch support
CREATE OR REPLACE FUNCTION public.update_quotation_v2(
  p_id bigint, 
  p_patch jsonb, 
  p_updated_by text DEFAULT 'system'
)
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

-- Continue with more functions...
COMMENT ON TABLE public.quotation IS 'Main quotation table with full audit trail and multi-currency support';
COMMENT ON TABLE public.quotation_item IS 'Line items for quotations with currency conversion';
COMMENT ON TABLE public.quotation_version IS 'Version history for quotation changes';
COMMENT ON TABLE public.pre_trip_action IS 'Queue of automated actions before trip date';
COMMENT ON TABLE public.customer_preference IS 'Customer preferences for personalized suggestions';
COMMENT ON TABLE public.quotation_template IS 'Reusable quotation templates';


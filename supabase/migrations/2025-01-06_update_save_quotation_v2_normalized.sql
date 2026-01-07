-- ============================================================
-- ATUALIZAÇÃO: save_quotation_v2 - Versão NORMALIZADA
-- Salva bagagens em tabela separada (NÃO JSON)
-- ============================================================

CREATE OR REPLACE FUNCTION public.save_quotation_v2(p_quotation jsonb)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_quotation_id bigint;
  v_item jsonb;
  v_luggage jsonb;
BEGIN
  -- Inserir ou atualizar cotação principal
  INSERT INTO public.quotation (
    quotation_number,
    type,
    status,
    client_id,
    client_name,
    client_email,
    client_phone,
    client_document,
    agency_id,
    agency_commission_rate,
    travel_date,
    return_date,
    passenger_count,
    origin,
    destination,
    hotel,
    room_type,
    nights,
    vehicle,
    driver,
    quotation_date,
    expiration_date,
    sent_date,
    viewed_date,
    accepted_date,
    rejected_date,
    subtotal,
    discount_amount,
    tax_rate,
    tax_amount,
    total,
    currency,
    notes,
    special_requests,
    cancellation_policy,
    payment_terms,
    created_by,
    created_at,
    updated_at
  )
  VALUES (
    (p_quotation->>'quotationNumber')::text,
    (p_quotation->>'type')::text,
    (p_quotation->>'status')::text,
    (p_quotation->>'clientId')::bigint,
    (p_quotation->>'clientName')::text,
    (p_quotation->>'clientEmail')::text,
    (p_quotation->>'clientPhone')::text,
    (p_quotation->>'clientDocument')::text,
    (p_quotation->>'agencyId')::bigint,
    (p_quotation->>'agencyCommissionRate')::numeric,
    (p_quotation->>'travelDate')::timestamp,
    (p_quotation->>'returnDate')::timestamp,
    (p_quotation->>'passengerCount')::int,
    (p_quotation->>'origin')::text,
    (p_quotation->>'destination')::text,
    (p_quotation->>'hotel')::text,
    (p_quotation->>'roomType')::text,
    (p_quotation->>'nights')::int,
    (p_quotation->>'vehicle')::text,
    (p_quotation->>'driver')::text,
    (p_quotation->>'quotationDate')::timestamp,
    (p_quotation->>'expirationDate')::timestamp,
    (p_quotation->>'sentDate')::timestamp,
    (p_quotation->>'viewedDate')::timestamp,
    (p_quotation->>'acceptedDate')::timestamp,
    (p_quotation->>'rejectedDate')::timestamp,
    (p_quotation->>'subtotal')::numeric,
    (p_quotation->>'discountAmount')::numeric,
    (p_quotation->>'taxRate')::numeric,
    (p_quotation->>'taxAmount')::numeric,
    (p_quotation->>'total')::numeric,
    (p_quotation->>'currency')::text,
    (p_quotation->>'notes')::text,
    (p_quotation->>'specialRequests')::text,
    (p_quotation->>'cancellationPolicy')::text,
    (p_quotation->>'paymentTerms')::text,
    (p_quotation->>'createdBy')::text,
    COALESCE((p_quotation->>'createdAt')::timestamp, NOW()),
    NOW()
  )
  ON CONFLICT (quotation_number) DO UPDATE SET
    type = EXCLUDED.type,
    status = EXCLUDED.status,
    client_name = EXCLUDED.client_name,
    client_email = EXCLUDED.client_email,
    client_phone = EXCLUDED.client_phone,
    client_document = EXCLUDED.client_document,
    agency_id = EXCLUDED.agency_id,
    agency_commission_rate = EXCLUDED.agency_commission_rate,
    travel_date = EXCLUDED.travel_date,
    return_date = EXCLUDED.return_date,
    passenger_count = EXCLUDED.passenger_count,
    origin = EXCLUDED.origin,
    destination = EXCLUDED.destination,
    hotel = EXCLUDED.hotel,
    room_type = EXCLUDED.room_type,
    nights = EXCLUDED.nights,
    vehicle = EXCLUDED.vehicle,
    driver = EXCLUDED.driver,
    expiration_date = EXCLUDED.expiration_date,
    subtotal = EXCLUDED.subtotal,
    discount_amount = EXCLUDED.discount_amount,
    tax_rate = EXCLUDED.tax_rate,
    tax_amount = EXCLUDED.tax_amount,
    total = EXCLUDED.total,
    currency = EXCLUDED.currency,
    notes = EXCLUDED.notes,
    special_requests = EXCLUDED.special_requests,
    cancellation_policy = EXCLUDED.cancellation_policy,
    payment_terms = EXCLUDED.payment_terms,
    updated_at = NOW()
  RETURNING id INTO v_quotation_id;

  -- ============================================================
  -- DELETAR ITENS ANTIGOS
  -- ============================================================
  DELETE FROM public.quotation_item WHERE quotation_id = v_quotation_id;

  -- ============================================================
  -- INSERIR ITENS
  -- ============================================================
  FOR v_item IN SELECT * FROM jsonb_array_elements(p_quotation->'items')
  LOOP
    INSERT INTO public.quotation_item (
      quotation_id,
      description,
      date,
      value,
      category,
      service_id,
      product_id,
      quantity,
      discount,
      notes,
      start_time,
      end_time,
      location,
      provider
    )
    VALUES (
      v_quotation_id,
      (v_item->>'description')::text,
      (v_item->>'date')::timestamp,
      (v_item->>'value')::numeric,
      (v_item->>'category')::text,
      (v_item->>'serviceId')::bigint,
      (v_item->>'productId')::bigint,
      (v_item->>'quantity')::int,
      (v_item->>'discount')::numeric,
      (v_item->>'notes')::text,
      (v_item->>'startTime')::timestamp,
      (v_item->>'endTime')::timestamp,
      (v_item->>'location')::text,
      (v_item->>'provider')::text
    );
  END LOOP;

  -- ============================================================
  -- DELETAR BAGAGENS ANTIGAS (se for update)
  -- ============================================================
  DELETE FROM public.quotation_luggage WHERE quotation_id = v_quotation_id;

  -- ============================================================
  -- INSERIR BAGAGENS DE FORMA NORMALIZADA
  -- ============================================================
  IF p_quotation->'luggage' IS NOT NULL THEN
    FOR v_luggage IN SELECT * FROM jsonb_array_elements(p_quotation->'luggage')
    LOOP
      -- Só inserir se quantity > 0
      IF (v_luggage->>'quantity')::int > 0 THEN
        INSERT INTO public.quotation_luggage (
          quotation_id,
          luggage_type,
          quantity
        )
        VALUES (
          v_quotation_id,
          (v_luggage->>'type')::text,
          (v_luggage->>'quantity')::int
        )
        ON CONFLICT (quotation_id, luggage_type) 
        DO UPDATE SET 
          quantity = EXCLUDED.quantity,
          updated_at = NOW();
      END IF;
    END LOOP;
  END IF;

  -- Retornar resultado
  RETURN jsonb_build_object(
    'success', true,
    'id', v_quotation_id,
    'quotationNumber', p_quotation->>'quotationNumber'
  );

EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object(
    'success', false,
    'error', SQLERRM
  );
END;
$$;

-- Adicionar comentário
COMMENT ON FUNCTION public.save_quotation_v2(jsonb) IS 
'Salva ou atualiza cotação com todos os campos. Bagagens são salvas de forma normalizada na tabela quotation_luggage.';

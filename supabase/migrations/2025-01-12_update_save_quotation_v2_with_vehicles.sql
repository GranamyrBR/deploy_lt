-- ============================================================================
-- ATUALIZAÇÃO: save_quotation_v2 - Adicionar Suporte a Veículos
-- Data: 2025-01-12
-- Descrição: Atualiza a função save_quotation_v2 para salvar veículos
--            de forma normalizada na tabela quotation_vehicle
-- ============================================================================

CREATE OR REPLACE FUNCTION public.save_quotation_v2(p_quotation jsonb)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_quotation_id bigint;
  v_item jsonb;
  v_luggage jsonb;
  v_vehicle jsonb;
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
    updated_by,
    created_at,
    updated_at,
    currency_id,
    exchange_rate_to_usd,
    subtotal_in_brl,
    subtotal_in_usd,
    total_in_brl,
    total_in_usd
  ) VALUES (
    (p_quotation->>'quotation_number')::text,
    (p_quotation->>'type')::text,
    COALESCE((p_quotation->>'status')::text, 'draft'),
    (p_quotation->>'client_id')::bigint,
    (p_quotation->>'client_name')::text,
    (p_quotation->>'client_email')::text,
    (p_quotation->>'client_phone')::text,
    (p_quotation->>'client_document')::text,
    (p_quotation->>'agency_id')::bigint,
    (p_quotation->>'agency_commission_rate')::numeric,
    (p_quotation->>'travel_date')::timestamp,
    (p_quotation->>'return_date')::timestamp,
    COALESCE((p_quotation->>'passenger_count')::integer, 1),
    (p_quotation->>'origin')::text,
    (p_quotation->>'destination')::text,
    (p_quotation->>'hotel')::text,
    (p_quotation->>'room_type')::text,
    (p_quotation->>'nights')::integer,
    (p_quotation->>'vehicle')::text,
    (p_quotation->>'driver')::text,
    COALESCE((p_quotation->>'quotation_date')::timestamp, NOW()),
    (p_quotation->>'expiration_date')::timestamp,
    (p_quotation->>'sent_date')::timestamp,
    (p_quotation->>'viewed_date')::timestamp,
    (p_quotation->>'accepted_date')::timestamp,
    (p_quotation->>'rejected_date')::timestamp,
    (p_quotation->>'subtotal')::numeric,
    COALESCE((p_quotation->>'discount_amount')::numeric, 0),
    COALESCE((p_quotation->>'tax_rate')::numeric, 0),
    COALESCE((p_quotation->>'tax_amount')::numeric, 0),
    (p_quotation->>'total')::numeric,
    COALESCE((p_quotation->>'currency')::text, 'USD'),
    (p_quotation->>'notes')::text,
    (p_quotation->>'special_requests')::text,
    (p_quotation->>'cancellation_policy')::text,
    (p_quotation->>'payment_terms')::text,
    COALESCE((p_quotation->>'created_by')::text, 'system'),
    (p_quotation->>'updated_by')::text,
    COALESCE((p_quotation->>'created_at')::timestamp, NOW()),
    COALESCE((p_quotation->>'updated_at')::timestamp, NOW()),
    (p_quotation->>'currency_id')::integer,
    (p_quotation->>'exchange_rate_to_usd')::numeric,
    (p_quotation->>'subtotal_in_brl')::numeric,
    (p_quotation->>'subtotal_in_usd')::numeric,
    (p_quotation->>'total_in_brl')::numeric,
    (p_quotation->>'total_in_usd')::numeric
  )
  RETURNING id INTO v_quotation_id;

  -- Inserir itens da cotação (se houver)
  IF p_quotation ? 'items' AND jsonb_array_length(p_quotation->'items') > 0 THEN
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_quotation->'items')
    LOOP
      INSERT INTO public.quotation_item (
        quotation_id,
        service_id,
        product_id,
        description,
        quantity,
        date,
        value,
        category,
        discount,
        notes,
        start_time,
        end_time,
        location,
        provider
      ) VALUES (
        v_quotation_id,
        (v_item->>'service_id')::bigint,
        (v_item->>'product_id')::bigint,
        (v_item->>'description')::text,
        COALESCE((v_item->>'quantity')::integer, 1),
        COALESCE((v_item->>'date')::timestamp, NOW()),
        (v_item->>'value')::numeric,
        COALESCE((v_item->>'category')::text, 'service'),
        (v_item->>'discount')::numeric,
        (v_item->>'notes')::text,
        (v_item->>'start_time')::timestamp,
        (v_item->>'end_time')::timestamp,
        (v_item->>'location')::text,
        (v_item->>'provider')::text
      );
    END LOOP;
  END IF;

  -- Inserir bagagens (se houver) na tabela normalizada
  IF p_quotation ? 'luggage' AND jsonb_array_length(p_quotation->'luggage') > 0 THEN
    FOR v_luggage IN SELECT * FROM jsonb_array_elements(p_quotation->'luggage')
    LOOP
      INSERT INTO public.quotation_luggage (
        quotation_id,
        luggage_type,
        quantity
      ) VALUES (
        v_quotation_id,
        (v_luggage->>'type')::text,
        (v_luggage->>'quantity')::integer
      );
    END LOOP;
  END IF;

  -- ✨ NOVO: Inserir veículos (se houver) na tabela normalizada
  IF p_quotation ? 'vehicles' AND jsonb_array_length(p_quotation->'vehicles') > 0 THEN
    FOR v_vehicle IN SELECT * FROM jsonb_array_elements(p_quotation->'vehicles')
    LOOP
      INSERT INTO public.quotation_vehicle (
        quotation_id,
        vehicle_type,
        quantity,
        max_passengers
      ) VALUES (
        v_quotation_id,
        (v_vehicle->>'type')::text,
        (v_vehicle->>'quantity')::integer,
        (v_vehicle->>'max_passengers')::integer  -- Corrigido para snake_case
      );
    END LOOP;
  END IF;

  -- Retornar resultado com ID e sucesso
  RETURN jsonb_build_object(
    'id', v_quotation_id,
    'success', true,
    'quotation_number', p_quotation->>'quotation_number'
  );

EXCEPTION
  WHEN OTHERS THEN
    -- Em caso de erro, retornar detalhes
    RETURN jsonb_build_object(
      'success', false,
      'error', SQLERRM,
      'error_detail', SQLSTATE
    );
END;
$$;

-- Comentário atualizado
COMMENT ON FUNCTION public.save_quotation_v2(jsonb) IS 
'Salva ou atualiza cotação com todos os campos. Bagagens e veículos são salvos de forma normalizada nas tabelas quotation_luggage e quotation_vehicle.';

-- ============================================================================
-- FIM DA ATUALIZAÇÃO
-- ============================================================================

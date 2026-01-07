-- Quotation persistence schema
create table if not exists public.quotation (
  id bigint generated always as identity primary key,
  quotation_number text not null unique,
  type text not null check (type in ('tourism','corporate','event','transfer','other')),
  status text not null default 'draft' check (status in ('draft','sent','viewed','accepted','rejected','expired','cancelled')),
  client_id bigint references public.contact(id) on delete set null,
  client_name text not null,
  client_email text not null,
  client_phone text,
  agency_id bigint references public.account(id) on delete set null,
  agency_commission_rate numeric,
  travel_date timestamp without time zone not null,
  return_date timestamp without time zone,
  passenger_count int not null default 1,
  origin text,
  destination text,
  hotel text,
  room_type text,
  nights int,
  vehicle text,
  driver text,
  quotation_date timestamp without time zone not null default now(),
  expiration_date timestamp without time zone,
  sent_date timestamp without time zone,
  viewed_date timestamp without time zone,
  accepted_date timestamp without time zone,
  rejected_date timestamp without time zone,
  subtotal numeric not null,
  discount_amount numeric not null default 0,
  tax_rate numeric not null default 0,
  tax_amount numeric not null default 0,
  total numeric not null,
  currency text not null default 'USD',
  notes text,
  special_requests text,
  cancellation_policy text,
  payment_terms text,
  created_by text not null,
  created_at timestamp without time zone not null default now(),
  updated_at timestamp without time zone
);

alter table public.quotation enable row level security;
create policy quotation_select_authenticated on public.quotation for select using (auth.uid() is not null);
create policy quotation_insert_authenticated on public.quotation for insert with check (auth.uid() is not null);
create policy quotation_update_authenticated on public.quotation for update using (auth.uid() is not null);

create table if not exists public.quotation_item (
  id bigint generated always as identity primary key,
  quotation_id bigint not null references public.quotation(id) on delete cascade,
  description text not null,
  date timestamp without time zone not null,
  value numeric not null,
  category text not null check (category in ('service','product','ticket','fee')),
  service_id bigint references public.service(id) on delete set null,
  product_id bigint references public.product(id) on delete set null,
  quantity int not null default 1,
  discount numeric,
  notes text,
  start_time timestamp without time zone,
  end_time timestamp without time zone,
  location text,
  provider text
);

alter table public.quotation_item enable row level security;
create policy quotation_item_select_authenticated on public.quotation_item for select using (auth.uid() is not null);
create policy quotation_item_insert_authenticated on public.quotation_item for insert with check (auth.uid() is not null);
create policy quotation_item_update_authenticated on public.quotation_item for update using (auth.uid() is not null);

-- Version history
create table if not exists public.quotation_version (
  id bigint generated always as identity primary key,
  quotation_id bigint not null references public.quotation(id) on delete cascade,
  version_number int not null,
  snapshot jsonb not null,
  changed_by text not null,
  created_at timestamp without time zone not null default now()
);

create or replace function public.record_quotation_version() returns trigger as $$
begin
  insert into public.quotation_version(quotation_id, version_number, snapshot, changed_by)
  values (new.id,
          coalesce((select max(version_number) from public.quotation_version where quotation_id = new.id), 0) + 1,
          to_jsonb(new),
          coalesce(new.created_by, 'system'));
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_quotation_version on public.quotation;
create trigger trg_quotation_version
after insert or update on public.quotation
for each row execute function public.record_quotation_version();

-- Pre-trip actions queue
create table if not exists public.pre_trip_action (
  id bigint generated always as identity primary key,
  quotation_id bigint not null references public.quotation(id) on delete cascade,
  action_type text not null check (action_type in ('call','email','whatsapp')),
  scheduled_at timestamp without time zone not null,
  status text not null default 'pending' check (status in ('pending','done','failed')),
  created_at timestamp without time zone not null default now()
);

create or replace function public.enqueue_pre_trip_actions() returns trigger as $$
begin
  if new.travel_date is not null then
    insert into public.pre_trip_action(quotation_id, action_type, scheduled_at)
    values (new.id, 'call', new.travel_date - interval '24 hours');
  end if;
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_pre_trip_enqueue on public.quotation;
create trigger trg_pre_trip_enqueue
after insert on public.quotation
for each row execute function public.enqueue_pre_trip_actions();

-- RPC: save quotation with validation
create or replace function public.save_quotation(p_quotation jsonb) returns bigint as $$
declare
  qid bigint;
begin
  if p_quotation is null then raise exception 'Quotation payload required'; end if;
  insert into public.quotation(
    quotation_number, type, status,
    client_id, client_name, client_email, client_phone,
    agency_id, agency_commission_rate,
    travel_date, return_date, passenger_count,
    origin, destination, hotel, room_type, nights, vehicle, driver,
    quotation_date, expiration_date, sent_date, viewed_date, accepted_date, rejected_date,
    subtotal, discount_amount, tax_rate, tax_amount, total, currency,
    notes, special_requests, cancellation_policy, payment_terms,
    created_by, created_at
  ) values (
    p_quotation->>'quotationNumber', p_quotation->>'type', coalesce(p_quotation->>'status','draft'),
    (p_quotation->'clientContact'->>'id')::bigint, p_quotation->>'clientName', p_quotation->>'clientEmail', p_quotation->>'clientPhone',
    (p_quotation->'agency'->>'id')::bigint, (p_quotation->>'agencyCommissionRate')::numeric,
    (p_quotation->>'travelDate')::timestamp, (p_quotation->>'returnDate')::timestamp, (p_quotation->>'passengerCount')::int,
    p_quotation->>'origin', p_quotation->>'destination', p_quotation->>'hotel', p_quotation->>'roomType', (p_quotation->>'nights')::int, p_quotation->>'vehicle', p_quotation->>'driver',
    coalesce((p_quotation->>'quotationDate')::timestamp, now()), (p_quotation->>'expirationDate')::timestamp,
    (p_quotation->>'sentDate')::timestamp, (p_quotation->>'viewedDate')::timestamp, (p_quotation->>'acceptedDate')::timestamp, (p_quotation->>'rejectedDate')::timestamp,
    (p_quotation->>'subtotal')::numeric, (p_quotation->>'discountAmount')::numeric,
    (p_quotation->>'taxRate')::numeric, (p_quotation->>'taxAmount')::numeric, (p_quotation->>'total')::numeric, coalesce(p_quotation->>'currency','USD'),
    p_quotation->>'notes', p_quotation->>'specialRequests', p_quotation->>'cancellationPolicy', p_quotation->>'paymentTerms',
    coalesce(p_quotation->>'createdBy', 'system'), coalesce((p_quotation->>'createdAt')::timestamp, now())
  ) returning id into qid;

  -- items
  insert into public.quotation_item(quotation_id, description, date, value, category, service_id, product_id, quantity, discount, notes, start_time, end_time, location, provider)
  select qid,
    (item->>'description'), (item->>'date')::timestamp, (item->>'value')::numeric,
    (item->>'category'), (item->>'serviceId')::bigint, (item->>'productId')::bigint,
    coalesce((item->>'quantity')::int, 1), (item->>'discount')::numeric, (item->>'notes'),
    (item->>'startTime')::timestamp, (item->>'endTime')::timestamp, (item->>'location'), (item->>'provider')
  from jsonb_array_elements(p_quotation->'items') as item;

  return qid;
end;
$$ language plpgsql security definer;

-- RPC: search quotations by criteria
create or replace function public.search_quotations(p_id bigint default null, p_client_id bigint default null, p_from timestamp default null, p_to timestamp default null) returns setof public.quotation as $$
begin
  return query
  select * from public.quotation q
  where (p_id is null or q.id = p_id)
    and (p_client_id is null or q.client_id = p_client_id)
    and (p_from is null or q.quotation_date >= p_from)
    and (p_to is null or q.quotation_date <= p_to)
  order by q.quotation_date desc;
end;
$$ language plpgsql security definer;

-- RPC: update quotation (partial) and record version
create or replace function public.update_quotation(p_id bigint, p_patch jsonb) returns void as $$
begin
  update public.quotation set
    status = coalesce(p_patch->>'status', status),
    notes = coalesce(p_patch->>'notes', notes),
    updated_at = now()
  where id = p_id;
end;
$$ language plpgsql security definer;

-- Suggestions: addons based on hotel/roomType/product categories
create or replace function public.suggest_addons_for_quotation(p_id bigint) returns jsonb as $$
declare q record; result jsonb := '[]'::jsonb;
begin
  select * into q from public.quotation where id = p_id;
  if not found then return result; end if;
  -- simple heuristic: if hotel present, suggest transfer and city-tour
  result := (
    select jsonb_agg(s) from (
      select 'service' as kind, svc.id, svc.name, svc.price
      from public.service svc
      where svc.is_active = true and (svc.name ilike '%transfer%' or svc.name ilike '%city%')
      limit 5
    ) s
  );
  return coalesce(result, '[]'::jsonb);
end;
$$ language plpgsql;

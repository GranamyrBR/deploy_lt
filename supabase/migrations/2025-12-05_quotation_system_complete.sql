-- ============================================================
-- QUOTATION SYSTEM - COMPLETE IMPLEMENTATION
-- Version: 2.0 Complete
-- Date: 2025-12-05
-- Description: Full quotation system with base tables and enhancements
-- ============================================================

-- ============================================================
-- PART 1: BASE TABLES
-- ============================================================

-- Main quotation table
CREATE TABLE IF NOT EXISTS public.quotation (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  quotation_number text NOT NULL UNIQUE,
  type text NOT NULL CHECK (type IN ('tourism','corporate','event','transfer','other')),
  status text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft','sent','viewed','accepted','rejected','expired','cancelled')),
  client_id bigint REFERENCES public.contact(id) ON DELETE SET NULL,
  client_name text NOT NULL,
  client_email text NOT NULL,
  client_phone text,
  agency_id bigint REFERENCES public.account(id) ON DELETE SET NULL,
  agency_commission_rate numeric,
  travel_date timestamp without time zone NOT NULL,
  return_date timestamp without time zone,
  passenger_count int NOT NULL DEFAULT 1,
  origin text,
  destination text,
  hotel text,
  room_type text,
  nights int,
  vehicle text,
  driver text,
  quotation_date timestamp without time zone NOT NULL DEFAULT now(),
  expiration_date timestamp without time zone,
  sent_date timestamp without time zone,
  viewed_date timestamp without time zone,
  accepted_date timestamp without time zone,
  rejected_date timestamp without time zone,
  subtotal numeric NOT NULL,
  discount_amount numeric NOT NULL DEFAULT 0,
  tax_rate numeric NOT NULL DEFAULT 0,
  tax_amount numeric NOT NULL DEFAULT 0,
  total numeric NOT NULL,
  currency text NOT NULL DEFAULT 'USD',
  notes text,
  special_requests text,
  cancellation_policy text,
  payment_terms text,
  created_by text NOT NULL,
  created_at timestamp without time zone NOT NULL DEFAULT now(),
  updated_at timestamp without time zone
);

ALTER TABLE public.quotation ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS quotation_select_authenticated ON public.quotation;
CREATE POLICY quotation_select_authenticated ON public.quotation FOR SELECT USING (auth.uid() IS NOT NULL);
DROP POLICY IF EXISTS quotation_insert_authenticated ON public.quotation;
CREATE POLICY quotation_insert_authenticated ON public.quotation FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
DROP POLICY IF EXISTS quotation_update_authenticated ON public.quotation;
CREATE POLICY quotation_update_authenticated ON public.quotation FOR UPDATE USING (auth.uid() IS NOT NULL);

-- Quotation items table
CREATE TABLE IF NOT EXISTS public.quotation_item (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  quotation_id bigint NOT NULL REFERENCES public.quotation(id) ON DELETE CASCADE,
  description text NOT NULL,
  date timestamp without time zone NOT NULL,
  value numeric NOT NULL,
  category text NOT NULL CHECK (category IN ('service','product','ticket','fee')),
  service_id bigint REFERENCES public.service(id) ON DELETE SET NULL,
  product_id bigint REFERENCES public.product(product_id) ON DELETE SET NULL,
  quantity int NOT NULL DEFAULT 1,
  discount numeric,
  notes text,
  start_time timestamp without time zone,
  end_time timestamp without time zone,
  location text,
  provider text
);

ALTER TABLE public.quotation_item ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS quotation_item_select_authenticated ON public.quotation_item;
CREATE POLICY quotation_item_select_authenticated ON public.quotation_item FOR SELECT USING (auth.uid() IS NOT NULL);
DROP POLICY IF EXISTS quotation_item_insert_authenticated ON public.quotation_item;
CREATE POLICY quotation_item_insert_authenticated ON public.quotation_item FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
DROP POLICY IF EXISTS quotation_item_update_authenticated ON public.quotation_item;
CREATE POLICY quotation_item_update_authenticated ON public.quotation_item FOR UPDATE USING (auth.uid() IS NOT NULL);

-- Version history table
CREATE TABLE IF NOT EXISTS public.quotation_version (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  quotation_id bigint NOT NULL REFERENCES public.quotation(id) ON DELETE CASCADE,
  version_number int NOT NULL,
  snapshot jsonb NOT NULL,
  changed_by text NOT NULL,
  created_at timestamp without time zone NOT NULL DEFAULT now()
);

-- Pre-trip actions queue
CREATE TABLE IF NOT EXISTS public.pre_trip_action (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  quotation_id bigint NOT NULL REFERENCES public.quotation(id) ON DELETE CASCADE,
  action_type text NOT NULL CHECK (action_type IN ('call','email','whatsapp')),
  scheduled_at timestamp without time zone NOT NULL,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','done','failed')),
  created_at timestamp without time zone NOT NULL DEFAULT now()
);

-- ============================================================
-- PART 2: ENHANCEMENTS - Additional columns
-- ============================================================

-- Add audit columns to quotation
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='quotation' AND column_name='updated_by') THEN
    ALTER TABLE public.quotation ADD COLUMN updated_by text;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='quotation' AND column_name='converted_to_sale_id') THEN
    ALTER TABLE public.quotation ADD COLUMN converted_to_sale_id bigint REFERENCES public.sale(id);
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='quotation' AND column_name='converted_at') THEN
    ALTER TABLE public.quotation ADD COLUMN converted_at timestamp without time zone;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='quotation' AND column_name='last_reminder_sent_at') THEN
    ALTER TABLE public.quotation ADD COLUMN last_reminder_sent_at timestamp without time zone;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='quotation' AND column_name='reminder_count') THEN
    ALTER TABLE public.quotation ADD COLUMN reminder_count int DEFAULT 0;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='quotation' AND column_name='follow_up_date') THEN
    ALTER TABLE public.quotation ADD COLUMN follow_up_date timestamp without time zone;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='quotation' AND column_name='assigned_to_user_id') THEN
    ALTER TABLE public.quotation ADD COLUMN assigned_to_user_id uuid REFERENCES public."user"(id);
  END IF;
  
  -- Multi-currency columns
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='quotation' AND column_name='currency_id') THEN
    ALTER TABLE public.quotation ADD COLUMN currency_id int REFERENCES public.currency(currency_id);
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='quotation' AND column_name='exchange_rate_to_usd') THEN
    ALTER TABLE public.quotation ADD COLUMN exchange_rate_to_usd numeric DEFAULT 1.0;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='quotation' AND column_name='subtotal_in_brl') THEN
    ALTER TABLE public.quotation ADD COLUMN subtotal_in_brl numeric;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='quotation' AND column_name='subtotal_in_usd') THEN
    ALTER TABLE public.quotation ADD COLUMN subtotal_in_usd numeric;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='quotation' AND column_name='total_in_brl') THEN
    ALTER TABLE public.quotation ADD COLUMN total_in_brl numeric;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='quotation' AND column_name='total_in_usd') THEN
    ALTER TABLE public.quotation ADD COLUMN total_in_usd numeric;
  END IF;
END $$;

-- Add columns to quotation_item
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='quotation_item' AND column_name='currency_id') THEN
    ALTER TABLE public.quotation_item ADD COLUMN currency_id int REFERENCES public.currency(currency_id);
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='quotation_item' AND column_name='exchange_rate_to_usd') THEN
    ALTER TABLE public.quotation_item ADD COLUMN exchange_rate_to_usd numeric DEFAULT 1.0;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='quotation_item' AND column_name='value_in_brl') THEN
    ALTER TABLE public.quotation_item ADD COLUMN value_in_brl numeric;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='quotation_item' AND column_name='value_in_usd') THEN
    ALTER TABLE public.quotation_item ADD COLUMN value_in_usd numeric;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='quotation_item' AND column_name='total_in_brl') THEN
    ALTER TABLE public.quotation_item ADD COLUMN total_in_brl numeric;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='quotation_item' AND column_name='total_in_usd') THEN
    ALTER TABLE public.quotation_item ADD COLUMN total_in_usd numeric;
  END IF;
END $$;

-- Add columns to pre_trip_action
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='pre_trip_action' AND column_name='executed_at') THEN
    ALTER TABLE public.pre_trip_action ADD COLUMN executed_at timestamp without time zone;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='pre_trip_action' AND column_name='executed_by') THEN
    ALTER TABLE public.pre_trip_action ADD COLUMN executed_by text;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='pre_trip_action' AND column_name='error_message') THEN
    ALTER TABLE public.pre_trip_action ADD COLUMN error_message text;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='pre_trip_action' AND column_name='retry_count') THEN
    ALTER TABLE public.pre_trip_action ADD COLUMN retry_count int DEFAULT 0;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='pre_trip_action' AND column_name='max_retries') THEN
    ALTER TABLE public.pre_trip_action ADD COLUMN max_retries int DEFAULT 3;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='pre_trip_action' AND column_name='priority') THEN
    ALTER TABLE public.pre_trip_action ADD COLUMN priority int DEFAULT 1;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='pre_trip_action' AND column_name='notes') THEN
    ALTER TABLE public.pre_trip_action ADD COLUMN notes text;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='pre_trip_action' AND column_name='contact_phone') THEN
    ALTER TABLE public.pre_trip_action ADD COLUMN contact_phone text;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='pre_trip_action' AND column_name='contact_email') THEN
    ALTER TABLE public.pre_trip_action ADD COLUMN contact_email text;
  END IF;
END $$;

-- ============================================================
-- PART 3: INDEXES
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_quotation_client_id ON public.quotation(client_id);
CREATE INDEX IF NOT EXISTS idx_quotation_agency_id ON public.quotation(agency_id);
CREATE INDEX IF NOT EXISTS idx_quotation_status ON public.quotation(status);
CREATE INDEX IF NOT EXISTS idx_quotation_date_desc ON public.quotation(quotation_date DESC);
CREATE INDEX IF NOT EXISTS idx_quotation_travel_date ON public.quotation(travel_date);
CREATE INDEX IF NOT EXISTS idx_quotation_client_status_date ON public.quotation(client_id, status, quotation_date DESC);
CREATE INDEX IF NOT EXISTS idx_quotation_expiring ON public.quotation(expiration_date) WHERE status = 'sent' AND expiration_date IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_pre_trip_action_pending ON public.pre_trip_action(scheduled_at) WHERE status = 'pending';
CREATE INDEX IF NOT EXISTS idx_quotation_item_quotation_id ON public.quotation_item(quotation_id);
CREATE INDEX IF NOT EXISTS idx_quotation_version_quotation_id ON public.quotation_version(quotation_id, version_number DESC);

-- ============================================================
-- PART 4: NEW TABLES
-- ============================================================

-- Customer preferences
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

CREATE INDEX IF NOT EXISTS idx_customer_preference_client ON public.customer_preference(client_id);

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

-- Quotation templates
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
-- PART 5: TRIGGERS AND FUNCTIONS
-- ============================================================

-- Record quotation version on insert/update
CREATE OR REPLACE FUNCTION public.record_quotation_version() RETURNS trigger AS $$
BEGIN
  INSERT INTO public.quotation_version(quotation_id, version_number, snapshot, changed_by)
  VALUES (
    NEW.id,
    COALESCE((SELECT MAX(version_number) FROM public.quotation_version WHERE quotation_id = NEW.id), 0) + 1,
    to_jsonb(NEW),
    COALESCE(NEW.created_by, 'system')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_quotation_version ON public.quotation;
CREATE TRIGGER trg_quotation_version
AFTER INSERT OR UPDATE ON public.quotation
FOR EACH ROW EXECUTE FUNCTION public.record_quotation_version();

-- Enqueue pre-trip actions (enhanced version)
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

DROP TRIGGER IF EXISTS trg_pre_trip_enqueue ON public.quotation;
CREATE TRIGGER trg_pre_trip_enqueue
AFTER INSERT OR UPDATE OF status ON public.quotation
FOR EACH ROW 
WHEN (NEW.status = 'accepted')
EXECUTE FUNCTION public.enqueue_pre_trip_actions_v2();

-- Continue in next file due to length...


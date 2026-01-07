-- Script para adicionar campos complementares aos produtos
-- Este script usa o campo scheduled_date da tabela operation como data do produto
-- e adiciona apenas campos complementares à tabela product

-- Adicionar campos complementares à tabela product
ALTER TABLE public.product 
ADD COLUMN IF NOT EXISTS booking_url TEXT,
ADD COLUMN IF NOT EXISTS venue_name VARCHAR(255),
ADD COLUMN IF NOT EXISTS venue_address TEXT,
ADD COLUMN IF NOT EXISTS event_description TEXT,
ADD COLUMN IF NOT EXISTS event_timezone VARCHAR(50) DEFAULT 'America/New_York',
ADD COLUMN IF NOT EXISTS available_times JSONB,
ADD COLUMN IF NOT EXISTS recurring_schedule JSONB;

-- Comentários sobre os novos campos:
-- NOTA: A data do evento é armazenada no campo scheduled_date da tabela operation
-- booking_url: URL específica para reservas (diferente de site_url que pode ser informativo)
-- venue_name: Nome do local do evento
-- venue_address: Endereço do local
-- event_description: Descrição detalhada do evento
-- event_timezone: Fuso horário do evento
-- available_times: JSON com horários disponíveis para o produto
-- recurring_schedule: JSON com informações de cronograma recorrente

-- Exemplos de uso dos campos JSONB:
-- available_times: ["19:30", "21:00", "14:00"]
-- recurring_schedule: {"days": ["monday", "wednesday", "friday"], "times": ["19:30", "21:00"]}

-- Inserir dados de exemplo para produtos de ingressos
-- NOTA: As datas específicas serão definidas no campo scheduled_date da tabela operation
INSERT INTO public.product (
    name, 
    price_per_unit, 
    tax_percentage, 
    limited, 
    active_for_sale, 
    category_id, 
    site_url,
    booking_url,
    venue_name,
    venue_address,
    event_description,
    available_times
) VALUES 
(
    'Hamilton - Musical Broadway',
    450.00,
    8.88,
    true,
    true,
    1, -- categoria Broadway
    'https://hamiltonmusical.com',
    'https://hamiltonmusical.com/tickets',
    'Richard Rodgers Theatre',
    '226 W 46th St, New York, NY 10036',
    'O musical revolucionário de Lin-Manuel Miranda sobre a vida de Alexander Hamilton',
    '["19:30", "14:00"]'
),
(
    'The Lion King - Musical Broadway',
    380.00,
    8.88,
    true,
    true,
    1,
    'https://lionking.com',
    'https://lionking.com/tickets',
    'Minskoff Theatre',
    '1515 Broadway, New York, NY 10036',
    'O espetacular musical da Disney baseado no filme clássico',
    '["20:00", "14:00"]'
),
(
    'Yankees vs Red Sox - MLB',
    150.00,
    8.88,
    true,
    true,
    2, -- categoria Esportes
    'https://mlb.com/yankees',
    'https://mlb.com/yankees/tickets',
    'Yankee Stadium',
    '1 E 161st St, Bronx, NY 10451',
    'Clássico rivalidade entre Yankees e Red Sox no Yankee Stadium',
    '["19:05", "13:05"]'
),
(
    'Knicks vs Lakers - NBA',
    200.00,
    8.88,
    true,
    true,
    2,
    'https://nba.com/knicks',
    'https://nba.com/knicks/tickets',
    'Madison Square Garden',
    '4 Pennsylvania Plaza, New York, NY 10001',
    'Jogo emocionante entre Knicks e Lakers no icônico Madison Square Garden',
    '["19:30", "15:30"]'
),
(
    'Metropolitan Opera - La Traviata',
    250.00,
    8.88,
    true,
    true,
    1,
    'https://metopera.org',
    'https://metopera.org/tickets',
    'Metropolitan Opera House',
    '30 Lincoln Center Plaza, New York, NY 10023',
    'Ópera clássica de Verdi em uma produção espetacular',
    '["19:30"]'
);

-- Atualizar produtos existentes com informações de site_url
UPDATE public.product 
SET site_url = CASE 
    WHEN name LIKE '%Yankees%' THEN 'https://mlb.com/yankees'
    WHEN name LIKE '%Knicks%' THEN 'https://nba.com/knicks'
    WHEN name LIKE '%Nets%' THEN 'https://nba.com/nets'
    WHEN name LIKE '%Rangers%' THEN 'https://nhl.com/rangers'
    WHEN name LIKE '%Mets%' THEN 'https://mlb.com/mets'
    WHEN name LIKE '%Giants%' THEN 'https://giants.com'
    WHEN name LIKE '%Metropolitan Museum%' THEN 'https://metmuseum.org'
    WHEN name LIKE '%MoMA%' THEN 'https://moma.org'
    WHEN name LIKE '%Natural History%' THEN 'https://amnh.org'
    WHEN name LIKE '%Guggenheim%' THEN 'https://guggenheim.org'
    WHEN name LIKE '%Whitney%' THEN 'https://whitney.org'
    WHEN name LIKE '%Brooklyn Museum%' THEN 'https://brooklynmuseum.org'
    WHEN name LIKE '%Empire State%' THEN 'https://esbnyc.com'
    WHEN name LIKE '%Top of the Rock%' THEN 'https://topoftherocknyc.com'
    WHEN name LIKE '%One World%' THEN 'https://oneworldobservatory.com'
    WHEN name LIKE '%Statue of Liberty%' THEN 'https://statueofliberty.org'
    WHEN name LIKE '%Bronx Zoo%' THEN 'https://bronxzoo.com'
    WHEN name LIKE '%Aquarium%' THEN 'https://nyaquarium.com'
    ELSE site_url
END
WHERE site_url IS NULL OR site_url = '';

-- Criar índices para melhor performance
CREATE INDEX IF NOT EXISTS idx_product_site_url ON public.product(site_url);
CREATE INDEX IF NOT EXISTS idx_product_venue_name ON public.product(venue_name);
CREATE INDEX IF NOT EXISTS idx_operation_scheduled_date ON public.operation(scheduled_date);

-- Criar view para produtos com eventos programados usando scheduled_date da operation
CREATE OR REPLACE VIEW product_events AS
SELECT 
    p.product_id,
    p.name,
    p.price_per_unit,
    p.site_url,
    p.booking_url,
    p.venue_name,
    p.venue_address,
    p.event_description,
    p.event_timezone,
    p.available_times,
    pc.name as category_name,
    o.scheduled_date,
    o.id as operation_id,
    o.status as operation_status
FROM public.product p
LEFT JOIN public.product_category pc ON p.category_id = pc.category_id
LEFT JOIN public.operation o ON p.product_id = o.product_id
WHERE p.active_for_sale = true
ORDER BY o.scheduled_date;

COMMENT ON VIEW product_events IS 'View que combina produtos com suas informações de eventos, usando scheduled_date da tabela operation para as datas';
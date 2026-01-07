-- Script para normalizar países e estados em tabelas separadas
-- Análise: Existem 195 países reconhecidos pela ONU (193 membros + 2 observadores)
-- Tamanho estimado: ~195 registros x ~50 bytes por nome = ~10KB (muito leve)
-- Benefícios: Padronização, integridade referencial, facilita relatórios
-- Recomendação: Implementar com todos os países do mundo
-- Criado para resolver duplicações e melhorar performance

-- 1. Criar tabela de países
CREATE TABLE IF NOT EXISTS public.country (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE,
  iso_code_2 CHAR(2) UNIQUE, -- BR, US, etc
  iso_code_3 CHAR(3) UNIQUE, -- BRA, USA, etc
  phone_prefix VARCHAR(10), -- +55, +1, etc
  flag_url TEXT, -- URL da bandeira para exibição
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Criar tabela de estados/províncias
CREATE TABLE IF NOT EXISTS public.state (
  id SERIAL PRIMARY KEY,
  country_id INTEGER NOT NULL REFERENCES public.country(id),
  name VARCHAR(100) NOT NULL,
  code VARCHAR(10), -- SP, RJ, NY, CA, etc
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(country_id, name),
  UNIQUE(country_id, code)
);

-- 3. Inserir países principais
INSERT INTO public.country (name, iso_code_2, iso_code_3, phone_prefix, flag_url) VALUES
('Brasil', 'BR', 'BRA', '+55', 'https://flagcdn.com/br.svg'),
('Estados Unidos', 'US', 'USA', '+1', 'https://flagcdn.com/us.svg'),
('Portugal', 'PT', 'PRT', '+351', 'https://flagcdn.com/pt.svg'),
('Espanha', 'ES', 'ESP', '+34', 'https://flagcdn.com/es.svg'),
('Reino Unido', 'GB', 'GBR', '+44', 'https://flagcdn.com/gb.svg')
ON CONFLICT (name) DO NOTHING;

-- 4. Inserir estados brasileiros
INSERT INTO public.state (country_id, name, code) 
SELECT 
  c.id,
  state_name,
  state_code
FROM (
  VALUES 
    ('Acre', 'AC'),
    ('Alagoas', 'AL'),
    ('Amapá', 'AP'),
    ('Amazonas', 'AM'),
    ('Bahia', 'BA'),
    ('Ceará', 'CE'),
    ('Distrito Federal', 'DF'),
    ('Espírito Santo', 'ES'),
    ('Goiás', 'GO'),
    ('Maranhão', 'MA'),
    ('Mato Grosso', 'MT'),
    ('Mato Grosso do Sul', 'MS'),
    ('Minas Gerais', 'MG'),
    ('Pará', 'PA'),
    ('Paraíba', 'PB'),
    ('Paraná', 'PR'),
    ('Pernambuco', 'PE'),
    ('Piauí', 'PI'),
    ('Rio de Janeiro', 'RJ'),
    ('Rio Grande do Norte', 'RN'),
    ('Rio Grande do Sul', 'RS'),
    ('Rondônia', 'RO'),
    ('Roraima', 'RR'),
    ('Santa Catarina', 'SC'),
    ('São Paulo', 'SP'),
    ('Sergipe', 'SE'),
    ('Tocantins', 'TO')
) AS states(state_name, state_code)
CROSS JOIN public.country c
WHERE c.name = 'Brasil'
ON CONFLICT (country_id, name) DO NOTHING;

-- 5. Inserir estados americanos
INSERT INTO public.state (country_id, name, code) 
SELECT 
  c.id,
  state_name,
  state_code
FROM (
  VALUES 
    ('Alabama', 'AL'),
    ('Alaska', 'AK'),
    ('Arizona', 'AZ'),
    ('Arkansas', 'AR'),
    ('California', 'CA'),
    ('Colorado', 'CO'),
    ('Connecticut', 'CT'),
    ('Delaware', 'DE'),
    ('Florida', 'FL'),
    ('Georgia', 'GA'),
    ('Hawaii', 'HI'),
    ('Idaho', 'ID'),
    ('Illinois', 'IL'),
    ('Indiana', 'IN'),
    ('Iowa', 'IA'),
    ('Kansas', 'KS'),
    ('Kentucky', 'KY'),
    ('Louisiana', 'LA'),
    ('Maine', 'ME'),
    ('Maryland', 'MD'),
    ('Massachusetts', 'MA'),
    ('Michigan', 'MI'),
    ('Minnesota', 'MN'),
    ('Mississippi', 'MS'),
    ('Missouri', 'MO'),
    ('Montana', 'MT'),
    ('Nebraska', 'NE'),
    ('Nevada', 'NV'),
    ('New Hampshire', 'NH'),
    ('New Jersey', 'NJ'),
    ('New Mexico', 'NM'),
    ('New York', 'NY'),
    ('North Carolina', 'NC'),
    ('North Dakota', 'ND'),
    ('Ohio', 'OH'),
    ('Oklahoma', 'OK'),
    ('Oregon', 'OR'),
    ('Pennsylvania', 'PA'),
    ('Rhode Island', 'RI'),
    ('South Carolina', 'SC'),
    ('South Dakota', 'SD'),
    ('Tennessee', 'TN'),
    ('Texas', 'TX'),
    ('Utah', 'UT'),
    ('Vermont', 'VT'),
    ('Virginia', 'VA'),
    ('Washington', 'WA'),
    ('West Virginia', 'WV'),
    ('Wisconsin', 'WI'),
    ('Wyoming', 'WY'),
    ('District of Columbia', 'DC')
) AS states(state_name, state_code)
CROSS JOIN public.country c
WHERE c.name = 'Estados Unidos'
ON CONFLICT (country_id, name) DO NOTHING;

-- 6. Adicionar colunas de FK na tabela contact
ALTER TABLE public.contact 
ADD COLUMN IF NOT EXISTS country_id INTEGER REFERENCES public.country(id),
ADD COLUMN IF NOT EXISTS state_id INTEGER REFERENCES public.state(id);

-- 7. Migrar dados existentes - países
UPDATE public.contact 
SET country_id = (
  SELECT c.id 
  FROM public.country c 
  WHERE c.name = contact.country
  LIMIT 1
)
WHERE country IS NOT NULL AND country_id IS NULL;

-- 8. Migrar dados existentes - estados brasileiros (por nome completo)
UPDATE public.contact 
SET state_id = (
  SELECT s.id 
  FROM public.state s 
  JOIN public.country c ON s.country_id = c.id
  WHERE s.name = contact.state 
    AND c.name = 'Brasil'
  LIMIT 1
)
WHERE state IS NOT NULL 
  AND state_id IS NULL 
  AND country_id = (SELECT id FROM public.country WHERE name = 'Brasil');

-- 9. Migrar dados existentes - estados brasileiros (por código)
UPDATE public.contact 
SET state_id = (
  SELECT s.id 
  FROM public.state s 
  JOIN public.country c ON s.country_id = c.id
  WHERE s.code = contact.state 
    AND c.name = 'Brasil'
  LIMIT 1
)
WHERE state IS NOT NULL 
  AND state_id IS NULL 
  AND country_id = (SELECT id FROM public.country WHERE name = 'Brasil');

-- 10. Migrar dados existentes - estados americanos (por código)
UPDATE public.contact 
SET state_id = (
  SELECT s.id 
  FROM public.state s 
  JOIN public.country c ON s.country_id = c.id
  WHERE s.code = contact.state 
    AND c.name = 'Estados Unidos'
  LIMIT 1
)
WHERE state IS NOT NULL 
  AND state_id IS NULL 
  AND country_id = (SELECT id FROM public.country WHERE name = 'Estados Unidos');

-- 11. Criar índices para performance
CREATE INDEX IF NOT EXISTS idx_contact_country_id ON public.contact(country_id);
CREATE INDEX IF NOT EXISTS idx_contact_state_id ON public.contact(state_id);
CREATE INDEX IF NOT EXISTS idx_state_country_id ON public.state(country_id);

-- 12. Verificar migração
SELECT 
  'Contatos sem país normalizado' as tipo,
  COUNT(*) as quantidade
FROM public.contact 
WHERE country IS NOT NULL AND country_id IS NULL

UNION ALL

SELECT 
  'Contatos sem estado normalizado' as tipo,
  COUNT(*) as quantidade
FROM public.contact 
WHERE state IS NOT NULL AND state_id IS NULL

UNION ALL

SELECT 
  'Total de países' as tipo,
  COUNT(*) as quantidade
FROM public.country

UNION ALL

SELECT 
  'Total de estados' as tipo,
  COUNT(*) as quantidade
FROM public.state;

-- Comentários:
-- Após validar a migração, você pode remover as colunas antigas:
-- ALTER TABLE public.contact DROP COLUMN country;
-- ALTER TABLE public.contact DROP COLUMN state;
-- Script para corrigir duplicações de categorias entre singular e plural
-- Padronizando todas as categorias para o plural

-- Identificar as duplicações encontradas:
-- Existente no CSV: Museu (singular) vs Script: Museus (plural)
-- Existente no CSV: Parque (singular) vs Script: Parques (plural) 
-- Existente no CSV: Esporte (singular) vs Script: Esportes (plural)

BEGIN;

-- 1. Atualizar categoria "Museu" para "Museus" (padronizar para plural)
UPDATE public.product_category 
SET name = 'Museus',
    description = 'Museus e atrações culturais',
    updated_at = now()
WHERE name = 'Museu';

-- 2. Atualizar categoria "Parque" para "Parques" (padronizar para plural)
UPDATE public.product_category 
SET name = 'Parques',
    description = 'Parques temáticos e de diversão',
    updated_at = now()
WHERE name = 'Parque';

-- 3. Atualizar categoria "Esporte" para "Esportes" (padronizar para plural)
UPDATE public.product_category 
SET name = 'Esportes',
    description = 'Eventos esportivos',
    updated_at = now()
WHERE name = 'Esporte';

-- 4. Verificar se existem produtos usando as categorias antigas e atualizar se necessário
-- (Isso é importante caso já existam produtos cadastrados)

-- Verificar produtos que podem estar usando as categorias antigas
DO $$
DECLARE
    museu_id INTEGER;
    parque_id INTEGER;
    esporte_id INTEGER;
    museus_id INTEGER;
    parques_id INTEGER;
    esportes_id INTEGER;
BEGIN
    -- Buscar IDs das categorias antigas (se ainda existirem)
    SELECT category_id INTO museu_id FROM public.product_category WHERE name = 'Museu';
    SELECT category_id INTO parque_id FROM public.product_category WHERE name = 'Parque';
    SELECT category_id INTO esporte_id FROM public.product_category WHERE name = 'Esporte';
    
    -- Buscar IDs das categorias novas (plurais)
    SELECT category_id INTO museus_id FROM public.product_category WHERE name = 'Museus';
    SELECT category_id INTO parques_id FROM public.product_category WHERE name = 'Parques';
    SELECT category_id INTO esportes_id FROM public.product_category WHERE name = 'Esportes';
    
    -- Atualizar produtos se necessário
    IF museu_id IS NOT NULL AND museus_id IS NOT NULL AND museu_id != museus_id THEN
        UPDATE public.product SET category_id = museus_id WHERE category_id = museu_id;
        RAISE NOTICE 'Produtos atualizados da categoria Museu para Museus';
    END IF;
    
    IF parque_id IS NOT NULL AND parques_id IS NOT NULL AND parque_id != parques_id THEN
        UPDATE public.product SET category_id = parques_id WHERE category_id = parque_id;
        RAISE NOTICE 'Produtos atualizados da categoria Parque para Parques';
    END IF;
    
    IF esporte_id IS NOT NULL AND esportes_id IS NOT NULL AND esporte_id != esportes_id THEN
        UPDATE public.product SET category_id = esportes_id WHERE category_id = esporte_id;
        RAISE NOTICE 'Produtos atualizados da categoria Esporte para Esportes';
    END IF;
END $$;

-- 5. Inserir categorias que podem estar faltando (do script de produtos)
INSERT INTO public.product_category (name, description) 
VALUES 
    ('Broadway', 'Musicais e peças da Broadway'),
    ('Museus', 'Museus e atrações culturais'),
    ('Passeios', 'Tours e atrações turísticas'),
    ('Esportes', 'Eventos esportivos'),
    ('Shows/Eventos', 'Shows e eventos especiais'),
    ('Parques', 'Parques temáticos e de diversão'),
    ('Experiências Imersivas', 'Experiências de realidade virtual e imersivas'),
    ('Washington DC', 'Atrações em Washington DC')
ON CONFLICT (name) DO UPDATE SET
    description = EXCLUDED.description,
    updated_at = now();

-- 6. Verificar resultado final
SELECT 
    category_id,
    name,
    description,
    is_active,
    created_at,
    updated_at
FROM public.product_category 
ORDER BY name;

COMMIT;

-- Comentários finais
COMMENT ON SCRIPT IS 'Script para padronizar nomes de categorias para o plural e evitar duplicações';

-- Log de alterações:
-- ✓ Museu → Museus
-- ✓ Parque → Parques  
-- ✓ Esporte → Esportes
-- ✓ Produtos atualizados para usar as categorias padronizadas
-- ✓ Inserção de categorias faltantes com ON CONFLICT para evitar duplicações
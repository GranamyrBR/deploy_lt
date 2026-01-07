-- Script SQL corrigido para inserir todos os produtos da planilha de Ingressos e Tickets
-- Versão com escape de aspas simples corrigido

-- Primeiro, vamos inserir as categorias de produtos se não existirem
-- NOTA: Categorias padronizadas no PLURAL para evitar duplicações
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

-- Inserir produtos da categoria BROADWAY
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
    event_description,
    available_times
) VALUES 
(
    'Aladdin',
    90.00,
    8.88,
    true,
    true,
    (SELECT category_id FROM public.product_category WHERE name = 'Broadway'),
    'https://www.broadway-show-tickets.com/pt/musical/aladdin-ingressos/',
    'https://www.broadway-show-tickets.com/pt/musical/aladdin-ingressos/',
    'Broadway Theatre',
    'O musical Aladdin da Broadway leva você a uma viagem encantada no tapete mágico com figurinos e cenários elaborados e belos. Você assistirá a um espetáculo encantador. Duração: 2h30 com intervalo. Adequado para maiores de 6 anos.',
    '["19:30", "14:00"]'
),
(
    'Rei Leão',
    133.00,
    8.88,
    true,
    true,
    (SELECT category_id FROM public.product_category WHERE name = 'Broadway'),
    'https://www.broadway-show-tickets.com/pt/musical/o-rei-leao-ingressos/',
    'https://www.broadway-show-tickets.com/pt/musical/o-rei-leao-ingressos/',
    'Minskoff Theatre',
    'Baseado no popularíssimo filme homônimo da Disney de 1994, o musical foi dirigido para o palco por Julie Taymor, ganhadora do prêmio Tony, e já chegou aos cinemas em mais de 100 cidades de 21 países em mais de 9 idiomas. Uma delícia para crianças e adultos, esse conto comovente sobre família, destino, aventura, perseverança e amor foi traduzido para o palco por meio de cenários espetaculares, coreografia inspiradora, música comovente e uma bela narrativa. Duração: 2h30 com intervalo. Adequado para maiores de 6 anos.',
    '["19:30", "14:00"]'
),
(
    'MJ',
    104.00,
    8.88,
    true,
    true,
    (SELECT category_id FROM public.product_category WHERE name = 'Broadway'),
    'https://www.broadway-show-tickets.com/pt/musical/mj-the-musical-ingressos/',
    'https://www.broadway-show-tickets.com/pt/musical/mj-the-musical-ingressos/',
    'Neil Simon Theatre',
    'Conheça os bastidores e confira a Dangerous World Tour de 1992 de Michael Jackson e saiba tudo sobre o processo criativo envolvido. Testemunhe a magia do Rei do Pop neste musical de jukebox, MJ, que foi duas vezes vencedor do Prêmio Pulitzer. Curta as músicas icônicas de MJ, como "Billie Jean", "Thriller" e "Beat It", entre outras incríveis. Duração: 2h30 com intervalo. Adequado para maiores de 8 anos.',
    '["19:30", "14:00"]'
),
(
    'Harry Potter e a criança amaldiçoada',
    83.50,
    8.88,
    true,
    true,
    (SELECT category_id FROM public.product_category WHERE name = 'Broadway'),
    'https://www.broadway-show-tickets.com/pt/plays/harry-potter-and-the-cursed-child-tickets/',
    'https://www.broadway-show-tickets.com/pt/plays/harry-potter-and-the-cursed-child-tickets/',
    'Lyric Theatre',
    'Dirigida por John Tiffany, essa aclamada peça apresenta magia, viagem no tempo e batalhas épicas que transportam você para o mundo de Harry Potter. A oitava história de Harry Potter explora o aprofundamento da amizade entre Albus Potter e Scorpius Malfoy, filho de Draco Malfoy, antigo rival de Harry. Uma das peças mais reverenciadas da Broadway, Harry Potter e a Criança Amaldiçoada foi aclamada pela Forbes como um evento que definiu a cultura pop e está de volta com toda a sua magia e batalhas épicas! Duração: 3h30 com intervalo. Adequado para maiores de 8 anos.',
    '["19:00", "14:00"]'
),
(
    'Six: The Musical',
    86.50,
    8.88,
    true,
    true,
    (SELECT category_id FROM public.product_category WHERE name = 'Broadway'),
    'https://www.broadway-show-tickets.com/pt/musical/six-the-musical-ingressos/',
    'https://www.broadway-show-tickets.com/pt/musical/six-the-musical-ingressos/',
    'Lena Horne Theatre',
    'Vencedor de 23 prêmios, incluindo o Tony Award de 2022 de Melhor Trilha Sonora Original. De rainhas Tudor majestosas, porém trágicas, a poderosas princesas do pop, as esposas de Henrique VIII se transformaram em uma girl band do século XXI que se apresenta em um show em SIX: The Musical na Broadway. Vivencie a história britânica nesse musical exuberante por meio do desempenho dinâmico do talentoso elenco que redefinirá sua perspectiva. Duração: 80 minutos sem intervalo. Adequado para maiores de 10 anos.',
    '["19:30", "14:00"]'
),
(
    'Moulin Rouge',
    73.50,
    8.88,
    true,
    true,
    (SELECT category_id FROM public.product_category WHERE name = 'Broadway'),
    'https://www.broadway-show-tickets.com/pt/musical/moulin-rouge-the-musical-ingressos/',
    'https://www.broadway-show-tickets.com/pt/musical/moulin-rouge-the-musical-ingressos/',
    'Al Hirschfeld Theatre',
    'Dirigido pelo vencedor do prêmio Tony Alex Timbers, com arranjos musicais do vencedor do prêmio Tony Justin Levine e coreografia da vencedora do prêmio Tony Sonya Tayeh. Adorado pelo público e pela crítica, esse grande sucesso é vencedor de 10 prêmios Tony e um dos musicais mais antigos em cartaz na Broadway. Duração: 2h45 com intervalo. Adequado para maiores de 12 anos.',
    '["19:30", "14:00"]'
),
(
    'Chicago',
    84.00,
    8.88,
    true,
    true,
    (SELECT category_id FROM public.product_category WHERE name = 'Broadway'),
    'https://www.broadway-show-tickets.com/pt/musical/chicago-ingressos/',
    'https://www.broadway-show-tickets.com/pt/musical/chicago-ingressos/',
    'Ambassador Theatre',
    'Musical vencedor do Grammy, com impressionantes 6 prêmios Tony e 2 prêmios Olivier. Duração: 2 horas e 30 minutos com intervalo de 15 minutos. Adequado para maiores de 12 anos.',
    '["20:00", "14:30"]'
),
(
    'Wicked',
    124.00,
    8.88,
    true,
    true,
    (SELECT category_id FROM public.product_category WHERE name = 'Broadway'),
    'https://www.broadway-show-tickets.com/pt/musical/wicked-ingressos/',
    'https://www.broadway-show-tickets.com/pt/musical/wicked-ingressos/',
    'Gershwin Theatre',
    'Aclamado pela crítica e um sucesso estrondoso desde sua estreia em 2003, Wicked leva você a uma jornada que acompanha dois rivais que se tornaram amigos e os altos e baixos de suas vidas. Conhecido por seu enredo criativo, músicas hipnotizantes e visuais encantadores, Wicked é mágico em todos os sentidos da palavra. Duração: 2h45 com intervalo. Adequado para maiores de 8 anos.',
    '["19:30", "14:00"]'
),
(
    'Hamilton',
    124.00,
    8.88,
    true,
    true,
    (SELECT category_id FROM public.product_category WHERE name = 'Broadway'),
    'https://www.broadway-show-tickets.com/pt/musical/hamilton-ingressos/',
    'https://www.broadway-show-tickets.com/pt/musical/hamilton-ingressos/',
    'Richard Rodgers Theatre',
    'História do Pai Fundador dos Estados Unidos, inspirada na biografia de Alexander Hamilton escrita por Ron Chernow. Assista a Lin-Manuel Miranda, vencedor dos prêmios Tony, Grammy e Emmy, fazer mágica no palco como nunca antes. Thomas Kail, indicado ao prêmio Tony, dá vida ao musical com sua direção ardente, que fala sobre a importância de falar o que pensa e conquistar o mundo. Demanda incrivelmente alta, deve ser comprado com antecedência. Duração: 2h30 com intervalo. Adequado para maiores de 10 anos.',
    '["19:30", "14:00"]'
),
(
    'De volta para o futuro, o musical',
    72.10,
    8.88,
    true,
    true,
    (SELECT category_id FROM public.product_category WHERE name = 'Broadway'),
    'https://www.broadway-show-tickets.com/pt/musical/de-volta-para-o-futuro-o-musical-ingressos/',
    'https://www.broadway-show-tickets.com/pt/musical/de-volta-para-o-futuro-o-musical-ingressos/',
    'Winter Garden Theatre',
    'Baseado no filme da Universal Pictures/Amblin Entertainment, De Volta para o Futuro, o musical com certeza manterá você grudado em seus assentos enquanto o leva a uma aventura pelo passado, presente e futuro. Com músicas de sucesso como "The Power of Love", "Back in Time" e "Johnny B. Goode", essa adaptação para o palco fará você dançar durante todo o show. Duração: 2h35 com intervalo. Adequado para maiores de 6 anos.',
    '["19:30", "14:00"]'
);

-- Script concluído - versão corrigida com escape de aspas simples adequado
-- Para continuar com os demais produtos, execute o script original corrigido
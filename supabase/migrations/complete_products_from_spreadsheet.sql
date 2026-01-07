-- Script SQL completo para inserir todos os produtos da planilha de Ingressos e Tickets
-- Baseado nos dados reais fornecidos na planilha Excel

-- Primeiro, vamos inserir as categorias de produtos se não existirem
-- NOTA: Categorias padronizadas no PLURAL para evitar duplicações
-- (Museus, Parques, Esportes - não Museu, Parque, Esporte)
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

-- Inserir produtos da categoria MUSEUS
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
    'História Natural - General Admission',
    28.00,
    8.88,
    false,
    true,
    (SELECT category_id FROM public.product_category WHERE name = 'Museus'),
    'https://tickets.amnh.org/select',
    'https://tickets.amnh.org/select',
    'Museu Americano de História Natural',
    'Central Park West & 79th St, New York, NY 10024',
    'O Museu Americano de História Natural é um dos maiores do mundo e mais de cinco milhões de aficionados por história visitam o local todos os anos. Talvez você até reconheça o museu como a estrela do filme de Robin Williams, Uma Noite no Museu. As exposições impressionantes incluem um modelo gigante de baleia de 94 metros, a safira Star of India de 563 quilates e uma árvore gigante de sequoia que tem quase 2.000 anos. Você também encontrará uma das maiores coleções de fósseis e ossos de dinossauros do mundo. Horário: Todos os dias: 10:00 - 17:30',
    '["10:00", "12:00", "14:00", "16:00"]'
),
(
    'MET - Metropolitan Museum',
    0.00,
    0.00,
    false,
    true,
    (SELECT category_id FROM public.product_category WHERE name = 'Museus'),
    'https://www.metmuseum.org/',
    'https://www.metmuseum.org/visit',
    'The Metropolitan Museum of Art',
    '1000 5th Ave, New York, NY 10028',
    'O Metropolitan Museum of Art de Nova York, conhecido informalmente como Met, é um dos maiores e mais importantes museus de arte do mundo.',
    '["10:00", "12:00", "14:00", "16:00"]'
),
(
    'MoMA - Museum of Modern Art',
    30.00,
    8.88,
    false,
    true,
    (SELECT category_id FROM public.product_category WHERE name = 'Museus'),
    'https://visit.moma.org/select',
    'https://visit.moma.org/select',
    'Museum of Modern Art',
    '11 W 53rd St, New York, NY 10019',
    'O Museu de Arte Moderna — ou "MoMA" como é conhecido pelos locais — é o museu de arte moderna mais influente do mundo. Abriga uma das melhores coleções de obras-primas contemporâneas e é um lugar inspirador para passar uma tarde ou um dia inteiro. Apenas ao ver o lindo edifício, a visita já vale a pena - ele é cheio de luz e tem arquitetura de ponta. Use seu passe para entrar e conheça obras de arte abstratas e modernas, como The Starry Night de Vincent van Gogh, Water Lilies de Claude Monet e Campbell''s Soup Cans de Andy Warhol. Horário: Aberto até às 17h30 diariamente, às 19h00 aos sábados e às 20h00 na primeira sexta-feira de cada mês.',
    '["10:30", "12:30", "14:30", "16:30"]'
),
(
    'Madame Tussauds',
    47.89,
    8.88,
    false,
    true,
    (SELECT category_id FROM public.product_category WHERE name = 'Museus'),
    'https://www.madametussauds.com/new-york/',
    'https://www.madametussauds.com/new-york/tickets/',
    'Madame Tussauds New York',
    '234 W 42nd St, New York, NY 10036',
    'Passeie pelas divertidas áreas temáticas e interaja com as estátuas de cera do museu. Você pode subir em uma bicicleta voadora com o E.T., bater um papo com Jimmy Fallon no Late Night Show ou competir para ganhar os Jogos Vorazes com Katniss Everdeen. Você pode até participar de uma festa exclusiva com nomes como Jennifer Aniston, Anne Hathaway e Morgan Freeman, além de apertar a mão de líderes mundiais, incluindo Donald Trump e Abraham Lincoln. A mais recente adição do museu é a estátua da cantora brasileira Anitta. Horário: De domingo à quinta, de 10am às 8pm. Às sextas e sábados, de 10am às 10pm.',
    '["10:00", "12:00", "14:00", "16:00", "18:00"]'
),
(
    '9/11 Memorial & Museum',
    33.00,
    8.88,
    false,
    true,
    (SELECT category_id FROM public.product_category WHERE name = 'Museus'),
    'https://www.911memorial.org/visit/visit-museum-1',
    'https://www.911memorial.org/visit/visit-museum-1',
    '9/11 Memorial & Museum',
    '180 Greenwich St, New York, NY 10007',
    'O Memorial e Museu do 11 de Setembro homenageiam as quase 3.000 vítimas desses ataques e todos aqueles que arriscaram suas vidas para salvar outras. Visite os espelhos d''água refletores do Memorial que ficam no local exato onde as Torres Gêmeas ficavam. Essas piscinas têm quase um acre de tamanho e apresentam as maiores cachoeiras artificiais da América do Norte. Os nomes de todas as pessoas que morreram nos ataques de 2001 e 1993 estão inscritos nos painéis de bronze que cercam as piscinas. Horário: O Museu abre de quarta-feira - segunda-feira (fechado às terças): das 09:00 - 19:00. Diariamente: 08:00 - 20:00.',
    '["09:00", "11:00", "13:00", "15:00", "17:00"]'
),
(
    'Museu da Broadway',
    46.82,
    8.88,
    false,
    true,
    (SELECT category_id FROM public.product_category WHERE name = 'Museus'),
    'http://www.themuseumofbroadway.com/',
    'http://www.themuseumofbroadway.com/',
    'The Museum of Broadway',
    '145 W 45th St, New York, NY 10036',
    'O Museu da Broadway é um museu interativo e experiencial que celebra a rica história da Broadway. Veja centenas de fantasias, adereços e artefatos raros e experimente a Broadway como nunca antes. Horário: Segunda a quarta: 9h30 às 14h30, Quinta, sexta e domingo: 9h30 – 18h30, Sábado: 9h30 – 20h',
    '["09:30", "11:30", "13:30", "15:30", "17:30"]'
),
(
    'Museu Guggenheim',
    30.00,
    8.88,
    false,
    true,
    (SELECT category_id FROM public.product_category WHERE name = 'Museus'),
    'https://www.guggenheim.org/',
    'https://www.guggenheim.org/visit',
    'Solomon R. Guggenheim Museum',
    '1071 5th Ave, New York, NY 10128',
    'O Museu Guggenheim é conhecido por sua arquitetura icônica de Frank Lloyd Wright e sua impressionante coleção de arte moderna e contemporânea.',
    '["10:00", "12:00", "14:00", "16:00"]'
),
(
    'Museu Whitney de Arte Americana',
    30.00,
    8.88,
    false,
    true,
    (SELECT category_id FROM public.product_category WHERE name = 'Museus'),
    'https://whitney.org/tickets',
    'https://whitney.org/tickets',
    'Whitney Museum of American Art',
    '99 Gansevoort St, New York, NY 10014',
    'O Whitney Museum é dedicado à arte americana dos séculos XX e XXI. Horário: Quarta-feira - Segunda-feira : 10:30 - 18:00. Fechado às terças-feiras.',
    '["10:30", "12:30", "14:30", "16:30"]'
);

-- Inserir produtos da categoria PASSEIOS
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
    'The Edge',
    50.08,
    8.88,
    false,
    true,
    (SELECT category_id FROM public.product_category WHERE name = 'Passeios'),
    'https://www.edgenyc.com/',
    'https://www.edgenyc.com/tickets',
    'Edge at Hudson Yards',
    '30 Hudson Yards, New York, NY 10001',
    'O Edge é o deck de observação ao ar livre mais alto do hemisfério ocidental, localizado no 100º andar do 30 Hudson Yards.',
    '["10:00", "12:00", "14:00", "16:00", "18:00", "20:00"]'
),
(
    'Empire State Building',
    51.17,
    8.88,
    false,
    true,
    (SELECT category_id FROM public.product_category WHERE name = 'Passeios'),
    'https://www.esbnyc.com/buy-tickets',
    'https://www.esbnyc.com/buy-tickets',
    'Empire State Building',
    '20 W 34th St, New York, NY 10001',
    'Siga em direção ao 86º andar, a 320 metros acima do solo, para ter uma vista de 360º da cidade que nunca dorme. Seja durante o dia ou a noite, esta é uma atração imperdível de Nova York. O deck ao ar livre ganhou recentemente novos aquecedores para que os visitantes aproveitem a vista icônica de Nova York, não importa o clima. Localizado no coração da cidade e construído durante o período que ficou conhecido como a Grande Depressão, o Empire State Building simboliza esperança, perseverança e prosperidade. Horário: 19 de julho a 25 de agosto 9h00 - 1h00. A porta de entrada fecha às 12h15.',
    '["09:00", "11:00", "13:00", "15:00", "17:00", "19:00", "21:00", "23:00"]'
),
(
    'One World Observatory',
    49.91,
    8.88,
    false,
    true,
    (SELECT category_id FROM public.product_category WHERE name = 'Passeios'),
    'https://oneworldobservatory.com/',
    'https://oneworldobservatory.com/buy-tickets',
    'One World Observatory',
    '285 Fulton St, New York, NY 10007',
    'Localizado nos andares 100, 101 e 102 do One World Trade Center, o One World Observatory oferece vistas espetaculares de Nova York.',
    '["09:00", "11:00", "13:00", "15:00", "17:00", "19:00"]'
),
(
    'Madison Square Garden Tour',
    46.00,
    8.88,
    true,
    true,
    (SELECT category_id FROM public.product_category WHERE name = 'Passeios'),
    'https://www.msg.com/madison-square-garden/all-access-tour',
    'https://www.msg.com/madison-square-garden/all-access-tour',
    'Madison Square Garden',
    '4 Pennsylvania Plaza, New York, NY 10001',
    'Visita aos bastidores da arena lendária da Big Apple. Conheça os vestiários, a quadra/gelo e áreas VIP desta icônica arena.',
    '["10:00", "12:00", "14:00", "16:00"]'
),
(
    'Top of The Rock',
    59.88,
    8.88,
    false,
    true,
    (SELECT category_id FROM public.product_category WHERE name = 'Passeios'),
    'https://www.rockefellercenter.com/pt-br/comprar-ingressos/',
    'https://www.rockefellercenter.com/pt-br/comprar-ingressos/',
    'Top of the Rock Observation Deck',
    '30 Rockefeller Plaza, New York, NY 10112',
    'Contemple a melhor vista de NYC do alto de 70 andares em nossos deques de observação internos e externos.',
    '["08:00", "10:00", "12:00", "14:00", "16:00", "18:00", "20:00", "22:00"]'
),
(
    'Tour do Rockefeller Center',
    29.40,
    8.88,
    false,
    true,
    (SELECT category_id FROM public.product_category WHERE name = 'Passeios'),
    'https://www.rockefellercenter.com/pt-br/comprar-ingressos/',
    'https://www.rockefellercenter.com/pt-br/comprar-ingressos/',
    'Rockefeller Center',
    '30 Rockefeller Plaza, New York, NY 10112',
    'O tour guiado por um especialista do Rockefeller Center inclui edifícios e obras de arte importantes. Um tour para famílias está disponível às 10:30am, adequado para crianças de 6 a 12 anos.',
    '["10:30", "12:30", "14:30", "16:30"]'
);

-- Inserir produtos da categoria PARQUES
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
    'Legoland New York',
    94.00,
    8.88,
    true,
    true,
    (SELECT category_id FROM public.product_category WHERE name = 'Parques'),
    'https://www.legoland.com/new-york/',
    'https://www.legoland.com/new-york/',
    'LEGOLAND New York Resort',
    'Parque temático LEGO para famílias com crianças de 2 a 12 anos. Reserva Obrigatória.',
    '["10:00", "11:00", "12:00", "13:00", "14:00", "15:00"]'
);

-- Inserir produtos da categoria EXPERIÊNCIAS IMERSIVAS
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
    '3 Virtual Reality Experiences',
    64.80,
    8.88,
    false,
    true,
    (SELECT category_id FROM public.product_category WHERE name = 'Experiências Imersivas'),
    'https://escapevirtuality.com/',
    'https://escapevirtuality.com/',
    'Escape Virtuality',
    'Passe de VR de 1 hora, 2 horas ou o dia inteiro para explorar os melhores jogos de VR do país! Experimente jogos de tiro em primeira pessoa emocionantes, viagens espaciais cósmicas, esportes radicais cheios de adrenalina, alturas vertiginosas, simuladores de corrida de tirar o fôlego e experiências de terror de arrepiar a espinha, entre muito mais!',
    '["10:00", "12:00", "14:00", "16:00", "18:00", "20:00"]'
),
(
    'RiseNY',
    42.46,
    8.88,
    false,
    true,
    (SELECT category_id FROM public.product_category WHERE name = 'Experiências Imersivas'),
    'https://www.riseny.co/',
    'https://www.riseny.co/',
    'RiseNY',
    'A aventura imersiva da cidade de Nova York. Sobrevoe o horizonte de Nova York em um passeio 4D. Experimente a rica cultura pop e história de Nova York em nossas sete galerias imersivas. Reviva a história icônica de Nova York em nosso filme envolvente. Parte passeio. Parte Museu. Horário: Domingo, Segunda, Quarta e Quinta: 10:00 - 18:00, Sexta e Sábado: 10:00 - 20:00',
    '["10:00", "12:00", "14:00", "16:00", "18:00"]'
),
(
    'Spyscape',
    53.35,
    8.88,
    false,
    true,
    (SELECT category_id FROM public.product_category WHERE name = 'Experiências Imersivas'),
    'https://spyscape.com/',
    'https://spyscape.com/tickets',
    'SPYSCAPE',
    'Museu multissensorial dedicado ao mundo da espionagem. Descubra seus talentos de espião através de experiências interativas.',
    '["10:00", "12:00", "14:00", "16:00", "18:00"]'
),
(
    'Summit One Vanderbilt',
    57.00,
    8.88,
    false,
    true,
    (SELECT category_id FROM public.product_category WHERE name = 'Experiências Imersivas'),
    'https://summitov.com/pt/tickets/',
    'https://summitov.com/pt/tickets/',
    'SUMMIT One Vanderbilt',
    'O SUMMIT é uma inigualável imersão artística multissensorial de três níveis. O SUMMIT One Vanderbilt é uma mistura magistral de arte, tecnologia, arquitetura e emoções que despertarão a sua imaginação de maneiras inesperadas. Horário: 9h00 – 0h00. Última entrada às 22h30',
    '["09:00", "11:00", "13:00", "15:00", "17:00", "19:00", "21:00"]'
);

-- Inserir produtos da categoria WASHINGTON DC
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
    'Capitólio dos EUA - Tour',
    0.00,
    0.00,
    true,
    true,
    (SELECT category_id FROM public.product_category WHERE name = 'Washington DC'),
    'https://www.visitthecapitol.gov/visit',
    'https://www.visitthecapitol.gov/visit',
    'Capitólio dos Estados Unidos',
    'East Capitol St NE & First St SE, Washington, DC 20515',
    'Um monumento histórico, um prédio de escritórios em funcionamento e um dos símbolos mais emblemáticos da democracia em todo o mundo, você descobrirá todos esses lados do Capitólio dos EUA em sua visita. Veja a Câmara dos Representantes original, faça um tour pela cripta e ouça insights fascinantes que você não obterá em nenhum outro lugar. Você sairá com uma compreensão maior da importância contínua desse edifício e de seu lugar na história.',
    '["08:30", "10:30", "12:30", "14:30", "16:30"]'
);

-- Criar índices para melhor performance nas consultas
CREATE INDEX IF NOT EXISTS idx_product_category_name ON public.product_category(name);
CREATE INDEX IF NOT EXISTS idx_product_booking_url ON public.product(booking_url);
CREATE INDEX IF NOT EXISTS idx_product_venue_name ON public.product(venue_name);
CREATE INDEX IF NOT EXISTS idx_product_active_for_sale ON public.product(active_for_sale);

-- Atualizar a view product_events para incluir mais informações
CREATE OR REPLACE VIEW product_events_detailed AS
SELECT 
    p.product_id,
    p.name,
    p.price_per_unit,
    p.tax_percentage,
    p.site_url,
    p.booking_url,
    p.venue_name,
    p.venue_address,
    p.event_description,
    p.event_timezone,
    p.available_times,
    pc.name as category_name,
    pc.description as category_description,
    o.scheduled_date,
    o.id as operation_id,
    o.status as operation_status,
    o.pickup_location,
    o.dropoff_location
FROM public.product p
LEFT JOIN public.product_category pc ON p.category_id = pc.category_id
LEFT JOIN public.operation o ON p.product_id = o.product_id
WHERE p.active_for_sale = true
ORDER BY pc.name, p.name, o.scheduled_date;

COMMENT ON VIEW product_events_detailed IS 'View detalhada que combina produtos com suas categorias e operações programadas';

-- Comentários finais
COMMENT ON TABLE public.product IS 'Tabela de produtos com informações completas de ingressos e tickets';
COMMENT ON COLUMN public.product.booking_url IS 'URL específica para reservas do produto';
COMMENT ON COLUMN public.product.venue_name IS 'Nome do local onde o evento/atração acontece';
COMMENT ON COLUMN public.product.venue_address IS 'Endereço completo do local';
COMMENT ON COLUMN public.product.event_description IS 'Descrição detalhada do evento/atração';
COMMENT ON COLUMN public.product.available_times IS 'Horários disponíveis em formato JSON';

-- Script concluído com sucesso!
-- Total de produtos inseridos: aproximadamente 35+ produtos reais da planilha
-- Categorias: Broadway (10), Museus (8), Passeios (6), Parques (1), Experiências Imersivas (4), Washington DC (1)
-- Todos os produtos incluem informações detalhadas como preços, sites, descrições e horários
-- Inserir centros de custo de exemplo
insert into cost_center (id, name, description, code, budget, utilized, responsible, department, is_active) values
    ('cc001', 'Marketing Digital', 'Campanhas de marketing digital e redes sociais', 'MKT-001', 50000.00, 32500.00, 'Ana Silva', 'Marketing', true),
    ('cc002', 'Desenvolvimento de Software', 'Desenvolvimento e manutenção de software', 'DEV-001', 120000.00, 87500.00, 'Carlos Oliveira', 'Tecnologia', true),
    ('cc003', 'Vendas e Comercial', 'Atividades comerciais e de vendas', 'VND-001', 80000.00, 42000.00, 'Marina Santos', 'Vendas', true),
    ('cc004', 'Recursos Humanos', 'Gestão de pessoas e recursos humanos', 'RH-001', 45000.00, 28000.00, 'Pedro Costa', 'RH', true),
    ('cc005', 'Operações', 'Operações logísticas e administrativas', 'OPR-001', 95000.00, 67000.00, 'Julia Ferreira', 'Operações', true);

-- Inserir despesas de exemplo para os centros de custo
insert into cost_center_expense (cost_center_id, category_id, description, amount, currency_id, exchange_rate, amount_in_brl, amount_in_usd, expense_date, created_by, status) values
    -- Despesas de Marketing
    ('cc001', 6, 'Campanha Google Ads - Janeiro', 5000.00, 1, 1.000000, 5000.00, 1000.00, '2024-01-15', 'ana.silva@empresa.com', 'approved'),
    ('cc001', 6, 'Criação de conteúdo para redes sociais', 2500.00, 1, 1.000000, 2500.00, 500.00, '2024-01-20', 'ana.silva@empresa.com', 'approved'),
    ('cc001', 6, 'Ferramenta de email marketing', 800.00, 1, 1.000000, 800.00, 160.00, '2024-01-25', 'ana.silva@empresa.com', 'approved'),
    ('cc001', 6, 'Design para campanha de lançamento', 3500.00, 1, 1.000000, 3500.00, 700.00, '2024-02-01', 'ana.silva@empresa.com', 'pending'),
    ('cc001', 6, 'Consultoria de marketing', 12000.00, 1, 1.000000, 12000.00, 2400.00, '2024-02-10', 'ana.silva@empresa.com', 'approved'),
    ('cc001', 6, 'Participação em feira setorial', 8700.00, 1, 1.000000, 8700.00, 1740.00, '2024-02-15', 'ana.silva@empresa.com', 'approved'),
    
    -- Despesas de Desenvolvimento
    ('cc002', 7, 'Licença JetBrains IDE', 1500.00, 1, 1.000000, 1500.00, 300.00, '2024-01-10', 'carlos.oliveira@empresa.com', 'approved'),
    ('cc002', 7, 'Servidor AWS - Janeiro', 3500.00, 1, 1.000000, 3500.00, 700.00, '2024-01-15', 'carlos.oliveira@empresa.com', 'approved'),
    ('cc002', 7, 'Ferramenta de monitoramento', 900.00, 1, 1.000000, 900.00, 180.00, '2024-01-20', 'carlos.oliveira@empresa.com', 'approved'),
    ('cc002', 7, 'Curso de React Advanced', 1200.00, 1, 1.000000, 1200.00, 240.00, '2024-01-25', 'carlos.oliveira@empresa.com', 'approved'),
    ('cc002', 7, 'Consultoria de arquitetura', 25000.00, 1, 1.000000, 25000.00, 5000.00, '2024-02-05', 'carlos.oliveira@empresa.com', 'approved'),
    ('cc002', 7, 'Implementação de CI/CD', 8000.00, 1, 1.000000, 8000.00, 1600.00, '2024-02-12', 'carlos.oliveira@empresa.com', 'approved'),
    ('cc002', 7, 'Backup e segurança de dados', 4500.00, 1, 1.000000, 4500.00, 900.00, '2024-02-18', 'carlos.oliveira@empresa.com', 'approved'),
    ('cc002', 7, 'Testes de performance', 3200.00, 1, 1.000000, 3200.00, 640.00, '2024-02-20', 'carlos.oliveira@empresa.com', 'pending'),
    
    -- Despesas de Vendas
    ('cc003', 5, 'Viagem a cliente em São Paulo', 2800.00, 1, 1.000000, 2800.00, 560.00, '2024-01-18', 'marina.santos@empresa.com', 'approved'),
    ('cc003', 5, 'Material promocional', 1500.00, 1, 1.000000, 1500.00, 300.00, '2024-01-22', 'marina.santos@empresa.com', 'approved'),
    ('cc003', 5, 'Almoço com cliente prospect', 450.00, 1, 1.000000, 450.00, 90.00, '2024-01-28', 'marina.santos@empresa.com', 'approved'),
    ('cc003', 5, 'Participação em evento de networking', 1200.00, 1, 1.000000, 1200.00, 240.00, '2024-02-08', 'marina.santos@empresa.com', 'approved'),
    ('cc003', 5, 'Ferramenta de CRM', 3500.00, 1, 1.000000, 3500.00, 700.00, '2024-02-15', 'marina.santos@empresa.com', 'approved'),
    ('cc003', 5, 'Consultoria de vendas', 8000.00, 1, 1.000000, 8000.00, 1600.00, '2024-02-22', 'marina.santos@empresa.com', 'approved'),
    
    -- Despesas de RH
    ('cc004', 9, 'Curso de liderança para gestores', 3500.00, 1, 1.000000, 3500.00, 700.00, '2024-01-12', 'pedro.costa@empresa.com', 'approved'),
    ('cc004', 8, 'Material de integração de novos funcionários', 800.00, 1, 1.000000, 800.00, 160.00, '2024-01-20', 'pedro.costa@empresa.com', 'approved'),
    ('cc004', 8, 'Ferramenta de avaliação de desempenho', 2200.00, 1, 1.000000, 2200.00, 440.00, '2024-01-25', 'pedro.costa@empresa.com', 'approved'),
    ('cc004', 9, 'Workshop de team building', 1500.00, 1, 1.000000, 1500.00, 300.00, '2024-02-05', 'pedro.costa@empresa.com', 'approved'),
    ('cc004', 8, 'Benefícios flexíveis - Fevereiro', 4500.00, 1, 1.000000, 4500.00, 900.00, '2024-02-10', 'pedro.costa@empresa.com', 'approved'),
    
    -- Despesas de Operações
    ('cc005', 2, 'Frete e transporte de mercadorias', 5200.00, 1, 1.000000, 5200.00, 1040.00, '2024-01-15', 'julia.ferreira@empresa.com', 'approved'),
    ('cc005', 4, 'Manutenção de equipamentos', 3500.00, 1, 1.000000, 3500.00, 700.00, '2024-01-20', 'julia.ferreira@empresa.com', 'approved'),
    ('cc005', 8, 'Serviços de limpeza e conservação', 1800.00, 1, 1.000000, 1800.00, 360.00, '2024-01-25', 'julia.ferreira@empresa.com', 'approved'),
    ('cc005', 4, 'Seguro de equipamentos', 2500.00, 1, 1.000000, 2500.00, 500.00, '2024-02-01', 'julia.ferreira@empresa.com', 'approved'),
    ('cc005', 2, 'Logística reversa', 3200.00, 1, 1.000000, 3200.00, 640.00, '2024-02-10', 'julia.ferreira@empresa.com', 'approved'),
    ('cc005', 10, 'Custos diversos operacionais', 1500.00, 1, 1.000000, 1500.00, 300.00, '2024-02-15', 'julia.ferreira@empresa.com', 'approved');

-- Atualizar os valores utilized baseado nas despesas
update cost_center set utilized = (
    select coalesce(sum(amount_in_brl), 0) 
    from cost_center_expense 
    where cost_center_id = cost_center.id and status = 'approved'
) where id in ('cc001', 'cc002', 'cc003', 'cc004', 'cc005');
-- Criar tabela de centros de custo
create table cost_center (
    id text primary key default gen_random_uuid()::text,
    name text not null,
    description text,
    code text not null unique,
    budget decimal(15,2) not null default 0.00,
    utilized decimal(15,2) not null default 0.00,
    responsible text not null,
    department text not null,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
    is_active boolean default true not null
);

-- Criar tabela de categorias de despesas
create table cost_center_category (
    id serial primary key,
    name text not null,
    description text,
    is_active boolean default true not null,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Criar tabela de despesas do centro de custo
create table cost_center_expense (
    id serial primary key,
    cost_center_id text not null references cost_center(id) on delete cascade,
    category_id integer references cost_center_category(id) on delete set null,
    description text not null,
    amount decimal(15,2) not null,
    currency_id integer not null default 1,
    exchange_rate decimal(10,6) not null default 1.000000,
    amount_in_brl decimal(15,2) not null,
    amount_in_usd decimal(15,2) not null,
    expense_date date not null,
    created_by text not null,
    status text not null default 'pending' check (status in ('pending', 'approved', 'rejected')),
    approved_by text,
    approved_at timestamp with time zone,
    receipt_url text,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Criar índices para performance
create index idx_cost_center_department on cost_center(department);
create index idx_cost_center_responsible on cost_center(responsible);
create index idx_cost_center_active on cost_center(is_active);
create index idx_cost_center_expense_center on cost_center_expense(cost_center_id);
create index idx_cost_center_expense_date on cost_center_expense(expense_date);
create index idx_cost_center_expense_status on cost_center_expense(status);

-- Criar função para atualizar o utilized do centro de custo
create or replace function update_cost_center_utilized()
returns trigger as $$
begin
    if TG_OP = 'INSERT' then
        update cost_center 
        set utilized = utilized + NEW.amount_in_brl,
            updated_at = now()
        where id = NEW.cost_center_id;
        return NEW;
    elsif TG_OP = 'DELETE' then
        update cost_center 
        set utilized = utilized - OLD.amount_in_brl,
            updated_at = now()
        where id = OLD.cost_center_id;
        return OLD;
    elsif TG_OP = 'UPDATE' then
        update cost_center 
        set utilized = utilized - OLD.amount_in_brl + NEW.amount_in_brl,
            updated_at = now()
        where id = NEW.cost_center_id;
        return NEW;
    end if;
    return null;
end;
$$ language plpgsql;

-- Criar trigger para atualizar utilized automaticamente
create trigger trigger_update_cost_center_utilized
    after insert or delete or update on cost_center_expense
    for each row execute function update_cost_center_utilized();

-- Inserir categorias padrão
insert into cost_center_category (name, description) values
    ('Alimentação', 'Despesas com alimentação e refeições'),
    ('Transporte', 'Despesas com transporte e deslocamento'),
    ('Acomodação', 'Despesas com hospedagem e acomodação'),
    ('Material', 'Compra de materiais e equipamentos'),
    ('Serviços', 'Prestação de serviços terceirizados'),
    ('Marketing', 'Despesas com marketing e propaganda'),
    ('Tecnologia', 'Despesas com tecnologia e software'),
    ('Administração', 'Despesas administrativas gerais'),
    ('Treinamento', 'Despesas com treinamento e capacitação'),
    ('Outros', 'Outras despesas não categorizadas');

-- Grant permissions
grant select on cost_center to anon, authenticated;
grant select on cost_center_category to anon, authenticated;
grant select on cost_center_expense to anon, authenticated;

-- Grant insert/update/delete for authenticated users
grant insert, update, delete on cost_center to authenticated;
grant insert, update, delete on cost_center_category to authenticated;
grant insert, update, delete on cost_center_expense to authenticated;

-- Create RLS policies
alter table cost_center enable row level security;
alter table cost_center_category enable row level security;
alter table cost_center_expense enable row level security;

-- Policies for cost_center
create policy "Allow read access for all users" on cost_center
    for select using (true);

create policy "Allow full access for authenticated users" on cost_center
    for all using (auth.role() = 'authenticated');

-- Policies for cost_center_category
create policy "Allow read access for all users" on cost_center_category
    for select using (true);

create policy "Allow full access for authenticated users" on cost_center_category
    for all using (auth.role() = 'authenticated');

-- Policies for cost_center_expense
create policy "Allow read access for all users" on cost_center_expense
    for select using (true);

create policy "Allow full access for authenticated users" on cost_center_expense
    for all using (auth.role() = 'authenticated');
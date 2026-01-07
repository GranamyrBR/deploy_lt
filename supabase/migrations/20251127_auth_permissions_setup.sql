-- Enable extensions
create extension if not exists pgcrypto;

-- Permissions catalog
create table if not exists public.app_permission (
  code text primary key,
  description text
);

-- Roles catalog
create table if not exists public.app_role (
  code text primary key,
  description text
);

-- Role-permission mapping
create table if not exists public.app_role_permission (
  role_code text references public.app_role(code) on delete cascade,
  permission_code text references public.app_permission(code) on delete cascade,
  primary key (role_code, permission_code)
);

-- User-role mapping
create table if not exists public.app_user_role (
  user_id uuid references public."user"(id) on delete cascade,
  role_code text references public.app_role(code) on delete cascade,
  primary key (user_id, role_code)
);

-- Add password hash column
alter table public."user" add column if not exists password_hash text;

-- Backfill password hashes
update public."user"
set password_hash = crypt(password, gen_salt('bf'))
where password is not null and (password_hash is null or password_hash = '');

-- Default permissions set
insert into public.app_permission(code, description) values
  ('view_dashboard','Ver dashboards'),
  ('view_contact','Ver contatos'),
  ('manage_contact','Gerenciar contatos'),
  ('view_driver','Ver motoristas'),
  ('manage_driver','Gerenciar motoristas'),
  ('view_agencies','Ver agências'),
  ('manage_agencies','Gerenciar agências'),
  ('view_flights','Ver voos'),
  ('manage_flights','Gerenciar voos'),
  ('view_leads','Ver leads'),
  ('manage_leads','Gerenciar leads'),
  ('view_reports','Ver relatórios'),
  ('manage_settings','Gerenciar configurações'),
  ('view_all_sales','Ver todas as vendas'),
  ('view_own_sales','Ver próprias vendas'),
  ('create_sale','Criar venda'),
  ('edit_sale','Editar venda'),
  ('delete_sale','Deletar venda'),
  ('view_cost_center','Ver centro de custos'),
  ('manage_cost_center','Gerenciar centro de custos'),
  ('manage_users','Gerenciar usuários')
on conflict (code) do nothing;

-- Default roles
insert into public.app_role(code, description) values
  ('admin','Administrador'),
  ('manager','Gestor'),
  ('seller','Vendedor'),
  ('viewer','Leitor'),
  ('dba','Administrador de Banco')
on conflict (code) do nothing;

-- Role to permission bootstrap
insert into public.app_role_permission(role_code, permission_code)
select r.code, p.code
from public.app_role r
join public.app_permission p on (
  (r.code = 'admin') or
  (r.code = 'manager' and p.code in ('view_all_sales','create_sale','edit_sale','delete_sale','manage_users')) or
  (r.code = 'seller' and p.code in ('view_own_sales','create_sale','edit_sale')) or
  (r.code = 'viewer' and p.code in ('view_own_sales')) or
  (r.code = 'dba' and p.code in ('manage_users','manage_settings','view_reports'))
)
on conflict do nothing;

-- Function to set password hash
create or replace function public.app_set_password(p_user_id uuid, p_password text)
returns void as $$
update public."user"
set password_hash = crypt(p_password, gen_salt('bf')),
    updated_at = now()
where id = p_user_id;
$$ language sql volatile;

-- Login function using password hash
create or replace function public.app_login(p_email text, p_password text)
returns setof public."user" as $$
select u.*
from public."user" u
where u.email = p_email
  and coalesce(u.is_active, true) = true
  and u.password_hash is not null
  and crypt(p_password, u.password_hash) = u.password_hash;
$$ language sql stable;

-- Aggregate permissions from assigned roles
create or replace function public.sync_user_permissions(p_user_id uuid)
returns void as $$
update public."user" u
set permissions = (
  select coalesce(array_agg(distinct rp.permission_code), array[]::text[])
  from public.app_user_role ur
  join public.app_role_permission rp on rp.role_code = ur.role_code
  where ur.user_id = p_user_id
)
where u.id = p_user_id;
$$ language sql volatile;

-- Sync permissions when user roles change
create or replace function public.app_user_role_sync_trigger()
returns trigger as $$
begin
  perform public.sync_user_permissions(case when tg_op = 'DELETE' then old.user_id else new.user_id end);
  return null;
end;
$$ language plpgsql;

drop trigger if exists app_user_role_sync on public.app_user_role;
create trigger app_user_role_sync
after insert or update or delete on public.app_user_role
for each row execute function public.app_user_role_sync_trigger();

-- Sync permissions when role permissions change
create or replace function public.app_role_permission_sync_trigger()
returns trigger as $$
begin
  update public."user" u
  set permissions = (
    select coalesce(array_agg(distinct rp.permission_code), array[]::text[])
    from public.app_user_role ur
    join public.app_role_permission rp on rp.role_code = ur.role_code
    where ur.user_id = u.id
  )
  where exists (
    select 1 from public.app_user_role ur2 where ur2.role_code = coalesce(new.role_code, old.role_code)
  );
  return null;
end;
$$ language plpgsql;

drop trigger if exists app_role_permission_sync on public.app_role_permission;
create trigger app_role_permission_sync
after insert or update or delete on public.app_role_permission
for each statement execute function public.app_role_permission_sync_trigger();

-- Grants for RPC functions
grant execute on function public.app_login(text, text) to anon, authenticated;
grant execute on function public.app_set_password(uuid, text) to service_role;
grant execute on function public.sync_user_permissions(uuid) to service_role;
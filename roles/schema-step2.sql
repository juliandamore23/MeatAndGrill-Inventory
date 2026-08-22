-- ============================================================
-- Meat & Grill · Control de Stock — Paso 2: cuentas y permisos
-- Pegar completo en Supabase → SQL Editor → New query → Run
-- Este script REEMPLAZA las políticas temporales del Paso 1.
-- ============================================================

-- 1) Tabla de empleados, vinculada 1 a 1 con una cuenta real de Auth.
create table if not exists employees (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null,
  role text not null
);

-- 2) Cuando crees una cuenta en Authentication → Add user con datos en
--    "User Metadata" como {"name":"Julián","role":"Cocinero"}, este
--    trigger copia esos datos acá automáticamente. No hace falta que
--    hagas nada manual además de crear la cuenta.
create or replace function public.handle_new_employee()
returns trigger as $$
begin
  insert into public.employees (id, name, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'name', new.email),
    coalesce(new.raw_user_meta_data->>'role', 'Sin rol')
  )
  on conflict (id) do update set name = excluded.name, role = excluded.role;
  return new;
end;
$$ language plpgsql security definer set search_path = public;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_employee();

-- 3) Función que responde "¿qué rol tiene la persona que está pidiendo
--    esto ahora mismo?" — la usan las políticas de abajo.
--    Se llama mg_role() y no current_role() porque CURRENT_ROLE es una
--    palabra reservada de Postgres y no se puede usar como nombre de función.
create or replace function public.mg_role()
returns text
language sql stable
as $$
  select role from public.employees where id = auth.uid();
$$;

-- 4) Matriz de permisos: qué categorías puede ver/editar cada rol
--    restringido (Jefe y Cocinero no necesitan filas: ven y editan todo).
create table if not exists role_categories (
  role text not null,
  category text not null,
  primary key (role, category)
);
truncate role_categories;
insert into role_categories (role, category) values
  ('Armador', 'Panadería'),
  ('Armador', 'Vegetales'),
  ('Armador', 'Salsas y Aderezos'),
  ('Armador', 'Condimentos'),
  ('Armador', 'Fiambres'),
  ('Armador', 'Manteca'),
  ('Armador', 'Congelados'),
  ('Armador', 'Despensa'),
  ('Panadero', 'Panadería'),
  ('Panadero', 'Despensa'),
  ('Papero', 'Papas'),
  ('Limpieza', 'Limpieza'),
  ('Limpieza', 'Bolsas y Papeles'),
  ('Caja', 'Caja Aderezo Individual'),
  ('Caja', 'Bebidas sin Alcohol'),
  ('Caja', 'Bebidas con Alcohol'),
  ('Caja', 'Descartables'),
  ('Caja', 'Librería'),
  ('Runner', 'Caja Aderezo Individual'),
  ('Runner', 'Bebidas sin Alcohol'),
  ('Runner', 'Bebidas con Alcohol'),
  ('Runner', 'Descartables'),
  ('Runner', 'Librería');

alter table employees enable row level security;
alter table role_categories enable row level security;
drop policy if exists "employees_select_self" on employees;
create policy "employees_select_self" on employees for select using (id = auth.uid());
drop policy if exists "role_categories_select" on role_categories;
create policy "role_categories_select" on role_categories for select using (auth.uid() is not null);

-- 5) Reemplazamos las políticas permisivas del Paso 1 por las reales.
drop policy if exists "temp_public_read_products" on products;
drop policy if exists "temp_public_write_products" on products;
drop policy if exists "temp_public_read_movements" on movements;
drop policy if exists "temp_public_write_movements" on movements;

-- Borramos también las nuevas por si el script ya se corrió antes, así se
-- puede volver a correr entero cuantas veces haga falta sin que tire
-- "policy already exists".
drop policy if exists "products_select" on products;
drop policy if exists "products_update" on products;
drop policy if exists "movements_select" on movements;
drop policy if exists "movements_insert" on movements;

create policy "products_select" on products for select using (
  public.mg_role() in ('Jefe', 'Cocinero', 'Caja', 'Runner')
  or category in (select category from role_categories where role = public.mg_role())
);

create policy "products_update" on products for update using (
  public.mg_role() in ('Jefe', 'Cocinero')
  or category in (select category from role_categories where role = public.mg_role())
) with check (
  public.mg_role() in ('Jefe', 'Cocinero')
  or category in (select category from role_categories where role = public.mg_role())
);

create policy "movements_select" on movements for select using (
  public.mg_role() in ('Jefe', 'Cocinero', 'Caja', 'Runner')
  or category in (select category from role_categories where role = public.mg_role())
);

create policy "movements_insert" on movements for insert with check (
  public.mg_role() in ('Jefe', 'Cocinero')
  or category in (select category from role_categories where role = public.mg_role())
);

-- 6) Sobre los PIN de 4 dígitos: NO hay nada que configurar en Supabase.
--    El mínimo de 6 caracteres no se puede bajar, así que la app le agrega
--    sola el sufijo "mg" al PIN antes de mandarlo, asi que el PIN de 4
--    digitos viaja como una password de 6 caracteres.
--    Al crear cada cuenta, cargá la password con el sufijo ya incluido.

-- 7) Verificación: si todo salió bien, esto te devuelve 6 filas —
--    las 4 políticas nuevas de products/movements y las 2 de las tablas
--    de roles. Si ves menos, algo no se aplicó.
select tablename, policyname
from pg_policies
where schemaname = 'public'
  and tablename in ('products', 'movements', 'employees', 'role_categories')
order by tablename, policyname;


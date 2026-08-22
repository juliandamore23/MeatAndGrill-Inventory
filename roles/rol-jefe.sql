-- ============================================================
-- Meat & Grill - Cambiar el rol "Dueño" por "Jefe"
-- Supabase -> SQL Editor -> New query -> Run
--
-- POR QUE: el rol se compara letra por letra contra estas politicas.
-- Un "Dueno" sin ñ, o una ñ que viajo mal codificada, no matchea y esa
-- persona no ve NADA, sin ningun mensaje de error. "Jefe" no tiene ese
-- riesgo porque es todo ASCII.
--
-- Es seguro correrlo aunque no haya todavia ninguna cuenta de Jefe, y se
-- puede correr las veces que haga falta.
--
-- OJO: el index.html tambien tiene que decir 'Jefe' en FULL_VIEW_ROLES,
-- FULL_EDIT_ROLES y en las filas de Pablo y Flor. Eso ya esta hecho y
-- publicado; este script es solo el lado de la base.
-- ============================================================

-- 1) ANTES: que roles hay hoy.
select role, count(*) as personas
from employees
group by role
order by role;

-- 2) Migrar las cuentas que ya tuvieran el rol viejo (metadata + tabla).
update auth.users
set raw_user_meta_data = raw_user_meta_data || '{"role":"Jefe"}'::jsonb
where raw_user_meta_data->>'role' = 'Dueño';

update employees
set role = 'Jefe'
where role = 'Dueño';

-- 3) Recrear las 4 politicas con el rol nuevo.
--    Son identicas a las de schema-step2.sql, solo cambia 'Dueño' -> 'Jefe'.
drop policy if exists "products_select" on products;
create policy "products_select" on products for select using (
  public.mg_role() in ('Jefe', 'Cocinero', 'Caja', 'Runner')
  or category in (select category from role_categories where role = public.mg_role())
);

drop policy if exists "products_update" on products;
create policy "products_update" on products for update using (
  public.mg_role() in ('Jefe', 'Cocinero')
  or category in (select category from role_categories where role = public.mg_role())
) with check (
  public.mg_role() in ('Jefe', 'Cocinero')
  or category in (select category from role_categories where role = public.mg_role())
);

drop policy if exists "movements_select" on movements;
create policy "movements_select" on movements for select using (
  public.mg_role() in ('Jefe', 'Cocinero', 'Caja', 'Runner')
  or category in (select category from role_categories where role = public.mg_role())
);

drop policy if exists "movements_insert" on movements;
create policy "movements_insert" on movements for insert with check (
  public.mg_role() in ('Jefe', 'Cocinero')
  or category in (select category from role_categories where role = public.mg_role())
);

-- 4) DESPUES: no puede quedar ningun "Dueño".
select role, count(*) as personas
from employees
group by role
order by role;

-- 5) Control: 0 filas = todos los roles son validos.
select name, role
from employees
where role not in ('Jefe', 'Cocinero', 'Armador', 'Panadero',
                   'Papero', 'Limpieza', 'Caja', 'Runner');

-- 6) Y que las politicas quedaron: tiene que devolver 6 filas.
select tablename, policyname
from pg_policies
where schemaname = 'public'
  and tablename in ('products', 'movements', 'employees', 'role_categories')
order by tablename, policyname;

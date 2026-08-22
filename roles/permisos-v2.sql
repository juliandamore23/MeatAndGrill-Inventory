-- ============================================================
-- Meat & Grill - Permisos v2 + cierre del auto-ascenso
-- Supabase -> SQL Editor -> New query -> Run
--
-- Hace tres cosas de una:
--   A) Cierra el agujero del trigger (nadie puede ascenderse solo).
--   B) Carga la nueva matriz de lo que cada rol puede MODIFICAR.
--   C) Recrea las politicas separando VER de MODIFICAR.
--
-- Se puede correr las veces que haga falta.
--
-- IMPORTANTE: correr esto DESPUES de rol-jefe.sql. Si todavia no lo
-- corriste, no pasa nada malo — este script tambien deja las politicas
-- con 'Jefe', pero las cuentas que tuvieran el rol viejo 'Dueño' hay que
-- migrarlas igual con aquel script.
-- ============================================================


-- ============================================================
-- A) Cerrar el auto-ascenso
-- ============================================================
-- El problema: cualquier persona logueada puede editar su PROPIO metadata
-- por la API de Supabase (es una funcion normal de Supabase, pensada para
-- que uno cambie su nombre). Como el trigger copiaba el "role" del
-- metadata a employees, y las politicas confian en employees.role,
-- alguien podia ponerse "Jefe" solo y quedar con acceso total.
--
-- La solucion: en un UPDATE el trigger sincroniza SOLO el nombre. El rol
-- se toma del metadata unicamente al CREAR la cuenta (INSERT), que es algo
-- que solo podes hacer vos desde el panel.
--
-- Consecuencia practica: para cambiarle el rol a alguien YA CREADO, no
-- alcanza con editar el metadata en el panel. Hay que hacerlo por SQL:
--     update employees set role = 'Caja' where name = 'Ana';
create or replace function public.handle_new_employee()
returns trigger as $$
begin
  if TG_OP = 'INSERT' then
    insert into public.employees (id, name, role)
    values (
      new.id,
      coalesce(new.raw_user_meta_data->>'name', new.email),
      coalesce(new.raw_user_meta_data->>'role', 'Sin rol')
    )
    on conflict (id) do update
      set name = excluded.name,
          role = excluded.role;
  else
    -- Solo el nombre. El rol NO se toca desde el metadata.
    update public.employees
    set name = coalesce(new.raw_user_meta_data->>'name', new.email)
    where id = new.id;
  end if;
  return new;
end;
$$ language plpgsql security definer set search_path = public;


-- ============================================================
-- B) Nueva matriz de lo que cada rol puede MODIFICAR
-- ============================================================
-- Jefe y Cocinero no llevan filas: modifican todo.
truncate role_categories;
insert into role_categories (role, category) values
  -- Panadero
  ('Panadero', 'Panadería'),
  ('Panadero', 'Despensa'),
  -- Armador
  ('Armador', 'Panadería'),
  ('Armador', 'Vegetales'),
  ('Armador', 'Condimentos'),
  ('Armador', 'Salsas y Aderezos'),
  ('Armador', 'Fiambres'),
  ('Armador', 'Congelados'),
  ('Armador', 'Manteca'),
  ('Armador', 'Bolsas y Papeles'),
  ('Armador', 'Despensa'),
  -- Papero: solo papas
  ('Papero', 'Papas'),
  -- Limpieza
  ('Limpieza', 'Limpieza'),
  ('Limpieza', 'Bolsas y Papeles'),
  ('Limpieza', 'Despensa'),
  -- Caja y Runner: las 5 categorias del menu Caja
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


-- ============================================================
-- C) Politicas: VER y MODIFICAR ahora son cosas distintas
-- ============================================================
-- La tabla movements no tiene columna "menu", asi que necesitamos saber si
-- una categoria es de Cocina mirando products. Va como security definer
-- para que no choque contra las politicas de products (si no, se llamaria
-- a si misma en loop).
create or replace function public.mg_es_cocina(cat text)
returns boolean
language sql stable security definer set search_path = public
as $$
  select exists (
    select 1 from products p
    where p.category = cat
      and coalesce(p.menu, 'Cocina') <> 'Caja'
  );
$$;

-- VER products: Jefe/Cocinero/Caja/Runner ven todo. Los otros cuatro roles
-- ven toda la Cocina y nada de Caja.
drop policy if exists "products_select" on products;
create policy "products_select" on products for select using (
  public.mg_role() in ('Jefe', 'Cocinero', 'Caja', 'Runner')
  or (
    public.mg_role() in ('Panadero', 'Armador', 'Papero', 'Limpieza')
    and coalesce(menu, 'Cocina') <> 'Caja'
  )
);

-- MODIFICAR products: Jefe/Cocinero todo; el resto solo sus categorias.
drop policy if exists "products_update" on products;
create policy "products_update" on products for update using (
  public.mg_role() in ('Jefe', 'Cocinero')
  or category in (select category from role_categories where role = public.mg_role())
) with check (
  public.mg_role() in ('Jefe', 'Cocinero')
  or category in (select category from role_categories where role = public.mg_role())
);

-- VER movements: mismo criterio que products.
drop policy if exists "movements_select" on movements;
create policy "movements_select" on movements for select using (
  public.mg_role() in ('Jefe', 'Cocinero', 'Caja', 'Runner')
  or (
    public.mg_role() in ('Panadero', 'Armador', 'Papero', 'Limpieza')
    and public.mg_es_cocina(category)
  )
);

-- CARGAR movements: solo donde la persona puede modificar.
drop policy if exists "movements_insert" on movements;
create policy "movements_insert" on movements for insert with check (
  public.mg_role() in ('Jefe', 'Cocinero')
  or category in (select category from role_categories where role = public.mg_role())
);


-- ============================================================
-- VERIFICACION
-- ============================================================
-- 1) Que puede modificar cada rol. Esperado:
--      Armador 9 | Caja 5 | Limpieza 3 | Panadero 2 | Papero 1 | Runner 5
select role, count(*) as categorias_que_modifica
from role_categories
group by role
order by role;

-- 2) Los dos triggers tienen que existir: uno de INSERT y uno de UPDATE.
select trigger_name, event_manipulation
from information_schema.triggers
where event_object_schema = 'auth'
  and event_object_table = 'users'
order by trigger_name;

-- 3) Las 6 politicas.
select tablename, policyname
from pg_policies
where schemaname = 'public'
  and tablename in ('products', 'movements', 'employees', 'role_categories')
order by tablename, policyname;

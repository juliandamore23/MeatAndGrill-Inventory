-- ============================================================
-- Meat & Grill - Arreglar los roles de las cuentas ("Sin rol")
-- Supabase -> SQL Editor -> New query -> Run
--
-- POR QUE PASA: cuando creaste la cuenta, el campo "User Metadata"
-- quedo vacio. El trigger que copia los datos a la tabla employees hace
-- coalesce(metadata->>'role', 'Sin rol'), asi que guardo literalmente
-- "Sin rol". Y como las politicas RLS preguntan por employees.role, esa
-- persona no matchea con ningun permiso y no ve NADA.
--
-- OJO - el detalle que hace que "arreglarlo desde el panel" no alcance:
-- el trigger original era "after INSERT on auth.users". Si ahora vas al
-- panel y le cargas el metadata a mano, la tabla employees NO se entera.
-- El paso 4 de aca abajo arregla eso para siempre.
-- ============================================================

-- 1) ANTES: mira como esta cada cuenta hoy.
select u.email,
       u.raw_user_meta_data->>'name' as meta_name,
       u.raw_user_meta_data->>'role' as meta_role,
       e.name as employees_name,
       e.role as employees_role,
       (u.email_confirmed_at is not null) as confirmado
from auth.users u
left join employees e on e.id = u.id
order by u.email;

-- 2) Cargar el metadata correcto en cada cuenta.
--    >>> SI CAMBIAS LOS EMAILS a los personales, edita esta lista y
--    >>> volve a correr el script entero. Las filas que no matcheen
--    >>> ningun email simplemente no hacen nada.
with datos(email, nombre, rol) as (
  values
    -- Julian ya usa su mail personal. Dejo tambien el interno viejo por si
    -- todavia no migraste la cuenta: la fila que no matchee no hace nada.
    ('julian.damore1@gmail.com',           'Julian',         'Cocinero'),
    ('julian@meatandgrill.local',          'Julian',         'Cocinero'),
    ('awol@meatandgrill.local',            'Awol',           'Cocinero'),
    ('pablo@meatandgrill.local',           'Pablo',          'Jefe'),
    ('flor@meatandgrill.local',            'Flor',           'Jefe'),
    ('valentin@meatandgrill.local',        'Valentín',       'Armador'),
    ('pedro@meatandgrill.local',           'Pedro',          'Armador'),
    ('manolo@meatandgrill.local',          'Manolo',         'Panadero'),
    ('aldo@meatandgrill.local',            'Aldo',           'Papero'),
    ('horacio@meatandgrill.local',         'Horacio',        'Papero'),
    ('ulises@meatandgrill.local',          'Ulises',         'Limpieza'),
    ('mariela.caja@meatandgrill.local',    'Mariela Caja',   'Caja'),
    ('ana@meatandgrill.local',             'Ana',            'Caja'),
    ('mariela.runner@meatandgrill.local',  'Mariela Runner', 'Runner'),
    ('aye@meatandgrill.local',             'Aye',            'Runner')
)
update auth.users u
set raw_user_meta_data =
      coalesce(u.raw_user_meta_data, '{}'::jsonb)
      || jsonb_build_object('name', d.nombre, 'role', d.rol)
from datos d
where lower(u.email) = lower(d.email);

-- 3) Bajar ese metadata a la tabla employees, que es la que mira RLS.
insert into employees (id, name, role)
select u.id,
       coalesce(u.raw_user_meta_data->>'name', u.email),
       coalesce(u.raw_user_meta_data->>'role', 'Sin rol')
from auth.users u
on conflict (id) do update
  set name = excluded.name,
      role = excluded.role;

-- 4) Que de ahora en mas editar el metadata desde el panel alcance:
--    el mismo trigger, pero tambien on UPDATE.
drop trigger if exists on_auth_user_updated on auth.users;
create trigger on_auth_user_updated
  after update on auth.users
  for each row execute function public.handle_new_employee();

-- 5) DESPUES: ninguna fila puede decir "Sin rol", y los roles tienen que
--    estar escritos con acento y ñ igual que en la app.
select e.name, e.role, u.email,
       (u.email_confirmed_at is not null) as confirmado
from employees e
join auth.users u on u.id = e.id
order by e.role, e.name;

-- 6) Control final: 0 filas = todos los roles son validos.
select name, role
from employees
where role not in ('Jefe', 'Cocinero', 'Armador', 'Panadero',
                   'Papero', 'Limpieza', 'Caja', 'Runner');

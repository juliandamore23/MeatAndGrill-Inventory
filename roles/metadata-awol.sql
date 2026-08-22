-- ============================================================
-- Meat & Grill - Cargarle el rol a la cuenta de Awol
-- Supabase -> SQL Editor -> New query -> Run
--
-- POR QUE: la cuenta kyubezard@gmail.com se creo con el campo
-- "User Metadata" vacio. Sin eso, el trigger guarda role = 'Sin rol' en la
-- tabla employees, y como las politicas RLS preguntan por employees.role,
-- Awol pasa el login pero la app le queda VACIA (0 productos).
--
-- OJO: esto no se puede arreglar desde el panel de Supabase. Cuando
-- cerramos el auto-ascenso, el trigger dejo de copiar el rol desde el
-- metadata en los UPDATE, justamente para que nadie se ascienda solo.
-- Por eso hay que tocar las dos tablas a mano, que es lo que hace esto.
--
-- Es seguro correrlo mas de una vez.
-- ============================================================

-- 1) ANTES
select u.email,
       u.raw_user_meta_data->>'name' as meta_name,
       u.raw_user_meta_data->>'role' as meta_role,
       e.name as employees_name,
       e.role as employees_role
from auth.users u
left join employees e on e.id = u.id
where lower(u.email) = 'kyubezard@gmail.com';


-- 2) El metadata de la cuenta.
update auth.users
set raw_user_meta_data = coalesce(raw_user_meta_data, '{}'::jsonb)
    || '{"name":"Awol","role":"Cocinero"}'::jsonb
where lower(email) = 'kyubezard@gmail.com';

-- 3) La fila de employees, que es la que miran las politicas.
insert into employees (id, name, role)
select id, 'Awol', 'Cocinero'
from auth.users
where lower(email) = 'kyubezard@gmail.com'
on conflict (id) do update
  set name = excluded.name,
      role = excluded.role;


-- 4) DESPUES: tiene que decir Awol / Cocinero.
select e.name, e.role, u.email,
       (u.email_confirmed_at is not null) as confirmado
from employees e
join auth.users u on u.id = e.id
order by e.role, e.name;

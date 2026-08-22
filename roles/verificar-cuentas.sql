-- ============================================================
-- Meat & Grill - Chequeo de cuentas
-- Supabase -> SQL Editor -> New query -> Run
--
-- Compara lo que la app ESPERA contra lo que hay de verdad en Supabase.
-- La lista de abajo esta sacada del EMPLOYEES de index.html, asi que si
-- cambias un mail en el codigo hay que regenerar este archivo.
--
-- No modifica nada: solo mira. Corrilo cada vez que des de alta a alguien.
-- ============================================================

with esperado(nombre, rol, email) as (
  values
    ('Julian',          'Cocinero',   'julian.damore1@gmail.com'         ),
    ('Awol',            'Cocinero',   'kyubezard@gmail.com'              ),
    ('Valentín',        'Armador',    'valentin@meatandgrill.local'      ),
    ('Pedro',           'Armador',    'pedro@meatandgrill.local'         ),
    ('Manolo',          'Panadero',   'manolo@meatandgrill.local'        ),
    ('Aldo',            'Papero',     'aldo@meatandgrill.local'          ),
    ('Pablo',           'Jefe',       'pablo@meatandgrill.local'         ),
    ('Flor',            'Jefe',       'flor@meatandgrill.local'          ),
    ('Ulises',          'Limpieza',   'ulises@meatandgrill.local'        ),
    ('Mariela Caja',    'Caja',       'mariela.caja@meatandgrill.local'  ),
    ('Mariela Runner',  'Runner',     'mariela.runner@meatandgrill.local'),
    ('Ana',             'Caja',       'ana@meatandgrill.local'           ),
    ('Horacio',         'Papero',     'horacio@meatandgrill.local'       ),
    ('Aye',             'Runner',     'aye@meatandgrill.local'           ),
    ('Reportes',        'Runner',     'reportes@meatandgrill.local'      )
)
select
  e.nombre,
  e.email                                as email_que_pide_la_app,
  e.rol                                  as rol_esperado,
  coalesce(emp.role, '-')                as rol_en_employees,
  case
    when u.id is null                    then 'FALTA LA CUENTA en Supabase'
    when u.email_confirmed_at is null    then 'SIN CONFIRMAR - no va a poder entrar'
    when emp.id is null                  then 'sin fila en employees'
    when emp.role = 'Sin rol'            then 'SIN ROL - entra pero no ve nada'
    when emp.role <> e.rol               then 'ROL DISTINTO al que espera la app'
    else                                      'OK'
  end                                    as estado
from esperado e
left join auth.users u  on lower(u.email) = lower(e.email)
left join employees emp on emp.id = u.id
order by (case when u.id is null then 0 else 1 end), e.nombre;


-- Y al reves: cuentas que existen en Supabase pero que la app no conoce.
-- Deberia devolver 0 filas. Si aparece alguna, o sobra o tiene el mail mal
-- escrito (que es lo mismo que no existir, desde el punto de vista de la app).
with esperado(email) as (
  values
    ('julian.damore1@gmail.com'),
    ('kyubezard@gmail.com'),
    ('valentin@meatandgrill.local'),
    ('pedro@meatandgrill.local'),
    ('manolo@meatandgrill.local'),
    ('aldo@meatandgrill.local'),
    ('pablo@meatandgrill.local'),
    ('flor@meatandgrill.local'),
    ('ulises@meatandgrill.local'),
    ('mariela.caja@meatandgrill.local'),
    ('mariela.runner@meatandgrill.local'),
    ('ana@meatandgrill.local'),
    ('horacio@meatandgrill.local'),
    ('aye@meatandgrill.local'),
    ('reportes@meatandgrill.local')
)
select u.email, u.raw_user_meta_data->>'role' as rol_metadata
from auth.users u
where lower(u.email) not in (select lower(email) from esperado);

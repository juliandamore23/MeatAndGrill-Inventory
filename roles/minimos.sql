-- ============================================================
-- Meat & Grill - Ajuste de stocks minimos
-- Supabase -> SQL Editor -> New query -> Run
--
-- Los minimos viven en la base, no en el codigo: por eso esto va por SQL.
-- Se puede correr las veces que haga falta.
--
-- OJO: Condimentos y Manteca salieron de este script. Ahora avisan solo
-- cuando llegan a cero (minimo 0) y se manejan en avisar-solo-en-cero.sql.
-- ============================================================

-- 1) ANTES
select category, name, stock, minimo
from products
where category in ('Panadería', 'Congelados', 'Condimentos', 'Despensa', 'Manteca')
order by category, name;


-- 2) Pan de Lomo: la alerta salta con 5 (antes 10)
update products set minimo = 5
where category = 'Panadería' and name = 'Pan de Lomo';

-- 3) Notco: minimo 2 (antes 5)
update products set minimo = 2
where category = 'Congelados' and name = 'Notco';

-- 4) y 5) Condimentos y Manteca: YA NO VAN ACA.
--    Los dos pasaron a "avisar solo en cero" (minimo 0), junto con la
--    mostaza de mamadera. Eso vive en avisar-solo-en-cero.sql.
--    Si se dejaran los updates a 1 que estaban aca, volver a correr este
--    script desharia aquel cambio sin que nadie se diera cuenta.

-- 6) Despensa: todos en 1, y despues la excepcion.
--    El orden importa: primero todos, despues Cheddar.
update products set minimo = 1
where category = 'Despensa';

update products set minimo = 5
where category = 'Despensa' and name = 'Cheddar (Despensa)';


-- 7) DESPUES: verifica los 3 que cambiaron.
--    Esperado: Pan de Lomo 5 | Notco 2 | Cheddar (Despensa) 5
select category, name, stock, minimo,
       case when stock <= minimo then 'REPONER' else 'en stock' end as estado
from products
where name in ('Pan de Lomo', 'Notco', 'Cheddar (Despensa)')
order by name;

-- 8) Y que no quede ningun minimo raro en esas categorias.
select category, minimo, count(*) as productos
from products
where category in ('Panadería', 'Congelados', 'Condimentos', 'Despensa', 'Manteca')
group by category, minimo
order by category, minimo;

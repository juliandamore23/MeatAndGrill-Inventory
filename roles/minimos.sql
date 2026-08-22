-- ============================================================
-- Meat & Grill - Ajuste de stocks minimos
-- Supabase -> SQL Editor -> New query -> Run
--
-- Los minimos viven en la base, no en el codigo: por eso esto va por SQL.
-- Se puede correr las veces que haga falta.
--
-- OJO: de todo lo que pediste, en realidad solo 3 productos cambian. Los
-- minimos de Condimentos, Despensa y Manteca YA estaban todos en 1. Los
-- updates de categoria completa quedan igual, para dejar la intencion
-- escrita y por si alguien los toca en el futuro.
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

-- 4) Condimentos: todos en 1 (los 9 ya estaban asi)
update products set minimo = 1
where category = 'Condimentos';

-- 5) Manteca: todos en 1 (los 2 ya estaban asi)
update products set minimo = 1
where category = 'Manteca';

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

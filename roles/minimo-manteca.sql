-- ============================================================
-- Meat & Grill - Manteca: avisar solo cuando no queda nada
-- Supabase -> SQL Editor -> New query -> Run
--
-- Pedido: las dos mantecas tienen que verse en VERDE con 1 unidad, y salir
-- en REPONER unicamente cuando esten en 0.
--
-- La regla de toda la app es: alerta cuando  stock <= minimo.
--   con minimo 1 -> stock 1 da alerta   (1 <= 1)
--   con minimo 0 -> stock 1 va verde    (1 <= 0 es falso)
--                   stock 0 da alerta   (0 <= 0)
--
-- Asi que alcanza con poner el minimo en 0: no hace falta ninguna excepcion
-- en el codigo, y la app, el PDF del reporte y la base siguen usando todos
-- la misma regla. Ademas queda a la vista por que se comporta distinto,
-- en vez de tener dos productos que dicen "min. 1" y actuan diferente.
-- ============================================================

-- 1) ANTES
select name, unit, stock, minimo,
       case when stock <= minimo then 'REPONER' else 'en stock' end as estado
from products
where category = 'Manteca'
order by name;

-- 2) El cambio: las dos de Manteca.
update products set minimo = 0
where category = 'Manteca';

-- 3) DESPUES. Con el stock en 0 las dos siguen en REPONER; apenas entre
--    una unidad pasan a verde solas.
select name, unit, stock, minimo,
       case when stock <= minimo then 'REPONER' else 'en stock' end as estado
from products
where category = 'Manteca'
order by name;

-- 4) Control: ningun otro producto tiene que haber quedado en minimo 0.
--    Solo tienen que aparecer las dos mantecas.
select category, name, minimo
from products
where minimo = 0
order by category, name;

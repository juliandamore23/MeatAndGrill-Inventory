-- ============================================================
-- Meat & Grill - Productos que avisan SOLO cuando llegan a cero
-- Supabase -> SQL Editor -> New query -> Run
--
-- Reemplaza a minimo-manteca.sql, que hacia lo mismo pero solo con manteca.
-- OJO: Condimentos y Manteca se sacaron de minimos.sql, que los ponia en 1.
-- Si no, volver a correr aquel script desharia esto sin que se note.
--
-- Son productos de los que nunca se usa mas de uno a la vez: con 1 estan
-- bien y solo hay que reponer cuando no queda ninguno.
--
-- La regla de toda la app es: alerta cuando  stock <= minimo.
--   con minimo 1 -> stock 1 da alerta   (1 <= 1)
--   con minimo 0 -> stock 1 va verde    (1 <= 0 es falso)
--                   stock 0 da alerta   (0 <= 0)
--
-- Por eso alcanza con poner el minimo en 0. No hace falta ninguna excepcion
-- en el codigo: la app, el PDF del reporte y la base siguen usando todos la
-- misma regla, y en pantalla se ve "avisa en 0" en lugar de un minimo.
-- ============================================================

-- 1) ANTES
select category, name, unit, stock, minimo,
       case when stock <= minimo then 'REPONER' else 'en stock' end as estado
from products
where category in ('Manteca', 'Condimentos')
   or (category = 'Salsas y Aderezos' and name = 'Mostaza')
order by category, name;


-- 2) Las dos mantecas.
update products set minimo = 0
where category = 'Manteca';

-- 3) Los 9 condimentos: de uno solo nunca se usa mas de uno a la vez.
update products set minimo = 0
where category = 'Condimentos';

-- 4) La mostaza de mamadera.
--    OJO: solo esta. Hay otras dos mostazas que NO se tocan, porque son
--    envases distintos y con otro consumo:
--      Mostaza (Despensa)          -> sachet de 3kg
--      Mostaza (Caja Individual)   -> caja de 196 unidades
update products set minimo = 0
where category = 'Salsas y Aderezos' and name = 'Mostaza';


-- 5) DESPUES: con 1 tienen que decir "en stock".
select category, name, unit, stock, minimo,
       case when stock <= minimo then 'REPONER' else 'en stock' end as estado
from products
where category in ('Manteca', 'Condimentos')
   or (category = 'Salsas y Aderezos' and name = 'Mostaza')
order by category, name;


-- 6) Control: estos tienen que ser los UNICOS con minimo 0.
--    Esperado: 12 filas -> las 2 mantecas, los 9 condimentos y la mostaza
--    de mamadera. Si aparece alguno mas, se colo.
select category, name, unit, stock
from products
where minimo = 0
order by category, name;

select count(*) as con_minimo_cero from products where minimo = 0;


-- 7) Para tener a la vista: las otras mamaderas de Salsas y Aderezos siguen
--    con minimo 1, asi que con 1 sola van a marcar REPONER. Si queres que se
--    porten como la mostaza, agregalas al update del paso 4.
select name, unit, stock, minimo
from products
where category = 'Salsas y Aderezos' and unit = 'Mamadera'
order by name;

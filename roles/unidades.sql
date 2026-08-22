-- ============================================================
-- Meat & Grill - Unidades por envase y ajuste de minimos
-- Supabase -> SQL Editor -> New query -> Run
--
-- La columna "factor" es cuantas unidades sueltas trae cada envase. Cuando
-- esta cargada, la app muestra las dos cosas: "9 Bolsas - 54 u.", y el PDF
-- del reporte tambien. Cuando esta en null, solo muestra los envases.
--
-- Se puede correr las veces que haga falta.
-- ============================================================

-- 1) ANTES
select name, unit, factor, stock, minimo
from products
where category in ('Carnicería', 'Condimentos', 'Papas')
order by category, name;


-- 2) Carniceria: cortes envasados en bolsas, con su rinde por bolsa.
--    Se cambia tambien la unidad de "Envasado" a "Bolsa", que es como los
--    nombran en el local.
update products set unit = 'Bolsa', factor = 4, minimo = 2
where category = 'Carnicería' and name = 'Bife de Chorizo';

update products set unit = 'Bolsa', factor = 6, minimo = 2
where category = 'Carnicería' and name = 'Ojo de Bife';

update products set unit = 'Bolsa', factor = 5, minimo = 2
where category = 'Carnicería' and name = 'Lomo';


-- 3) Condimentos: se cuentan por unidad, no por frasco (los 9).
update products set unit = 'Unidad'
where category = 'Condimentos';


-- 4) Papas.
--    Las precocidas YA estaban en 'Batea', igual se deja escrito.
update products set unit = 'Bolsa de 5kg'
where category = 'Papas' and name = 'Papas Congeladas';

update products set unit = 'Batea'
where category = 'Papas' and name = 'Papas Precocidas';


-- 5) DESPUES. Esperado:
--      Bife de Chorizo  Bolsa          factor 4  minimo 2
--      Ojo de Bife      Bolsa          factor 6  minimo 2
--      Lomo             Bolsa          factor 5  minimo 2
--      los 9 condimentos en 'Unidad'
--      Papas Congeladas 'Bolsa de 5kg' / Papas Precocidas 'Batea'
select name, unit, factor, stock, minimo,
       case when factor is not null then stock * factor end as unidades_totales,
       case when stock <= minimo then 'REPONER' else 'en stock' end as estado
from products
where category in ('Carnicería', 'Condimentos', 'Papas')
order by category, name;


-- 6) Todos los productos que tienen rinde cargado, para tenerlos a la vista.
select category, name, unit, factor, stock, stock * factor as unidades_totales
from products
where factor is not null
order by category, name;

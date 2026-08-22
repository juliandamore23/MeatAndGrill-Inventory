-- ============================================================
-- Meat & Grill - Completar la columna "menu" de los productos
-- Supabase -> SQL Editor -> New query -> Run
--
-- Los 102 productos ya estan cargados, pero varios tienen menu = null.
-- Para los de Cocina eso NO rompe nada (la app los muestra igual), pero
-- para los 28 de Caja SI: si un producto de Caja quedo con menu = null,
-- aparece en Cocina y no aparece nunca en la pantalla de Caja.
--
-- menu y period se deducen 100% de la categoria, asi que alcanza con
-- estos 3 UPDATE. Se puede correr las veces que haga falta.
-- ============================================================

-- 1) ANTES: mira como esta hoy.
select coalesce(menu, '(null)') as menu,
       coalesce(period, '(null)') as period,
       count(*) as productos
from products
group by 1, 2
order by 1, 2;

-- 2) Caja - conteo SEMANAL (17 productos)
update products
set menu = 'Caja', period = 'Semanal'
where category in ('Caja Aderezo Individual',
                   'Bebidas sin Alcohol',
                   'Bebidas con Alcohol');

-- 3) Caja - conteo MENSUAL (11 productos)
update products
set menu = 'Caja', period = 'Mensual'
where category in ('Descartables',
                   'Librería');

-- 4) Todo lo demas es Cocina (74 productos), sin period.
update products
set menu = 'Cocina', period = null
where category not in ('Caja Aderezo Individual',
                       'Bebidas sin Alcohol',
                       'Bebidas con Alcohol',
                       'Descartables',
                       'Librería');

-- 5) DESPUES: tiene que dar exactamente estas 3 filas y ninguna con null.
--      Caja   | Mensual | 11
--      Caja   | Semanal | 17
--      Cocina | (null)  | 74
select coalesce(menu, '(null)') as menu,
       coalesce(period, '(null)') as period,
       count(*) as productos
from products
group by 1, 2
order by 1, 2;

-- 6) Y este control tiene que devolver 0 filas. Si devuelve alguna, esa
--    categoria esta escrita distinto en la base que en la app (tipico:
--    un acento o una ñ), y esos productos no se van a ver.
select distinct category
from products
where category not in ('Panadería', 'Carnicería', 'Fiambres', 'Vegetales',
                       'Salsas y Aderezos', 'Condimentos', 'Despensa',
                       'Papas', 'Congelados', 'Manteca', 'Bolsas y Papeles',
                       'Limpieza', 'Caja Aderezo Individual',
                       'Bebidas sin Alcohol', 'Bebidas con Alcohol',
                       'Descartables', 'Librería');

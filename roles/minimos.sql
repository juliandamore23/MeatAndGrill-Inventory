-- ============================================================
-- Meat & Grill - TODOS los stocks minimos
-- Supabase -> SQL Editor -> New query -> Run
--
-- Este es el UNICO archivo que define minimos. Antes estaban repartidos
-- entre este y avisar-solo-en-cero.sql, y se contradecian: los updates por
-- categoria de aca pisaban a los de alla. Volver a correr el script
-- equivocado deshacia el otro en silencio.
--
-- Ahora se lee de arriba hacia abajo y GANA EL ULTIMO QUE ESCRIBE. Por eso
-- el orden importa y esta pensado: primero los valores por categoria,
-- despues las excepciones producto por producto. Correrlo entero, siempre.
-- Se puede repetir las veces que haga falta.
--
-- LA REGLA: la app avisa cuando  stock <= minimo.
--   minimo 1 -> con 1 unidad ya avisa
--   minimo 0 -> con 1 esta en verde y solo avisa en 0
-- ============================================================

-- 1) ANTES
select category, name, unit, stock, minimo,
       case when stock <= minimo then 'REPONER' else 'en stock' end as estado
from products
order by category, name;


-- ============================================================
-- A) Valores por categoria
-- ============================================================
update products set minimo = 1 where category = 'Despensa';


-- ============================================================
-- B) Excepciones puntuales
-- ============================================================
-- Pan de Lomo: la alerta salta con 5 (antes 10)
update products set minimo = 5
where category = 'Panadería' and name = 'Pan de Lomo';

-- Notco: minimo 2 (antes 5)
update products set minimo = 2
where category = 'Congelados' and name = 'Notco';

-- Cheddar de Despensa: minimo 5. Ojo, es el de Despensa; el de Fiambres
-- es otro producto y queda como esta.
update products set minimo = 5
where category = 'Despensa' and name = 'Cheddar (Despensa)';


-- ============================================================
-- C) Los que avisan SOLO cuando llegan a cero  (minimo 0)
--    VA AL FINAL A PROPOSITO: asi gana sobre cualquier valor por
--    categoria de mas arriba, sin importar cuantos se agreguen despues.
--    Son productos de los que nunca se usa mas de uno a la vez.
-- ============================================================

-- Las dos mantecas
update products set minimo = 0 where category = 'Manteca';

-- Los 9 condimentos
update products set minimo = 0 where category = 'Condimentos';

-- La mostaza de mamadera. SOLO esta: hay otras dos mostazas que no se
-- tocan, porque son envases distintos y con otro consumo.
--   Mostaza (Despensa)        -> sachet de 3kg
--   Mostaza (Caja Individual) -> caja de 196 unidades
update products set minimo = 0
where category = 'Salsas y Aderezos' and name = 'Mostaza';

-- Los de Despensa. Ojo con dos: en Condimentos hay una "Paprika" y un
-- "Sesamo Tostado" que son otros productos (y ya quedaron en 0 arriba).
-- Estos son los de Despensa.
update products set minimo = 0
where category = 'Despensa'
  and name in ('Aceite de Cocina',
               'Gochujang',
               'Paprika (Despensa)',
               'Salsa de Soja',
               'Salsa de Pescado',
               'Salsa Inglesa',
               'Sésamo (Despensa)',
               'Vinagre de Arroz');


-- ============================================================
-- VERIFICACION
-- ============================================================
-- 1) Los que avisan solo en cero. Esperado: 20 filas.
--       2  Manteca
--       9  Condimentos
--       1  Mostaza (mamadera)
--       8  Despensa
select category, name, unit, stock
from products
where minimo = 0
order by category, name;

select count(*) as deberian_ser_20 from products where minimo = 0;

-- 2) Control de nombres: si alguno de los 8 de Despensa estuviera escrito
--    distinto en la base, el update no lo habria encontrado. Esta consulta
--    tiene que devolver 0 filas.
select 'no encontrado en la base' as problema, n as nombre_buscado
from (values ('Aceite de Cocina'), ('Gochujang'), ('Paprika (Despensa)'),
             ('Salsa de Soja'), ('Salsa de Pescado'), ('Salsa Inglesa'),
             ('Sésamo (Despensa)'), ('Vinagre de Arroz')) as t(n)
where not exists (
  select 1 from products p where p.category = 'Despensa' and p.name = t.n
);

-- 3) Como queda todo Despensa, para revisarlo de un vistazo.
select name, unit, stock, minimo,
       case when stock <= minimo then 'REPONER' else 'en stock' end as estado
from products
where category = 'Despensa'
order by minimo, name;

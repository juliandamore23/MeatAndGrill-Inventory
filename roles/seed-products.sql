-- ============================================================
-- Meat & Grill - Carga de los 102 productos del inventario
-- Pegar completo en Supabase -> SQL Editor -> New query -> Run
--
-- Es seguro correrlo aunque los productos YA existan: usa
-- "on conflict (id) do nothing", asi que NO pisa el stock que
-- ya tengan cargado. Solo agrega los que falten.
--
-- Antes de correrlo, fijate cuantos hay:
--     select count(*) from products;
--   102 -> ya esta todo, no hace falta correr nada.
--     0 -> corre este script entero.
-- ============================================================

insert into products (id, name, category, unit, factor, stock, minimo, menu, period) values
  ('bollos', 'Bollos', 'Carnicería', 'Bolsa', 20, 20, 20, 'Cocina', null),
  ('jamon', 'Jamón', 'Fiambres', 'Paquete', null, 2, 1, 'Cocina', null),
  ('panceta', 'Panceta', 'Fiambres', 'Batea', null, 2, 1, 'Cocina', null),
  ('ojo-de-bife', 'Ojo de Bife', 'Carnicería', 'Envasado', null, 9, 5, 'Cocina', null),
  ('bife-chorizo', 'Bife de Chorizo', 'Carnicería', 'Envasado', null, 7, 5, 'Cocina', null),
  ('lomo', 'Lomo', 'Carnicería', 'Envasado', null, 19, 5, 'Cocina', null),
  ('tybo', 'Tybo', 'Fiambres', 'Enfilmado', null, 2, 1, 'Cocina', null),
  ('cheddar', 'Cheddar', 'Fiambres', 'Batea', null, 2, 1, 'Cocina', null),
  ('cebolla-myg', 'Cebolla Meat & Grill', 'Vegetales', 'Envasado', null, 6, 2, 'Cocina', null),
  ('manteca-myg', 'Manteca Noisette (Meat & Grill)', 'Manteca', 'GN', null, 0, 1, 'Cocina', null),
  ('manteca-tostadora', 'Manteca Noisette (Tostadora)', 'Manteca', 'GN', null, 0, 1, 'Cocina', null),
  ('salsa-myg', 'Salsa Meat & Grill', 'Salsas y Aderezos', 'Mamadera', null, 6, 3, 'Cocina', null),
  ('salsa-meatmac', 'Salsa MeatMac', 'Salsas y Aderezos', 'Mamadera', null, 6, 3, 'Cocina', null),
  ('salsa-emmy', 'Salsa Emmy', 'Salsas y Aderezos', 'Mamadera', null, 2, 1, 'Cocina', null),
  ('ketchup', 'Ketchup', 'Salsas y Aderezos', 'Mamadera', null, 2, 1, 'Cocina', null),
  ('mostaza', 'Mostaza', 'Salsas y Aderezos', 'Mamadera', null, 1, 1, 'Cocina', null),
  ('mayonesa', 'Mayonesa', 'Salsas y Aderezos', 'Mamadera', null, 2, 1, 'Cocina', null),
  ('cebolla-oklahoma', 'Cebolla Oklahoma', 'Vegetales', 'Batea', null, 1, 1, 'Cocina', null),
  ('lechuga', 'Lechuga', 'Vegetales', 'GN', null, 2, 2, 'Cocina', null),
  ('tomate', 'Tomate', 'Vegetales', 'GN', null, 1, 1, 'Cocina', null),
  ('pepinillos', 'Pepinillos', 'Vegetales', 'GN', null, 1, 1, 'Cocina', null),
  ('cebolla-brunoise', 'Cebolla Brunoise', 'Vegetales', 'GN', null, 1, 1, 'Cocina', null),
  ('chimi', 'Chimichurri', 'Vegetales', 'Frasco', null, 1, 1, 'Cocina', null),
  ('criolla', 'Criolla', 'Vegetales', 'Frasco', null, 1, 1, 'Cocina', null),
  ('notco', 'Notco', 'Congelados', 'Paquete', null, 5, 5, 'Cocina', null),
  ('panes-hamburguesa', 'Panes de Hamburguesa', 'Panadería', 'Unidad', null, 171, 60, 'Cocina', null),
  ('ciabattas', 'Ciabattas', 'Panadería', 'Unidad', null, 11, 10, 'Cocina', null),
  ('pan-de-lomo', 'Pan de Lomo', 'Panadería', 'Unidad', null, 9, 10, 'Cocina', null),
  ('medallones', 'Medallones', 'Carnicería', 'Bolsa', null, 3, 2, 'Cocina', null),
  ('papas-congeladas', 'Papas Congeladas', 'Papas', 'Bolsa', null, 0, 6, 'Cocina', null),
  ('papas-precocidas', 'Papas Precocidas', 'Papas', 'Batea', null, 0, 5, 'Cocina', null),
  ('salpimienta', 'SalPimienta', 'Condimentos', 'Frasco', null, 0, 1, 'Cocina', null),
  ('paprika-condimento', 'Paprika', 'Condimentos', 'Frasco', null, 0, 1, 'Cocina', null),
  ('sesamo-condimento', 'Sésamo Tostado', 'Condimentos', 'Frasco', null, 0, 1, 'Cocina', null),
  ('morron-condimento', 'Morrón', 'Condimentos', 'Frasco', null, 0, 1, 'Cocina', null),
  ('ajo-condimento', 'Ajo', 'Condimentos', 'Frasco', null, 0, 1, 'Cocina', null),
  ('perejil-condimento', 'Perejil', 'Condimentos', 'Frasco', null, 0, 1, 'Cocina', null),
  ('salvia-condimento', 'Salvia', 'Condimentos', 'Frasco', null, 0, 1, 'Cocina', null),
  ('romero-condimento', 'Romero', 'Condimentos', 'Frasco', null, 0, 1, 'Cocina', null),
  ('tomillo-condimento', 'Tomillo', 'Condimentos', 'Frasco', null, 0, 1, 'Cocina', null),
  ('mayonesa-despensa', 'Mayonesa (Despensa)', 'Despensa', 'Sachet de 3kg', null, 1, 1, 'Cocina', null),
  ('ketchup-despensa', 'Ketchup (Despensa)', 'Despensa', 'Sachet de 3kg', null, 1, 1, 'Cocina', null),
  ('mostaza-despensa', 'Mostaza (Despensa)', 'Despensa', 'Sachet de 3kg', null, 1, 1, 'Cocina', null),
  ('sesamo-despensa', 'Sésamo (Despensa)', 'Despensa', 'Bolsa', null, 1, 1, 'Cocina', null),
  ('paprika-despensa', 'Paprika (Despensa)', 'Despensa', 'Bolsa', null, 1, 1, 'Cocina', null),
  ('sal', 'Sal', 'Despensa', 'Paquete de 5kg', null, 1, 1, 'Cocina', null),
  ('pimienta', 'Pimienta', 'Despensa', 'Paquete de 1kg', null, 1, 1, 'Cocina', null),
  ('jim-bean', 'Jim Bean', 'Despensa', 'Botella de 750ml', null, 1, 1, 'Cocina', null),
  ('barbacoa-despensa', 'Salsa Barbacoa (Despensa)', 'Despensa', 'Sachet de 3kg', null, 1, 1, 'Cocina', null),
  ('salsa-pescado', 'Salsa de Pescado', 'Despensa', 'Botella de 400ml', null, 1, 1, 'Cocina', null),
  ('gochujang', 'Gochujang', 'Despensa', 'Envase', null, 1, 1, 'Cocina', null),
  ('salsa-soja', 'Salsa de Soja', 'Despensa', 'Botella de 860ml', null, 1, 1, 'Cocina', null),
  ('aceite-cocina', 'Aceite de Cocina', 'Despensa', 'Bidón de 5L', null, 1, 1, 'Cocina', null),
  ('vinagre-arroz', 'Vinagre de Arroz', 'Despensa', 'Botella de 900ml', null, 1, 1, 'Cocina', null),
  ('salsa-inglesa', 'Salsa Inglesa', 'Despensa', 'Botella de 148ml', null, 1, 1, 'Cocina', null),
  ('azucar', 'Azúcar', 'Despensa', 'Paquete de 1kg', null, 1, 1, 'Cocina', null),
  ('manteca-despensa', 'Manteca (Despensa)', 'Despensa', 'Bloque de 5kg', null, 1, 1, 'Cocina', null),
  ('cheddar-despensa', 'Cheddar (Despensa)', 'Despensa', 'Bolsa', null, 20, 1, 'Cocina', null),
  ('panceta-despensa', 'Panceta Envasada (Despensa)', 'Despensa', 'Envasado', null, 2, 1, 'Cocina', null),
  ('desinfectante', 'Desinfectante', 'Limpieza', 'Bidón de 5L', null, 1, 1, 'Cocina', null),
  ('detergente', 'Detergente', 'Limpieza', 'Bidón de 5L', null, 1, 1, 'Cocina', null),
  ('desodorante', 'Desodorante de Ambientes', 'Limpieza', 'Bidón de 5L', null, 1, 1, 'Cocina', null),
  ('lavandina', 'Lavandina', 'Limpieza', 'Bidón de 4L', null, 1, 1, 'Cocina', null),
  ('panther-h', 'Panther H', 'Limpieza', 'Bidón de 5L', null, 1, 1, 'Cocina', null),
  ('alcohol-70', 'Alcohol 70%', 'Limpieza', 'Bidón de 5L', null, 1, 1, 'Cocina', null),
  ('limon-limpieza', 'Limón (Limpieza)', 'Limpieza', 'Bidón de 5L', null, 1, 1, 'Cocina', null),
  ('vinagre-limpieza', 'Vinagre (Limpieza)', 'Limpieza', 'Bidón de 5L', null, 1, 1, 'Cocina', null),
  ('jabon-liquido', 'Jabón Líquido de Manos', 'Limpieza', 'Bidón de 5L', null, 1, 1, 'Cocina', null),
  ('limpiavidrios', 'Limpiavidrios', 'Limpieza', 'Bidón de 5L', null, 1, 1, 'Cocina', null),
  ('papel-parafinado', 'Papel Parafinado', 'Bolsas y Papeles', 'Bolsa', null, 1, 1, 'Cocina', null),
  ('bolsas-envasar', 'Bolsas de Envasar', 'Bolsas y Papeles', 'Bolsa', null, 1, 1, 'Cocina', null),
  ('folex-grande', 'Folex Grande (25x35cm)', 'Bolsas y Papeles', 'Bolsa', null, 1, 1, 'Cocina', null),
  ('folex-pequeno', 'Folex Pequeño', 'Bolsas y Papeles', 'Bolsa', null, 1, 1, 'Cocina', null),
  ('cajas-papa', 'Cajas de Papa', 'Bolsas y Papeles', 'Caja', null, 1, 1, 'Cocina', null),
  ('mayonesa-caja', 'Mayonesa (Caja Individual)', 'Caja Aderezo Individual', 'Caja de 196 unidades', null, 0, 1, 'Caja', 'Semanal'),
  ('ketchup-caja', 'Ketchup (Caja Individual)', 'Caja Aderezo Individual', 'Caja de 196 unidades', null, 0, 1, 'Caja', 'Semanal'),
  ('mostaza-caja', 'Mostaza (Caja Individual)', 'Caja Aderezo Individual', 'Caja de 196 unidades', null, 0, 1, 'Caja', 'Semanal'),
  ('sal-caja', 'Sal (Caja Individual)', 'Caja Aderezo Individual', 'Caja de 1000 unidades', null, 0, 1, 'Caja', 'Semanal'),
  ('fanta', 'Fanta', 'Bebidas sin Alcohol', 'Unidad', null, 0, 1, 'Caja', 'Semanal'),
  ('coca', 'Coca-Cola', 'Bebidas sin Alcohol', 'Unidad', null, 0, 1, 'Caja', 'Semanal'),
  ('coca-zero', 'Coca-Cola Zero', 'Bebidas sin Alcohol', 'Unidad', null, 0, 1, 'Caja', 'Semanal'),
  ('sprite', 'Sprite', 'Bebidas sin Alcohol', 'Unidad', null, 0, 1, 'Caja', 'Semanal'),
  ('sprite-zero', 'Sprite Zero', 'Bebidas sin Alcohol', 'Unidad', null, 0, 1, 'Caja', 'Semanal'),
  ('agua', 'Agua', 'Bebidas sin Alcohol', 'Unidad', null, 0, 1, 'Caja', 'Semanal'),
  ('soda', 'Soda', 'Bebidas sin Alcohol', 'Unidad', null, 0, 1, 'Caja', 'Semanal'),
  ('stella', 'Stella Artois', 'Bebidas con Alcohol', 'Unidad', null, 0, 1, 'Caja', 'Semanal'),
  ('stella-cero', 'Stella Cero', 'Bebidas con Alcohol', 'Unidad', null, 0, 1, 'Caja', 'Semanal'),
  ('patagonia-24-7', 'Patagonia 24/7', 'Bebidas con Alcohol', 'Unidad', null, 0, 1, 'Caja', 'Semanal'),
  ('patagonia-lagune', 'Patagonia Lagune', 'Bebidas con Alcohol', 'Unidad', null, 0, 1, 'Caja', 'Semanal'),
  ('ipa-vera', 'IPA Vera', 'Bebidas con Alcohol', 'Unidad', null, 0, 1, 'Caja', 'Semanal'),
  ('barriles-amber', 'Barriles de Amber Lager Patagonia', 'Bebidas con Alcohol', 'Barril', null, 0, 1, 'Caja', 'Semanal'),
  ('servilletas', 'Servilletas', 'Descartables', 'Caja', null, 0, 1, 'Caja', 'Mensual'),
  ('vasos', 'Vasos', 'Descartables', 'Caja', null, 0, 1, 'Caja', 'Mensual'),
  ('bolsas-delivery', 'Bolsas de Delivery', 'Descartables', 'Caja', null, 0, 1, 'Caja', 'Mensual'),
  ('cubiertos-descartables', 'Cubiertos Descartables', 'Descartables', 'Unidad', null, 0, 1, 'Caja', 'Mensual'),
  ('salsa-tabasco', 'Salsa Tabasco', 'Descartables', 'Unidad', null, 0, 1, 'Caja', 'Mensual'),
  ('escarbadientes', 'Escarbadientes', 'Descartables', 'Caja', null, 0, 1, 'Caja', 'Mensual'),
  ('banditas-elasticas', 'Banditas Elásticas', 'Librería', 'Caja', null, 0, 1, 'Caja', 'Mensual'),
  ('ganchos-abrochadora', 'Ganchos de Abrochadora', 'Librería', 'Caja', null, 0, 1, 'Caja', 'Mensual'),
  ('lapicera', 'Lapicera', 'Librería', 'Unidad', null, 0, 1, 'Caja', 'Mensual'),
  ('fibrones', 'Fibrones', 'Librería', 'Unidad', null, 0, 1, 'Caja', 'Mensual'),
  ('rollo-termico', 'Rollo Térmico', 'Librería', 'Unidad', null, 0, 1, 'Caja', 'Mensual')
on conflict (id) do nothing;

-- Verificacion: tiene que devolver 102.
select count(*) as productos_cargados from products;

-- Y este desglose tiene que dar 17 categorias (12 de Cocina + 5 de Caja):
select menu, category, count(*) as items
from products
group by menu, category
order by menu, category;

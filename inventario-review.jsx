import React, { useState, useEffect, useCallback, useMemo, useRef } from 'react';
import { Plus, Minus, RotateCcw, ChevronLeft, AlertTriangle, Check, UserCircle2, Clock, Download } from 'lucide-react';

// ==================== CONSTANTES ====================
const EMPLOYEES = [
  { name: 'Julián', role: 'Cocinero' },
  { name: 'Awol', role: 'Cocinero' },
  { name: 'Valentín', role: 'Armador' },
  { name: 'Pedro', role: 'Armador' },
  { name: 'Manolo', role: 'Panadero' },
  { name: 'Aldo', role: 'Papero' },
  { name: 'Pablo', role: 'Dueño' },
  { name: 'Flor', role: 'Dueño' },
  { name: 'Ulises', role: 'Limpieza' },
  { name: 'Mariela Caja', role: 'Caja' },
  { name: 'Mariela Runner', role: 'Caja' },
  { name: 'Ana', role: 'Caja' },
  { name: 'Horacio', role: 'Papero' },
  { name: 'Aye', role: 'Runner' },
];

const CATEGORIES = [
  { key: 'Panadería', emoji: '🥖' },
  { key: 'Carnicería', emoji: '🥩' },
  { key: 'Fiambres', emoji: '🥓' },
  { key: 'Vegetales', emoji: '🥬' },
  { key: 'Salsas y Aderezos', emoji: '🥫' },
  { key: 'Condimentos', emoji: '🧂' },
  { key: 'Despensa', emoji: '🧺' },
  { key: 'Papas', emoji: '🍟' },
  { key: 'Congelados', emoji: '🧊' },
  { key: 'Manteca', emoji: '🧈' },
  { key: 'Bolsas y Papeles', emoji: '📦' },
  { key: 'Limpieza', emoji: '🧼' },
];

const CAJA_STRUCTURE = {
  Semanal: [
    { key: 'Caja Aderezo Individual', emoji: '🥡' },
    { key: 'Bebidas sin Alcohol', emoji: '🥤' },
    { key: 'Bebidas con Alcohol', emoji: '🍺' },
  ],
  Mensual: [
    { key: 'Descartables', emoji: '🍽️' },
    { key: 'Librería', emoji: '✏️' },
  ],
};

// ==================== COLORS ====================
const C = {
  accent: '#D9622E',
  accentDark: '#B84E22',
  alert: '#E4483A',
  ok: '#6FA96A',
  bg: '#18140F',
  surface: '#241E17',
  surface2: '#2E271D',
  line: '#3A3226',
  cream: '#F3ECE1',
  muted: '#A0937F',
};

// ==================== UTILITY FUNCTIONS ====================
const STORAGE_KEY = 'meatgrill-inventario-v9';

// FIX: normalizeProduct calculaba Number(product.stock) / Number(product.minimo)
// dos veces cada uno. Ahora se calcula una sola vez por campo.
const normalizeProduct = (product) => {
  const stockNum = Number(product.stock);
  const minimoNum = Number(product.minimo);
  return {
    ...product,
    stock: Number.isFinite(stockNum) ? stockNum : 0,
    minimo: Number.isFinite(minimoNum) ? minimoNum : 1,
  };
};

// Verifica si un producto está por debajo del mínimo
const isLow = (product) => {
  const stock = Number(product.stock);
  const minimo = Number(product.minimo);
  return Number.isFinite(stock) && Number.isFinite(minimo) && stock <= minimo;
};

// Calcula unidades totales si tiene factor
const totalUnits = (product) =>
  product.factor ? product.stock * product.factor : null;

// FIX (bug crítico): esta función estaba declarada con `const` DESPUÉS de los
// useMemo que la usaban (filteredProducts, visibleLowCount). En JS, un `const`
// no se "hoistea" con su valor: existe en temporal dead zone hasta que se
// ejecuta la línea de declaración. Como los useMemo corren su función factory
// de forma síncrona durante el render, llamar a matchesMenu ahí arrojaba
// "ReferenceError: Cannot access 'matchesMenu' before initialization" en el
// primer render. Solución: moverla fuera del componente (además evita que se
// vuelva a crear en cada render, ya que no depende de closures).
const matchesMenu = (product, currentMenu, currentPeriod) => {
  if (currentMenu === 'Caja') return product.menu === 'Caja' && product.period === currentPeriod;
  return product.menu !== 'Caja';
};

// ==================== SEED PRODUCTS ====================
const SEED_PRODUCTS = [
  { id: 'bollos', name: 'Bollos', category: 'Carnicería', unit: 'Bolsa', factor: 20, stock: 20, minimo: 20 },
  { id: 'jamon', name: 'Jamón', category: 'Fiambres', unit: 'Paquete', factor: null, stock: 2, minimo: 1 },
  { id: 'panceta', name: 'Panceta', category: 'Fiambres', unit: 'Batea', factor: null, stock: 2, minimo: 1 },
  { id: 'ojo-de-bife', name: 'Ojo de Bife', category: 'Carnicería', unit: 'Envasado', factor: null, stock: 9, minimo: 5 },
  { id: 'bife-chorizo', name: 'Bife de Chorizo', category: 'Carnicería', unit: 'Envasado', factor: null, stock: 7, minimo: 5 },
  { id: 'lomo', name: 'Lomo', category: 'Carnicería', unit: 'Envasado', factor: null, stock: 19, minimo: 5 },
  { id: 'tybo', name: 'Tybo', category: 'Fiambres', unit: 'Enfilmado', factor: null, stock: 2, minimo: 1 },
  { id: 'cheddar', name: 'Cheddar', category: 'Fiambres', unit: 'Batea', factor: null, stock: 2, minimo: 1 },
  { id: 'cebolla-myg', name: 'Cebolla Meat & Grill', category: 'Vegetales', unit: 'Envasado', factor: null, stock: 6, minimo: 2 },
  { id: 'manteca-myg', name: 'Manteca Noisette (Meat & Grill)', category: 'Manteca', unit: 'GN', factor: null, stock: 0, minimo: 1 },
  { id: 'manteca-tostadora', name: 'Manteca Noisette (Tostadora)', category: 'Manteca', unit: 'GN', factor: null, stock: 0, minimo: 1 },
  { id: 'salsa-myg', name: 'Salsa Meat & Grill', category: 'Salsas y Aderezos', unit: 'Mamadera', factor: null, stock: 6, minimo: 3 },
  { id: 'salsa-meatmac', name: 'Salsa MeatMac', category: 'Salsas y Aderezos', unit: 'Mamadera', factor: null, stock: 6, minimo: 3 },
  { id: 'salsa-emmy', name: 'Salsa Emmy', category: 'Salsas y Aderezos', unit: 'Mamadera', factor: null, stock: 2, minimo: 1 },
  { id: 'ketchup', name: 'Ketchup', category: 'Salsas y Aderezos', unit: 'Mamadera', factor: null, stock: 2, minimo: 1 },
  { id: 'mostaza', name: 'Mostaza', category: 'Salsas y Aderezos', unit: 'Mamadera', factor: null, stock: 1, minimo: 1 },
  { id: 'mayonesa', name: 'Mayonesa', category: 'Salsas y Aderezos', unit: 'Mamadera', factor: null, stock: 2, minimo: 1 },
  { id: 'cebolla-oklahoma', name: 'Cebolla Oklahoma', category: 'Vegetales', unit: 'Batea', factor: null, stock: 1, minimo: 1 },
  { id: 'lechuga', name: 'Lechuga', category: 'Vegetales', unit: 'GN', factor: null, stock: 2, minimo: 2 },
  { id: 'tomate', name: 'Tomate', category: 'Vegetales', unit: 'GN', factor: null, stock: 1, minimo: 1 },
  { id: 'pepinillos', name: 'Pepinillos', category: 'Vegetales', unit: 'GN', factor: null, stock: 1, minimo: 1 },
  { id: 'cebolla-brunoise', name: 'Cebolla Brunoise', category: 'Vegetales', unit: 'GN', factor: null, stock: 1, minimo: 1 },
  { id: 'chimi', name: 'Chimichurri', category: 'Vegetales', unit: 'Frasco', factor: null, stock: 1, minimo: 1 },
  { id: 'criolla', name: 'Criolla', category: 'Vegetales', unit: 'Frasco', factor: null, stock: 1, minimo: 1 },
  { id: 'notco', name: 'Notco', category: 'Congelados', unit: 'Paquete', factor: null, stock: 5, minimo: 5 },
  { id: 'panes-hamburguesa', name: 'Panes de Hamburguesa', category: 'Panadería', unit: 'Unidad', factor: null, stock: 171, minimo: 60 },
  { id: 'ciabattas', name: 'Ciabattas', category: 'Panadería', unit: 'Unidad', factor: null, stock: 11, minimo: 10 },
  { id: 'pan-de-lomo', name: 'Pan de Lomo', category: 'Panadería', unit: 'Unidad', factor: null, stock: 9, minimo: 10 },
  { id: 'medallones', name: 'Medallones', category: 'Carnicería', unit: 'Bolsa', factor: null, stock: 3, minimo: 2 },
  { id: 'papas-congeladas', name: 'Papas Congeladas', category: 'Papas', unit: 'Bolsa', factor: null, stock: 0, minimo: 6 },
  { id: 'papas-precocidas', name: 'Papas Precocidas', category: 'Papas', unit: 'Batea', factor: null, stock: 0, minimo: 5 },
  { id: 'salpimienta', name: 'SalPimienta', category: 'Condimentos', unit: 'Frasco', factor: null, stock: 0, minimo: 1 },
  { id: 'paprika-condimento', name: 'Paprika', category: 'Condimentos', unit: 'Frasco', factor: null, stock: 0, minimo: 1 },
  { id: 'sesamo-condimento', name: 'Sésamo Tostado', category: 'Condimentos', unit: 'Frasco', factor: null, stock: 0, minimo: 1 },
  { id: 'morron-condimento', name: 'Morrón', category: 'Condimentos', unit: 'Frasco', factor: null, stock: 0, minimo: 1 },
  { id: 'ajo-condimento', name: 'Ajo', category: 'Condimentos', unit: 'Frasco', factor: null, stock: 0, minimo: 1 },
  { id: 'perejil-condimento', name: 'Perejil', category: 'Condimentos', unit: 'Frasco', factor: null, stock: 0, minimo: 1 },
  { id: 'salvia-condimento', name: 'Salvia', category: 'Condimentos', unit: 'Frasco', factor: null, stock: 0, minimo: 1 },
  { id: 'romero-condimento', name: 'Romero', category: 'Condimentos', unit: 'Frasco', factor: null, stock: 0, minimo: 1 },
  { id: 'tomillo-condimento', name: 'Tomillo', category: 'Condimentos', unit: 'Frasco', factor: null, stock: 0, minimo: 1 },
  { id: 'mayonesa-despensa', name: 'Mayonesa (Despensa)', category: 'Despensa', unit: 'Sachet de 3kg', factor: null, stock: 1, minimo: 1 },
  { id: 'ketchup-despensa', name: 'Ketchup (Despensa)', category: 'Despensa', unit: 'Sachet de 3kg', factor: null, stock: 1, minimo: 1 },
  { id: 'mostaza-despensa', name: 'Mostaza (Despensa)', category: 'Despensa', unit: 'Sachet de 3kg', factor: null, stock: 1, minimo: 1 },
  { id: 'sesamo-despensa', name: 'Sésamo (Despensa)', category: 'Despensa', unit: 'Bolsa', factor: null, stock: 1, minimo: 1 },
  { id: 'paprika-despensa', name: 'Paprika (Despensa)', category: 'Despensa', unit: 'Bolsa', factor: null, stock: 1, minimo: 1 },
  { id: 'sal', name: 'Sal', category: 'Despensa', unit: 'Paquete de 5kg', factor: null, stock: 1, minimo: 1 },
  { id: 'pimienta', name: 'Pimienta', category: 'Despensa', unit: 'Paquete de 1kg', factor: null, stock: 1, minimo: 1 },
  { id: 'jim-bean', name: 'Jim Bean', category: 'Despensa', unit: 'Botella de 750ml', factor: null, stock: 1, minimo: 1 },
  { id: 'barbacoa-despensa', name: 'Salsa Barbacoa (Despensa)', category: 'Despensa', unit: 'Sachet de 3kg', factor: null, stock: 1, minimo: 1 },
  { id: 'salsa-pescado', name: 'Salsa de Pescado', category: 'Despensa', unit: 'Botella de 400ml', factor: null, stock: 1, minimo: 1 },
  { id: 'gochujang', name: 'Gochujang', category: 'Despensa', unit: 'Envase', factor: null, stock: 1, minimo: 1 },
  { id: 'salsa-soja', name: 'Salsa de Soja', category: 'Despensa', unit: 'Botella de 860ml', factor: null, stock: 1, minimo: 1 },
  { id: 'aceite-cocina', name: 'Aceite de Cocina', category: 'Despensa', unit: 'Bidón de 5L', factor: null, stock: 1, minimo: 1 },
  { id: 'vinagre-arroz', name: 'Vinagre de Arroz', category: 'Despensa', unit: 'Botella de 900ml', factor: null, stock: 1, minimo: 1 },
  { id: 'salsa-inglesa', name: 'Salsa Inglesa', category: 'Despensa', unit: 'Botella de 148ml', factor: null, stock: 1, minimo: 1 },
  { id: 'azucar', name: 'Azúcar', category: 'Despensa', unit: 'Paquete de 1kg', factor: null, stock: 1, minimo: 1 },
  { id: 'manteca-despensa', name: 'Manteca (Despensa)', category: 'Despensa', unit: 'Bloque de 5kg', factor: null, stock: 1, minimo: 1 },
  { id: 'cheddar-despensa', name: 'Cheddar (Despensa)', category: 'Despensa', unit: 'Bolsa', factor: null, stock: 20, minimo: 1 },
  { id: 'panceta-despensa', name: 'Panceta Envasada (Despensa)', category: 'Despensa', unit: 'Envasado', factor: null, stock: 2, minimo: 1 },
  { id: 'desinfectante', name: 'Desinfectante', category: 'Limpieza', unit: 'Bidón de 5L', factor: null, stock: 1, minimo: 1 },
  { id: 'detergente', name: 'Detergente', category: 'Limpieza', unit: 'Bidón de 5L', factor: null, stock: 1, minimo: 1 },
  { id: 'desodorante', name: 'Desodorante de Ambientes', category: 'Limpieza', unit: 'Bidón de 5L', factor: null, stock: 1, minimo: 1 },
  { id: 'lavandina', name: 'Lavandina', category: 'Limpieza', unit: 'Bidón de 4L', factor: null, stock: 1, minimo: 1 },
  { id: 'panther-h', name: 'Panther H', category: 'Limpieza', unit: 'Bidón de 5L', factor: null, stock: 1, minimo: 1 },
  { id: 'alcohol-70', name: 'Alcohol 70%', category: 'Limpieza', unit: 'Bidón de 5L', factor: null, stock: 1, minimo: 1 },
  { id: 'limon-limpieza', name: 'Limón (Limpieza)', category: 'Limpieza', unit: 'Bidón de 5L', factor: null, stock: 1, minimo: 1 },
  { id: 'vinagre-limpieza', name: 'Vinagre (Limpieza)', category: 'Limpieza', unit: 'Bidón de 5L', factor: null, stock: 1, minimo: 1 },
  { id: 'jabon-liquido', name: 'Jabón Líquido de Manos', category: 'Limpieza', unit: 'Bidón de 5L', factor: null, stock: 1, minimo: 1 },
  { id: 'limpiavidrios', name: 'Limpiavidrios', category: 'Limpieza', unit: 'Bidón de 5L', factor: null, stock: 1, minimo: 1 },
  { id: 'papel-parafinado', name: 'Papel Parafinado', category: 'Bolsas y Papeles', unit: 'Bolsa', factor: null, stock: 1, minimo: 1 },
  { id: 'bolsas-envasar', name: 'Bolsas de Envasar', category: 'Bolsas y Papeles', unit: 'Bolsa', factor: null, stock: 1, minimo: 1 },
  { id: 'folex-grande', name: 'Folex Grande (25x35cm)', category: 'Bolsas y Papeles', unit: 'Bolsa', factor: null, stock: 1, minimo: 1 },
  { id: 'folex-pequeno', name: 'Folex Pequeño', category: 'Bolsas y Papeles', unit: 'Bolsa', factor: null, stock: 1, minimo: 1 },
  { id: 'cajas-papa', name: 'Cajas de Papa', category: 'Bolsas y Papeles', unit: 'Caja', factor: null, stock: 1, minimo: 1 },
  // Caja products
  { id: 'mayonesa-caja', name: 'Mayonesa (Caja Individual)', category: 'Caja Aderezo Individual', unit: 'Caja de 196 unidades', factor: null, stock: 0, minimo: 1, menu: 'Caja', period: 'Semanal' },
  { id: 'ketchup-caja', name: 'Ketchup (Caja Individual)', category: 'Caja Aderezo Individual', unit: 'Caja de 196 unidades', factor: null, stock: 0, minimo: 1, menu: 'Caja', period: 'Semanal' },
  { id: 'mostaza-caja', name: 'Mostaza (Caja Individual)', category: 'Caja Aderezo Individual', unit: 'Caja de 196 unidades', factor: null, stock: 0, minimo: 1, menu: 'Caja', period: 'Semanal' },
  { id: 'sal-caja', name: 'Sal (Caja Individual)', category: 'Caja Aderezo Individual', unit: 'Caja de 1000 unidades', factor: null, stock: 0, minimo: 1, menu: 'Caja', period: 'Semanal' },
  { id: 'fanta', name: 'Fanta', category: 'Bebidas sin Alcohol', unit: 'Unidad', factor: null, stock: 0, minimo: 1, menu: 'Caja', period: 'Semanal' },
  { id: 'coca', name: 'Coca-Cola', category: 'Bebidas sin Alcohol', unit: 'Unidad', factor: null, stock: 0, minimo: 1, menu: 'Caja', period: 'Semanal' },
  { id: 'coca-zero', name: 'Coca-Cola Zero', category: 'Bebidas sin Alcohol', unit: 'Unidad', factor: null, stock: 0, minimo: 1, menu: 'Caja', period: 'Semanal' },
  { id: 'sprite', name: 'Sprite', category: 'Bebidas sin Alcohol', unit: 'Unidad', factor: null, stock: 0, minimo: 1, menu: 'Caja', period: 'Semanal' },
  { id: 'sprite-zero', name: 'Sprite Zero', category: 'Bebidas sin Alcohol', unit: 'Unidad', factor: null, stock: 0, minimo: 1, menu: 'Caja', period: 'Semanal' },
  { id: 'agua', name: 'Agua', category: 'Bebidas sin Alcohol', unit: 'Unidad', factor: null, stock: 0, minimo: 1, menu: 'Caja', period: 'Semanal' },
  { id: 'soda', name: 'Soda', category: 'Bebidas sin Alcohol', unit: 'Unidad', factor: null, stock: 0, minimo: 1, menu: 'Caja', period: 'Semanal' },
  { id: 'stella', name: 'Stella Artois', category: 'Bebidas con Alcohol', unit: 'Unidad', factor: null, stock: 0, minimo: 1, menu: 'Caja', period: 'Semanal' },
  { id: 'stella-cero', name: 'Stella Cero', category: 'Bebidas con Alcohol', unit: 'Unidad', factor: null, stock: 0, minimo: 1, menu: 'Caja', period: 'Semanal' },
  { id: 'patagonia-24-7', name: 'Patagonia 24/7', category: 'Bebidas con Alcohol', unit: 'Unidad', factor: null, stock: 0, minimo: 1, menu: 'Caja', period: 'Semanal' },
  { id: 'patagonia-lagune', name: 'Patagonia Lagune', category: 'Bebidas con Alcohol', unit: 'Unidad', factor: null, stock: 0, minimo: 1, menu: 'Caja', period: 'Semanal' },
  { id: 'ipa-vera', name: 'IPA Vera', category: 'Bebidas con Alcohol', unit: 'Unidad', factor: null, stock: 0, minimo: 1, menu: 'Caja', period: 'Semanal' },
  { id: 'barriles-amber', name: 'Barriles de Amber Lager Patagonia', category: 'Bebidas con Alcohol', unit: 'Barril', factor: null, stock: 0, minimo: 1, menu: 'Caja', period: 'Semanal' },
  { id: 'servilletas', name: 'Servilletas', category: 'Descartables', unit: 'Caja', factor: null, stock: 0, minimo: 1, menu: 'Caja', period: 'Mensual' },
  { id: 'vasos', name: 'Vasos', category: 'Descartables', unit: 'Caja', factor: null, stock: 0, minimo: 1, menu: 'Caja', period: 'Mensual' },
  { id: 'bolsas-delivery', name: 'Bolsas de Delivery', category: 'Descartables', unit: 'Caja', factor: null, stock: 0, minimo: 1, menu: 'Caja', period: 'Mensual' },
  { id: 'cubiertos-descartables', name: 'Cubiertos Descartables', category: 'Descartables', unit: 'Unidad', factor: null, stock: 0, minimo: 1, menu: 'Caja', period: 'Mensual' },
  { id: 'salsa-tabasco', name: 'Salsa Tabasco', category: 'Descartables', unit: 'Unidad', factor: null, stock: 0, minimo: 1, menu: 'Caja', period: 'Mensual' },
  { id: 'escarbadientes', name: 'Escarbadientes', category: 'Descartables', unit: 'Caja', factor: null, stock: 0, minimo: 1, menu: 'Caja', period: 'Mensual' },
  { id: 'banditas-elasticas', name: 'Banditas Elásticas', category: 'Librería', unit: 'Caja', factor: null, stock: 0, minimo: 1, menu: 'Caja', period: 'Mensual' },
  { id: 'ganchos-abrochadora', name: 'Ganchos de Abrochadora', category: 'Librería', unit: 'Caja', factor: null, stock: 0, minimo: 1, menu: 'Caja', period: 'Mensual' },
  { id: 'lapicera', name: 'Lapicera', category: 'Librería', unit: 'Unidad', factor: null, stock: 0, minimo: 1, menu: 'Caja', period: 'Mensual' },
  { id: 'fibrones', name: 'Fibrones', category: 'Librería', unit: 'Unidad', factor: null, stock: 0, minimo: 1, menu: 'Caja', period: 'Mensual' },
  { id: 'rollo-termico', name: 'Rollo Térmico', category: 'Librería', unit: 'Unidad', factor: null, stock: 0, minimo: 1, menu: 'Caja', period: 'Mensual' },
].map(normalizeProduct);

// FIX: getDefaultStorage devolvía el mismo array/objetos de SEED_PRODUCTS por
// referencia. Si en cualquier parte del código (futuro o actual) se llegara a
// mutar un producto en lugar de reemplazarlo de forma inmutable, se corrompería
// la "semilla" usada por mergeWithSeed para siempre (incluso tras recargar la
// página, porque JS mantiene el módulo en memoria durante toda la sesión).
// Clonamos superficialmente cada producto para aislar el storage por defecto
// de la constante SEED_PRODUCTS.
const getDefaultStorage = () => ({
  products: SEED_PRODUCTS.map((p) => ({ ...p })),
  movements: [],
});

// ==================== COMPONENTES ====================
const FontStyles = () => (
  <style>{`
    @import url('https://fonts.googleapis.com/css2?family=Oswald:wght@400;500;600;700&family=Inter:wght@400;500;600;700&display=swap');
    .mg-display { font-family: 'Oswald', sans-serif; letter-spacing: 0.01em; }
    .mg-body { font-family: 'Inter', sans-serif; }
    .mg-tap { -webkit-tap-highlight-color: transparent; }
  `}</style>
);

const StampBadge = () => (
  <div
    className="mg-display"
    style={{
      width: 108,
      height: 108,
      borderRadius: '9999px',
      border: `3px solid ${C.accent}`,
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      transform: 'rotate(-6deg)',
      color: C.accent,
      boxShadow: `0 0 0 4px ${C.bg}, 0 0 0 5px ${C.line}`,
    }}
  >
    <div style={{ textAlign: 'center', lineHeight: 1.1 }}>
      <div style={{ fontSize: 26, fontWeight: 700 }}>M&G</div>
      <div style={{ fontSize: 9, letterSpacing: '0.25em', marginTop: 2 }}>STOCK</div>
    </div>
  </div>
);

// ==================== HELPERS ====================
const mergeWithSeed = (storedProducts) => {
  const storedMap = new Map(storedProducts.map((p) => [p.id, p]));
  return SEED_PRODUCTS.map((seed) => {
    const stored = storedMap.get(seed.id);
    if (!stored) return seed;
    return normalizeProduct({
      ...seed,
      ...stored,
    });
  });
};

// ==================== HOOKS ====================
const useStorage = () => {
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  // FIX: mismo problema de referencia compartida que en getDefaultStorage —
  // el estado inicial no debe apuntar directamente al array/objetos de
  // SEED_PRODUCTS.
  const [products, setProducts] = useState(() => SEED_PRODUCTS.map((p) => ({ ...p })));
  const [movements, setMovements] = useState([]);

  const loadData = useCallback(async () => {
    setLoading(true);
    try {
      // Simular almacenamiento - en producción usar AsyncStorage o similar
      const stored = localStorage.getItem(STORAGE_KEY);
      if (stored) {
        const parsed = JSON.parse(stored);
        const merged = mergeWithSeed(parsed.products || []);
        setProducts(merged);
        setMovements(parsed.movements || []);
        // Guardar merge
        localStorage.setItem(STORAGE_KEY, JSON.stringify({ products: merged, movements: parsed.movements || [] }));
      } else {
        const defaults = getDefaultStorage();
        localStorage.setItem(STORAGE_KEY, JSON.stringify(defaults));
        setProducts(defaults.products);
        setMovements(defaults.movements);
      }
    } catch (e) {
      console.error('Error loading data:', e);
      const defaults = getDefaultStorage();
      // No sobreescribimos localStorage acá: si JSON.parse falló por datos
      // corruptos, machacar el storage silenciosamente le hace perder al
      // usuario cualquier dato recuperable. Solo garantizamos que la UI
      // arranque con algo consistente en memoria.
      setProducts(defaults.products);
      setMovements(defaults.movements);
    } finally {
      setLoading(false);
    }
  }, []);

  const persist = useCallback(async (nextProducts, nextMovements) => {
    setSaving(true);
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify({ products: nextProducts, movements: nextMovements }));
    } catch (e) {
      console.error('Error saving:', e);
    } finally {
      setSaving(false);
    }
  }, []);

  return { loading, saving, products, setProducts, movements, setMovements, loadData, persist };
};

// ==================== MAIN APP ====================
export default function App() {
  const { loading, saving, products, setProducts, movements, setMovements, loadData, persist } = useStorage();
  const [view, setView] = useState('login');
  const [user, setUser] = useState(null);
  const [menu, setMenu] = useState(null);
  const [period, setPeriod] = useState(null);
  const [category, setCategory] = useState(null);
  const [productId, setProductId] = useState(null);
  const [actionMode, setActionMode] = useState(null);
  const [qty, setQty] = useState(1);
  const [note, setNote] = useState('');
  const [toast, setToast] = useState(null);

  // FIX: showToast usaba setTimeout sin guardar la referencia. Si el usuario
  // dispara dos toasts seguidos (ej. dos movimientos rápidos), el primer
  // timeout podía ejecutarse DESPUÉS de que se seteara el segundo toast y
  // lo borraba antes de tiempo. Guardamos el id en un ref y limpiamos el
  // anterior antes de programar uno nuevo.
  const toastTimeoutRef = useRef(null);

  useEffect(() => {
    loadData();
  }, [loadData]);

  // Limpieza del timeout de toast al desmontar, por prolijidad.
  useEffect(() => {
    return () => {
      if (toastTimeoutRef.current) clearTimeout(toastTimeoutRef.current);
    };
  }, []);

  // ===== MEMOIZED DATA =====
  const currentProduct = useMemo(
    () => products.find((p) => p.id === productId) || null,
    [products, productId]
  );

  const activeCategories = useMemo(() => {
    if (menu === 'Caja') return CAJA_STRUCTURE[period] || [];
    return CATEGORIES;
  }, [menu, period]);

  const filteredProducts = useMemo(() => {
    if (!category) return [];
    return products.filter((p) => p.category === category && matchesMenu(p, menu, period));
  }, [products, category, menu, period]);

  const visibleLowCount = useMemo(() => {
    return products.filter((p) => matchesMenu(p, menu, period) && isLow(p)).length;
  }, [products, menu, period]);

  const productMovements = useMemo(() => {
    if (!currentProduct) return [];
    // NOTA: esto asume que los movimientos más recientes están al PRINCIPIO
    // del array (ver confirmAction, que ahora hace unshift). Si en algún
    // lugar se llegan a agregar movimientos con push() al final, este slice
    // devolverá los 4 movimientos más VIEJOS en lugar de los más recientes.
    return movements.filter((m) => m.productId === currentProduct.id).slice(0, 4);
  }, [movements, currentProduct]);

  // ===== FUNCTIONS =====
  const showToast = useCallback((msg) => {
    if (toastTimeoutRef.current) clearTimeout(toastTimeoutRef.current);
    setToast(msg);
    toastTimeoutRef.current = setTimeout(() => setToast(null), 2200);
  }, []);

  const openProduct = (id) => {
    setProductId(id);
    setActionMode(null);
    setView('detail');
  };

  const startAction = (mode) => {
    setActionMode(mode);
    // FIX: usa currentProduct (ya memoizado) en vez de volver a recorrer el
    // array de productos con find().
    setQty(mode === 'conteo' ? (currentProduct ? currentProduct.stock : 0) : 1);
    setNote('');
  };

  const cancelAction = () => {
    setActionMode(null);
    setNote('');
  };

  const confirmAction = async () => {
    if (!currentProduct) return;

    // FIX: si `qty` llegara a ser NaN (por ejemplo, el input de cantidad se
    // vació y quedó como string vacío / NaN antes de esta función),
    // Math.max(0, NaN) da NaN y newStock terminaba en NaN, corrompiendo el
    // stock guardado. Nos aseguramos de tener siempre un entero válido.
    const qtyNum = Number.isFinite(Number(qty)) ? Math.max(0, Math.trunc(Number(qty))) : 0;

    let newStock = currentProduct.stock;
    switch (actionMode) {
      case 'ingreso':
        newStock = currentProduct.stock + qtyNum;
        break;
      case 'salida':
        newStock = Math.max(0, currentProduct.stock - qtyNum);
        break;
      case 'conteo':
        newStock = qtyNum;
        break;
      default:
        return;
    }

    const nextProducts = products.map((p) =>
      p.id === productId ? { ...p, stock: newStock } : p
    );

    const entry = {
      // Nota: Date.now() + Math.random() es suficiente para este caso de uso
      // (ids locales, sin colisión práctica), pero si en algún momento se
      // sincroniza con un backend conviene pasar a crypto.randomUUID().
      id: `${Date.now()}-${Math.random().toString(36).slice(2, 6)}`,
      productId,
      mode: actionMode,
      qty: qtyNum,
      previousStock: currentProduct.stock,
      newStock,
      note: note.trim() || null,
      user,
      timestamp: Date.now(),
    };

    // Los más recientes primero (ver comentario en productMovements).
    const nextMovements = [entry, ...movements];

    setProducts(nextProducts);
    setMovements(nextMovements);
    await persist(nextProducts, nextMovements);

    setActionMode(null);
    setNote('');
    showToast('Movimiento guardado');
  };

  // --- El resto del archivo (pantallas de login, selección de menú,
  //     listado por categoría, detalle de producto, historial, export, etc.)
  //     no llegó completo en el pegado original: se cortó dentro del literal
  //     de `entry.id` en confirmAction. Pegá el resto del componente (JSX de
  //     las vistas, el guard de `loading`, etc.) y reviso esa parte también. ---
}

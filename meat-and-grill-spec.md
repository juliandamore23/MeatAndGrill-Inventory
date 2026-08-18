# Meat & Grill · Control de Stock — Especificación del proyecto

## 1. Descripción general

App de stock para Meat & Grill, con los mismos rojos y negros ya usados (#D9622E y #18140F). Cada empleado entra con su perfil y un rol fijo que solo le permite editar ciertos parámetros del inventario. Solo algunos roles ven el inventario completo. Todos los días a las 23:00 se genera un archivo con los cambios de stock entre las 8:00 y las 23:00, y se envía por mail a mi correo personal.

## 2. Estado actual (versión Alpha)

### 2.1 Funcionalidades ya implementadas

1. Login por selección de nombre, entre 14 empleados con rol asignado (Cocinero, Armador, Panadero, Papero, Dueño, Limpieza, Caja, Runner).
2. Dos módulos separados: **Cocina** (inventario general por categorías) y **Caja** (conteo Semanal y Mensual).
3. 12 categorías de Cocina (Panadería, Carnicería, Fiambres, Vegetales, Salsas y Aderezos, Condimentos, Despensa, Papas, Congelados, Manteca, Bolsas y Papeles, Limpieza) y 5 categorías dentro de Caja (Caja Aderezo Individual, Bebidas sin Alcohol, Bebidas con Alcohol, Descartables, Librería).
4. 102 productos precargados, cada uno con stock inicial, unidad de medida y mínimo configurado.
5. Tres tipos de movimiento por producto: Ingreso, Salida (con nota opcional) y Conteo manual.
6. Alertas visuales automáticas cuando un producto cae por debajo de su mínimo, tanto en el detalle del producto como en el resumen por categoría.
7. Historial de los últimos 4 movimientos por producto, con hasta 300 movimientos totales guardados.
8. Exportación manual a CSV: inventario completo y listado de movimientos, con nombre de archivo fechado.
9. Diseño mobile-first pensado para usarse desde el celular o una tablet en el local.

### 2.2 Aspectos técnicos

1. Aplicación de una sola página en React, sin instalación ni cuenta de desarrollador necesaria.
2. Los datos se guardan en el `localStorage` del navegador (por ahora, un dispositivo = una copia del inventario).
3. Desplegable como sitio estático (por ejemplo en Netlify), sin backend ni base de datos.

## 3. Identidad visual (mantener igual en todo lo que se agregue)

| Uso | Color | Hex |
|---|---|---|
| Fondo principal | Negro cálido | `#18140F` |
| Superficie / tarjetas | Marrón oscuro | `#241E17` |
| Superficie secundaria | Marrón oscuro 2 | `#2E271D` |
| Líneas / bordes | Marrón línea | `#3A3226` |
| Acento principal | Rojo-naranja | `#D9622E` |
| Acento oscuro (hover/press) | Rojo-naranja oscuro | `#B84E22` |
| Alerta / bajo stock / salida | Rojo | `#E4483A` |
| Positivo / ingreso | Verde | `#6FA96A` |
| Texto principal | Crema | `#F3ECE1` |
| Texto secundario | Gris cálido | `#A0937F` |

Tipografías: **Oswald** (títulos, números grandes) + **Inter** (texto general).

## 4. Roles y permisos (a implementar)

1. Cada persona tiene un perfil propio con un rol fijo asignado (no un simple nombre en una lista, como ahora).
2. Cada rol solo puede modificar ciertos parámetros del inventario — falta definir la matriz exacta de "qué categorías/productos puede tocar cada rol".
3. Solo determinados roles (por ejemplo, Dueños) pueden ver el inventario completo; el resto ve una vista acotada a su área de trabajo.
4. Pendiente de definir con el usuario: la lista concreta de permisos por rol.

## 5. Reporte diario automático por mail (a implementar)

1. Todos los días a las 23:00 se genera un archivo con el stock total de todos los productos.
2. El archivo contempla específicamente los cambios de stock registrados entre las 8:00 y las 23:00 de ese día.
3. El archivo se envía automáticamente por mail a la casilla personal del dueño, sin que nadie tenga que exportarlo a mano.

## 6. Qué falta para pasar de Alpha a Beta

### 6.1 Cuentas y seguridad
1. No hay contraseña ni autenticación real: cualquiera puede elegir cualquier nombre de la lista y cargar movimientos en su nombre.
2. No hay control de sesión (cierre automático, expiración, "recordarme").
3. Falta el sistema de permisos por rol descrito en la sección 4.

### 6.2 Datos compartidos entre dispositivos
1. El stock vive en el `localStorage` de cada navegador: si dos personas usan dispositivos distintos, cada una ve y edita su propia copia, no una compartida.
2. Sin un backend y una base de datos central no es posible sincronizar cambios en tiempo real entre dispositivos, ni generar el reporte diario automático de la sección 5.
3. No hay backups automáticos: si se borra el caché del navegador, se pierde todo el historial cargado hasta ese momento.

### 6.3 Automatización
1. Hoy la exportación a CSV es manual (alguien tiene que entrar y tocar el botón); todavía no existe el reporte diario automático.
2. No hay envío de mail automatizado.
3. No hay notificaciones push cuando un producto cae por debajo del mínimo — solo se ve si alguien entra a la app.

### 6.4 Trazabilidad y control
1. El historial guarda como máximo 300 movimientos; no hay un archivo histórico completo ni reportes filtrables por rango de fechas.
2. No queda registro de quién exportó o vio el inventario completo.
3. No hay forma de deshacer un movimiento cargado por error, solo cargar uno nuevo que lo compense.

### 6.5 Funcionalidad de producto
1. Los productos no tienen foto.
2. No hay proveedor asociado ni gestión de pedidos/compras.
3. No hay lectura de código de barras para acelerar el conteo.
4. No hay soporte para más de un local o sucursal.

### 6.6 Calidad y accesibilidad
1. No se validó formalmente el contraste de colores ni el uso con lectores de pantalla.
2. No hay tests automáticos que avisen si un cambio futuro rompe algo que ya funcionaba.
3. No es instalable como app: falta manifest, ícono y service worker para poder "agregar a inicio" desde el celular.

## 7. Hoja de ruta sugerida

1. **Alpha (estado actual):** uso en un solo dispositivo, sin cuentas reales, exportación manual a CSV.
2. **Beta:** cuentas con contraseña, roles y permisos (sección 4), base de datos compartida entre dispositivos, reporte diario automático por mail (sección 5).
3. **v1.0:** fotos de producto, proveedores y pedidos, notificaciones push, soporte multi-sucursal, accesibilidad validada, tests automáticos.

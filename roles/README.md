# Meat & Grill · Control de Stock — scripts de base de datos

Todo lo que hay acá se corre en **Supabase → SQL Editor → New query → Run**.
Todos los scripts son **idempotentes**: se pueden correr las veces que haga
falta sin romper nada.

> ⚠️ **Este repositorio es público.** Nunca pegues acá una `service_role key`,
> una contraseña de aplicación de Gmail ni el PIN concreto de nadie. Las
> credenciales del reporte automático van en *Settings → Secrets and
> variables → Actions*, que sí están encriptadas.

---

## Cómo está armado el sistema

- **La app** es un único `index.html` en la raíz del repo, servido por GitHub
  Pages en https://juliandamore23.github.io/MeatAndGrill-Inventory/. Pisar ese
  archivo **es** el deploy; no hay build.
- **Los datos** viven en Supabase (proyecto `cnjbsrhpyxdvolysokzv`). Los 102
  productos, sus mínimos y sus unidades están en la tabla `products`, no en el
  código: `SEED_PRODUCTS` del HTML es solo el estado inicial de React.
- **Los permisos** los hace cumplir la base (RLS), no la app. El HTML oculta
  botones por comodidad, pero quien decide de verdad es Postgres. Si cambiás
  permisos, hay que tocar **los dos lados**.

## Dos trampas que ya nos mordieron

1. **Crear una cuenta sin "User Metadata".** El trigger guarda
   `role = 'Sin rol'`, esa persona pasa el login y la app le queda **vacía**.
   Pasó tres veces. Síntoma delator: en `employees`, la columna `name` muestra
   el *email* en lugar del nombre.
2. **El mail del código y el de Supabase tienen que coincidir exactamente.**
   Si la fila de `EMPLOYEES` no tiene `email`, la app pide el interno
   `nombre@meatandgrill.local`. Si la cuenta se creó con otra dirección, el
   login falla con **"PIN incorrecto"** aunque el PIN esté perfecto.

Para las dos, el diagnóstico rápido es `verificar-cuentas.sql`.

---

## Los scripts

### Estructura y permisos

| Archivo | Qué hace |
|---|---|
| `schema-step2.sql` | Crea `employees` y `role_categories`, el trigger que copia el metadata, y las políticas RLS. Es la base de todo. |
| `rol-jefe.sql` | Renombra el rol `Dueño` a `Jefe`. La ñ era un riesgo: si se guardaba mal codificada, esa persona no veía nada y **sin ningún error**. |
| `permisos-v2.sql` | La matriz de permisos vigente, y cierra el auto-ascenso de rol. **Es el que manda hoy sobre las políticas.** |

### Datos del inventario

| Archivo | Qué hace |
|---|---|
| `seed-products.sql` | Carga los 102 productos. Usa `on conflict do nothing`: no pisa el stock existente. |
| `fix-menu.sql` | Completa la columna `menu` (Cocina / Caja) y el `period`. |
| `minimos.sql` | Ajusta los stocks mínimos. |
| `unidades.sql` | Carga el rinde por envase (`factor`) y corrige las unidades. |

### Cuentas

| Archivo | Qué hace |
|---|---|
| `verificar-cuentas.sql` | **Solo lee.** Compara lo que la app espera contra lo que hay en Supabase y te dice qué le falta a cada cuenta. Correlo cada vez que des de alta a alguien. |
| `fix-roles.sql` | Carga el metadata y el rol de varias cuentas de una. |
| `metadata-awol.sql` | Ejemplo de cómo arreglar **una** cuenta que quedó sin rol. Sirve de molde para cualquier otra: cambiás el mail, el nombre y el rol. |

---

## Permisos vigentes

| Rol | Ve | Modifica |
|---|---|---|
| Jefe, Cocinero | Todo (Cocina + Caja) | Todo |
| Caja, Runner | Todo (Cocina + Caja) | Solo las 5 categorías de Caja |
| Panadero | Toda la Cocina | Panadería, Despensa |
| Armador | Toda la Cocina | Panadería, Vegetales, Condimentos, Salsas y Aderezos, Fiambres, Congelados, Manteca, Bolsas y Papeles, Despensa |
| Papero | Toda la Cocina | Papas |
| Limpieza | Toda la Cocina | Limpieza, Bolsas y Papeles, Despensa |

Ninguno de los cuatro últimos ve el menú Caja. Un rol desconocido
(por ejemplo `Sin rol`) **no ve nada**, a propósito.

## Cómo se cambia un rol

Desde que se cerró el auto-ascenso, el trigger ya **no** copia el rol desde el
metadata en los UPDATE — si lo hiciera, cualquiera podría ascenderse solo
editando su propio perfil por la API. Así que se hace por SQL:

```sql
update employees set role = 'Caja' where name = 'Ana';
```

Al **crear** una cuenta nueva, el metadata sigue funcionando normalmente. El
rol solo queda blindado después.

## Sobre los PIN

Supabase no acepta contraseñas de menos de 6 caracteres y ese límite no se
puede bajar. Por eso la app le agrega sola el sufijo `mg` al PIN antes de
mandarlo: la persona escribe 4 dígitos y viajan como 6.

**Al cargar o resetear un PIN en Supabase, va con el sufijo incluido.** Si el
login falla con el PIN correcto, casi siempre es que se cargó sin el `mg`.

Los PIN los asigna Julián; nadie cambia el suyo. No están escritos en ningún
archivo de este repo, y no deben estarlo.

## El reporte diario

`.github/workflows/reporte-diario.yml` corre de lunes a sábado a las 23:00 de
Argentina, arma un PDF con el inventario y lo manda por mail
(`scripts/reporte_inventario.py`). Se puede disparar a mano desde la pestaña
**Actions → Run workflow**.

El cron va a las 02:00 UTC porque Argentina es UTC−3, así que corresponde a
las 23:00 del día anterior. Además el script vuelve a chequear el día en hora
argentina, así que los domingos no manda nada aunque el cron falle.

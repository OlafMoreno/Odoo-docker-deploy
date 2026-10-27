# Despliegue de Odoo con Docker

Este repositorio prepara una instancia de Odoo 19 y PostgreSQL 15 con Docker Compose. La imagen de Odoo se construye desde `odoo:19`; los módulos adicionales se leen desde la carpeta local `addons/`.

## Requisitos

- Docker con Docker Compose v2 (Docker Desktop en Windows).
- Una copia local de `.env` basada en `.env.example`.

Desde la raíz del repositorio, creá `.env` una sola vez.

**Linux (Terminal):**

```bash
cp .env.example .env
```

**Windows (PowerShell):**

```powershell
Copy-Item .env.example .env
```

Editá `.env` y definí credenciales propias antes de iniciar los servicios. El archivo `.env` está excluido de Git; no guardes credenciales reales en `.env.example`.

## Cómo está montado

| Ruta local | Ruta en el contenedor | Uso |
| --- | --- | --- |
| `./data/odoo` | `/var/lib/odoo` | Datos de Odoo, sesiones y filestore. |
| `./data/db` | `/var/lib/postgresql/data` | Persistencia de PostgreSQL 15. |
| `./config` | `/etc/odoo` | Configuración de Odoo; `config/odoo.conf` establece `addons_path = /mnt/extra-addons`. |
| `./addons` | `/mnt/extra-addons` | Addons adicionales disponibles para Odoo. Actualmente esta carpeta está vacía. |

El `Dockerfile` parte de la imagen oficial `odoo:19` y agrega un entrypoint que delega en el entrypoint original de la imagen. Si no encuentra `/etc/odoo/odoo.conf`, `entrypoint.sh` crea una configuración mínima; en este repositorio el archivo ya existe y se monta desde `config/`.

El código de Odoo y sus addons Community incluidos en la imagen no se copian a `./addons`. Ese montaje es para módulos adicionales. Para que un módulo externo se descubra, su carpeta debe quedar directamente dentro de `addons/` y contener su manifiesto, por ejemplo `addons/<nombre_tecnico>/__manifest__.py`. También hay que incluir allí los addons de los que dependa. No alcanza con copiar un archivo ZIP sin extraerlo ni con dejar el módulo anidado en una subcarpeta que no esté en `addons_path`.

## Inicio

Primero, creá `.env` si todavía no existe (ver **Requisitos**) y editá el archivo para definir tus credenciales. Después, desde la raíz del repositorio:

**Linux (Terminal):**

```bash
docker compose up -d --build
docker compose ps
docker compose logs -f web
```

**Windows (PowerShell):**

```powershell
docker compose up -d --build
docker compose ps
docker compose logs -f web
```

La aplicación se publica en `http://localhost:<PORT>`; con el valor de ejemplo de `.env.example`, el puerto es `8069`. En la primera apertura, seleccioná o creá la base de datos de Odoo desde el asistente. `POSTGRES_DB` configura PostgreSQL; no es necesariamente el nombre de la base de datos de Odoo que se crea en el asistente.

Para detener los servicios sin borrar los datos:

**Linux (Terminal):**

```bash
docker compose down
```

**Windows (PowerShell):**

```powershell
docker compose down
```

No uses `docker compose down -v` si querés conservar los datos persistidos.

## Addons Community y módulos solicitados

Los módulos de Odoo incluidos en la imagen son distintos de los addons adicionales de OCA. Para usar un addon de OCA, hay que obtener la versión compatible con Odoo 19, revisar su manifiesto y dependencias, y colocar el módulo y sus dependencias en `./addons`. Después hay que reiniciar Odoo y actualizar la lista de aplicaciones.

Los dos módulos solicitados no son addons OCA disponibles para esta configuración:

- **`timesheet_grid`**: no es un módulo OCA. El código de OCA `timesheet` lo identifica como módulo de Odoo Enterprise; además, el listado de addons de su rama `19.0` no incluye un módulo con ese nombre. No está incluido en `odoo:19` ni en la carpeta local `addons/`.
- **Servicio de Campo (Field Service, habitualmente `industry_fsm`)**: es una aplicación de Odoo Enterprise, no un addon Community incluido en esta imagen. La documentación funcional de Odoo 19 no implica que el código del módulo esté disponible en la imagen Community.

Para usar cualquiera de esos módulos se necesita acceso y licencia al código Enterprise de la misma versión mayor que el servidor, además de sus dependencias compatibles. Este Compose solo monta `./addons` en `/mnt/extra-addons` y no monta el repositorio Enterprise. Por lo tanto, primero habría que disponer legalmente del código Enterprise y ajustar los mounts y `addons_path` para incluirlo. No cambies la versión mayor del código del addon respecto de Odoo (`19.0` para la imagen actual). Si se busca una alternativa OCA, elegí un módulo publicado explícitamente para Odoo 19 y no supongas que reemplaza la funcionalidad de `timesheet_grid` o Field Service.

## Instalar o actualizar un módulo

### Agregar e instalar un módulo por primera vez

Un módulo de Odoo es una carpeta con archivos de código y configuración. El archivo que permite reconocerla es `__manifest__.py`. En este proyecto, Odoo busca módulos adicionales dentro de `addons/`, que en el contenedor corresponde a `/mnt/extra-addons`.

**Importante:** no se puede subir un ZIP ni copiar el código del addon desde el portal web de Odoo. Primero hay que poner la carpeta del módulo en `addons/` siguiendo los pasos 1 a 5 de abajo. Después, desde el portal web, se actualiza la lista de aplicaciones y se instala el módulo con los pasos 6 y 7.

1. **Conseguí el módulo correcto.** Descargalo desde la página oficial del proveedor o desde el repositorio del autor. Comprobá que sea para Odoo 19 y para la edición que usás (Community o Enterprise). Si descargás un ZIP, extraelo primero; Odoo no instala el ZIP directamente. Para módulos OCA, usá la rama `19.0`.
2. **Buscá la carpeta del módulo.** Abrí lo que descargaste y localizá la carpeta que contiene `__manifest__.py`. Esa carpeta es el módulo. Si el módulo requiere otros addons, conseguí también esas dependencias: el nombre suele aparecer en el manifiesto, en la documentación del módulo o en las instrucciones del proveedor.
3. **Copiá la carpeta a `addons/`.** Abrí una terminal en la raíz de este repositorio (la carpeta donde está `docker-compose.yml`). Reemplazá `nombre_tecnico` por el nombre real de la carpeta del módulo.

   **Linux (Terminal):**

   ```bash
   cp -r "$HOME/Downloads/nombre_tecnico" "./addons/nombre_tecnico"
   ```

   **Windows (PowerShell):**

   ```powershell
   Copy-Item -Recurse "$env:USERPROFILE\Downloads\nombre_tecnico" ".\addons\nombre_tecnico"
   ```

   Repetí el comando de tu sistema para cada dependencia. Cada carpeta debe quedar directamente dentro de `addons/`, por ejemplo `addons/nombre_tecnico/__manifest__.py` (Linux) o `addons\nombre_tecnico\__manifest__.py` (Windows); no la dejes dentro de una carpeta adicional como `addons/repositorio/nombre_tecnico`.
4. **Comprobá que la ruta quedó bien.**

   **Linux (Terminal):** debe mostrar `Encontrado`:

   ```bash
   if test -f "./addons/nombre_tecnico/__manifest__.py"; then echo "Encontrado"; else echo "No encontrado"; fi
   ```

   **Windows (PowerShell):** debe mostrar `True`:

   ```powershell
   Test-Path ".\addons\nombre_tecnico\__manifest__.py"
   ```

   Si no se encuentra el archivo, revisá la carpeta que copiaste: probablemente copiaste la carpeta contenedora y el manifiesto quedó más adentro.
5. **Reiniciá Odoo** para que detecte el código nuevo.

   **Linux (Terminal):**

   ```bash
   docker compose restart web
   ```

   **Windows (PowerShell):**

   ```powershell
   docker compose restart web
   ```

6. **Actualizá el catálogo desde el portal web.** Abrí `http://localhost:8069` (o el puerto configurado en `PORT`), iniciá sesión y entrá a la base de datos. Activá el modo desarrollador desde **Ajustes**. Después abrí **Aplicaciones → Actualizar lista de aplicaciones** y confirmá si Odoo lo solicita.
7. **Instalá el módulo desde el portal web.** En **Aplicaciones**, buscá el nombre técnico del módulo y elegí **Activar/Instalar**. Ese nombre suele coincidir con el de la carpeta, aunque el nombre visible puede ser distinto.

Si no aparece, revisá que el manifiesto esté en la ruta indicada, que reiniciaste el servicio, que actualizaste la lista, y que el módulo y todas sus dependencias sean compatibles con la versión y edición instaladas. La actualización de la lista solo vuelve a buscar código que ya está disponible; no descarga ni instala módulos por sí sola.

### Actualizar un módulo ya instalado desde la interfaz web

1. Reemplazá la carpeta del módulo en `addons/` por la nueva versión compatible, conservando el mismo nombre técnico.
2. Reiniciá el servicio:

   **Linux (Terminal):** `docker compose restart web`

   **Windows (PowerShell):** `docker compose restart web`
3. En Odoo, activá el modo desarrollador y actualizá la lista de aplicaciones.
4. Abrí el módulo y elegí **Actualizar**. Esto aplica los cambios del módulo a la base de datos; reiniciar el contenedor por sí solo no lo actualiza.

La actualización de la lista solo vuelve a escanear addons disponibles; no descarga módulos ni instala código que no esté en el contenedor.

### Desde la CLI de Odoo

Usá el nombre de la base de datos de Odoo, no necesariamente el valor `POSTGRES_DB`. Detené primero el servidor web para evitar ejecutar una instalación simultánea sobre la misma base. Reemplazá `nombre_de_la_base_de_odoo` y `nombre_tecnico` por los nombres reales.

**Linux (Terminal):**

```bash
docker compose stop web
docker compose run --rm web odoo -c /etc/odoo/odoo.conf -d nombre_de_la_base_de_odoo -i nombre_tecnico --stop-after-init
docker compose start web
```

**Windows (PowerShell):**

```powershell
docker compose stop web
docker compose run --rm web odoo -c /etc/odoo/odoo.conf -d nombre_de_la_base_de_odoo -i nombre_tecnico --stop-after-init
docker compose start web
```

Para actualizar un módulo ya instalado, reemplazá `-i` por `-u`. La CLI no hace disponible un módulo ausente: su código y dependencias deben estar en los addons paths antes de ejecutar el comando. Por ejemplo, `timesheet_grid` solo se puede instalar con la edición/código Enterprise que lo provee; el comando no convierte la imagen Community en Enterprise.

## Referencias

- [Odoo 19: instalar y actualizar aplicaciones](https://www.odoo.com/documentation/19.0/applications/general/apps_modules.html)
- [Odoo 19: CLI y opciones `-i`, `-u`, `--addons-path`](https://www.odoo.com/documentation/19.0/developer/reference/cli.html)
- [Odoo 19: documentación de Field Service](https://www.odoo.com/documentation/19.0/applications/services/field_service.html)
- [OCA/timesheet, rama 19.0](https://github.com/OCA/timesheet/tree/19.0)

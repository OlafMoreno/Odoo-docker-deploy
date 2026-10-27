# Despliegue de Odoo con Docker

Este repositorio prepara una instancia de Odoo 19 y PostgreSQL 15 con Docker Compose. La imagen de Odoo se construye desde `odoo:19`; los módulos adicionales se leen desde la carpeta local `addons/`.

## Requisitos

- Docker Desktop con Docker Compose v2.
- Una copia local de `.env` basada en `.env.example`.

En PowerShell, desde la raíz del repositorio:

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

> **Atención:** en el `docker-compose.yml` actual, `web.restart` está escrito como una lista (`- always`). Compose espera un valor escalar, por ejemplo `restart: always`; por eso el archivo puede ser rechazado antes de iniciar. Este README no modifica la configuración de despliegue. Una vez corregida esa validación en el archivo de Compose, los comandos previstos son:

```powershell
Copy-Item .env.example .env  # solo la primera vez
# Editar .env antes de continuar
docker compose up -d --build
docker compose ps
docker compose logs -f web
```

La aplicación se publica en `http://localhost:<PORT>`; con el valor de ejemplo de `.env.example`, el puerto es `8069`. En la primera apertura, seleccioná o creá la base de datos de Odoo desde el asistente. `POSTGRES_DB` configura PostgreSQL; no es necesariamente el nombre de la base de datos de Odoo que se crea en el asistente.

Para detener los servicios sin borrar los datos:

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

### Desde la interfaz web

1. Colocá el código del módulo y sus dependencias en un directorio descubierto por `addons_path`.
2. Reiniciá el servicio web para que vuelva a leer el código:

   ```powershell
   docker compose restart web
   ```

3. En Odoo, activá el modo desarrollador y abrí **Aplicaciones → Actualizar lista de aplicaciones**.
4. Buscá el módulo por su nombre técnico y elegí **Activar/Instalar**. Si no aparece, verificá la versión, el manifiesto, las dependencias, el montaje y que el módulo esté disponible para la edición instalada.

La actualización de la lista solo vuelve a escanear addons disponibles; no descarga módulos ni instala código que no esté en el contenedor.

### Desde la CLI de Odoo

Usá el nombre de la base de datos de Odoo, no necesariamente el valor `POSTGRES_DB`. Detené primero el servidor web para evitar ejecutar una instalación simultánea sobre la misma base:

```powershell
$env:ODOO_DB = "nombre_de_la_base_de_odoo"
docker compose stop web
docker compose run --rm web odoo -c /etc/odoo/odoo.conf -d $env:ODOO_DB -i nombre_tecnico --stop-after-init
docker compose start web
```

Para actualizar un módulo ya instalado, reemplazá `-i` por `-u`. La CLI no hace disponible un módulo ausente: su código y dependencias deben estar en los addons paths antes de ejecutar el comando. Por ejemplo, `timesheet_grid` solo se puede instalar con la edición/código Enterprise que lo provee; el comando no convierte la imagen Community en Enterprise.

## Referencias

- [Odoo 19: instalar y actualizar aplicaciones](https://www.odoo.com/documentation/19.0/applications/general/apps_modules.html)
- [Odoo 19: CLI y opciones `-i`, `-u`, `--addons-path`](https://www.odoo.com/documentation/19.0/developer/reference/cli.html)
- [Odoo 19: documentación de Field Service](https://www.odoo.com/documentation/19.0/applications/services/field_service.html)
- [OCA/timesheet, rama 19.0](https://github.com/OCA/timesheet/tree/19.0)

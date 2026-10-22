#!/bin/bash
set -e

# Crear odoo.conf en la carpeta montada si no existe
if [ ! -f /etc/odoo/odoo.conf ]; then
    echo "Generando /etc/odoo/odoo.conf automáticamente..."
    mkdir -p /etc/odoo
    echo "[options]" > /etc/odoo/odoo.conf
    echo "addons_path = /mnt/extra-addons" >> /etc/odoo/odoo.conf
    echo "data_dir = /var/lib/odoo" >> /etc/odoo/odoo.conf
fi

# Ejecutar el comando original de la imagen de Odoo
exec /entrypoint.sh "$@"
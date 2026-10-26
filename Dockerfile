FROM odoo:19

USER root

# Copiar el script de entrada y darle permisos de ejecución
COPY entrypoint.sh /custom-entrypoint.sh
RUN chmod +x /custom-entrypoint.sh

USER odoo

ENTRYPOINT ["/custom-entrypoint.sh"]
CMD ["odoo"]
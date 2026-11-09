#!/usr/bin/env bash
# Entregable 1 (Tarea: Configurar servidor MySQL en Microsoft Azure)
# Crea Azure Database for MySQL - Flexible Server con ACCESO PRIVADO (dentro de
# la VNet creada por 01_configurar_red_mysql.sh) y la base de datos de la intranet.
# Uso: ./02_crear_servidor_mysql.sh
source "$(dirname "$0")/_comun.sh"

requerir AZ_RESOURCE_GROUP AZ_LOCATION VNET_NAME SUBNET_MYSQL MYSQL_SERVER_NAME \
         MYSQL_ADMIN_USER MYSQL_ADMIN_PASSWORD MYSQL_DATABASE MYSQL_VERSION \
         MYSQL_SKU MYSQL_TIER MYSQL_STORAGE_GB BACKUP_RETENTION_DAYS
verificar_sesion_azure

log "Registrando el proveedor Microsoft.DBforMySQL (solo la primera vez)"
az provider register --namespace Microsoft.DBforMySQL --wait

log "Verificando que la región $AZ_LOCATION ofrece MySQL Flexible Server"
if ! az mysql flexible-server list-skus --location "$AZ_LOCATION" -o none 2>/dev/null; then
  echo "ERROR: $AZ_LOCATION no admite MySQL Flexible Server en esta suscripción." >&2
  echo "Cambia AZ_LOCATION en .env (por ejemplo southcentralus) y vuelve a correr el script 01." >&2
  exit 1
fi

SUBNET_ID="$(az network vnet subnet show -g "$AZ_RESOURCE_GROUP" --vnet-name "$VNET_NAME" \
  -n "$SUBNET_MYSQL" --query id -o tsv 2>/dev/null || true)"
ZONA_ID="$(az network private-dns zone show -g "$AZ_RESOURCE_GROUP" \
  -n "${MYSQL_SERVER_NAME}.private.mysql.database.azure.com" --query id -o tsv 2>/dev/null || true)"
if [[ -z "$SUBNET_ID" || -z "$ZONA_ID" ]]; then
  echo "ERROR: falta la red privada. Ejecuta primero ./01_configurar_red_mysql.sh" >&2
  exit 1
fi

if az mysql flexible-server show -g "$AZ_RESOURCE_GROUP" -n "$MYSQL_SERVER_NAME" -o none 2>/dev/null; then
  ACCESO="$(az mysql flexible-server show -g "$AZ_RESOURCE_GROUP" -n "$MYSQL_SERVER_NAME" \
    --query network.publicNetworkAccess -o tsv)"
  if [[ "$ACCESO" == "Enabled" ]]; then
    echo "ERROR: $MYSQL_SERVER_NAME ya existe con ACCESO PÚBLICO." >&2
    echo "El tipo de red no se puede cambiar; hay que eliminarlo y crearlo de nuevo:" >&2
    echo "  az mysql flexible-server delete -g $AZ_RESOURCE_GROUP -n $MYSQL_SERVER_NAME --yes" >&2
    exit 1
  fi
  log "El servidor $MYSQL_SERVER_NAME ya existe con acceso privado; se omite la creación."
else
  log "Creando $MYSQL_SERVER_NAME con acceso privado (puede tardar 10-15 minutos)"
  az mysql flexible-server create \
    --resource-group "$AZ_RESOURCE_GROUP" \
    --name "$MYSQL_SERVER_NAME" \
    --location "$AZ_LOCATION" \
    --admin-user "$MYSQL_ADMIN_USER" \
    --admin-password "$MYSQL_ADMIN_PASSWORD" \
    --version "$MYSQL_VERSION" \
    --sku-name "$MYSQL_SKU" \
    --tier "$MYSQL_TIER" \
    --storage-size "$MYSQL_STORAGE_GB" \
    --backup-retention "$BACKUP_RETENTION_DAYS" \
    --geo-redundant-backup Disabled \
    --high-availability Disabled \
    --subnet "$SUBNET_ID" \
    --private-dns-zone "$ZONA_ID" \
    --tags proyecto=intranet-woowguau responsable=amanda-aragon \
    --yes -o none
fi

log "Creando la base de datos $MYSQL_DATABASE (utf8mb4)"
az mysql flexible-server db create \
  --resource-group "$AZ_RESOURCE_GROUP" \
  --server-name "$MYSQL_SERVER_NAME" \
  --database-name "$MYSQL_DATABASE" \
  --charset utf8mb4 --collation utf8mb4_unicode_ci -o none

log "Forzando conexiones cifradas (require_secure_transport = ON)"
az mysql flexible-server parameter set -g "$AZ_RESOURCE_GROUP" -s "$MYSQL_SERVER_NAME" \
  --name require_secure_transport --value ON -o none

log "Listo:"
az mysql flexible-server show -g "$AZ_RESOURCE_GROUP" -n "$MYSQL_SERVER_NAME" \
  --query "{nombre:name, host:fullyQualifiedDomainName, version:version, estado:state, accesoPublico:network.publicNetworkAccess, subred:network.delegatedSubnetResourceId}" -o yaml

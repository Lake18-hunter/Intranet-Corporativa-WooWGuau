#!/usr/bin/env bash
# Entregable 2 (Tarea: Configurar servidor MySQL en Microsoft Azure)
# Configura la red privada del motor de base de datos:
#   - VNet con dos subredes:
#       snet-mysql -> delegada a MySQL Flexible Server (sin acceso desde Internet)
#       snet-app   -> para la VM cliente que ejecuta Python
#   - Zona DNS privada para resolver el nombre del servidor dentro de la VNet
# Uso: ./01_configurar_red_mysql.sh
source "$(dirname "$0")/_comun.sh"

requerir AZ_RESOURCE_GROUP AZ_LOCATION VNET_NAME VNET_PREFIX SUBNET_MYSQL \
         SUBNET_MYSQL_PREFIX SUBNET_APP SUBNET_APP_PREFIX MYSQL_SERVER_NAME
verificar_sesion_azure

ZONA_DNS="${MYSQL_SERVER_NAME}.private.mysql.database.azure.com"

log "Asegurando el grupo de recursos $AZ_RESOURCE_GROUP"
if [[ "$(az group exists --name "$AZ_RESOURCE_GROUP")" == "false" ]]; then
  az group create --name "$AZ_RESOURCE_GROUP" --location "$AZ_LOCATION" -o none
fi

log "VNet $VNET_NAME ($VNET_PREFIX)"
if ! az network vnet show -g "$AZ_RESOURCE_GROUP" -n "$VNET_NAME" -o none 2>/dev/null; then
  az network vnet create -g "$AZ_RESOURCE_GROUP" -n "$VNET_NAME" \
    --location "$AZ_LOCATION" --address-prefixes "$VNET_PREFIX" -o none
fi

log "Subred $SUBNET_MYSQL ($SUBNET_MYSQL_PREFIX) delegada a MySQL Flexible Server"
if ! az network vnet subnet show -g "$AZ_RESOURCE_GROUP" --vnet-name "$VNET_NAME" -n "$SUBNET_MYSQL" -o none 2>/dev/null; then
  az network vnet subnet create -g "$AZ_RESOURCE_GROUP" --vnet-name "$VNET_NAME" \
    -n "$SUBNET_MYSQL" --address-prefixes "$SUBNET_MYSQL_PREFIX" \
    --delegations Microsoft.DBforMySQL/flexibleServers -o none
fi

log "Subred $SUBNET_APP ($SUBNET_APP_PREFIX) para la VM cliente"
if ! az network vnet subnet show -g "$AZ_RESOURCE_GROUP" --vnet-name "$VNET_NAME" -n "$SUBNET_APP" -o none 2>/dev/null; then
  # La VM necesita salida a Internet para instalar paquetes (apt). Las subredes
  # nuevas pueden ser privadas por defecto, así que se pide salida explícita.
  az network vnet subnet create -g "$AZ_RESOURCE_GROUP" --vnet-name "$VNET_NAME" \
    -n "$SUBNET_APP" --address-prefixes "$SUBNET_APP_PREFIX" \
    --default-outbound true -o none 2>/dev/null \
  || az network vnet subnet create -g "$AZ_RESOURCE_GROUP" --vnet-name "$VNET_NAME" \
    -n "$SUBNET_APP" --address-prefixes "$SUBNET_APP_PREFIX" -o none
fi

log "Zona DNS privada $ZONA_DNS"
if ! az network private-dns zone show -g "$AZ_RESOURCE_GROUP" -n "$ZONA_DNS" -o none 2>/dev/null; then
  az network private-dns zone create -g "$AZ_RESOURCE_GROUP" -n "$ZONA_DNS" -o none
fi
if ! az network private-dns link vnet show -g "$AZ_RESOURCE_GROUP" -z "$ZONA_DNS" -n "enlace-$VNET_NAME" -o none 2>/dev/null; then
  az network private-dns link vnet create -g "$AZ_RESOURCE_GROUP" -z "$ZONA_DNS" \
    -n "enlace-$VNET_NAME" --virtual-network "$VNET_NAME" --registration-enabled false -o none
fi

log "Red lista:"
az network vnet subnet list -g "$AZ_RESOURCE_GROUP" --vnet-name "$VNET_NAME" \
  --query "[].{subred:name, prefijo:addressPrefix, delegacion:delegations[0].serviceName, nsg:networkSecurityGroup.id}" -o table

#!/usr/bin/env bash
# Entregable 2 (Tarea: Configurar reglas de seguridad (NSG) y respaldos)
# Automatiza la retención de los respaldos de la base de datos.
#   - Ajusta los días de retención (1 a 35) de los respaldos automáticos
#   - Crea un respaldo manual (bajo demanda) como evidencia
#   - Lista los respaldos disponibles y la ventana de restauración
# Uso: ./05_respaldos.sh
source "$(dirname "$0")/_comun.sh"

requerir AZ_RESOURCE_GROUP MYSQL_SERVER_NAME BACKUP_RETENTION_DAYS
verificar_sesion_azure

if (( BACKUP_RETENTION_DAYS < 1 || BACKUP_RETENTION_DAYS > 35 )); then
  echo "ERROR: BACKUP_RETENTION_DAYS debe estar entre 1 y 35." >&2
  exit 1
fi

log "Configurando retención de respaldos: $BACKUP_RETENTION_DAYS días"
az mysql flexible-server update \
  --resource-group "$AZ_RESOURCE_GROUP" \
  --name "$MYSQL_SERVER_NAME" \
  --backup-retention "$BACKUP_RETENTION_DAYS" -o none

NOMBRE_RESPALDO="manual-$(date +%Y%m%d-%H%M)"
log "Creando respaldo bajo demanda: $NOMBRE_RESPALDO"
az mysql flexible-server backup create \
  --resource-group "$AZ_RESOURCE_GROUP" \
  --name "$MYSQL_SERVER_NAME" \
  --backup-name "$NOMBRE_RESPALDO" -o none

log "Política de respaldos vigente:"
az mysql flexible-server show -g "$AZ_RESOURCE_GROUP" -n "$MYSQL_SERVER_NAME" \
  --query "{retencionDias:backup.backupRetentionDays, georedundante:backup.geoRedundantBackup, restauracionMasAntigua:backup.earliestRestoreDate}" -o table

log "Respaldos disponibles:"
az mysql flexible-server backup list -g "$AZ_RESOURCE_GROUP" -n "$MYSQL_SERVER_NAME" \
  --query "[].{nombre:name, tipo:backupType, fecha:completedTime}" -o table

echo -e "\nPara restaurar a un punto en el tiempo (crea un servidor nuevo):"
echo "  az mysql flexible-server restore -g $AZ_RESOURCE_GROUP --name ${MYSQL_SERVER_NAME}-restaurado \\"
echo "     --source-server $MYSQL_SERVER_NAME --restore-time \"AAAA-MM-DDTHH:MM:SS+00:00\""

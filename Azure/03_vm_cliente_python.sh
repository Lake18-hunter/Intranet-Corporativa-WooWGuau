#!/usr/bin/env bash
# Post-condición (Tarea: Configurar servidor MySQL en Microsoft Azure)
# El servidor es privado, así que Python se ejecuta desde una VM dentro de la VNet.
#   - Crea la VM en snet-app SIN IP pública y sin puertos abiertos
#   - La administra con "az vm run-command" (no usa SSH)
#   - Instala Python + mysql-connector y ejecuta prueba_conexion.py
# Uso: ./03_vm_cliente_python.sh            (crea si hace falta y ejecuta la prueba)
#      ./03_vm_cliente_python.sh --apagar   (desasigna la VM para no gastar créditos)
source "$(dirname "$0")/_comun.sh"

requerir AZ_RESOURCE_GROUP VNET_NAME SUBNET_APP VM_NAME VM_SIZE VM_ADMIN_USER \
         MYSQL_SERVER_NAME MYSQL_ADMIN_USER MYSQL_ADMIN_PASSWORD MYSQL_DATABASE
verificar_sesion_azure

if [[ "${1:-}" == "--apagar" ]]; then
  log "Desasignando $VM_NAME (deja de cobrar cómputo)"
  az vm deallocate -g "$AZ_RESOURCE_GROUP" -n "$VM_NAME" -o none
  exit 0
fi

if ! az vm show -g "$AZ_RESOURCE_GROUP" -n "$VM_NAME" -o none 2>/dev/null; then
  log "Creando la VM $VM_NAME ($VM_SIZE) sin IP pública"
  az vm create -g "$AZ_RESOURCE_GROUP" -n "$VM_NAME" \
    --image Ubuntu2204 --size "$VM_SIZE" \
    --vnet-name "$VNET_NAME" --subnet "$SUBNET_APP" \
    --public-ip-address "" --nsg "" \
    --admin-username "$VM_ADMIN_USER" --generate-ssh-keys \
    --tags proyecto=intranet-woowguau -o none

  log "Instalando Python y el conector de MySQL en la VM"
  az vm run-command invoke -g "$AZ_RESOURCE_GROUP" -n "$VM_NAME" \
    --command-id RunShellScript \
    --scripts "apt-get update -q && apt-get install -y -q python3 python3-mysql.connector ca-certificates" \
    --query "value[0].message" -o tsv | tail -n 3
else
  log "La VM $VM_NAME ya existe; encendiéndola si está apagada"
  az vm start -g "$AZ_RESOURCE_GROUP" -n "$VM_NAME" -o none
fi

log "Ejecutando prueba_conexion.py dentro de la VNet"
TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT
{
  printf 'export MYSQL_SERVER_NAME=%q\n' "$MYSQL_SERVER_NAME"
  printf 'export MYSQL_ADMIN_USER=%q\n' "$MYSQL_ADMIN_USER"
  printf 'export MYSQL_ADMIN_PASSWORD=%q\n' "$MYSQL_ADMIN_PASSWORD"
  printf 'export MYSQL_DATABASE=%q\n' "$MYSQL_DATABASE"
  echo "cat > /tmp/prueba_conexion.py <<'PYTHON'"
  cat "$DIR_SCRIPTS/prueba_conexion.py"
  echo "PYTHON"
  echo "python3 /tmp/prueba_conexion.py; rm -f /tmp/prueba_conexion.py"
} > "$TMP"

az vm run-command invoke -g "$AZ_RESOURCE_GROUP" -n "$VM_NAME" \
  --command-id RunShellScript --scripts @"$TMP" \
  --query "value[0].message" -o tsv

echo -e "\nCuando termines, apaga la VM: ./03_vm_cliente_python.sh --apagar"

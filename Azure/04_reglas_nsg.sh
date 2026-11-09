#!/usr/bin/env bash
# Entregable 1 (Tarea: Configurar reglas de seguridad (NSG) y respaldos)
# Define o actualiza las NSG de las dos subredes y verifica que no se expongan puertos.
#
#   nsg-snet-mysql (subred del servidor)
#     100  Permitir 3306/TCP desde snet-app
#     110  Permitir 3306/TCP dentro de snet-mysql
#     200  Denegar 3306/TCP desde cualquier otro origen
#     4000 Denegar todo el tráfico entrante desde Internet
#   nsg-snet-app (subred de la VM cliente)
#     4000 Denegar todo el tráfico entrante desde Internet (sin SSH ni RDP)
#
# Uso: ./04_reglas_nsg.sh            (crea/actualiza y asocia)
#      ./04_reglas_nsg.sh --revisar  (solo audita, no cambia nada)
source "$(dirname "$0")/_comun.sh"

requerir AZ_RESOURCE_GROUP AZ_LOCATION VNET_NAME SUBNET_MYSQL SUBNET_MYSQL_PREFIX \
         SUBNET_APP SUBNET_APP_PREFIX NSG_MYSQL NSG_APP
verificar_sesion_azure

MODO="${1:-aplicar}"

asegurar_nsg() {
  local nsg="$1"
  if ! az network nsg show -g "$AZ_RESOURCE_GROUP" -n "$nsg" -o none 2>/dev/null; then
    log "Creando NSG $nsg"
    az network nsg create -g "$AZ_RESOURCE_GROUP" -n "$nsg" -l "$AZ_LOCATION" \
      --tags proyecto=intranet-woowguau -o none
  fi
}

# regla <nsg> <nombre> <prioridad> <Allow|Deny> <protocolo> <origen> <destino> <puerto>
regla() {
  local nsg="$1" nombre="$2" prioridad="$3" acceso="$4" protocolo="$5" origen="$6" destino="$7" puerto="$8"
  local accion=create
  az network nsg rule show -g "$AZ_RESOURCE_GROUP" --nsg-name "$nsg" -n "$nombre" -o none 2>/dev/null && accion=update
  echo "  [$accion] $nsg / $prioridad $nombre: $acceso $protocolo $origen -> $destino:$puerto"
  az network nsg rule "$accion" -g "$AZ_RESOURCE_GROUP" --nsg-name "$nsg" -n "$nombre" \
    --priority "$prioridad" --direction Inbound --access "$acceso" --protocol "$protocolo" \
    --source-address-prefixes "$origen" --source-port-ranges '*' \
    --destination-address-prefixes "$destino" --destination-port-ranges "$puerto" -o none
}

asociar() {
  local subred="$1" nsg="$2"
  log "Asociando $nsg a la subred $subred"
  az network vnet subnet update -g "$AZ_RESOURCE_GROUP" --vnet-name "$VNET_NAME" \
    -n "$subred" --network-security-group "$nsg" -o none
}

auditar() {
  log "Auditoría: reglas de entrada que permiten tráfico desde Internet o desde cualquier origen"
  local hallazgos=0
  for nsg in "$NSG_MYSQL" "$NSG_APP"; do
    local abiertas
    abiertas="$(az network nsg rule list -g "$AZ_RESOURCE_GROUP" --nsg-name "$nsg" \
      --query "[?direction=='Inbound' && access=='Allow' && (sourceAddressPrefix=='*' || sourceAddressPrefix=='Internet' || sourceAddressPrefix=='0.0.0.0/0')].[name,destinationPortRange]" \
      -o tsv 2>/dev/null || true)"
    if [[ -n "$abiertas" ]]; then
      echo "ALERTA en $nsg:"; echo "$abiertas"; hallazgos=1
    fi
    echo -e "\n$nsg:"
    az network nsg rule list -g "$AZ_RESOURCE_GROUP" --nsg-name "$nsg" \
      --query "sort_by([], &priority)[].{prioridad:priority, regla:name, acceso:access, origen:sourceAddressPrefix, puerto:destinationPortRange}" \
      -o table 2>/dev/null || echo "  (no existe)"
  done

  local ips_publicas
  ips_publicas="$(az network public-ip list -g "$AZ_RESOURCE_GROUP" --query "[].name" -o tsv)"
  if [[ -n "$ips_publicas" ]]; then
    echo -e "\nALERTA: hay IPs públicas en el grupo de recursos: $ips_publicas"; hallazgos=1
  fi
  local acceso
  acceso="$(az mysql flexible-server show -g "$AZ_RESOURCE_GROUP" -n "$MYSQL_SERVER_NAME" \
    --query network.publicNetworkAccess -o tsv 2>/dev/null || echo "?")"
  echo -e "\nAcceso público del servidor MySQL: $acceso"
  [[ "$acceso" == "Enabled" ]] && hallazgos=1

  if (( hallazgos == 0 )); then
    echo -e "\nResultado: ningún puerto expuesto a Internet."
  else
    echo -e "\nResultado: revisar las alertas anteriores."
  fi
}

if [[ "$MODO" == "--revisar" ]]; then
  auditar; exit 0
fi

asegurar_nsg "$NSG_MYSQL"
regla "$NSG_MYSQL" Permitir-MySQL-desde-app     100  Allow Tcp "$SUBNET_APP_PREFIX"   "$SUBNET_MYSQL_PREFIX" 3306
regla "$NSG_MYSQL" Permitir-MySQL-misma-subred  110  Allow Tcp "$SUBNET_MYSQL_PREFIX" "$SUBNET_MYSQL_PREFIX" 3306
regla "$NSG_MYSQL" Denegar-MySQL-resto          200  Deny  Tcp '*'                    '*'                    3306
regla "$NSG_MYSQL" Denegar-Internet-entrada     4000 Deny  '*' Internet               '*'                    '*'
asociar "$SUBNET_MYSQL" "$NSG_MYSQL"

asegurar_nsg "$NSG_APP"
regla "$NSG_APP" Denegar-Internet-entrada       4000 Deny  '*' Internet               '*'                    '*'
asociar "$SUBNET_APP" "$NSG_APP"

auditar

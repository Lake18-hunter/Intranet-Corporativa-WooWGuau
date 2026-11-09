#!/usr/bin/env bash
# Entregable 3 (Tarea: Configurar reglas de seguridad (NSG) y respaldos)
# Crea o actualiza un presupuesto de Azure Cost Management sobre el grupo de
# recursos de la base de datos, con alertas por correo:
#   - 50 % y 80 % del gasto real
#   - 100 % del gasto pronosticado
# Uso: ./06_presupuesto.sh
source "$(dirname "$0")/_comun.sh"

requerir AZ_RESOURCE_GROUP BUDGET_NAME BUDGET_AMOUNT BUDGET_EMAILS
verificar_sesion_azure

SUB_ID="$(az account show --query id -o tsv)"
ALCANCE="/subscriptions/$SUB_ID/resourceGroups/$AZ_RESOURCE_GROUP"
INICIO="$(date -u +%Y-%m-01)T00:00:00Z"            # debe ser día 1 del mes
FIN="$(( $(date -u +%Y) + 1 ))-$(date -u +%m)-01T00:00:00Z"   # vigencia de 1 año

# Lista de correos en formato JSON: "a@b.mx","c@d.mx"
CORREOS="$(echo "$BUDGET_EMAILS" | sed 's/[[:space:]]//g; s/,/","/g; s/^/"/; s/$/"/')"

CUERPO="$(cat <<JSON
{
  "properties": {
    "category": "Cost",
    "amount": $BUDGET_AMOUNT,
    "timeGrain": "Monthly",
    "timePeriod": { "startDate": "$INICIO", "endDate": "$FIN" },
    "notifications": {
      "Real_50": {
        "enabled": true, "operator": "GreaterThanOrEqualTo", "threshold": 50,
        "thresholdType": "Actual", "contactEmails": [ $CORREOS ]
      },
      "Real_80": {
        "enabled": true, "operator": "GreaterThanOrEqualTo", "threshold": 80,
        "thresholdType": "Actual", "contactEmails": [ $CORREOS ]
      },
      "Pronostico_100": {
        "enabled": true, "operator": "GreaterThanOrEqualTo", "threshold": 100,
        "thresholdType": "Forecasted", "contactEmails": [ $CORREOS ]
      }
    }
  }
}
JSON
)"

log "Creando/actualizando presupuesto $BUDGET_NAME de $BUDGET_AMOUNT al mes sobre $AZ_RESOURCE_GROUP"
az rest --method put \
  --url "https://management.azure.com${ALCANCE}/providers/Microsoft.Consumption/budgets/${BUDGET_NAME}?api-version=2023-05-01" \
  --body "$CUERPO" -o none

log "Presupuesto vigente:"
az rest --method get \
  --url "https://management.azure.com${ALCANCE}/providers/Microsoft.Consumption/budgets/${BUDGET_NAME}?api-version=2023-05-01" \
  --query "{nombre:name, monto:properties.amount, periodo:properties.timeGrain, gastoActual:properties.currentSpend.amount, alertas:keys(properties.notifications)}" -o json

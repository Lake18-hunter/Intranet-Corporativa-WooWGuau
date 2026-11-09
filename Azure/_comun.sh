#!/usr/bin/env bash
# Funciones y variables compartidas por todos los scripts.
set -euo pipefail

DIR_SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -f "$DIR_SCRIPTS/.env" ]]; then
  set -a; source "$DIR_SCRIPTS/.env"; set +a
else
  echo "ERROR: no existe $DIR_SCRIPTS/.env (copia .env.example y complétalo)." >&2
  exit 1
fi

requerir() {
  for var in "$@"; do
    if [[ -z "${!var:-}" ]]; then
      echo "ERROR: la variable $var está vacía en .env" >&2
      exit 1
    fi
  done
}

log() { echo -e "\n==> $*"; }

verificar_sesion_azure() {
  if ! az account show > /dev/null 2>&1; then
    echo "No hay sesión de Azure CLI. Ejecuta: az login" >&2
    exit 1
  fi
  log "Suscripción activa: $(az account show --query name -o tsv)"
}

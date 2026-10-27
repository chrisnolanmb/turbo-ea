#!/usr/bin/env bash
# Carga el modelo de Grupo Velsen en una instalación nueva de Turbo EA.
# Lo llama setup-demo.sh cuando el codespace se crea. Es idempotente: si la
# instancia ya tiene usuarios, no hace nada.
set -u +e

cd "$(dirname "$0")"
BASE="${TURBO_EA_URL:-http://localhost:8920}/api/v1"
EMAIL="admin@velsen.demo"
PASS="Holding!2026demo"
JAR="$(mktemp)"
trap 'rm -f "$JAR"' EXIT

log() { echo "[velsen] $*"; }
json() { python3 -c "import json,sys; print(json.load(sys.stdin).get('$1',''))"; }

code=$(curl -s -o /dev/null -w "%{http_code}" -c "$JAR" -H 'content-type: application/json' \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASS\",\"display_name\":\"Administrador Velsen\"}" \
  "$BASE/auth/register")
if [ "$code" != "200" ]; then
  log "La instancia ya tiene usuarios (registro respondió $code): no se importa de nuevo."
  exit 0
fi

ME=$(curl -s -b "$JAR" "$BASE/auth/me" | json id)
curl -s -o /dev/null -b "$JAR" -X PATCH -H 'content-type: application/json' -d '{"locale":"es"}' "$BASE/users/$ME"

log "Subiendo el espacio de trabajo de Grupo Velsen..."
TID=$(curl -s -b "$JAR" -F "file=@grupo-velsen-workspace.zip;type=application/zip" "$BASE/admin/workspace/import" | json id)
if [ -z "$TID" ]; then log "ERROR: no se pudo subir el archivo."; exit 0; fi

wait_for() {  # espera a que el estado deje de ser $1
  for _ in $(seq 1 300); do
    st=$(curl -s -b "$JAR" "$BASE/admin/workspace/import/$TID" | json status)
    [ "$st" != "$1" ] && [ "$st" != "parsing" ] && { echo "$st"; return; }
    sleep 2
  done
  echo "timeout"
}
st=$(wait_for previewing); log "Vista previa: $st"
[ "$st" = "previewed" ] || { log "ERROR: la vista previa terminó en $st."; exit 0; }

curl -s -o /dev/null -b "$JAR" -X POST "$BASE/admin/workspace/import/$TID/apply"
st=$(wait_for applying); log "Importación: $st"

total=$(curl -s -b "$JAR" "$BASE/cards?page_size=1" | json total)
log "Fichas cargadas: $total"

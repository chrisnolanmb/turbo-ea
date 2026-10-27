#!/usr/bin/env bash
# Carga el modelo de Grupo Velsen en Turbo EA.
# Lo llaman setup-demo.sh y start-demo.sh; también se puede correr a mano:
#   bash .devcontainer/velsen/import-velsen.sh
# Es idempotente: si la instancia ya tiene fichas, no hace nada.
# Solo usa bash, curl, grep y sed (sin python).
set -u +e

cd "$(dirname "$0")"
BASE="${TURBO_EA_URL:-http://localhost:8920}/api/v1"
EMAIL="${VELSEN_EMAIL:-admin@velsen.demo}"
PASS="${VELSEN_PASSWORD:-Holding!2026demo}"
JAR="$(mktemp)"
trap 'rm -f "$JAR"' EXIT

log() { echo "[velsen] $*" | tee -a import.log; }
field() { grep -o "\"$1\":\"[^\"]*\"" | head -1 | sed "s/\"$1\":\"//; s/\"$//"; }
number() { grep -o "\"$1\":[0-9]*" | head -1 | sed "s/\"$1\"://"; }

# Esperar a que la plataforma responda.
for _ in $(seq 1 150); do
  curl -sf -o /dev/null -m 3 "$BASE/../health" && break
  sleep 2
done

body="{\"email\":\"$EMAIL\",\"password\":\"$PASS\",\"display_name\":\"Administrador Velsen\"}"
code=$(curl -s -o /dev/null -w "%{http_code}" -c "$JAR" -H 'content-type: application/json' -d "$body" "$BASE/auth/register")
if [ "$code" != "200" ]; then
  code=$(curl -s -o /dev/null -w "%{http_code}" -c "$JAR" -H 'content-type: application/json' \
    -d "{\"email\":\"$EMAIL\",\"password\":\"$PASS\"}" "$BASE/auth/login")
  if [ "$code" != "200" ]; then
    log "No pude entrar como $EMAIL (respuesta $code). Importa a mano desde"
    log "Administración → Configuración → Transferencia de espacio de trabajo."
    exit 0
  fi
fi

total=$(curl -s -b "$JAR" "$BASE/cards?page_size=1" | number total)
if [ "${total:-0}" -gt 0 ]; then
  log "Ya hay $total fichas cargadas: no se importa de nuevo."
  exit 0
fi

ME=$(curl -s -b "$JAR" "$BASE/auth/me" | field id)
[ -n "$ME" ] && curl -s -o /dev/null -b "$JAR" -X PATCH -H 'content-type: application/json' -d '{"locale":"es"}' "$BASE/users/$ME"

log "Subiendo el espacio de trabajo de Grupo Velsen..."
TID=$(curl -s -b "$JAR" -F "file=@grupo-velsen-workspace.zip;type=application/zip" "$BASE/admin/workspace/import" | field id)
if [ -z "$TID" ]; then log "ERROR: no se pudo subir el archivo."; exit 0; fi

status() { curl -s -b "$JAR" "$BASE/admin/workspace/import/$TID" | field status; }
wait_while() {
  for _ in $(seq 1 300); do
    st=$(status)
    case " $* " in *" $st "*) sleep 2 ;; *) echo "$st"; return ;; esac
  done
  echo "timeout"
}

st=$(wait_while parsing previewing); log "Vista previa: $st"
[ "$st" = "previewed" ] || { log "ERROR: la vista previa terminó en «$st»."; exit 0; }

curl -s -o /dev/null -b "$JAR" -X POST "$BASE/admin/workspace/import/$TID/apply"
st=$(wait_while applying); log "Importación: $st"

total=$(curl -s -b "$JAR" "$BASE/cards?page_size=1" | number total)
log "Fichas cargadas: ${total:-0}. Recarga la página de Turbo EA."

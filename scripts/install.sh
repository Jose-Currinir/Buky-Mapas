#!/usr/bin/env bash
#
# Prepara Buky-Mapas en un servidor nuevo (Ubuntu Server 22.04/24.04, amd64 o arm64,
# p. ej. EC2 t4g.large) o en local. Idempotente: se puede volver a ejecutar.
#   1. dependencias del sistema (Docker, curl, sqlite3, python3) en Ubuntu
#   2. .env desde la plantilla (prod o dev) con la URL pública indicada
#   3. datos: extracto OSM, Natural Earth, relieve y mapa (solo lo que falte)
#   4. levanta el stack
#
# Uso:  ./scripts/install.sh [--prod|--dev] [--url https://maps.ejemplo.cl]
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODE="prod"; URL=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --prod) MODE="prod" ;;
    --dev) MODE="dev" ;;
    --url) URL="$2"; shift ;;
    *) echo "Opción desconocida: $1" >&2; exit 2 ;;
  esac
  shift
done

step() { echo; echo "== $* =="; }

# ---- 1. dependencias
if [[ "$(uname -s)" == "Linux" ]] && command -v apt-get >/dev/null; then
  step "dependencias del sistema"
  missing=()
  for cmd in curl sqlite3 python3; do command -v "$cmd" >/dev/null || missing+=("$cmd"); done
  if (( ${#missing[@]} )); then
    sudo apt-get update -qq && sudo apt-get install -y -qq "${missing[@]}"
  fi
  if ! command -v docker >/dev/null; then
    bash "$ROOT_DIR/install_docker.sh"
    echo "Docker instalado. Cierra la sesión, vuelve a entrar (grupo docker) y ejecuta de nuevo este script."
    exit 0
  fi
fi
for cmd in docker curl sqlite3 python3; do
  command -v "$cmd" >/dev/null || { echo "Falta $cmd" >&2; exit 1; }
done

source "$ROOT_DIR/scripts/lib/common.sh"

# ---- 2. entorno
ENV_FILE="$ROOT_DIR/.env"
if [[ ! -f "$ENV_FILE" ]]; then
  step "creando .env ($MODE)"
  cp "$ROOT_DIR/.env.$MODE.example" "$ENV_FILE"
fi
[[ -n "$URL" ]] && set_env_value "$ENV_FILE" MAPS_PUBLIC_URL "$URL"
echo "MAPS_PUBLIC_URL=$(read_env_value "$ENV_FILE" MAPS_PUBLIC_URL)"

DATA_DIR="$(resolve_data_path "$ENV_FILE")"
COUNTRY="$(read_env_value "$ENV_FILE" ACTIVE_COUNTRY chile)"
TILESET="$(read_env_value "$ENV_FILE" MAPS_PRIMARY_TILESET "$COUNTRY.mbtiles")"
PBF="$DATA_DIR/countries/$COUNTRY/map.osm.pbf"

# ---- 3. datos (solo lo que falta)
if [[ ! -f "$PBF" ]]; then
  step "extracto de OSM ($COUNTRY)"
  bash "$ROOT_DIR/scripts/fetch-pbf.sh" "$ENV_FILE" --force
  mv "$PBF.new" "$PBF"
fi
if [[ ! -f "$DATA_DIR/fonts/Roboto Regular/0-255.pbf" ]]; then
  step "fuentes"
  bash "$ROOT_DIR/scripts/install-roboto-fonts.sh" "$ENV_FILE"
fi
step "Natural Earth"
bash "$ROOT_DIR/scripts/fetch-natural-earth.sh" "$ENV_FILE"
if [[ ! -f "$DATA_DIR/mbtiles/terrain.mbtiles" ]]; then
  step "relieve"
  bash "$ROOT_DIR/scripts/build-terrain.sh" "$ENV_FILE"
fi
if [[ ! -f "$DATA_DIR/mbtiles/$TILESET" ]]; then
  step "mapa base (Planetiler)"
  bash "$ROOT_DIR/scripts/build-tiles.sh" "$ENV_FILE"
fi
bash "$ROOT_DIR/scripts/label-tilesets.sh" "$ENV_FILE" >/dev/null

# ---- 4. servicio
step "levantando el stack"
bash "$ROOT_DIR/scripts/up.sh" "$ENV_FILE"
step "estado"
bash "$ROOT_DIR/scripts/status.sh" "$ENV_FILE"
echo
echo "Listo. Actualizar datos sin cortar el servicio: ./manage.sh update"
echo "Actualización semanal automática (systemd):  ./manage.sh programar"

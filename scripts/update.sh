#!/usr/bin/env bash
#
# Actualiza mapa y rutas a los datos más recientes de OSM sin cortar el servicio:
#   1. descarga el extracto nuevo (si no hay uno nuevo, termina)
#   2. regenera el mapa desde él y recarga los TileServer de a uno
#   3. actualiza GraphHopper en azul/verde
#
# Uso:  ./scripts/update.sh [.env] [--force] [--solo-mapa | --solo-rutas]
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
ENV_FILE="$(resolve_env_file "${1:-.env}")"
require_env_file "$ENV_FILE"
shift || true
FORCE="" ; ONLY=""
for arg in "$@"; do
  case "$arg" in
    --force) FORCE="--force" ;;
    --solo-mapa) ONLY="mapa" ;;
    --solo-rutas) ONLY="rutas" ;;
    *) echo "Opción desconocida: $arg" >&2; exit 2 ;;
  esac
done

DATA_DIR="$(resolve_data_path "$ENV_FILE")"
COUNTRY="$(read_env_value "$ENV_FILE" "ACTIVE_COUNTRY" "chile")"
NEW_PBF="countries/$COUNTRY/map.osm.pbf.new"

# una sola actualización a la vez
LOCK="$DATA_DIR/.update.lock"
if ! mkdir "$LOCK" 2>/dev/null; then
  echo "Ya hay una actualización en curso ($LOCK)." >&2
  exit 1
fi
trap 'rmdir "$LOCK"' EXIT

echo "== $(date -u +%FT%TZ) actualización de datos =="
set +e
bash "$ROOT_DIR/scripts/fetch-pbf.sh" "$ENV_FILE" $FORCE
fetched=$?
set -e
if (( fetched == 3 )) && [[ ! -f "$DATA_DIR/$NEW_PBF" ]]; then
  echo "Nada que actualizar."
  python3 -I "$ROOT_DIR/scripts/data-status.py" "$ENV_FILE" | sed -n '1,6p' || true
  exit 0
fi
(( fetched == 0 || fetched == 3 )) || exit "$fetched"

if [[ "$ONLY" != "rutas" ]]; then
  echo "== mapa =="
  if [[ -f "$DATA_DIR/$NEW_PBF" ]]; then
    SOURCE_PBF="$NEW_PBF" bash "$ROOT_DIR/scripts/build-tiles.sh" "$ENV_FILE"
  else
    bash "$ROOT_DIR/scripts/build-tiles.sh" "$ENV_FILE"
  fi
fi

if [[ "$ONLY" != "mapa" ]]; then
  echo "== rutas =="
  bash "$ROOT_DIR/scripts/update-routing.sh" "$ENV_FILE"
fi

echo "== estado =="
python3 -I "$ROOT_DIR/scripts/data-status.py" "$ENV_FILE" | sed -n '1,6p' || true

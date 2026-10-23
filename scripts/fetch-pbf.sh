#!/usr/bin/env bash
#
# Descarga el extracto de OSM del país activo desde Geofabrik a
#   data/countries/<país>/map.osm.pbf.new
# verificando el MD5. No toca el .pbf en uso: update.sh decide cuándo activarlo.
# Si el extracto publicado es el mismo que el actual, no descarga nada.
#
# Uso:  ./scripts/fetch-pbf.sh [.env] [--force]
# Sale con código 3 si ya está al día (para que update.sh no regenere nada).
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
ENV_FILE="$(resolve_env_file "${1:-.env}")"
require_env_file "$ENV_FILE"
FORCE="${2:-}"

DATA_DIR="$(resolve_data_path "$ENV_FILE")"
COUNTRY="$(read_env_value "$ENV_FILE" "ACTIVE_COUNTRY" "chile")"
URL="$(read_env_value "$ENV_FILE" "OSM_EXTRACT_URL" "https://download.geofabrik.de/south-america/$COUNTRY-latest.osm.pbf")"
DIR="$DATA_DIR/countries/$COUNTRY"
CURRENT="$DIR/map.osm.pbf"
NEW="$DIR/map.osm.pbf.new"
mkdir -p "$DIR"

md5_of() { if command -v md5sum >/dev/null; then md5sum "$1" | cut -d' ' -f1; else md5 -q "$1"; fi; }

remote_md5="$(curl -fsSL --retry 3 "$URL.md5" | cut -d' ' -f1)"
[[ -n "$remote_md5" ]] || { echo "No se pudo leer $URL.md5" >&2; exit 1; }

if [[ "$FORCE" != "--force" && -f "$CURRENT" && "$(md5_of "$CURRENT")" == "$remote_md5" ]]; then
  echo "El extracto de OSM en uso ya es el último publicado ($URL)."
  exit 3
fi

echo "Descargando $URL..."
curl -fL --retry 3 --progress-bar "$URL" -o "$NEW.part"
if [[ "$(md5_of "$NEW.part")" != "$remote_md5" ]]; then
  rm -f "$NEW.part"
  echo "El MD5 no coincide; descarga descartada." >&2
  exit 1
fi
mv "$NEW.part" "$NEW"
echo "Listo: $NEW ($(du -h "$NEW" | cut -f1))"

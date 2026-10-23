#!/usr/bin/env bash
#
# Deja nombres y descripciones claros en los metadatos de los .mbtiles, que es
# lo que TileServer publica en el TileJSON de cada fuente de datos. Conserva la
# atribución (obligatoria por licencia) y los datos de replicación de OSM.
#
# Uso:  ./scripts/label-tilesets.sh [.env]   (idempotente)
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
ENV_FILE="$(resolve_env_file "${1:-.env}")"
require_env_file "$ENV_FILE"
DATA_DIR="$(resolve_data_path "$ENV_FILE")"
MAPS_PRIMARY_TILESET="$(read_env_value "$ENV_FILE" "MAPS_PRIMARY_TILESET")"
MAPS_BACKGROUND_TILESET="$(read_env_value "$ENV_FILE" "MAPS_BACKGROUND_TILESET")"
ACTIVE_COUNTRY="$(read_env_value "$ENV_FILE" "ACTIVE_COUNTRY" "chile")"

command -v sqlite3 >/dev/null || { echo "Falta sqlite3" >&2; exit 1; }

# set_meta <archivo> <clave> <valor>
set_meta() {
  local value="${3//\'/\'\'}"
  sqlite3 "$1" "DELETE FROM metadata WHERE name = '$2'; INSERT INTO metadata (name, value) VALUES ('$2', '$value');"
}

label() {
  local file="$DATA_DIR/mbtiles/$1" id="$2" name="$3" description="$4"
  if [[ ! -f "$file" ]]; then
    echo "  - omitido (no existe): $file"
    return
  fi
  set_meta "$file" id "$id"
  set_meta "$file" name "$name"
  set_meta "$file" description "$description"
  echo "  ✓ $1 → $name"
}

country_name="$(printf '%s' "$ACTIVE_COUNTRY" | awk '{print toupper(substr($0,1,1)) substr($0,2)}')"
label "$MAPS_PRIMARY_TILESET" "$ACTIVE_COUNTRY" "$country_name" \
  "Mapa base de $country_name: calles, edificios, lugares y nombres (OpenStreetMap)"
label "$MAPS_BACKGROUND_TILESET" "natural_earth" "Áreas urbanas" \
  "Manchas urbanas a zoom bajo (Natural Earth)"
label "terrain.mbtiles" "terrain" "Relieve" \
  "Modelo de elevación para el relieve sombreado (codificación terrarium)"

echo "Reinicia TileServer para publicar los nombres nuevos."

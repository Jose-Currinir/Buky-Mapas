#!/usr/bin/env bash

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

ENV_FILE="$(resolve_env_file "${1:-.env}")"
require_env_file "$ENV_FILE"

DATA_DIR="$(resolve_data_path "$ENV_FILE")"
ACTIVE_COUNTRY="$(read_env_value "$ENV_FILE" "ACTIVE_COUNTRY")"
MAPS_PRIMARY_TILESET="$(read_env_value "$ENV_FILE" "MAPS_PRIMARY_TILESET")"
MAPS_BACKGROUND_TILESET="$(read_env_value "$ENV_FILE" "MAPS_BACKGROUND_TILESET")"

required_paths=(
  "$DATA_DIR/config.yml"
  "$DATA_DIR/car_avoid.json"
  "$DATA_DIR/styles/cl-light.json"
  "$DATA_DIR/styles/cl-dark.json"
  "$DATA_DIR/sprites/cl.json"
  "$DATA_DIR/sprites/cl@2x.json"
  "$DATA_DIR/fonts/Roboto Regular/0-255.pbf"
  "$DATA_DIR/fonts/Roboto Medium/0-255.pbf"
  "$DATA_DIR/mbtiles/$MAPS_PRIMARY_TILESET"
  "$DATA_DIR/mbtiles/$MAPS_BACKGROUND_TILESET"
  "$DATA_DIR/mbtiles/terrain.mbtiles"
  "$DATA_DIR/countries/$ACTIVE_COUNTRY/map.osm.pbf"
)

for required_path in "${required_paths[@]}"; do
  if [[ ! -f "$required_path" ]]; then
    echo "Falta el archivo requerido: $required_path" >&2
    exit 1
  fi
done

echo "Datos requeridos presentes en $DATA_DIR"

#!/usr/bin/env bash

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

ENV_FILE="$(resolve_env_file "${1:-.env}")"
require_env_file "$ENV_FILE"

DATA_DIR="$(resolve_data_path "$ENV_FILE")"
MAPS_PRIMARY_TILESET="$(read_env_value "$ENV_FILE" "MAPS_PRIMARY_TILESET")"
MAPS_BACKGROUND_TILESET="$(read_env_value "$ENV_FILE" "MAPS_BACKGROUND_TILESET")"
OUTPUT_FILE="$DATA_DIR/config.json"

mkdir -p "$DATA_DIR"

# Se publican solo los estilos de Chile (claro y oscuro), sin render raster:
# los clientes usan tiles vectoriales. Cada style.json debe existir en data/styles/.
cat > "$OUTPUT_FILE" <<JSON
{
  "options": {
    "paths": {
      "mbtiles": "mbtiles",
      "sprites": "sprites",
      "fonts": "fonts"
    }
  },
  "styles": {
    "cl-light": {
      "style": "styles/cl-light.json",
      "serve_rendered": false,
      "tilejson": {
        "type": "vector"
      }
    },
    "cl-dark": {
      "style": "styles/cl-dark.json",
      "serve_rendered": false,
      "tilejson": {
        "type": "vector"
      }
    }
  },
  "data": {
    "openmaptiles": {
      "mbtiles": "${MAPS_PRIMARY_TILESET}"
    },
    "natural_earth": {
      "mbtiles": "${MAPS_BACKGROUND_TILESET}"
    },
    "terrain": {
      "mbtiles": "terrain.mbtiles"
    }
  }
}
JSON

echo "Archivo renderizado: $OUTPUT_FILE"

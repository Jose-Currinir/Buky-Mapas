#!/usr/bin/env bash
#
# Regenera el mapa base (data/mbtiles/<MAPS_PRIMARY_TILESET>) desde el .osm.pbf del
# país activo con Planetiler, esquema OpenMapTiles: el mismo que esperan los
# estilos cl-light / cl-dark. Planetiler guarda en los metadatos la marca de
# replicación de OSM del .pbf, que usa scripts/data-status.py.
#
# - Genera en un archivo temporal: el mapa actual sigue en línea hasta el final.
# - Descarga una vez las fuentes auxiliares (polígonos de agua, Natural Earth;
#   ~1,3 GB) y las borra al terminar, salvo KEEP_SOURCES=1.
# - Si el stack está arriba, recarga TileServer (el gateway responde desde su caché
#   mientras tanto) y vacía la caché cuando el mapa nuevo ya responde.
#
# Uso:  ./scripts/build-tiles.sh [.env]
#       PLANETILER_MEMORY=4g ./scripts/build-tiles.sh .env
#       SOURCE_PBF=countries/chile/map.osm.pbf.new ./scripts/build-tiles.sh .env
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
ENV_FILE="$(resolve_env_file "${1:-.env}")"
require_env_file "$ENV_FILE"
ensure_docker_available

DATA_DIR="$(resolve_data_path "$ENV_FILE")"
COUNTRY="$(read_env_value "$ENV_FILE" "ACTIVE_COUNTRY" "chile")"
TILESET="$(read_env_value "$ENV_FILE" "MAPS_PRIMARY_TILESET" "$COUNTRY.mbtiles")"
IMAGE="${PLANETILER_IMAGE:-ghcr.io/onthegomap/planetiler:0.8.3}"
MEMORY="${PLANETILER_MEMORY:-4g}"
# ruta relativa a DATA_DIR; update.sh la apunta al .pbf recién descargado
PBF="${SOURCE_PBF:-countries/$COUNTRY/map.osm.pbf}"
TMP_NAME=".${TILESET%.mbtiles}.new.mbtiles"

[[ -f "$DATA_DIR/$PBF" ]] || { echo "Falta $DATA_DIR/$PBF (descárgalo con ./manage.sh, opción 2)" >&2; exit 1; }
mkdir -p "$DATA_DIR/mbtiles" "$DATA_DIR/sources"
rm -f "$DATA_DIR/mbtiles/$TMP_NAME"

echo "Generando $TILESET desde $PBF con $IMAGE (memoria $MEMORY)..."
started=$(date +%s)
# Con el usuario del host: en Linux, sin esto, Planetiler (root en el contenedor) deja
# data/sources a nombre de root y el script no puede borrarlo ni regenerar el mapa.
docker run --rm \
  --user "$(id -u):$(id -g)" \
  -e JAVA_TOOL_OPTIONS="-Xmx$MEMORY" \
  -v "$DATA_DIR:/data" \
  "$IMAGE" \
  --osm-path="/data/$PBF" \
  --output="/data/mbtiles/$TMP_NAME" \
  --download --download-dir=/data/sources \
  --tmpdir=/data/sources/tmp \
  --tile_weights=/data/sources/tile_weights.tsv.gz \
  --force

# validación mínima antes de reemplazar el mapa en línea
tiles=$(sqlite3 "$DATA_DIR/mbtiles/$TMP_NAME" "select count(*) from tiles")
maxzoom=$(sqlite3 "$DATA_DIR/mbtiles/$TMP_NAME" "select value from metadata where name='maxzoom'")
if (( tiles < 1000 )) || [[ "$maxzoom" != "14" ]]; then
  echo "El mapa generado no es válido (tiles=$tiles, maxzoom=$maxzoom); se conserva el actual." >&2
  exit 1
fi
mv "$DATA_DIR/mbtiles/$TMP_NAME" "$DATA_DIR/mbtiles/$TILESET"
[[ "${KEEP_SOURCES:-0}" = "1" ]] || rm -rf "$DATA_DIR/sources"
echo "Mapa generado: $tiles tiles en $(( ($(date +%s) - started) / 60 )) min"

bash "$ROOT_DIR/scripts/label-tilesets.sh" "$ENV_FILE" >/dev/null

if [[ -n "$(service_container "$ENV_FILE" maps)" ]]; then
  bash "$ROOT_DIR/scripts/reload-maps.sh" "$ENV_FILE"
fi

python3 -I "$ROOT_DIR/scripts/data-status.py" "$ENV_FILE" | sed -n '1,6p' || true

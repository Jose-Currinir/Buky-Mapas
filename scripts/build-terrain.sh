#!/usr/bin/env bash
#
# Construye data/mbtiles/terrain.mbtiles: modelo de elevación (codificación
# terrarium) para el relieve sombreado de cl-light / cl-dark.
#
# Fuente: Terrain Tiles de AWS (Registro de Datos Abiertos, sin clave ni costo)
#   https://registry.opendata.aws/terrain-tiles/
# Zooms 0-9 sobre Chile y alrededores: ~1.700 tiles, ~120 MB. MapLibre amplía
# el relieve hasta z12, donde los estilos lo muestran.
#
# Requisitos: curl, sqlite3, python3. Si se interrumpe, reanuda la descarga.
# Uso:  ./scripts/build-terrain.sh [.env]
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
ENV_FILE="$(resolve_env_file "${1:-.env}")"
DATA_DIR="$(resolve_data_path "$ENV_FILE")"
CACHE_DIR="$DATA_DIR/terrain"
OUT="$DATA_DIR/mbtiles/terrain.mbtiles"
BASE_URL="https://s3.amazonaws.com/elevation-tiles-prod/terrarium"
MAX_ZOOM=9
# lon_min lat_max lon_max lat_min
BBOX=(-76.5 -16.5 -65.5 -56.5)

for cmd in curl sqlite3 python3; do
  command -v "$cmd" >/dev/null || { echo "Falta $cmd" >&2; exit 1; }
done
mkdir -p "$CACHE_DIR" "$(dirname "$OUT")"

# lista z/x/y de los tiles que cubren el BBOX
python3 -I - "$MAX_ZOOM" "${BBOX[@]}" >"$CACHE_DIR/tiles.txt" <<'EOF'
import math, sys
zmax, lon0, lat0, lon1, lat1 = int(sys.argv[1]), *map(float, sys.argv[2:])
def tile(lon, lat, z):
    n = 2 ** z
    return int((lon + 180) / 360 * n), int((1 - math.asinh(math.tan(math.radians(lat))) / math.pi) / 2 * n)
for z in range(zmax + 1):
    (x0, y0), (x1, y1) = tile(lon0, lat0, z), tile(lon1, lat1, z)
    for x in range(x0, x1 + 1):
        for y in range(y0, y1 + 1):
            print(f"{z}/{x}/{y}")
EOF
total=$(wc -l <"$CACHE_DIR/tiles.txt" | tr -d ' ')
echo "Descargando $total tiles de elevación (z0-z$MAX_ZOOM)..."

export CACHE_DIR BASE_URL
xargs -P 16 -I{} sh -c '
  f="$CACHE_DIR/{}.png"
  [ -s "$f" ] && exit 0
  mkdir -p "$(dirname "$f")"
  curl -fsS --retry 3 --max-time 60 "$BASE_URL/{}.png" -o "$f.part" && mv "$f.part" "$f"
' <"$CACHE_DIR/tiles.txt"

missing=0
while read -r t; do [ -s "$CACHE_DIR/$t.png" ] || missing=$((missing + 1)); done <"$CACHE_DIR/tiles.txt"
if (( missing > 0 )); then
  echo "Faltan $missing tiles; vuelve a ejecutar el script." >&2
  exit 1
fi

echo "Empaquetando $OUT..."
rm -f "$OUT.tmp"
sqlite3 "$OUT.tmp" <<EOF
CREATE TABLE metadata (name TEXT, value TEXT);
CREATE TABLE tiles (zoom_level INTEGER, tile_column INTEGER, tile_row INTEGER, tile_data BLOB);
CREATE UNIQUE INDEX tile_index ON tiles (zoom_level, tile_column, tile_row);
INSERT INTO metadata VALUES
  ('id', 'terrain'), ('name', 'Relieve'),
  ('description', 'Modelo de elevación para el relieve sombreado (codificación terrarium)'),
  ('format', 'png'), ('type', 'baselayer'), ('encoding', 'terrarium'),
  ('minzoom', '0'), ('maxzoom', '$MAX_ZOOM'), ('bounds', '${BBOX[0]},${BBOX[3]},${BBOX[2]},${BBOX[1]}'),
  ('attribution', 'Terrain Tiles: Mapzen, AWS Open Data');
EOF
# MBTiles usa filas TMS: y invertida
{
  echo "BEGIN;"
  while IFS=/ read -r z x y; do
    echo "INSERT INTO tiles VALUES ($z, $x, $(( (1 << z) - 1 - y )), readfile('$CACHE_DIR/$z/$x/$y.png'));"
  done <"$CACHE_DIR/tiles.txt"
  echo "COMMIT;"
} | sqlite3 "$OUT.tmp"
mv "$OUT.tmp" "$OUT"
rm -rf "$CACHE_DIR"   # el espacio en disco es prioritario: no se conserva la descarga
echo "Listo: $OUT ($(du -h "$OUT" | cut -f1))"

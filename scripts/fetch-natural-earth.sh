#!/usr/bin/env bash
#
# Descarga natural_earth.mbtiles (manchas urbanas a zoom bajo) si falta.
# Fuente: naturalearthtiles v1.0 (dominio público), ~20 MB.
#
# Uso:  ./scripts/fetch-natural-earth.sh [.env]
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
ENV_FILE="$(resolve_env_file "${1:-.env}")"
DATA_DIR="$(resolve_data_path "$ENV_FILE")"
NAME="$(read_env_value "$ENV_FILE" "MAPS_BACKGROUND_TILESET" "natural_earth.mbtiles")"
OUT="$DATA_DIR/mbtiles/$NAME"
URL="https://github.com/lukasmartinelli/naturalearthtiles/releases/download/v1.0/natural_earth.vector.mbtiles"
SHA256="2cbd8ee94ad453e8e86f79d25b868d0daa5f59cd71ce70a616ac5a718ea347ed"

if [[ -s "$OUT" ]]; then
  echo "Ya existe $OUT"
  exit 0
fi
mkdir -p "$(dirname "$OUT")"
echo "Descargando Natural Earth..."
curl -fL --retry 3 --progress-bar "$URL" -o "$OUT.part"
sha_of() { if command -v sha256sum >/dev/null; then sha256sum "$1" | cut -d' ' -f1; else shasum -a 256 "$1" | cut -d' ' -f1; fi; }
if [[ "$(sha_of "$OUT.part")" != "$SHA256" ]]; then
  rm -f "$OUT.part"
  echo "El SHA-256 no coincide; descarga descartada." >&2
  exit 1
fi
mv "$OUT.part" "$OUT"
bash "$ROOT_DIR/scripts/label-tilesets.sh" "$ENV_FILE" >/dev/null
echo "Listo: $OUT ($(du -h "$OUT" | cut -f1))"

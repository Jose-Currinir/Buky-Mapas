#!/usr/bin/env bash
#
# Descarga los glifos SDF de Roboto (Regular y Medium) usados por
# los estilos cl-light / cl-dark, desde el repositorio público de
# glifos pre-construidos korywka/fonts.pbf.
#
# data/fonts/ está en .gitignore (assets pesados), por eso este paso es
# explícito y reproducible. Idempotente: omite rangos ya presentes.
#
# Uso:  ./scripts/install-roboto-fonts.sh [.env]
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
ENV_FILE="$(resolve_env_file "${1:-.env}")"
DATA_DIR="$(resolve_data_path "$ENV_FILE")"
FONTS_DIR="$DATA_DIR/fonts"

BASE_URL="https://raw.githubusercontent.com/korywka/fonts.pbf/master"
FAMILIES=("Roboto Regular" "Roboto Medium")
# Rangos para español/latín (acentos, ñ), puntuación tipográfica y símbolos (★, ☆).
RANGES=("0-255" "256-511" "512-767" "768-1023" "7680-7935" "8192-8447" "9728-9983")

mkdir -p "$FONTS_DIR"
for family in "${FAMILIES[@]}"; do
  dest="$FONTS_DIR/$family"
  mkdir -p "$dest"
  enc_family="${family// /%20}"
  for range in "${RANGES[@]}"; do
    out="$dest/$range.pbf"
    if [[ -s "$out" ]]; then
      continue
    fi
    url="$BASE_URL/$enc_family/$range.pbf"
    if curl -fsSL --max-time 30 "$url" -o "$out"; then
      echo "  ✓ $family/$range.pbf"
    else
      echo "  ✗ no se pudo descargar $family/$range.pbf ($url)" >&2
      rm -f "$out"
    fi
  done
done

echo "Roboto instalado en $FONTS_DIR"

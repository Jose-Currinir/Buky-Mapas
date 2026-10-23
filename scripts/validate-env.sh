#!/usr/bin/env bash

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

ENV_FILE="$(resolve_env_file "${1:-.env}")"
require_env_file "$ENV_FILE"

required_keys=(
  COMPOSE_PROJECT_NAME
  MAPS_IMAGE
  ROUTING_IMAGE
  MAPS_PORT
  ROUTING_PORT
  MAPS_MEMORY_LIMIT
  ROUTING_MEMORY_LIMIT
  ROUTING_JAVA_OPTS
  MAPS_PUBLIC_URL
  MAPS_CONFIG_FILE
  MAPS_PRIMARY_TILESET
  MAPS_BACKGROUND_TILESET
  ROUTING_CONFIG_FILE
  ROUTING_OSM_FILE
  DATA_PATH
  ACTIVE_COUNTRY
)

for key in "${required_keys[@]}"; do
  if [[ -z "$(read_env_value "$ENV_FILE" "$key")" ]]; then
    echo "Falta la variable obligatoria $key en $ENV_FILE" >&2
    exit 1
  fi
done

for key in MAPS_PORT ROUTING_PORT; do
  value="$(read_env_value "$ENV_FILE" "$key")"
  if [[ ! "$value" =~ ^[0-9]+$ ]]; then
    echo "$key debe ser numérico" >&2
    exit 1
  fi
done

if [[ "$(read_env_value "$ENV_FILE" "MAPS_PUBLIC_URL")" != http://* && "$(read_env_value "$ENV_FILE" "MAPS_PUBLIC_URL")" != https://* ]]; then
  echo "MAPS_PUBLIC_URL debe comenzar con http:// o https://" >&2
  exit 1
fi

echo "Archivo de entorno válido: $ENV_FILE"

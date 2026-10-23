#!/usr/bin/env bash
# Levanta el stack: TileServer, el color activo de GraphHopper y el gateway.
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

ENV_FILE="$(resolve_env_file "${1:-.env}")"
require_env_file "$ENV_FILE"
ensure_docker_available

bash "$ROOT_DIR/scripts/validate-env.sh" "$ENV_FILE"
bash "$ROOT_DIR/scripts/render-tileserver-config.sh" "$ENV_FILE"
bash "$ROOT_DIR/scripts/validate-data.sh" "$ENV_FILE"

network="$(read_env_value "$ENV_FILE" "MAPS_SHARED_NETWORK" "butake-service-shared")"
docker network inspect "$network" >/dev/null 2>&1 || docker network create "$network" >/dev/null
ensure_gateway_state
color="$(active_routing_color)"

compose_cmd "$ENV_FILE" up -d maps "routing-$color"
wait_for_service_healthy "$ENV_FILE" maps 120
# la primera importación del grafo tarda varios minutos
wait_for_service_healthy "$ENV_FILE" "routing-$color" 1200
compose_cmd "$ENV_FILE" up -d gateway
wait_for_service_healthy "$ENV_FILE" gateway 60

echo "Servicios levantados (rutas en color $color) con $ENV_FILE"

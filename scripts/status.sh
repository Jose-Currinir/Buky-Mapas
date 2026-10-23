#!/usr/bin/env bash
# Estado del stack (contenedores, color activo de rutas) y atraso de los datos frente a OSM.
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

ENV_FILE="$(resolve_env_file "${1:-.env}")"
require_env_file "$ENV_FILE"
ensure_docker_available
ensure_gateway_state

compose_cmd "$ENV_FILE" ps --format 'table {{.Service}}\t{{.Status}}'
echo
echo "Rutas activas: routing-$(active_routing_color)"
echo
python3 -I "$ROOT_DIR/scripts/data-status.py" "$ENV_FILE" | sed -n '1,6p' || echo "(no se pudo consultar Geofabrik)"

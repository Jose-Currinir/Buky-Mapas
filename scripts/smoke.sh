#!/usr/bin/env bash

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

ENV_FILE="$(resolve_env_file "${1:-.env}")"
require_env_file "$ENV_FILE"
ensure_docker_available

bash "$ROOT_DIR/scripts/validate-env.sh" "$ENV_FILE"
bash "$ROOT_DIR/scripts/render-tileserver-config.sh" "$ENV_FILE"
bash "$ROOT_DIR/scripts/validate-data.sh" "$ENV_FILE"
compose_cmd "$ENV_FILE" config >/dev/null
compose_cmd "$ENV_FILE" ps

echo "Smoke check completado correctamente"

#!/usr/bin/env bash
# Recarga TileServer (SIGHUP) para que tome un mapa, estilo o config.json nuevo.
# Mientras se recarga, el gateway responde desde su caché; recién cuando TileServer
# vuelve a responder se vacía la caché, para que se sirva lo nuevo.
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

ENV_FILE="$(resolve_env_file "${1:-.env}")"
require_env_file "$ENV_FILE"
ensure_docker_available

bash "$ROOT_DIR/scripts/render-tileserver-config.sh" "$ENV_FILE" >/dev/null

id="$(service_container "$ENV_FILE" maps)"
[[ -n "$id" ]] || { echo "TileServer no está corriendo: ./manage.sh up" >&2; exit 1; }

health() {
  docker exec "$id" node -e "require('http').get('http://127.0.0.1:8080/health', r => process.exit(r.statusCode === 200 ? 0 : 1)).on('error', () => process.exit(1))" 2>/dev/null
}

docker kill --signal=HUP "$id" >/dev/null
sleep 1
ready=0
for _ in $(seq 1 90); do
  if health; then ready=1; break; fi
  sleep 1
done
if (( ready == 0 )); then
  echo "TileServer no volvió a responder; la caché del gateway se conserva." >&2
  exit 1
fi
echo "  ✓ TileServer recargado"

gateway="$(service_container "$ENV_FILE" gateway)"
if [[ -n "$gateway" ]]; then
  docker exec "$gateway" sh -c 'rm -rf /var/cache/nginx/maps/*'
  docker exec "$gateway" nginx -s reload >/dev/null 2>&1
  echo "  ✓ caché del gateway vaciada: ya se sirve el mapa nuevo"
fi

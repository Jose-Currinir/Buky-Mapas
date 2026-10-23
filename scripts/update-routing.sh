#!/usr/bin/env bash
#
# Actualiza GraphHopper al .pbf nuevo sin cortar el servicio (azul/verde):
#   1. activa data/countries/<país>/map.osm.pbf.new (si existe)
#   2. el color inactivo importa el grafo desde cero en su propio volumen
#   3. se prueba con una ruta real; si falla, se aborta y sigue el color actual
#   4. el gateway cambia al color nuevo en caliente (nginx -s reload)
#   5. el color anterior se detiene, conservando su grafo para volver atrás
#
# Durante la importación corren los dos colores: hace falta RAM para ambos
# (t4g.large, 8 GB). Con ROUTING_ZERO_DOWNTIME=0 se reimporta en el mismo color,
# con unos minutos sin rutas (máquinas de 4 GB).
#
# Uso:  ./scripts/update-routing.sh [.env]            actualizar
#       ./scripts/update-routing.sh [.env] --volver   volver al color anterior
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
ENV_FILE="$(resolve_env_file "${1:-.env}")"
require_env_file "$ENV_FILE"
ensure_docker_available
ensure_gateway_state

DATA_DIR="$(resolve_data_path "$ENV_FILE")"
COUNTRY="$(read_env_value "$ENV_FILE" "ACTIVE_COUNTRY" "chile")"
PROJECT="$(read_env_value "$ENV_FILE" "COMPOSE_PROJECT_NAME" "butake-service-maps")"
ZERO_DOWNTIME="$(read_env_value "$ENV_FILE" "ROUTING_ZERO_DOWNTIME" "1")"
PBF="$DATA_DIR/countries/$COUNTRY/map.osm.pbf"

active="$(active_routing_color)"
next="$([[ "$active" == blue ]] && echo green || echo blue)"

switch_gateway() {
  set_active_routing_color "$1"
  local gw
  gw="$(service_container "$ENV_FILE" gateway)"
  [[ -n "$gw" ]] && docker exec "$gw" nginx -s reload >/dev/null 2>&1
  echo "  ✓ gateway apuntando a routing-$1"
}

# prueba de humo: una ruta corta en el centro del país activo
probe_route() {
  local id="$1"
  docker exec "$id" sh -c 'curl -fsS "http://127.0.0.1:8080/route?point=-33.45,-70.66&point=-33.42,-70.60&profile=car&calc_points=false"' \
    | grep -q '"distance"'
}

if [[ "${2:-}" == "--volver" ]]; then
  echo "Volviendo de routing-$active a routing-$next..."
  compose_cmd "$ENV_FILE" up -d "routing-$next"
  wait_for_service_healthy "$ENV_FILE" "routing-$next" 1200
  switch_gateway "$next"
  compose_cmd "$ENV_FILE" stop "routing-$active" >/dev/null
  exit 0
fi

if [[ -f "$PBF.new" ]]; then
  # seguro: el color activo ya tiene el grafo en memoria y no vuelve a leer el .pbf
  mv "$PBF.new" "$PBF"
  echo "  ✓ .pbf nuevo activado"
fi

if [[ "$ZERO_DOWNTIME" == "0" ]]; then
  echo "Reimportando en routing-$active (sin rutas durante la importación)..."
  compose_cmd "$ENV_FILE" rm -sf "routing-$active" >/dev/null
  docker volume rm "${PROJECT}_routing_${active}" >/dev/null 2>&1 || true
  compose_cmd "$ENV_FILE" up -d "routing-$active"
  wait_for_service_healthy "$ENV_FILE" "routing-$active" 1800
  echo "Rutas actualizadas en routing-$active"
  exit 0
fi

echo "Importando el grafo nuevo en routing-$next (routing-$active sigue atendiendo)..."
compose_cmd "$ENV_FILE" rm -sf "routing-$next" >/dev/null
docker volume rm "${PROJECT}_routing_${next}" >/dev/null 2>&1 || true
compose_cmd "$ENV_FILE" up -d "routing-$next"
if ! wait_for_service_healthy "$ENV_FILE" "routing-$next" 1800; then
  echo "routing-$next no quedó sano; se mantiene routing-$active." >&2
  compose_cmd "$ENV_FILE" stop "routing-$next" >/dev/null
  exit 1
fi
if ! probe_route "$(service_container "$ENV_FILE" "routing-$next")"; then
  echo "routing-$next no calcula rutas; se mantiene routing-$active." >&2
  compose_cmd "$ENV_FILE" stop "routing-$next" >/dev/null
  exit 1
fi
echo "  ✓ routing-$next sano y calculando rutas"

switch_gateway "$next"
sleep 5   # termina las peticiones en curso del color anterior
compose_cmd "$ENV_FILE" stop "routing-$active" >/dev/null
echo "Rutas actualizadas: activo routing-$next (routing-$active detenido, disponible con --volver)"

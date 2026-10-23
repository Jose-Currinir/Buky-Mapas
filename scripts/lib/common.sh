#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
COMPOSE_FILE="$ROOT_DIR/docker-compose.yml"

resolve_env_file() {
  local env_file_input="${1:-.env}"

  if [[ "$env_file_input" = /* ]]; then
    printf '%s\n' "$env_file_input"
  else
    printf '%s\n' "$ROOT_DIR/$env_file_input"
  fi
}

require_env_file() {
  local env_file="$1"

  if [[ ! -f "$env_file" ]]; then
    echo "No existe el archivo de entorno: $env_file" >&2
    exit 1
  fi
}

read_env_value() {
  local env_file="$1"
  local key="$2"
  local default_value="${3:-}"
  local value

  value="$(
    awk -v key="$key" '
      /^[[:space:]]*#/ { next }
      $0 ~ "^[[:space:]]*" key "=" {
        value = substr($0, index($0, "=") + 1)
        sub(/^[[:space:]]+/, "", value)
        sub(/[[:space:]]+$/, "", value)
        if (value ~ /^".*"$/ || value ~ /^'\''.*'\''$/) {
          value = substr(value, 2, length(value) - 2)
        }
        print value
        exit
      }
    ' "$env_file"
  )"

  if [[ -n "$value" ]]; then
    printf '%s\n' "$value"
  else
    printf '%s\n' "$default_value"
  fi
}

compose_cmd() {
  local env_file="$1"
  shift
  docker compose --env-file "$env_file" -f "$COMPOSE_FILE" "$@"
}

ensure_docker_available() {
  if ! command -v docker >/dev/null 2>&1; then
    echo "Docker no está disponible en PATH" >&2
    exit 1
  fi
}

wait_for_container_running() {
  local container_name="$1"
  local timeout_seconds="${2:-60}"
  local started_at
  local status

  started_at="$(date +%s)"

  while true; do
    status="$(docker inspect --format '{{.State.Status}}' "$container_name" 2>/dev/null || true)"

    if [[ "$status" = "running" ]]; then
      return 0
    fi

    if (( "$(date +%s)" - started_at >= timeout_seconds )); then
      echo "El contenedor $container_name no alcanzó estado running en ${timeout_seconds}s" >&2
      return 1
    fi

    sleep 2
  done
}

wait_for_container_healthy() {
  local container_name="$1"
  local timeout_seconds="${2:-90}"
  local started_at
  local status

  started_at="$(date +%s)"

  while true; do
    status="$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "$container_name" 2>/dev/null || true)"

    if [[ "$status" = "healthy" ]]; then
      return 0
    fi

    if [[ "$status" = "unhealthy" ]]; then
      echo "El contenedor $container_name quedó unhealthy" >&2
      docker logs "$container_name" --tail 100 >&2 || true
      return 1
    fi

    if (( "$(date +%s)" - started_at >= timeout_seconds )); then
      echo "El contenedor $container_name no alcanzó estado healthy en ${timeout_seconds}s" >&2
      docker inspect "$container_name" >&2 || true
      docker logs "$container_name" --tail 100 >&2 || true
      return 1
    fi

    sleep 2
  done
}

resolve_data_path() {
  local env_file="$1"
  local data_path

  data_path="$(read_env_value "$env_file" "DATA_PATH" "./data")"
  if [[ "$data_path" = /* ]]; then
    printf '%s\n' "$data_path"
  else
    printf '%s\n' "$ROOT_DIR/$data_path"
  fi
}

# Id del contenedor de un servicio de compose (vacío si no existe).
service_container() {
  compose_cmd "$1" ps -a -q "$2" 2>/dev/null | head -n 1
}

# Espera a que un servicio de compose esté healthy.
wait_for_service_healthy() {
  local env_file="$1" service="$2" timeout="${3:-120}" id
  id="$(service_container "$env_file" "$service")"
  [[ -n "$id" ]] || { echo "El servicio $service no existe" >&2; return 1; }
  wait_for_container_healthy "$id" "$timeout"
}

# ---- color activo de GraphHopper (azul/verde) ----
routing_state_file() {
  printf '%s\n' "$ROOT_DIR/gateway/state/routing-upstream.conf"
}

active_routing_color() {
  if grep -q "routing-green" "$(routing_state_file)" 2>/dev/null; then echo green; else echo blue; fi
}

set_active_routing_color() {
  mkdir -p "$(dirname "$(routing_state_file)")"
  printf 'server routing-%s:8080;\n' "$1" > "$(routing_state_file).tmp"
  mv "$(routing_state_file).tmp" "$(routing_state_file)"
}

ensure_gateway_state() {
  [[ -f "$(routing_state_file)" ]] || set_active_routing_color blue
}

set_env_value() {
  local env_file="$1"
  local key="$2"
  local value="$3"
  local tmp_file

  tmp_file="$(mktemp)"

  if grep -q "^${key}=" "$env_file" 2>/dev/null; then
    awk -v key="$key" -v value="$value" '
      BEGIN { updated = 0 }
      $0 ~ "^" key "=" {
        print key "=" value
        updated = 1
        next
      }
      { print }
      END {
        if (updated == 0) {
          print key "=" value
        }
      }
    ' "$env_file" > "$tmp_file"
  else
    cat "$env_file" > "$tmp_file"
    printf '%s=%s\n' "$key" "$value" >> "$tmp_file"
  fi

  mv "$tmp_file" "$env_file"
}

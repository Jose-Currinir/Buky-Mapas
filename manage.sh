#!/usr/bin/env bash
set -euo pipefail

# =========================================================
# Buky-Mapas: gestor de mapas y rutas (CLI)
# Buky-Mapas - Sistema multipaís
# =========================================================

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="$BASE_DIR/.env"

# ---------------------------------------------------------
# Subcomandos (sin menú). Sin argumentos se abre el menú.
# ---------------------------------------------------------
usage() {
    cat <<USAGE
Uso: ./manage.sh [comando]

  install [--prod|--dev] [--url URL]  prepara el servidor y levanta todo (idempotente)
  update [--force] [--solo-mapa|--solo-rutas]
                                       actualiza mapa y rutas desde OSM sin cortar el servicio
  status                               contenedores, color de rutas y atraso de los datos
  up | down                            levanta o detiene el stack
  logs [servicio]                      gateway, maps, routing-blue, routing-green
  reload                               recarga TileServer sin cortar (estilos o mapa nuevo)
  rutas-volver                         vuelve al color anterior de GraphHopper
  programar [--quitar]                 actualización semanal automática (systemd)

Sin comando: menú interactivo.
USAGE
}

case "${1:-}" in
    install)      shift; exec bash "$BASE_DIR/scripts/install.sh" "$@" ;;
    update)       shift; exec bash "$BASE_DIR/scripts/update.sh" "$ENV_FILE" "$@" ;;
    status)       exec bash "$BASE_DIR/scripts/status.sh" "$ENV_FILE" ;;
    up)           exec bash "$BASE_DIR/scripts/up.sh" "$ENV_FILE" ;;
    down)         exec bash "$BASE_DIR/scripts/down.sh" "$ENV_FILE" ;;
    logs)         shift; exec bash "$BASE_DIR/scripts/logs.sh" "$ENV_FILE" "$@" ;;
    reload)       exec bash "$BASE_DIR/scripts/reload-maps.sh" "$ENV_FILE" ;;
    rutas-volver) exec bash "$BASE_DIR/scripts/update-routing.sh" "$ENV_FILE" --volver ;;
    programar)    shift; exec bash "$BASE_DIR/scripts/install-timer.sh" "$@" ;;
    help|-h|--help) usage; exit 0 ;;
    "") ;;
    *) usage; exit 2 ;;
esac

# Cargar .env
if [ -f "$ENV_FILE" ]; then
    set -a; source "$ENV_FILE"; set +a
fi

DATA_DIR="${DATA_PATH:-${BASE_DIR}/data}"
COUNTRIES_DIR="$DATA_DIR/countries"
CURRENT_COUNTRY="${ACTIVE_COUNTRY:-chile}"

# Colores
GREEN='\033[0;32m'; BLUE='\033[0;34m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

# Crear directorios base si no existen
mkdir -p "$DATA_DIR/fonts" "$DATA_DIR/sprites" "$DATA_DIR/styles" \
         "$DATA_DIR/mbtiles" "$COUNTRIES_DIR/chile"

# =========================================================
# Funciones internas
# =========================================================

show_banner() {
    clear
    echo -e "${BLUE}"
    echo "  ____        _        _              __  __                "
    echo " | __ ) _   _| |_ __ _| | _____      |  \/  | __ _ _ __  ___ "
    echo " |  _ \| | | | __/ _\` | |/ / _ \_____|  |\/| |/ _\` | '_ \/ __|"
    echo " | |_) | |_| | || (_| |   <  __/_____| |  | | (_| | |_) \__ \\"
    echo " |____/ \__,_|\__\__,_|_|\_\___|     |_|  |_|\__,_| .__/|___/"
    echo "                                                   |_|       "
    echo -e "${NC}"
    echo "  --- Buky-Mapas · Arquitectura multipaís ---"
    echo -e "  País activo (Rutas): ${GREEN}${CURRENT_COUNTRY}${NC}"
    echo ""
}

show_status() {
    echo -e "${BLUE}--- Estado de los Servicios ---${NC}"
    docker compose --env-file "$ENV_FILE" -f "$BASE_DIR/docker-compose.yml" ps
    echo ""
}

set_env_value() {
    local key="$1"
    local value="$2"
    local tmp_file

    tmp_file="$(mktemp)"

    if grep -q "^${key}=" "$ENV_FILE" 2>/dev/null; then
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
        ' "$ENV_FILE" > "$tmp_file"
    else
        cat "$ENV_FILE" > "$tmp_file"
        printf '%s=%s\n' "$key" "$value" >> "$tmp_file"
    fi

    mv "$tmp_file" "$ENV_FILE"
}

# =========================================================
# 1. Seleccionar País Activo
# =========================================================
select_country() {
    echo -e "${YELLOW}Países disponibles:${NC}"
    ls -1 "$COUNTRIES_DIR" 2>/dev/null || echo "  (ninguno)"
    echo ""
    read -rp "Escriba el nombre del país (ej: chile): " new_country

    if [ ! -d "$COUNTRIES_DIR/$new_country" ]; then
        echo -e "${RED}El país '$new_country' no existe. Descárgalo primero.${NC}"
        sleep 2; return
    fi

    set_env_value "ACTIVE_COUNTRY" "$new_country"
    set_env_value "MAPS_PRIMARY_TILESET" "$new_country.mbtiles"

    CURRENT_COUNTRY="$new_country"
    echo -e "${GREEN}País activo: $new_country${NC}"
    echo -e "${YELLOW}Publicando el mapa y las rutas de $new_country sin cortar el servicio...${NC}"
    bash "$BASE_DIR/scripts/reload-maps.sh" "$ENV_FILE"
    bash "$BASE_DIR/scripts/update-routing.sh" "$ENV_FILE"
    read -rp "Presione Enter para continuar..."
}

# =========================================================
# 2. Descargar Datos OSM (.pbf)
# =========================================================
download_data() {
    echo -e "${YELLOW}Seleccione el país para descargar:${NC}"
    echo " 1) Chile         (~ 450 MB)"
    echo " 2) Argentina     (~ 1.7 GB)"
    echo " 3) Perú          (~ 280 MB)"
    echo " 4) Colombia      (~ 230 MB)"
    echo " 5) Volver"
    read -rp "Opción [1-5]: " opt

    case $opt in
        1) URL="https://download.geofabrik.de/south-america/chile-latest.osm.pbf"    ; NAME="chile"     ;;
        2) URL="https://download.geofabrik.de/south-america/argentina-latest.osm.pbf"; NAME="argentina" ;;
        3) URL="https://download.geofabrik.de/south-america/peru-latest.osm.pbf"     ; NAME="peru"      ;;
        4) URL="https://download.geofabrik.de/south-america/colombia-latest.osm.pbf" ; NAME="colombia"  ;;
        5) return ;;
        *) echo -e "${RED}Opción inválida${NC}"; sleep 1; return ;;
    esac

    TARGET="$COUNTRIES_DIR/$NAME"
    mkdir -p "$TARGET"
    echo -e "${GREEN}Descargando $NAME desde Geofabrik...${NC}"
    curl -L --progress-bar "$URL" -o "$TARGET/map.osm.pbf"
    echo -e "${GREEN}✓ Descarga completada: $TARGET/map.osm.pbf${NC}"
    read -rp "Presione Enter para continuar..."
}

# =========================================================
# 3. Generar el mapa (MBTiles) con Planetiler
# =========================================================
generate_mbtiles() {
    echo -e "${YELLOW}Países con datos disponibles:${NC}"
    ls -1 "$COUNTRIES_DIR" 2>/dev/null || echo "  (ninguno)"
    echo ""
    read -rp "País a procesar (Enter = $CURRENT_COUNTRY): " country_name
    country_name="${country_name:-$CURRENT_COUNTRY}"

    if [ ! -f "$COUNTRIES_DIR/$country_name/map.osm.pbf" ]; then
        echo -e "${RED}No se encontró: $COUNTRIES_DIR/$country_name/map.osm.pbf${NC}"
        read -rp "Presione Enter para continuar..."; return
    fi

    set_env_value "ACTIVE_COUNTRY" "$country_name"
    set_env_value "MAPS_PRIMARY_TILESET" "$country_name.mbtiles"
    CURRENT_COUNTRY="$country_name"
    echo -e "${YELLOW}Generando mapa de $country_name (puede tardar varios minutos)...${NC}"
    if bash "$BASE_DIR/scripts/build-tiles.sh" "$ENV_FILE"; then
        bash "$BASE_DIR/scripts/render-tileserver-config.sh" "$ENV_FILE"
        echo -e "${GREEN}✓ Mapa generado: $DATA_DIR/mbtiles/$country_name.mbtiles${NC}"
    else
        echo -e "${RED}Error al generar el mapa; se conserva el anterior.${NC}"
    fi
    read -rp "Presione Enter para continuar..."
}

# =========================================================
# 4. Assets: fuentes y relieve (el sprite se versiona en el repo)
# =========================================================
setup_assets() {
    echo -e "${YELLOW}--- Fuentes Roboto y relieve ---${NC}"
    bash "$BASE_DIR/scripts/install-roboto-fonts.sh" "$ENV_FILE"
    bash "$BASE_DIR/scripts/build-terrain.sh" "$ENV_FILE"
    echo -e "${GREEN}✓ Assets listos.${NC}"
    read -rp "Presione Enter para continuar..."
}

# =========================================================
# 5. Generar/Actualizar config.json dinámicamente
# =========================================================
update_config() {
    echo -e "${YELLOW}Recargando TileServer (config.json, estilos y mapa)...${NC}"
    bash "$BASE_DIR/scripts/reload-maps.sh" "$ENV_FILE"
    read -rp "Presione Enter para continuar..."
}

# =========================================================
# 6. Logs
# =========================================================
show_logs() {
    echo -e "${YELLOW}Servicio [gateway/mapas/rutas/todos] (default: gateway)${NC}"
    read -rp "> " svc
    local color
    color="$(grep -q routing-green "$BASE_DIR/gateway/state/routing-upstream.conf" 2>/dev/null && echo green || echo blue)"
    case "${svc:-gateway}" in
        mapas)  bash "$BASE_DIR/scripts/logs.sh" "$ENV_FILE" maps ;;
        rutas)  bash "$BASE_DIR/scripts/logs.sh" "$ENV_FILE" "routing-$color" ;;
        todos)  docker compose --env-file "$ENV_FILE" -f "$BASE_DIR/docker-compose.yml" logs -f --tail 50 ;;
        *)      bash "$BASE_DIR/scripts/logs.sh" "$ENV_FILE" gateway ;;
    esac
}

# =========================================================
# 7. Diagnóstico Rápido
# =========================================================
diagnostico() {
    echo -e "${BLUE}=== Diagnóstico del Servidor de Mapas ===${NC}"
    echo ""
    
    # Servicios
    echo -e "${YELLOW}Servicios Docker:${NC}"
    docker compose --env-file "$ENV_FILE" -f "$BASE_DIR/docker-compose.yml" ps
    echo ""

    # MBTiles
    echo -e "${YELLOW}MBTiles disponibles:${NC}"
    ls -lh "$DATA_DIR/mbtiles/" 2>/dev/null || echo "  (ninguno)"
    echo ""

    # Sprites
    echo -e "${YELLOW}Sprites:${NC}"
    ls "$DATA_DIR/sprites/" 2>/dev/null || echo "  (ninguno)"
    echo ""

    # Fonts (primeras 5)
    echo -e "${YELLOW}Fuentes (muestra):${NC}"
    ls "$DATA_DIR/fonts/" 2>/dev/null | head -5 || echo "  (ninguna)"
    echo ""

    # URLs
    local PORT="${MAPS_PORT:-8085}"
    echo -e "${YELLOW}URLs:${NC}"
    echo "  Mapa (local):   http://localhost:$PORT"
    echo "  Mapa (remoto):  ${MAPS_PUBLIC_URL:-https://mapas.ejemplo.cl}"
    echo ""

    # Health check
    echo -e "${YELLOW}Health check (gateway):${NC}"
    curl -s -o /dev/null -w "  HTTP %{http_code}\n" http://localhost:$PORT/health 2>/dev/null || echo "  No accesible"
    echo ""

    read -rp "Presione Enter para continuar..."
}

# =========================================================
# Menú Principal
# =========================================================
while true; do
    show_banner
    show_status

    echo -e "${BLUE}Menú Principal:${NC}"
    echo " 1) Seleccionar País Activo (Rutas)"
    echo " 2) Descargar Datos OSM (.pbf)"
    echo " 3) Generar mapa (Planetiler)"
    echo " 4) Fuentes y relieve"
    echo " 5) Recargar mapas (config.json, estilos)"
    echo " 6) Diagnóstico Rápido"
    echo " 7) Ver Logs"
    echo " 8) Levantar todo"
    echo " 9) Detener Todo"
    echo " u) Actualizar datos desde OSM (sin cortar el servicio)"
    echo " s) Estado y atraso de los datos"
    echo " 0) Salir"
    echo ""
    read -rp "Seleccione una opción: " opt

    case $opt in
        1) select_country ;;
        2) download_data ;;
        3) generate_mbtiles ;;
        4) setup_assets ;;
        5) update_config ;;
        6) diagnostico ;;
        7) show_logs ;;
        8) bash "$BASE_DIR/scripts/up.sh" "$ENV_FILE" ;;
        9) bash "$BASE_DIR/scripts/down.sh" "$ENV_FILE" ;;
        u) bash "$BASE_DIR/scripts/update.sh" "$ENV_FILE"; read -rp "Presione Enter para continuar..." ;;
        s) bash "$BASE_DIR/scripts/status.sh" "$ENV_FILE"; read -rp "Presione Enter para continuar..." ;;
        0) echo -e "${GREEN}Hasta luego!${NC}"; exit 0 ;;
        *) echo -e "${RED}Opción no válida${NC}"; sleep 1 ;;
    esac
done

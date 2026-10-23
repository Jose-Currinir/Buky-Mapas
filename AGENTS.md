# AGENTS.md — Buky-Mapas

> **Fuente canónica para TODA IA de codificación** (Claude Code, Codex, Cursor, Copilot, etc.).
> `CLAUDE.md`, `.cursor/rules/` y `.github/copilot-instructions.md` son punteros finos a este
> archivo: **no dupliques reglas, edítalas aquí.**

---

## 1. Qué es

**Buky-Mapas** — servicio de mapas/routing de Butake

- Tipo: `service` · Familia: `infra` · Visibilidad: `PRIVATE`
- Parte del ecosistema **Butake** (Butake SpA).

Servicio de infraestructura que publica mapas vectoriales (TileServer GL) y cálculo de rutas
(GraphHopper) para las apps Butake. Lo consumen Buky-Mesh y Newy-Notificacion. Se despliega
aparte con Docker Compose y se expone por Cloudflare Tunnel en `mapas.ejemplo.cl` y
`rutas.ejemplo.cl`.

## 2. Arquitectura

- `docker-compose.yml`: `gateway` (nginx, `gateway/nginx.conf`, única puerta publicada y la que
  usan los clientes internos en la red `butake-service-shared`), `maps` (TileServer GL light
  4.4.2, una instancia) y `routing-blue` / `routing-green` (GraphHopper 11.0, uno activo a la vez;
  el color activo vive en `gateway/state/`, fuera de git). Imágenes arm64 para AWS t4g.
- `data/styles/`: los dos únicos estilos publicados, `cl-light` y `cl-dark` (Chile).
- `data/sprites/`: sprite `cl`. `data/fonts/`: Roboto Regular y Medium (en git).
- `data/config.yml` + `data/car_avoid.json`: perfiles `car` y `car_custom` de GraphHopper.
- `data/config.json`: lo genera `scripts/render-tileserver-config.sh`; no editarlo a mano.
- Pesados fuera de git y reconstruibles con scripts: `data/mbtiles/`, `data/countries/` (y
  temporales `data/sources/`, `data/terrain/`).

## 3. Cómo correrlo

```bash
./manage.sh install --dev      # prepara datos y levanta (idempotente); --prod --url URL en servidor
./manage.sh status             # contenedores, color de rutas y atraso frente a OSM
./manage.sh update             # actualiza mapa y rutas desde OSM sin cortar el servicio
./scripts/smoke.sh .env        # valida sin levantar
```

Variables documentadas en `docs/operacion.md` (sección Configuración).

## 4. Convenciones

- Los estilos usan rutas relativas (`/data/openmaptiles.json`, sprite por nombre, `{fontstack}/{range}.pbf`);
  TileServer las vuelve absolutas con `MAPS_PUBLIC_URL`. No fijar dominios en los estilos.
- Un estilo nuevo se registra en `render-tileserver-config.sh` y en `validate-data.sh`.
- `cl-light` y `cl-dark` se generan con `scripts/gen-styles.py`; no editarlos a mano. Sus
  colores están medidos sobre capturas de referencia: cambiar un color exige volver a medirlo,
  no estimarlo. Los zooms del generador están en zoom de referencia (MapLibre = referencia − 1).
- No se publican estilos de ejemplo ni con marcas de terceros: solo `cl-light` y `cl-dark`.
- Fuentes de los estilos como `mbtiles://{id}`, nunca `/data/x.json` (TileServer no reescribe las
  rutas relativas y los clientes externos no cargan los tiles).
- Cambiar `config.yml` o `car_avoid.json` exige reimportar el grafo: `./scripts/update-routing.sh .env`.
- Actualizar datos siempre con `./manage.sh update` (o sus scripts): nunca reiniciar `maps` ni
  borrar volúmenes de rutas a mano en producción, porque corta el servicio.
- Rendimiento: medir antes de optimizar. Fusionar capas con estilo por datos y zoom resultó más
  lento; mantener capas separadas con pintura constante. TileServer ya envía CORS: el gateway no
  debe agregar `Access-Control-Allow-Origin` (duplicada, los navegadores la rechazan).
- Scripts bash con `set -euo pipefail` y helpers de `scripts/lib/common.sh`.

## 5. Estado y pendientes

- Listo: stack Compose, validaciones, cinco estilos, perfiles de routing con zonas a evitar.
- Sin tests automáticos ni CI: la validación es `smoke.sh` y revisión manual.
- Pendientes de infraestructura (caché en Cloudflare, raster 500, GraphHopper sin auth):
  ver `docs/operacion.md`.

---

## Reglas no negociables (estándar Butake)

- **Verificar antes de decir "listo"**: compilar / correr tests y reportar la salida real.
- **Commit/push solo cuando el usuario lo pida**; si trabajas en `main`, crea rama primero.
- **No tocar** secretos, `.env`, claves ni migraciones aplicadas.
- **No vender humo**: si algo es scaffold o está bloqueado, dilo.

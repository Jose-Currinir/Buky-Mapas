# Operación de Buky-Mapas

Guía técnica: contrato operativo, instalación, actualización, estilos, datos, rutas,
configuración, scripts y rendimiento. La presentación del proyecto está en el
[README](../README.md).

## Contrato operativo

| Área | Valor |
|---|---|
| Repositorio | `Jose-Currinir/Buky-Mapas` |
| Runtime | Docker Compose standalone, Ubuntu Server 22.04/24.04 (amd64 o arm64) |
| Servicios | `gateway` (nginx, única puerta publicada), `maps` (TileServer GL light), `routing-blue` / `routing-green` (GraphHopper; corre uno a la vez) |
| Red compartida | `butake-service-shared` (externa; `up.sh` la crea si falta) |
| Clientes internos | `butake-service-maps-gateway:8080` (mapas) y `:8081` (rutas) en la red compartida |
| Hosts públicos | `mapas.ejemplo.cl`, `rutas.ejemplo.cl` (vía Cloudflare Tunnel al gateway) |
| Puertos | gateway: mapas `8085` dev / `8080` prod; rutas `8989` |
| Health | `GET /health` en ambos puertos del gateway |
| Datos críticos | `.mbtiles`, `.osm.pbf`, `data/config.yml`, `data/car_avoid.json`, estilos, sprite y fuentes |

## Qué trae el repo y qué se genera

Todo lo necesario para operar está en el repo o se reconstruye con sus scripts desde fuentes
públicas, sin pasos manuales:

| Pieza | Dónde | Cómo se obtiene |
|---|---|---|
| Estilos `cl-light`, `cl-dark` | `data/styles/` (en git) | `scripts/gen-styles.py` |
| Sprite `cl` | `data/sprites/` (en git) | `scripts/poi-sprite-build/` |
| Fuentes Roboto | `data/fonts/` (en git) | `scripts/install-roboto-fonts.sh` |
| Configuración de rutas | `data/config.yml`, `data/car_avoid.json` (en git) | a mano |
| Extracto OSM (`.osm.pbf`, ~350 MB) | `data/countries/<país>/` | `scripts/fetch-pbf.sh` (Geofabrik) |
| Mapa base (`.mbtiles`, ~630 MB) | `data/mbtiles/` | `scripts/build-tiles.sh` (Planetiler) |
| Relieve (~150 MB) | `data/mbtiles/terrain.mbtiles` | `scripts/build-terrain.sh` (AWS Open Data) |
| Áreas urbanas (~20 MB) | `data/mbtiles/natural_earth.mbtiles` | `scripts/fetch-natural-earth.sh` |

Los archivos pesados quedan fuera de git (GitHub no admite archivos de más de 100 MB).

## Instalar en un servidor

En un Ubuntu Server limpio (EC2 t4g.large o un servidor propio):

```bash
git clone https://github.com/Jose-Currinir/Buky-Mapas.git
cd Buky-Mapas
./manage.sh install --prod --url https://mapas.ejemplo.cl
```

`install` es idempotente: instala Docker si falta (la primera vez pide volver a entrar a la
sesión y ejecutarlo de nuevo), crea `.env` desde la plantilla, descarga y genera solo los datos que
falten, y levanta el stack. La primera vez tarda unos 15 minutos y necesita ~3 GB de disco libre
además de los datos.

En local (desarrollo): `./manage.sh install --dev`. Luego `http://localhost:8085` (visor de
TileServer) y `http://localhost:8989/maps/` (UI de GraphHopper).

## Actualizar sin cortar el servicio

```bash
./manage.sh update        # descarga el extracto nuevo de OSM, regenera mapa y rutas
./manage.sh status        # contenedores, color de rutas y atraso de los datos
./manage.sh programar     # actualización automática todos los domingos a las 04:00 (systemd)
```

`update` no hace nada si Geofabrik no publicó un extracto nuevo. Si lo hay:

1. **Mapa:** Planetiler genera el `.mbtiles` en un archivo aparte; al terminar lo reemplaza y
   recarga TileServer (una sola instancia). Mientras se recarga, el gateway responde desde su
   caché; cuando TileServer ya responde con el mapa nuevo, se vacía la caché.
2. **Rutas (azul/verde):** el color inactivo importa el grafo nuevo en su propio volumen mientras
   el activo sigue atendiendo. Se prueba con una ruta real, el gateway cambia en caliente y el
   color anterior se detiene conservando su grafo (`./manage.sh rutas-volver` para volver atrás).

Durante la importación corren los dos colores de GraphHopper: el activo en reposo (~2 GB) y el que
importa, hasta `ROUTING_MEMORY_LIMIT` (6 GB en el ejemplo de producción). Hacen falta 12 GB o más
(t4g.xlarge, 16 GB). En máquinas de 8 GB,
`ROUTING_ZERO_DOWNTIME=0` en `.env` reimporta en el mismo color, con unos minutos sin rutas. Los navegadores y Cloudflare guardan los tiles hasta un día, así que el
mapa nuevo se ve como mucho al día siguiente en clientes que ya lo tenían en caché.

## Estilos publicados

El servidor publica solo dos estilos para Chile, en tema claro y oscuro:

| ID | Nombre | URL |
|---|---|---|
| `cl-light` | Light | `https://mapas.ejemplo.cl/styles/cl-light/style.json` |
| `cl-dark` | Dark | `https://mapas.ejemplo.cl/styles/cl-dark/style.json` |

Ambos usan el esquema OpenMapTiles, el sprite `cl`, las fuentes Roboto Regular y Medium, y las
fuentes de datos `openmaptiles`, `natural_earth` y `terrain` (relieve). Las fuentes de datos se
declaran como `mbtiles://{id}` para que TileServer las publique con URL absoluta: con rutas
relativas, los clientes de otros dominios no cargan los tiles. Los clientes deberían obtener el
catálogo desde su backend en vez de fijar URLs en cada cliente.

Incluyen:

- suelo natural, mancha urbana, zona comercial, parques, hospitales, aeropuertos y agua;
  relieve sombreado hasta z13;
- jerarquía vial: calles gris azulado, autopistas azul pizarra, abreviaturas ("Av.", "Pje.",
  "Diag."), escudos de ruta y flechas de sentido;
- POI con chinchetas por categoría y punto para los menos importantes; metro y paradas de bus;
- comunas en tipografía normal y barrios en mayúsculas.

Limitaciones de los datos de OSM: los POI se eligen por clase, no por popularidad; algunas plazas
no tienen polígono de parque; las comunas no vienen en los tiles de z10, y los tiles cubren solo
Chile.

### Regenerar estilos y sprite

```bash
python3 scripts/gen-styles.py                                           # cl-light / cl-dark
(cd scripts/poi-sprite-build && npm install && node gen-poi-sprite.mjs) # sprite cl
```

Los estilos referencian el sprite por nombre (`cl`), nunca por dominio. Si cambia el sprite y
Cloudflare sirve uno viejo, purga la caché de `/styles/*/sprite*`.

## Fuentes de datos y actualización

| ID | Nombre | Contenido | Origen |
|---|---|---|---|
| `openmaptiles` | Chile | calles, edificios, lugares y nombres | `.mbtiles` OpenMapTiles generado desde OSM |
| `natural_earth` | Áreas urbanas | manchas urbanas a zoom bajo | Natural Earth |
| `terrain` | Relieve | elevación para el relieve sombreado | `./scripts/build-terrain.sh` |

Los nombres viven en los metadatos de cada `.mbtiles` (`./scripts/label-tilesets.sh`) y se
publican en su TileJSON. El índice web de TileServer 4.4.2 no los muestra en la sección de datos.

Para saber qué tan actualizados están el mapa y las rutas frente a OpenStreetMap:

```bash
python3 scripts/data-status.py           # fecha de los datos y diffs diarios de atraso
python3 scripts/data-status.py --contar  # además, cuántos elementos y calles cambiaron (descarga los diffs)
```

Compara la marca de replicación de OSM del `.mbtiles` y del `.osm.pbf` con la última publicada
por Geofabrik. Para ponerse al día: descargar un `.pbf` nuevo (`manage.sh`, opción 2) y regenerar
el mapa con `./scripts/build-tiles.sh .env` (o la opción 3). Usa Planetiler, el mismo esquema
OpenMapTiles de los estilos; genera en un archivo aparte sin cortar el servicio, guarda la marca
de replicación y, al terminar, reinicia TileServer y vacía la caché del gateway. Cambiar el `.pbf`
`./manage.sh update` hace todo el ciclo sin cortar el servicio.

## Routing y zonas a evitar

[`data/config.yml`](../data/config.yml) define dos perfiles:

- `car`: ruta más rápida, preparada con Contraction Hierarchies (CH).
- `car_custom`: mismo vehículo con el modelo [`data/car_avoid.json`](../data/car_avoid.json), que
  penaliza zonas. Se prepara con CH (consultas rápidas con el modelo fijo) y con Landmarks (LM),
  que permiten ajustar el modelo por request (`POST /route` con `"ch.disable": true`).

`car_avoid.json` tiene dos partes:

- `areas`: diccionario `nombre → Feature` (polígono GeoJSON en `[lon, lat]`).
- `priority`: reglas `if in_<nombre> → multiply_by`. `0` bloquea la zona; `0.05` la desincentiva
  pero permite pasar si no hay alternativa.

El polígono incluido es un **ejemplo** sobre el centro de Santiago.

```bash
curl "https://rutas.ejemplo.cl/route?point=-33.45,-70.66&point=-33.42,-70.60&profile=car_custom&points_encoded=false"
```

> ⚠️ Cambiar `config.yml` o `car_avoid.json` exige reconstruir el grafo: borra el volumen
> grafo: `./scripts/update-routing.sh .env` lo reimporta en el otro color sin cortar el servicio.

## Configuración

Plantillas: [`.env.dev.example`](../.env.dev.example), [`.env.prod.example`](../.env.prod.example) y
[`.env.example`](../.env.example). Ninguna contiene secretos.

| Variable | Para qué sirve |
|---|---|
| `MAPS_PUBLIC_URL` | URL pública que TileServer usa para volver absolutas las rutas de los estilos |
| `MAPS_PRIMARY_TILESET` / `MAPS_BACKGROUND_TILESET` | `.mbtiles` de `openmaptiles` y `natural_earth` |
| `ACTIVE_COUNTRY` | carpeta de `data/countries/` que usa GraphHopper |
| `MAPS_BIND_HOST` / `ROUTING_BIND_HOST` | interfaz donde se publican los puertos |
| `ROUTING_JAVA_OPTS`, `*_MEMORY_LIMIT` | memoria de cada contenedor |
| `DATA_PATH` | raíz de datos montada en los contenedores |

`data/config.json` (configuración de TileServer) lo genera
`scripts/render-tileserver-config.sh` en cada `up.sh`: edita el script, no el JSON.

## Estructura

```text
Buky-Mapas/
├── docker-compose.yml          # gateway, maps y routing
├── gateway/nginx.conf          # compresión, Cache-Control, caché y límite de peticiones
├── manage.sh                   # CLI interactiva: países, .pbf, .mbtiles, assets, logs
├── install_docker.sh           # instalación de Docker en Ubuntu 24.04
├── scripts/
│   ├── install.sh · update.sh · up.sh · down.sh · status.sh · logs.sh · smoke.sh
│   ├── fetch-pbf.sh · build-tiles.sh · reload-maps.sh · update-routing.sh · install-timer.sh
│   ├── validate-env.sh · validate-data.sh · render-tileserver-config.sh
│   ├── install-roboto-fonts.sh · build-terrain.sh
│   ├── gen-styles.py
│   ├── poi-sprite-build/       # generador del sprite cl (Node + sharp)
│   └── lib/common.sh
└── data/
    ├── config.yml              # GraphHopper
    ├── car_avoid.json          # modelo de zonas a evitar
    ├── config.json             # TileServer (generado)
    ├── styles/                 # estilos MapLibre versionados
    ├── sprites/                # sprite cl
    └── fonts/ mbtiles/ countries/              # pesados, fuera de git
```

## Scripts

| Script | Qué hace |
|---|---|
| `up.sh` | valida entorno y datos, renderiza `config.json`, levanta y espera a que estén `healthy` |
| `down.sh` | detiene el stack |
| `status.sh` | estado de los contenedores |
| `logs.sh <env> <servicio>` | sigue los logs (`gateway`, `maps`, `routing-blue`, `routing-green`) |
| `install.sh` | prepara un servidor nuevo y levanta todo (`./manage.sh install`) |
| `update.sh` | actualiza mapa y rutas desde OSM sin cortar el servicio (`./manage.sh update`) |
| `fetch-pbf.sh` | descarga el extracto OSM nuevo a `map.osm.pbf.new`, verificando el MD5 |
| `reload-maps.sh` | recarga TileServer sirviendo desde caché y vacía la caché al terminar |
| `update-routing.sh` | GraphHopper azul/verde; `--volver` regresa al color anterior |
| `fetch-natural-earth.sh` | descarga `natural_earth.mbtiles` verificando el SHA-256 |
| `install-timer.sh` | temporizador systemd semanal (`./manage.sh programar`) |
| `smoke.sh` | validaciones de entorno, datos y Compose, sin levantar nada |
| `validate-env.sh` / `validate-data.sh` | fallan temprano si falta una variable o un archivo |
| `install-roboto-fonts.sh` | descarga los glifos Roboto Regular y Medium de los estilos |
| `build-terrain.sh` | construye `terrain.mbtiles` (relieve) desde Terrain Tiles de AWS |
| `build-tiles.sh` | regenera el mapa base desde el `.osm.pbf` con Planetiler |
| `label-tilesets.sh` | nombres y descripciones de las fuentes de datos |
| `data-status.py` | atraso de los datos frente a OSM; `--contar` cuenta los cambios pendientes |

## Producción en AWS t4g (ARM64)

Las dos imágenes publican variante `arm64`, así que corren nativas en Graviton:
`maptiler/tileserver-gl:v4.4.2` y `israelhikingmap/graphhopper:11.0`. GraphHopper 7.0, la versión
anterior, solo existía para `amd64`.

Medido en local (arm64, Chile completo, perfiles `car` + `car_custom`):

| Servicio | RAM en uso | Arranque |
|---|---|---|
| routing | ~2,5 GB (con `-Xmx3g`) | ~1,5 min importando el grafo la primera vez |

Ojo: con `ROUTING_MEMORY_LIMIT=3G` el heap no es 3 GB sino el 75 % (2,25 GB), y ahí la importación
de Chile se cae por falta de memoria (visto en Ubuntu amd64). Con 6 GB importa en
~2 min y en reposo queda en ~2 GB.
| maps | ~250 MB | segundos |

Con esas cifras, un `t4g.large` (8 GB) basta con `ROUTING_ZERO_DOWNTIME=0`; para actualizar sin
caída, `t4g.xlarge` (16 GB).
Ajusta `ROUTING_MEMORY_LIMIT` y `ROUTING_JAVA_OPTS` según la instancia.

## Gateway y rendimiento

`gateway/nginx.conf` es la única puerta publicada:

- comprime JSON y glifos (los tiles ya vienen comprimidos desde el `.mbtiles`);
- `Cache-Control` por recurso: tiles 1 día en navegador y 7 en CDN, fuentes 7 días, sprites 1
  hora, estilos y TileJSON 5 minutos (llevan URLs absolutas de `MAPS_PUBLIC_URL`);
- caché propia en disco (volumen `maps_cache`, hasta 2 GB): TileServer solo atiende lo que no
  está cacheado; la respuesta trae `X-Cache-Status`;
- límite de 10 rutas por segundo por IP (ráfagas de 20, luego HTTP 429), usando la IP real que
  envía Cloudflare (`CF-Connecting-IP`).

Los contenedores de la red `butake-service-shared` llaman al gateway: `butake-service-maps-gateway:8080` (mapas) y `:8081` (rutas). TileServer y
GraphHopper quedan solo en la red interna del stack, porque el color de rutas cambia al actualizar.

Medido en local (arm64), carga en frío de un mapa, sin contar MapLibre ni tiles:

| Recurso | Antes | Ahora |
|---|---|---|
| Estilo | 48 KB | 6 KB |
| Sprite (@2x, PNG + JSON) | 166 KB | 21 KB |
| Glifos (juegos de fuentes) | 240–300 KB (4) | 83–93 KB (2) |
| TileJSON | 26 KB | 4 KB |
| RAM de TileServer | 328 MB | 44 MB (variante light, sin render raster) |
| Respuesta desde caché | 4–12 ms | <1 ms |

Probado y descartado: fusionar las capas de vías en capas con estilo por datos bajó el estilo de
79 a 46 capas pero hizo el render un 20 % más lento (las expresiones por zoom y por dato se
evalúan por feature). Las capas separadas con pintura constante rinden mejor.

Cambiar `MAPS_PUBLIC_URL` exige recrear TileServer y vaciar la caché: `./manage.sh up` seguido de
`./manage.sh reload`.

### Abrir el mapa desde otro dispositivo de la red local

En `.env`: `MAPS_BIND_HOST=0.0.0.0`, `ROUTING_BIND_HOST=0.0.0.0` y
`MAPS_PUBLIC_URL=http://<IP-del-equipo>:8085`. Luego `./manage.sh up` y abre
`http://<IP-del-equipo>:8085/styles/cl-light/` desde un dispositivo del mismo Wi-Fi.

## Infraestructura en Cloudflare

Vive fuera del repo; se deja escrita para poder rehacerla:

1. **Túnel.** `mapas.ejemplo.cl` → `http://127.0.0.1:8085` y `rutas.ejemplo.cl` →
   `http://127.0.0.1:8989`, en el túnel de Cloudflare del servidor. Con
   `MAPS_BIND_HOST=127.0.0.1` y `ROUTING_BIND_HOST=127.0.0.1` nada queda expuesto fuera del túnel.
2. **Caché.** Cloudflare no cachea `.pbf` por defecto: una Cache Rule para `mapas.ejemplo.cl` con
   rutas `/data/`, `/styles/` y `/fonts/`, *Eligible for cache* y TTL respetando el origen
   (que ya envía `Cache-Control`). Comprobación: el segundo pedido de un tile da `cf-cache-status: HIT`.

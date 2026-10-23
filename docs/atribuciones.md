# Atribuciones y licencias de terceros

Buky-Mapas usa datos, fuentes, íconos y programas de terceros. Cada uno conserva su licencia.

## Datos

| Datos | Uso | Licencia | Atribución obligatoria |
|---|---|---|---|
| [OpenStreetMap](https://www.openstreetmap.org/) (extractos de [Geofabrik](https://download.geofabrik.de/)) | mapa base y rutas | [ODbL 1.0](https://opendatacommons.org/licenses/odbl/) | © colaboradores de OpenStreetMap |
| Esquema [OpenMapTiles](https://openmaptiles.org/) | estructura de los tiles vectoriales | [CC-BY 4.0](https://github.com/openmaptiles/openmaptiles/blob/master/LICENSE.md) (esquema); código BSD-3 | © OpenMapTiles |
| [Natural Earth](https://www.naturalearthdata.com/) ([naturalearthtiles](https://github.com/lukasmartinelli/naturalearthtiles)) | áreas urbanas a zoom bajo | dominio público | no |
| [Terrain Tiles](https://registry.opendata.aws/terrain-tiles/) (AWS Open Data, Mapzen) | relieve sombreado | [varias fuentes abiertas](https://github.com/tilezen/joerd/blob/master/docs/attribution.md) | Mapzen y fuentes indicadas |

Los mapas publicados deben mostrar «© OpenMapTiles © colaboradores de OpenStreetMap». Los
estilos `cl-light` y `cl-dark` la incluyen en el TileJSON y MapLibre la muestra por defecto.

## Fuentes e íconos (incluidos en el repo)

| Recurso | Dónde | Licencia |
|---|---|---|
| Glifos de Roboto Regular y Medium (vía [fonts.pbf](https://github.com/korywka/fonts.pbf)) | `data/fonts/` | [Apache 2.0](https://www.apache.org/licenses/LICENSE-2.0) |
| Íconos [Material Symbols](https://github.com/marella/material-symbols) usados en el sprite `cl` | `data/sprites/` | [Apache 2.0](https://www.apache.org/licenses/LICENSE-2.0) |

## Programas (imágenes Docker, no incluidos en el repo)

| Programa | Licencia |
|---|---|
| [TileServer GL](https://github.com/maptiler/tileserver-gl) | BSD-2 |
| [GraphHopper](https://github.com/graphhopper/graphhopper) | Apache 2.0 |
| [Planetiler](https://github.com/onthegomap/planetiler) | Apache 2.0 |
| [nginx](https://nginx.org/) | BSD-2 |
| [MapLibre GL JS](https://github.com/maplibre/maplibre-gl-js) (visor de TileServer) | BSD-3 |

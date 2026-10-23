#!/usr/bin/env python3
"""Genera cl-light.json y cl-dark.json: estilos MapLibre (esquema OpenMapTiles)
para Chile, en tema claro y oscuro.

Los colores y anchos de vía se midieron píxel a píxel sobre capturas de
referencia en Santiago, Viña del Mar, la cordillera y el desierto, de z6 a z18.

Zoom: las paradas de este archivo están en zoom de referencia (tiles de 256 px).
MapLibre usa tiles de 512 px, así que el zoom Z de referencia equivale al zoom
Z-1 de MapLibre; gz() hace la conversión.

Uso:  python3 scripts/gen-styles.py
Salida: data/styles/cl-light.json, data/styles/cl-dark.json
"""
import json
import os

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
STYLES_DIR = os.path.join(BASE_DIR, "data/styles")
OMT = "openmaptiles"


def gz(z):
    """Zoom de referencia (tiles de 256 px) -> zoom de MapLibre."""
    return z - 1


# --------------------------------------------------------------------------
# Paletas medidas
# --------------------------------------------------------------------------
LIGHT = {
    "name": "Light",
    "sprite_theme": "light",
    # suelo
    "natural": "#f5f0e5",          # suelo sin vegetación (desierto, campo seco)
    "urban_low": "#f7f7f7",        # área urbana a zoom bajo
    "urban": "#f5f3f3",            # área urbana z13-z16
    "urban_high": "#f8f7f7",       # aceras/área urbana z18
    "vegetation": "#d3f8e2",       # vegetación natural
    "vegetation_dense": "#c5f2d6",
    "rock": "#e3ded5",
    "sand": "#f6efdb",
    "glacier": "#ffffff",
    "park": "#c3f1d5",
    "park_path": "#80cdb0",
    "cemetery": "#a9eac2",
    "commercial": "#f8f0de",
    "hospital": "#fce8e6",
    "airport": "#e0e8f7",
    "runway": "#ffffff",
    # relieve: en claro oscurece con marrones cálidos sobre el beige
    "hill_shadow": "#9c8763",
    "hill_highlight": "#fffcf3",
    "hill_accent": "#c9b896",
    "hill_strength": 0.24,
    # agua
    "water": ["interpolate", ["linear"], ["zoom"], gz(6), "#78d5ea", gz(10), "#90daee"],
    "waterway": "#90daee",
    # edificios
    "building": "#fdf9ef",
    "building_outline": "#e9dfc9",
    # vías
    "minor": ["interpolate", ["linear"], ["zoom"], gz(16), "#d8e0e7", gz(18), "#e8e9ed"],
    "major": ["interpolate", ["linear"], ["zoom"], gz(16), "#d8e0e7", gz(18), "#c1ccd8"],
    "major_casing": "#c7d0d7",
    "service": "#e3e8ed",
    "pedestrian": "#e8eaee",
    "path": "#c9d3dc",
    "motorway": ["interpolate", ["linear"], ["zoom"], gz(9), "#9db0cf", gz(12), "#a2b5d2", gz(13.5), "#8aa4c0"],
    "motorway_casing": "#7090b2",
    "rail": "#c4ccd5",
    "boundary_country": "#9aa3ad",
    "boundary_region": "#b9c0c8",
    # texto
    "text_city": "#202124",
    "text_town": "#3c4043",
    "text_suburb": "#5f6368",
    "text_road": "#354557",
    "text_water": "#3d84b8",
    "text_park": "#1a8660",
    "text_country": "#3c4043",
    "halo": "#ffffff",
    "halo_water": "#d6f1fa",
    "shield_text": "#202124",
    # POI: chincheta (pin) y texto por categoría
    "poi": {
        "food":      {"pin": "#ff8126", "text": "#d65a01"},
        "shop":      {"pin": "#0597ff", "text": "#1c74e8"},
        "lodging":   {"pin": "#f848c7", "text": "#e32aae"},
        "culture":   {"pin": "#b56aff", "text": "#8343d3"},
        "park":      {"pin": "#17a773", "text": "#1a8660"},
        "health":    {"pin": "#f74a55", "text": "#d93025"},
        "transport": {"pin": "#4286f3", "text": "#1967d2"},
        "service":   {"pin": "#848e96", "text": "#5f6368"},
    },
}

DARK = {
    "name": "Dark",
    "sprite_theme": "dark",
    "natural": "#2c3246",
    "urban_low": "#1c2a40",
    "urban": "#1c2a40",
    "urban_high": "#1c2a40",
    "vegetation": "#133949",
    "vegetation_dense": "#12313e",
    "rock": "#3d4457",
    "sand": "#30374d",
    "glacier": "#4b5469",
    "park": "#144a57",
    "park_path": "#518e6b",
    "cemetery": "#155361",
    "commercial": "#23314f",
    "hospital": "#3d3d57",
    "airport": "#2e476d",
    "runway": "#273f62",
    # en oscuro aclara las laderas iluminadas y oscurece las sombras
    "hill_shadow": "#161a26",
    "hill_highlight": "#6a7490",
    "hill_accent": "#262c40",
    "hill_strength": 0.3,
    "water": "#00102e",
    "waterway": "#00102e",
    "building": "#313e6e",
    "building_outline": "#2a3763",
    "minor": ["interpolate", ["linear"], ["zoom"], gz(16), "#3c4d62", gz(18), "#2c3a4f"],
    "major": "#3e5a77",
    "major_casing": "#080b10",
    "service": "#324054",
    "pedestrian": "#28384c",
    "path": "#3a4b61",
    "motorway": "#47688a",
    "motorway_casing": "#141c28",
    "rail": "#3a4a60",
    "boundary_country": "#6d7b98",
    "boundary_region": "#4d5b78",
    "text_city": "#e8eaed",
    "text_town": "#c8cdd5",
    "text_suburb": "#9aa5b4",
    "text_road": "#c4ccd7",
    "text_water": "#6f8fc0",
    "text_park": "#7eb490",
    "text_country": "#c8cdd5",
    "halo": "#1c2a40",
    "halo_water": "#00102e",
    "shield_text": "#202124",
    "poi": {
        "food":      {"pin": "#f0b178", "text": "#f0b178"},
        "shop":      {"pin": "#74bcfe", "text": "#74bcff"},
        "lodging":   {"pin": "#ea8ec5", "text": "#ea8ec5"},
        "culture":   {"pin": "#d998f7", "text": "#d998f7"},
        "park":      {"pin": "#90c9a0", "text": "#7eb490"},
        "health":    {"pin": "#fd8e96", "text": "#fd8e96"},
        "transport": {"pin": "#74bcfe", "text": "#74bcff"},
        "service":   {"pin": "#b4bcc8", "text": "#aab4c3"},
    },
}

# --------------------------------------------------------------------------
# POI: clase OpenMapTiles -> (categoría, glifo del sprite)
# Debe coincidir con scripts/poi-sprite-build/gen-poi-sprite.mjs
# --------------------------------------------------------------------------
POI_CLASSES = {
    "food": {
        "restaurant": ["restaurant", "food_court"],
        "fastfood": ["fast_food"],
        "cafe": ["cafe"],
        "bar": ["bar", "beer", "pub", "biergarten", "nightclub"],
        "icecream": ["ice_cream"],
        "bakery": ["bakery", "confectionery"],
    },
    "shop": {
        "grocery": ["grocery", "supermarket", "convenience", "greengrocer", "butcher"],
        "mall": ["mall", "department_store"],
        "clothing": ["clothing_store", "shoes", "shoe_store", "jewelry", "jewelry_store"],
        "shop": ["shop", "books", "bicycle", "car", "florist", "furniture", "hairdresser",
                 "laundry", "optician", "electronics", "hardware", "mobile_phone", "gift",
                 "music", "toys", "sports", "stationery", "pet", "beauty", "cosmetics",
                 "doityourself", "garden_centre", "variety_store", "car_repair"],
    },
    "lodging": {
        "lodging": ["lodging", "hotel", "hostel", "motel", "guest_house", "apartment"],
    },
    "culture": {
        "museum": ["museum"],
        "gallery": ["art_gallery", "gallery", "arts_centre"],
        "theatre": ["theatre"],
        "cinema": ["cinema"],
        "attraction": ["attraction", "zoo", "aquarium", "theme_park", "viewpoint", "monument",
                       "castle", "memorial"],
    },
    "park": {
        "park": ["park", "garden", "dog_park", "picnic_site", "nature_reserve"],
        "golf": ["golf", "miniature_golf"],
        "sport": ["pitch", "stadium", "swimming", "sports_centre", "playground", "fitness",
                  "fitness_centre"],
    },
    "health": {
        "hospital": ["hospital"],
        "pharmacy": ["pharmacy", "chemist"],
        "clinic": ["doctors", "dentist", "clinic", "veterinary"],
    },
    "transport": {
        "airport": ["airport", "aerodrome", "airfield"],
        "fuel": ["fuel"],
        "parking": ["parking", "bicycle_parking"],
    },
    "service": {
        "school": ["school", "college", "university", "kindergarten"],
        "library": ["library"],
        "worship": ["place_of_worship"],
        "civic": ["town_hall", "townhall", "courthouse", "embassy", "government", "bank",
                  "police", "fire_station", "post", "office"],
    },
}


# OpenMapTiles solo trae un rank por clase, no por popularidad:
# los POI se eligen por niveles de importancia por clase.
TIER1 = ["museum", "attraction", "zoo", "aquarium", "theme_park", "stadium", "theatre",
         "mall", "department_store", "university", "college", "castle", "hospital", "airport"]
TIER2 = ["restaurant", "cafe", "bar", "fast_food", "lodging", "hotel", "cinema", "library",
         "place_of_worship", "supermarket", "park", "golf", "art_gallery", "arts_centre",
         "town_hall", "embassy", "bank", "ice_cream", "bakery", "pharmacy", "school", "fuel"]


def poi_lookup():
    """(clase -> ícono, clase -> categoría) como listas para expresiones match."""
    icon, cat = {}, {}
    for category, glyphs in POI_CLASSES.items():
        for glyph, classes in glyphs.items():
            for c in classes:
                icon.setdefault(c, glyph)
                cat.setdefault(c, category)
    return icon, cat


def match(prop, mapping, default):
    groups = {}
    for k, v in mapping.items():
        groups.setdefault(v, []).append(k)
    expr = ["match", ["get", prop]]
    for v, ks in groups.items():
        expr += [sorted(ks), v]
    expr.append(default)
    return expr


# --------------------------------------------------------------------------
# Utilidades de estilo
# --------------------------------------------------------------------------
def ramp(*stops, base=1.4):
    """Interpolación exponencial con paradas en zoom de referencia."""
    expr = ["interpolate", ["exponential", base], ["zoom"]]
    for z, v in zip(stops[::2], stops[1::2]):
        expr += [gz(z), v]
    return expr


def ramp_at(r, z):
    """Valor de una rampa exponencial en el zoom z (de MapLibre)."""
    base = r[1][1]
    zs, vs = r[3::2], r[4::2]
    if z <= zs[0]:
        return vs[0]
    if z >= zs[-1]:
        return vs[-1]
    for (z0, v0), (z1, v1) in zip(zip(zs, vs), zip(zs[1:], vs[1:])):
        if z0 <= z <= z1:
            t = (base ** (z - z0) - 1) / (base ** (z1 - z0) - 1)
            return round(v0 + (v1 - v0) * t, 3)


def by_zoom(build_output, *ramps):
    """Una sola interpolación por zoom (lo que exige MapLibre) cuyas salidas
    combinan varias rampas: build_output recibe los valores de cada rampa en
    esa parada y devuelve la expresión de salida (p. ej. un match)."""
    zs = sorted({z for r in ramps for z in r[3::2]})
    expr = ["interpolate", ["exponential", ramps[0][1][1]], ["zoom"]]
    for z in zs:
        expr += [z, build_output(*[ramp_at(r, z) for r in ramps])]
    return expr


def plus(width_expr, extra):
    """Mismo ancho de vía + extra (para bordes)."""
    out = list(width_expr[:3])
    for z, v in zip(width_expr[3::2], width_expr[4::2]):
        out += [z, round(v + extra, 2)]
    return out


NAME = ["coalesce", ["get", "name:es"], ["get", "name:latin"], ["get", "name"]]

# Tipo de vía abreviado: "Avenida Perú" -> "Av. Perú", "Pasaje" -> "Pje.", etc.
ABBREV = [("Avenida ", "Av. "), ("Pasaje ", "Pje. "), ("Diagonal ", "Diag. "),
          ("Paseo ", "P.º "), ("Plaza ", "Pl. "), ("Camino ", "Cno. ")]


def abbreviated(name):
    expr = ["case"]
    for long, short in ABBREV:
        expr += [["==", ["slice", name, 0, len(long)], long],
                 ["concat", short, ["slice", name, len(long)]]]
    expr.append(name)
    return expr
# Solo dos juegos de fuentes: cada uno es una descarga de glifos aparte por rango.
FONT_REG = ["Roboto Regular"]
FONT_MED = ["Roboto Medium"]

# Anchos de relleno (px CSS) medidos sobre la app.
W_MOTORWAY = ramp(6, 0.8, 8, 1.3, 10, 2, 12, 2.8, 14, 3.5, 15, 4.6, 16, 7, 17, 11, 18, 19, 19, 34)
W_TRUNK = ramp(7, 0.7, 9, 1.1, 11, 1.7, 12, 2.4, 14, 3.2, 15, 4.4, 16, 6.6, 17, 10.5, 18, 18, 19, 32)
W_PRIMARY = ramp(9, 0.6, 11, 1.1, 12, 1.9, 13, 3.1, 14, 5.3, 15, 7.7, 16, 12, 17, 20, 18, 34, 19, 60)
W_SECONDARY = ramp(11, 0.6, 12, 1.1, 13, 1.9, 14, 3.1, 15, 5, 16, 8.4, 17, 14, 18, 26, 19, 47)
W_MINOR = ramp(13, 0.4, 14, 1.2, 15, 2.3, 16, 4.2, 17, 8, 18, 15, 19, 28)
W_SERVICE = ramp(15, 0.6, 16, 1.4, 17, 3, 18, 6, 19, 11)
W_PEDESTRIAN = ramp(15, 0.8, 16, 1.6, 17, 3.2, 18, 6.5, 19, 12)
W_PATH = ramp(16, 0.6, 17, 1, 18, 1.6, 19, 2.4)

ROAD_CLASSES = [
    # (id, filtro de clase, ancho, color, borde, minzoom en zoom de referencia)
    # en OpenMapTiles las calles peatonales son class=path, subclass=pedestrian
    ("path", ["all", ["in", ["get", "class"], ["literal", ["path", "track"]]],
              ["!=", ["get", "subclass"], "pedestrian"]], W_PATH, "path", None, 16),
    ("pedestrian", ["all", ["==", ["get", "class"], "path"], ["==", ["get", "subclass"], "pedestrian"]],
     W_PEDESTRIAN, "pedestrian", None, 15),
    ("service", ["==", ["get", "class"], "service"], W_SERVICE, "service", None, 15),
    ("minor", ["==", ["get", "class"], "minor"], W_MINOR, "minor", None, 13),
    ("secondary", ["in", ["get", "class"], ["literal", ["secondary", "tertiary"]]], W_SECONDARY, "major", "major_casing", 11),
    ("primary", ["==", ["get", "class"], "primary"], W_PRIMARY, "major", "major_casing", 9),
    ("trunk", ["==", ["get", "class"], "trunk"], W_TRUNK, "motorway", "motorway_casing", 7),
    ("motorway", ["==", ["get", "class"], "motorway"], W_MOTORWAY, "motorway", "motorway_casing", 6),
]


def road_layers(p, brunnel):
    """Vías de un nivel (túnel, superficie o puente): primero todos los bordes,
    luego todos los rellenos (los cruces no se cortan)."""
    if brunnel == "tunnel":
        bf = ["==", ["get", "brunnel"], "tunnel"]
    elif brunnel == "bridge":
        bf = ["==", ["get", "brunnel"], "bridge"]
    else:
        bf = ["!", ["in", ["get", "brunnel"], ["literal", ["bridge", "tunnel"]]]]
    casings, fills = [], []
    for rid, cf, width, color, casing, minz in ROAD_CLASSES:
        kind = cf
        is_link = ["==", ["get", "ramp"], 1]
        base = {
            "type": "line",
            "source": OMT,
            "source-layer": "transportation",
            "minzoom": gz(minz),
            "layout": {"line-cap": "round", "line-join": "round"},
        }
        flt = ["all", bf, kind]
        if casing:
            # motorway/trunk: borde de 1 px CSS por lado; avenidas: hilo de 0.4 px
            extra = 2 if rid in ("motorway", "trunk") else 0.8
            casings.append({**base, "id": f"{brunnel}-{rid}-casing",
                            "minzoom": gz(max(minz, 12 if rid in ("motorway", "trunk") else 13)),
                            "filter": flt,
                            "paint": {"line-color": p[casing], "line-width": plus(width, extra),
                                      **({"line-opacity": 0.6} if brunnel == "tunnel" else {})}})
        paint = {"line-color": p[color], "line-width": width}
        if brunnel == "tunnel":
            paint["line-opacity"] = 0.55
        if rid in ("motorway", "trunk"):
            # ramplas: mismo color, 70 % del ancho
            paint["line-width"] = by_zoom(lambda v: ["case", is_link, round(0.7 * v, 3), v], width)
        if rid == "path":
            paint["line-dasharray"] = [2, 1.5]
        fills.append({**base, "id": f"{brunnel}-{rid}", "filter": flt, "paint": paint})
    return casings + fills


# --------------------------------------------------------------------------
# Construcción
# --------------------------------------------------------------------------
def build(p):
    icon_by_class, cat_by_class = poi_lookup()
    theme = p["sprite_theme"]
    category = match("class", cat_by_class, "service")

    def by_cat(field):
        expr = ["match", category]
        for c, v in p["poi"].items():
            expr += [c, v[field]]
        expr.append(p["poi"]["service"][field])
        return expr

    layers = []
    add = layers.append

    # ---- suelo ----
    # Suelo natural beige a zoom bajo; en la ciudad (zoom alto) el
    # suelo es gris aunque OSM no tenga polígono residencial (p. ej. el centro).
    add({"id": "background", "type": "background",
         "paint": {"background-color": ["interpolate", ["linear"], ["zoom"],
                                        gz(12.5), p["natural"], gz(14), p["urban"],
                                        gz(16.5), p["urban"], gz(18), p["urban_high"]]}})
    # cobertura natural en una sola capa: color por clase sin depender del zoom (barato)
    add({"id": "landcover", "type": "fill", "source": OMT, "source-layer": "landcover",
         "filter": ["in", ["get", "class"], ["literal", ["wood", "grass", "wetland", "farmland", "rock", "sand", "ice"]]],
         "paint": {"fill-color": ["match", ["get", "class"], "wood", p["vegetation_dense"], "rock", p["rock"],
                                  "sand", p["sand"], "ice", p["glacier"], p["vegetation"]],
                   "fill-antialias": False}})
    # mancha urbana a zoom bajo: OSM casi no trae polígonos residenciales en z<=12,
    # así que usamos las áreas urbanas de Natural Earth (gris urbano en z10)
    add({"id": "urban-areas", "type": "fill", "source": "natural_earth", "source-layer": "urban",
         "maxzoom": gz(14),
         "paint": {"fill-color": p["urban_low"], "fill-antialias": False,
                   "fill-opacity": ["interpolate", ["linear"], ["zoom"], gz(5), 0, gz(7), 1,
                                    gz(12.5), 1, gz(13.5), 0]}})
    add({"id": "landuse-urban", "type": "fill", "source": OMT, "source-layer": "landuse",
         "filter": ["in", ["get", "class"], ["literal", [
             "residential", "suburb", "quarter", "neighbourhood", "commercial", "retail",
             "industrial", "garages", "railway", "school", "university", "college",
             "kindergarten", "hospital", "library", "bus_station", "military", "dam"]]],
         "paint": {"fill-color": ["interpolate", ["linear"], ["zoom"],
                                  gz(12), p["urban_low"], gz(14), p["urban"],
                                  gz(16.5), p["urban"], gz(18), p["urban_high"]],
                   "fill-antialias": False}})
    add({"id": "landuse-commercial", "type": "fill", "source": OMT, "source-layer": "landuse",
         "minzoom": gz(11),
         "filter": ["in", ["get", "class"], ["literal", ["commercial", "retail"]]],
         # en z18 deja de pintarse la manzana y se colorean los edificios
         "paint": {"fill-color": p["commercial"],
                   "fill-opacity": ["interpolate", ["linear"], ["zoom"], gz(11), 0, gz(12.5), 1,
                                    gz(16.5), 1, gz(17.5), 0]}})
    add({"id": "landuse-hospital", "type": "fill", "source": OMT, "source-layer": "landuse",
         "minzoom": gz(12), "filter": ["==", ["get", "class"], "hospital"],
         "paint": {"fill-color": p["hospital"]}})
    add({"id": "landuse-cemetery", "type": "fill", "source": OMT, "source-layer": "landuse",
         "filter": ["==", ["get", "class"], "cemetery"], "paint": {"fill-color": p["cemetery"]}})
    # parques nacionales y santuarios (capa park): no se rellenan, solo se rotulan
    add({"id": "landuse-park", "type": "fill", "source": OMT, "source-layer": "landuse",
         "filter": ["in", ["get", "class"], ["literal", [
             "park", "garden", "pitch", "playground", "stadium", "golf_course", "zoo",
             "recreation_ground", "village_green", "dog_park"]]],
         "paint": {"fill-color": p["park"]}})
    add({"id": "landcover-park", "type": "fill", "source": OMT, "source-layer": "landcover",
         "filter": ["in", ["get", "subclass"], ["literal", ["park", "garden", "golf_course", "pitch"]]],
         "paint": {"fill-color": p["park"]}})
    add({"id": "aeroway-area", "type": "fill", "source": OMT, "source-layer": "aeroway",
         "filter": ["all", ["==", ["geometry-type"], "Polygon"],
                    ["in", ["get", "class"], ["literal", ["aerodrome", "apron"]]]],
         "paint": {"fill-color": p["airport"]}})
    add({"id": "aeroway-runway", "type": "line", "source": OMT, "source-layer": "aeroway",
         "minzoom": gz(11),
         "filter": ["all", ["==", ["geometry-type"], "LineString"],
                    ["in", ["get", "class"], ["literal", ["runway", "taxiway"]]]],
         "paint": {"line-color": p["runway"],
                   "line-width": by_zoom(lambda rw, tw: ["match", ["get", "class"], "runway", rw, tw],
                                         ramp(11, 1, 13, 4, 15, 14, 17, 50),
                                         ramp(11, 0, 13, 0.5, 15, 3, 17, 12))}})

    # ---- relieve sombreado (hasta ~z13) ----
    add({"id": "hillshade", "type": "hillshade", "source": "terrain", "maxzoom": gz(15),
         "paint": {"hillshade-shadow-color": p["hill_shadow"],
                   "hillshade-highlight-color": p["hill_highlight"],
                   "hillshade-accent-color": p["hill_accent"],
                   "hillshade-illumination-direction": 315,
                   "hillshade-exaggeration": ["interpolate", ["linear"], ["zoom"],
                                              gz(6), p["hill_strength"], gz(12), p["hill_strength"] * 0.85,
                                              gz(14), 0]}})

    # ---- agua ----
    add({"id": "water", "type": "fill", "source": OMT, "source-layer": "water",
         "filter": ["!=", ["get", "brunnel"], "tunnel"],
         "paint": {"fill-color": p["water"], "fill-antialias": False}})
    add({"id": "waterway", "type": "line", "source": OMT, "source-layer": "waterway",
         "filter": ["!=", ["get", "brunnel"], "tunnel"],
         "layout": {"line-cap": "round", "line-join": "round"},
         "paint": {"line-color": p["waterway"],
                   "line-width": by_zoom(lambda big, small: ["match", ["get", "class"],
                                                             ["river", "canal"], big, small],
                                         ramp(8, 0.6, 11, 1, 13, 2, 15, 4, 17, 9, 19, 24),
                                         ramp(8, 0, 13, 0.4, 15, 1, 17, 2.5, 19, 5))}})

    # ---- caminos internos de parques y plazas ----
    add({"id": "park-path", "type": "line", "source": OMT, "source-layer": "transportation",
         "minzoom": gz(17),
         "filter": ["all", ["==", ["get", "class"], "path"],
                    ["in", ["get", "subclass"], ["literal", ["footway", "path"]]]],
         "paint": {"line-color": p["park_path"], "line-width": ramp(17, 0.6, 19, 1.5), "line-opacity": 0.8}})

    # ---- edificios (planos) ----
    add({"id": "building", "type": "fill", "source": OMT, "source-layer": "building",
         "minzoom": gz(16),
         "paint": {"fill-color": p["building"], "fill-outline-color": p["building_outline"],
                   "fill-opacity": ["interpolate", ["linear"], ["zoom"], gz(16), 0, gz(16.6), 1]}})

    # ---- vías ----
    layers.extend(road_layers(p, "tunnel"))
    add({"id": "railway", "type": "line", "source": OMT, "source-layer": "transportation",
         "minzoom": gz(12),
         "filter": ["all", ["==", ["get", "class"], "rail"], ["!=", ["get", "brunnel"], "tunnel"]],
         "paint": {"line-color": p["rail"], "line-width": ramp(12, 0.6, 15, 1.2, 18, 2.2)}})
    layers.extend(road_layers(p, "road"))
    layers.extend(road_layers(p, "bridge"))

    # ---- límites ----
    add({"id": "boundary-region", "type": "line", "source": OMT, "source-layer": "boundary",
         "minzoom": gz(5),
         "filter": ["all", ["==", ["get", "admin_level"], 4], ["!=", ["get", "maritime"], 1]],
         "paint": {"line-color": p["boundary_region"], "line-dasharray": [3, 2],
                   "line-width": ramp(5, 0.6, 10, 1.2)}})
    add({"id": "boundary-country", "type": "line", "source": OMT, "source-layer": "boundary",
         "filter": ["all", ["==", ["get", "admin_level"], 2], ["!=", ["get", "maritime"], 1]],
         "paint": {"line-color": p["boundary_country"], "line-width": ramp(3, 0.6, 8, 1.4, 12, 2)}})

    # ---- etiquetas de agua ----
    add({"id": "water-name-line", "type": "symbol", "source": OMT, "source-layer": "waterway",
         "minzoom": gz(13), "filter": ["in", ["get", "class"], ["literal", ["river", "canal"]]],
         "layout": {"text-field": NAME, "text-font": FONT_REG, "symbol-placement": "line",
                    "text-size": ramp(13, 11, 17, 13), "text-letter-spacing": 0.05},
         "paint": {"text-color": p["text_water"], "text-halo-color": p["halo_water"], "text-halo-width": 1}})
    add({"id": "water-name", "type": "symbol", "source": OMT, "source-layer": "water_name",
         "layout": {"text-field": NAME, "text-font": FONT_REG,
                    "text-size": by_zoom(lambda o, w: ["match", ["get", "class"], "ocean", o, w],
                                         ramp(3, 13, 7, 17, 14, 17), ramp(3, 11, 9, 11, 14, 14)),
                    "text-letter-spacing": ["match", ["get", "class"], "ocean", 0.25, 0.05],
                    "text-max-width": 7},
         "paint": {"text-color": p["text_water"], "text-halo-color": p["halo_water"], "text-halo-width": 1}})

    # ---- nombres de vías y escudos ----
    add({"id": "road-label", "type": "symbol", "source": OMT, "source-layer": "transportation_name",
         "minzoom": gz(13),
         "filter": ["!", ["in", ["get", "class"], ["literal", ["rail", "path", "track", "ferry"]]]],
         "layout": {"text-field": abbreviated(NAME), "text-font": FONT_MED, "symbol-placement": "line",
                    "symbol-spacing": 350,
                    "text-size": by_zoom(lambda big, small: ["match", ["get", "class"],
                                                             ["motorway", "trunk", "primary"], big, small],
                                         ramp(13, 11, 17, 13.5, 19, 15), ramp(13, 10, 14, 10, 17, 12.5, 19, 14)),
                    "text-rotation-alignment": "map", "text-pitch-alignment": "viewport"},
         "paint": {"text-color": p["text_road"], "text-halo-color": p["halo"], "text-halo-width": 1.4}})
    # rutas nacionales numéricas ("5", "68") -> escudo blanco; regionales ("G-30") -> verde
    numeric_ref = [">=", ["to-number", ["get", "ref"], -1], 0]
    shield_ok = ["all", ["has", "ref"], ["<=", ["get", "ref_length"], 5],
                 ["in", ["get", "class"], ["literal", ["motorway", "trunk", "primary"]]]]
    add({"id": "road-shield", "type": "symbol", "source": OMT, "source-layer": "transportation_name",
         "minzoom": gz(7), "maxzoom": gz(17), "filter": shield_ok,
         "layout": {"text-field": ["get", "ref"], "text-font": FONT_MED, "text-size": 10,
                    "symbol-placement": "line", "symbol-spacing": 400,
                    "text-rotation-alignment": "viewport", "icon-rotation-alignment": "viewport",
                    "icon-image": ["case", numeric_ref,
                                   f"shield-national-{theme}", f"shield-regional-{theme}"],
                    "icon-text-fit": "both", "icon-text-fit-padding": [2, 4, 2, 4]},
         "paint": {"text-color": ["case", numeric_ref,
                                  p["shield_text"], "#ffffff"]}})
    add({"id": "oneway", "type": "symbol", "source": OMT, "source-layer": "transportation",
         "minzoom": gz(16),
         "filter": ["all", ["==", ["get", "oneway"], 1],
                    ["in", ["get", "class"], ["literal", ["minor", "secondary", "tertiary", "primary"]]]],
         "layout": {"symbol-placement": "line", "symbol-spacing": 160, "icon-image": f"oneway-{theme}",
                    "icon-rotation-alignment": "map", "icon-size": ramp(16, 0.6, 19, 1)}})

    # ---- POI ----
    # Los POI importantes llevan chincheta + nombre; el resto, un punto.
    # Las capas posteriores se colocan primero, así que el nivel 1 va al final.
    icon_name = ["concat", "pin-", theme, "-", match("class", icon_by_class, "civic")]
    dot_name = ["concat", "dot-", theme, "-", category]
    named = ["all", ["has", "name"], ["!=", ["get", "class"], "bus"], ["!=", ["get", "class"], "railway"]]
    # las clínicas vienen como class=hospital; solo los hospitales van en el nivel 1
    tier1 = ["all", ["in", ["get", "class"], ["literal", TIER1]],
             ["!", ["all", ["==", ["get", "class"], "hospital"], ["!=", ["get", "subclass"], "hospital"]]]]
    tier2 = ["in", ["get", "class"], ["literal", TIER2]]
    pin_layout = {"icon-image": icon_name, "icon-anchor": "bottom",
                  "icon-size": ramp(14, 0.85, 16, 1, 19, 1.1),
                  "text-field": NAME, "text-font": FONT_MED, "text-size": ramp(14, 11.5, 17, 12.5, 19, 13.5),
                  "text-anchor": "left", "text-offset": [1.05, -1.2], "text-justify": "left",
                  "text-max-width": 9, "text-optional": True, "icon-padding": 4}
    pin_paint = {"text-color": by_cat("text"), "text-halo-color": p["halo"], "text-halo-width": 1.5}
    add({"id": "poi-dot", "type": "symbol", "source": OMT, "source-layer": "poi",
         "minzoom": gz(16), "filter": named,
         "layout": {"icon-image": dot_name, "icon-size": ramp(16, 0.8, 19, 1.1), "icon-padding": 7}})
    add({"id": "transit-bus", "type": "symbol", "source": OMT, "source-layer": "poi",
         "minzoom": gz(16), "filter": ["==", ["get", "class"], "bus"],
         "layout": {"icon-image": f"transit-bus-{theme}", "icon-size": ramp(16, 0.7, 19, 0.95),
                    "icon-padding": 4}})
    add({"id": "poi-tier3", "type": "symbol", "source": OMT, "source-layer": "poi",
         "minzoom": gz(19), "filter": ["all", named, ["!", tier1], ["!", tier2]],
         "layout": pin_layout, "paint": pin_paint})
    add({"id": "poi-tier2", "type": "symbol", "source": OMT, "source-layer": "poi",
         "minzoom": gz(15), "filter": ["all", named, tier2],
         "layout": {**pin_layout, "icon-padding": ["step", ["zoom"], 48, gz(16), 26, gz(17), 14, gz(18), 10]},
         "paint": pin_paint})
    add({"id": "park-name", "type": "symbol", "source": OMT, "source-layer": "poi",
         "minzoom": gz(14), "maxzoom": gz(16),
         "filter": ["all", ["has", "name"], ["in", ["get", "class"], ["literal", ["park", "garden"]]]],
         "layout": {"text-field": NAME, "text-font": FONT_MED, "text-size": ramp(14, 11.5, 16, 12.5),
                    "text-max-width": 7, "text-padding": 6},
         "paint": {"text-color": p["text_park"], "text-halo-color": p["halo"], "text-halo-width": 1.4}})
    add({"id": "transit-metro", "type": "symbol", "source": OMT, "source-layer": "poi",
         "minzoom": gz(13),
         "filter": ["all", ["==", ["get", "class"], "railway"],
                    ["in", ["get", "subclass"], ["literal", ["station", "subway", "halt"]]]],
         "layout": {"icon-image": f"transit-metro-{theme}", "icon-size": ramp(13, 0.75, 16, 1),
                    "text-field": ["step", ["zoom"], "", gz(16), NAME], "text-font": FONT_MED,
                    "text-size": 11.5, "text-anchor": "left", "text-offset": [0.8, 0],
                    "text-optional": True, "icon-padding": 2},
         "paint": {"text-color": p["text_town"], "text-halo-color": p["halo"], "text-halo-width": 1.4}})
    add({"id": "poi-tier1", "type": "symbol", "source": OMT, "source-layer": "poi",
         "minzoom": gz(14), "filter": ["all", named, tier1],
         "layout": {**pin_layout, "icon-padding": ["step", ["zoom"], 40, gz(15), 24, gz(16), 10, gz(17), 4]},
         "paint": pin_paint})

    # ---- aeropuertos ----
    add({"id": "airport-label", "type": "symbol", "source": OMT, "source-layer": "aerodrome_label",
         "minzoom": gz(10),
         "layout": {"icon-image": f"pin-{theme}-airport", "icon-anchor": "bottom",
                    "text-field": NAME, "text-font": FONT_MED, "text-size": ramp(10, 11, 14, 13),
                    "text-anchor": "left", "text-offset": [1.05, -1.2], "text-max-width": 9,
                    "text-optional": True},
         "paint": {"text-color": p["poi"]["transport"]["text"], "text-halo-color": p["halo"],
                   "text-halo-width": 1.5}})

    # ---- parques: nombre ----
    add({"id": "park-label", "type": "symbol", "source": OMT, "source-layer": "park",
         "minzoom": gz(11),
         "filter": ["all", ["has", "name"], ["in", ["get", "class"], ["literal", [
             "national_park", "natural_sanctuary", "nature_reserve", "park"]]]],
         "layout": {"text-field": NAME, "text-font": FONT_MED, "text-size": ramp(11, 11, 16, 13),
                    "text-max-width": 7},
         "paint": {"text-color": p["text_park"], "text-halo-color": p["halo"], "text-halo-width": 1.4}})

    # ---- lugares ----
    # En Chile las comunas vienen como suburb ("Huechuraba", tipografía normal)
    # y los barrios como neighbourhood/quarter ("PATRONATO", mayúsculas).
    add({"id": "place-neighbourhood", "type": "symbol", "source": OMT, "source-layer": "place",
         "minzoom": gz(13), "maxzoom": gz(17),
         "filter": ["in", ["get", "class"], ["literal", ["neighbourhood", "quarter"]]],
         "layout": {"text-field": NAME, "text-font": FONT_MED, "text-transform": "uppercase",
                    "text-size": ramp(13, 9.5, 16, 11.5), "text-letter-spacing": 0.12,
                    "text-max-width": 8},
         "paint": {"text-color": p["text_suburb"], "text-halo-color": p["halo"], "text-halo-width": 1.4}})
    add({"id": "place-suburb", "type": "symbol", "source": OMT, "source-layer": "place",
         "minzoom": gz(11), "maxzoom": gz(15), "filter": ["==", ["get", "class"], "suburb"],
         "layout": {"text-field": NAME, "text-font": FONT_MED, "text-size": ramp(11, 11.5, 14, 13.5),
                    "text-max-width": 8},
         "paint": {"text-color": p["text_town"], "text-halo-color": p["halo"], "text-halo-width": 1.5}})
    add({"id": "place-village", "type": "symbol", "source": OMT, "source-layer": "place",
         "minzoom": gz(10), "maxzoom": gz(16),
         "filter": ["in", ["get", "class"], ["literal", ["village", "hamlet"]]],
         "layout": {"text-field": NAME, "text-font": FONT_REG, "text-size": ramp(10, 10.5, 14, 12.5),
                    "text-max-width": 8},
         "paint": {"text-color": p["text_town"], "text-halo-color": p["halo"], "text-halo-width": 1.4}})
    add({"id": "place-town", "type": "symbol", "source": OMT, "source-layer": "place",
         "minzoom": gz(7), "maxzoom": gz(16), "filter": ["==", ["get", "class"], "town"],
         "layout": {"text-field": NAME, "text-font": FONT_MED, "text-size": ramp(7, 11, 10, 12.5, 13, 15),
                    "text-max-width": 8},
         "paint": {"text-color": p["text_town"], "text-halo-color": p["halo"], "text-halo-width": 1.5}})
    add({"id": "place-city", "type": "symbol", "source": OMT, "source-layer": "place",
         # la capital se oculta desde z14 (ya es todo ciudad); las demás siguen hasta z14
         "minzoom": gz(4), "maxzoom": gz(15),
         "filter": ["all", ["==", ["get", "class"], "city"],
                    ["any", [">", ["coalesce", ["get", "capital"], 9], 2], ["<", ["zoom"], gz(14)]]],
         "layout": {"text-field": NAME, "text-font": FONT_MED,
                    "text-size": by_zoom(lambda cap, other: ["case", ["<=", ["coalesce", ["get", "capital"], 9], 2],
                                                             cap, other],
                                         ramp(4, 12, 7, 15, 10, 20, 12, 24), ramp(4, 11, 7, 13, 10, 16, 12, 19)),
                    "text-max-width": 8,
                    "icon-image": ["step", ["zoom"], f"dot-{theme}", gz(9), ""],
                    "icon-size": 1, "text-anchor": ["step", ["zoom"], "left", gz(9), "center"],
                    "text-offset": ["step", ["zoom"], ["literal", [0.6, 0]], gz(9), ["literal", [0, 0]]]},
         "paint": {"text-color": p["text_city"], "text-halo-color": p["halo"], "text-halo-width": 1.6}})
    add({"id": "place-state", "type": "symbol", "source": OMT, "source-layer": "place",
         "minzoom": gz(5), "maxzoom": gz(8), "filter": ["==", ["get", "class"], "state"],
         "layout": {"text-field": NAME, "text-transform": "uppercase", "text-font": FONT_MED,
                    "text-size": ramp(5, 10, 8, 12),
                    "text-letter-spacing": 0.15, "text-max-width": 8},
         "paint": {"text-color": p["text_suburb"], "text-halo-color": p["halo"], "text-halo-width": 1.4}})
    add({"id": "place-country", "type": "symbol", "source": OMT, "source-layer": "place",
         "maxzoom": gz(8), "filter": ["==", ["get", "class"], "country"],
         "layout": {"text-field": NAME, "text-font": FONT_MED, "text-size": ramp(2, 11, 5, 14, 7, 17),
                    "text-max-width": 7},
         "paint": {"text-color": p["text_country"], "text-halo-color": p["halo"], "text-halo-width": 1.6}})

    return {
        "version": 8,
        "name": p["name"],
        "metadata": {"butake:generator": "scripts/gen-styles.py", "butake:country": "CL"},
        "center": [-70.6505, -33.4378],
        "zoom": 13,
        "sources": {
            OMT: {"type": "vector", "url": "mbtiles://{openmaptiles}"},
            "natural_earth": {"type": "vector", "url": "mbtiles://{natural_earth}"},
            # modelo de elevación: scripts/build-terrain.sh
            "terrain": {"type": "raster-dem", "url": "mbtiles://{terrain}", "encoding": "terrarium",
                        "tileSize": 256},
        },
        "sprite": "cl",
        "glyphs": "{fontstack}/{range}.pbf",
        "layers": layers,
    }


def write(style, identifier):
    os.makedirs(STYLES_DIR, exist_ok=True)
    out = os.path.join(STYLES_DIR, "%s.json" % identifier)
    with open(out, "w") as f:
        json.dump(style, f, indent=2, ensure_ascii=False)
    print("escrito:", out, "(%d capas)" % len(style["layers"]))


if __name__ == "__main__":
    # Sprite relativo: TileServer lo vuelve absoluto con --public_url, así que
    # funciona en local y en cualquier dominio.
    write(build(LIGHT), "cl-light")
    write(build(DARK), "cl-dark")

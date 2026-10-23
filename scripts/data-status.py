#!/usr/bin/env python3
"""¿Qué tan actualizados están los datos frente a OpenStreetMap?

Compara la marca de replicación de OSM de cada fuente con la última publicada
por Geofabrik (un diff por día):
  - mapa: el .mbtiles (metadatos planetiler:osm:osmosisreplication*)
  - rutas: el .osm.pbf que importa GraphHopper (cabecera del archivo)

Con --contar descarga los diffs pendientes y cuenta cuántos elementos de OSM
cambiaron (creados, modificados, eliminados) y cuántas calles.

Con --marcar copia la marca de replicación del .osm.pbf del país al .mbtiles
para mapas generados con herramientas que no la guardan (build-tiles.sh ya la guarda).

Uso:  python3 scripts/data-status.py [.env] [--contar | --marcar]
Solo biblioteca estándar.
"""
import concurrent.futures
import datetime as dt
import gzip
import io
import os
import sqlite3
import struct
import sys
import time
import urllib.request
import xml.etree.ElementTree as ET
import zlib

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def read_env(path):
    env = {}
    with open(path) as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith("#") and "=" in line:
                k, v = line.split("=", 1)
                env[k.strip()] = v.strip().strip('"').strip("'")
    return env


# ------------------------------------------------------------------ fuentes
def mbtiles_replication(path):
    """(secuencia, fecha, url) desde los metadatos del .mbtiles, o None."""
    db = sqlite3.connect(f"file:{path}?mode=ro", uri=True)
    meta = dict(db.execute("select name, value from metadata"))
    db.close()
    seq = meta.get("planetiler:osm:osmosisreplicationseq")
    if not seq:
        return None
    return int(seq), meta.get("planetiler:osm:osmosisreplicationtime"), meta.get("planetiler:osm:osmosisreplicationurl")


def _varint(buf, i):
    shift = result = 0
    while True:
        b = buf[i]; i += 1
        result |= (b & 0x7F) << shift
        if not b & 0x80:
            return result, i
        shift += 7


def _fields(buf):
    """Campos (número, valor) de un mensaje protobuf (solo varint y bytes)."""
    i = 0
    while i < len(buf):
        key, i = _varint(buf, i)
        num, wire = key >> 3, key & 7
        if wire == 0:
            val, i = _varint(buf, i)
        elif wire == 2:
            n, i = _varint(buf, i)
            val, i = buf[i:i + n], i + n
        elif wire == 1:
            val, i = buf[i:i + 8], i + 8
        elif wire == 5:
            val, i = buf[i:i + 4], i + 4
        else:
            raise ValueError("protobuf no soportado")
        yield num, val


def pbf_replication(path):
    """(secuencia, fecha, url) desde la cabecera OSMHeader de un .osm.pbf, o None."""
    with open(path, "rb") as f:
        (hlen,) = struct.unpack(">I", f.read(4))
        header = dict(_fields(f.read(hlen)))
        blob = dict(_fields(f.read(header[3])))
    data = zlib.decompress(blob[3]) if 3 in blob else blob[1]
    h = dict(_fields(data))
    if 33 not in h:
        return None
    ts = dt.datetime.fromtimestamp(h[32], dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ") if 32 in h else None
    return h[33], ts, h.get(34, b"").decode() or None


def fetch(url, timeout=60, tries=3):
    """Descarga con reintentos: Geofabrik a veces tarda en responder."""
    for attempt in range(1, tries + 1):
        try:
            with urllib.request.urlopen(url, timeout=timeout) as r:
                return r.read()
        except (OSError, TimeoutError):
            if attempt == tries:
                raise
            time.sleep(2 * attempt)


def remote_state(base_url):
    raw = fetch(base_url.rstrip("/") + "/state.txt")
    state = dict(line.split("=", 1) for line in raw.decode().splitlines() if "=" in line)
    return int(state["sequenceNumber"]), state["timestamp"].replace("\\:", ":")


# ------------------------------------------------------------------ diffs
def diff_url(base_url, seq):
    s = f"{seq:09d}"
    return f"{base_url.rstrip('/')}/{s[:3]}/{s[3:6]}/{s[6:]}.osc.gz"


def parse_diff(url):
    """Lista de (tipo, id, acción, es_calle) de un diff .osc.gz."""
    raw = fetch(url, timeout=120)
    out = []
    action = None
    for event, el in ET.iterparse(io.BytesIO(gzip.decompress(raw)), events=("start", "end")):
        if event == "start" and el.tag in ("create", "modify", "delete"):
            action = el.tag
        elif event == "end" and el.tag in ("node", "way", "relation"):
            street = el.tag == "way" and any(t.get("k") == "highway" for t in el.iter("tag"))
            out.append((el.tag, el.get("id"), action, street))
            el.clear()
    return out


def count_pending(base_url, start, end):
    """Elementos distintos que cambiaron entre las secuencias start+1 y end."""
    seqs = list(range(start + 1, end + 1))
    first, last, streets = {}, {}, set()
    with concurrent.futures.ThreadPoolExecutor(max_workers=8) as pool:
        results = pool.map(lambda s: (s, parse_diff(diff_url(base_url, s))), seqs)
        for done, (seq, changes) in enumerate(sorted(results), 1):
            for kind, oid, action, street in changes:
                key = (kind, oid)
                first.setdefault(key, action)
                last[key] = action
                if street:
                    streets.add(key)
            if sys.stderr.isatty():
                print(f"\r  leyendo diffs: {done}/{len(seqs)}", end="", file=sys.stderr, flush=True)
    if sys.stderr.isatty():
        print(file=sys.stderr)
    net = {"creados": 0, "modificados": 0, "eliminados": 0}
    by_type = {"node": 0, "way": 0, "relation": 0}
    for key, a0 in first.items():
        a1 = last[key]
        if a0 == "create" and a1 == "delete":
            continue  # se creó y se borró dentro del periodo: no cambia nada
        net["eliminados" if a1 == "delete" else "creados" if a0 == "create" else "modificados"] += 1
        by_type[key[0]] += 1
    return net, by_type, len(streets)


# ------------------------------------------------------------------ informe
def fmt_date(ts):
    return ts.replace("T", " ").replace("Z", " UTC") if ts else "desconocida"


def days_between(a, b):
    try:
        pa = dt.datetime.strptime(a, "%Y-%m-%dT%H:%M:%SZ")
        pb = dt.datetime.strptime(b, "%Y-%m-%dT%H:%M:%SZ")
        return (pb - pa).days
    except (TypeError, ValueError):
        return None


def stamp(mbtiles, pbf):
    """Escribe la marca de replicación del .pbf en los metadatos del .mbtiles."""
    rep = pbf_replication(pbf)
    if rep is None:
        sys.exit(f"{pbf} no trae marca de replicación de OSM.")
    seq, ts, url = rep
    db = sqlite3.connect(mbtiles)
    for key, value in (("seq", seq), ("time", ts), ("url", url)):
        db.execute("delete from metadata where name = ?", (f"planetiler:osm:osmosisreplication{key}",))
        db.execute("insert into metadata (name, value) values (?, ?)",
                   (f"planetiler:osm:osmosisreplication{key}", str(value)))
    db.commit(); db.close()
    print(f"{os.path.basename(mbtiles)}: datos OSM al {fmt_date(ts)} (secuencia {seq})")


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    contar = "--contar" in sys.argv
    env = read_env(os.path.join(ROOT, args[0] if args else ".env"))
    data = os.path.join(ROOT, env.get("DATA_PATH", "./data"))
    country = env.get("ACTIVE_COUNTRY", "chile")
    sources = {
        "Mapa (tiles)": ("mbtiles", os.path.join(data, "mbtiles", env.get("MAPS_PRIMARY_TILESET", f"{country}.mbtiles"))),
        "Rutas (GraphHopper)": ("pbf", os.path.join(data, "countries", country, "map.osm.pbf")),
    }
    if "--marcar" in sys.argv:
        stamp(sources["Mapa (tiles)"][1], sources["Rutas (GraphHopper)"][1])
        return
    rows, base_url = [], None
    for label, (kind, path) in sources.items():
        if not os.path.exists(path):
            rows.append((label, None, None)); continue
        rep = mbtiles_replication(path) if kind == "mbtiles" else pbf_replication(path)
        if rep is None:
            rows.append((label, None, None)); continue
        seq, ts, url = rep
        base_url = base_url or url
        rows.append((label, seq, ts))
    if not base_url:
        sys.exit("Ninguna fuente trae la marca de replicación de OSM: no se puede comparar.")

    latest_seq, latest_ts = remote_state(base_url)
    print(f"OpenStreetMap (Geofabrik): secuencia {latest_seq}, datos al {fmt_date(latest_ts)}\n")
    print(f"{'Fuente':22} {'Datos OSM al':24} {'Secuencia':>9}  Atraso")
    for label, seq, ts in rows:
        if seq is None:
            print(f"{label:22} {'sin marca de replicación':24} {'-':>9}  -")
            continue
        behind = latest_seq - seq
        days = days_between(ts, latest_ts)
        state = "al día" if behind <= 0 else f"{behind} diffs diarios ({days} día{'' if days == 1 else 's'})"
        print(f"{label:22} {fmt_date(ts):24} {seq:>9}  {state}")

    if contar:
        for label, seq, ts in rows:
            if seq is None or seq >= latest_seq:
                continue
            print(f"\n{label}: cambios de OSM pendientes de bajar (secuencias {seq + 1}–{latest_seq})")
            net, by_type, streets = count_pending(base_url, seq, latest_seq)
            total = sum(net.values())
            print(f"  elementos distintos que cambiaron: {total:,}".replace(",", "."))
            print("  " + "  ".join(f"{k}: {v:,}".replace(",", ".") for k, v in net.items()))
            print(f"  nodos: {by_type['node']:,}  vías: {by_type['way']:,}  relaciones: {by_type['relation']:,}".replace(",", "."))
            print(f"  calles (vías con highway) creadas o modificadas: {streets:,}".replace(",", "."))
    else:
        print("\nPara contar los cambios pendientes: python3 scripts/data-status.py --contar")


if __name__ == "__main__":
    main()

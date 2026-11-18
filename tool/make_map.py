"""Builds the offline world map asset (assets/map/world.bin).

Source: Natural Earth 1:50m vector data (public domain), as GeoJSON from
https://github.com/nvkelso/natural-earth-vector. The files are downloaded
into a cache folder on first use.

    python tool/make_map.py [cache_dir]

Format (all integers little-endian varints; signed ones zigzag-encoded;
coordinates in hundredths of a degree, each point a delta from the previous
one in its ring):

    "SCM1"
    land:    ring count, rings      (polygons; even-odd fill)
    lakes:   ring count, rings      (polygons; even-odd fill)
    borders: line count, lines      (country borders on land)
    cities:  count, then per city: lon, lat (signed, absolute), min zoom
             (byte), flags (byte; 1 = national capital), name length,
             UTF-8 name

A ring or line is a point count followed by lon, lat pairs.

Each city gets the lowest zoom (2..6) at which its label does not overlap the
label of a more important city at that zoom or any higher one, so labels
appear progressively as the map zooms in and never vanish when zooming in.
"""

import json
import math
import os
import sys
import urllib.request

BASE = ('https://raw.githubusercontent.com/nvkelso/natural-earth-vector/'
        'master/geojson/')
LAND = 'ne_50m_land'
LAKES = 'ne_50m_lakes'
BORDERS = 'ne_50m_admin_0_boundary_lines_land'
PLACES = 'ne_50m_populated_places'

MIN_ZOOM, MAX_ZOOM = 2, 6  # keep in step with lib/world_map.dart
Q = 100  # hundredths of a degree

# Label box estimate in pixels, matching the style in lib/world_map.dart.
CHAR_W, LABEL_H, DOT = 6.0, 14.0, 8.0
# Space kept free around each label.
PAD_X, PAD_Y = 12.0, 6.0


def load(cache, name):
    path = os.path.join(cache, name + '.geojson')
    if not os.path.exists(path):
        print('downloading', name)
        urllib.request.urlretrieve(BASE + name + '.geojson', path)
    with open(path, encoding='utf-8') as f:
        return json.load(f)['features']


def varint(out, n):
    while True:
        b = n & 0x7F
        n >>= 7
        if n:
            out.append(b | 0x80)
        else:
            out.append(b)
            return


def svarint(out, n):
    varint(out, (n << 1) ^ (n >> 63) if n < 0 else n << 1)


def quantize(points, closed):
    q = []
    for lon, lat, *_ in points:
        p = (round(lon * Q), round(lat * Q))
        if not q or q[-1] != p:
            q.append(p)
    if closed and len(q) > 1 and q[0] == q[-1]:
        q.pop()
    return q


def rings(features):
    for f in features:
        g = f['geometry']
        polys = [g['coordinates']] if g['type'] == 'Polygon' else g['coordinates']
        for poly in polys:
            for ring in poly:
                yield ring


def lines(features):
    for f in features:
        g = f['geometry']
        if g['type'] == 'LineString':
            yield g['coordinates']
        else:
            yield from g['coordinates']


def write_paths(out, paths, closed):
    qs = [q for q in (quantize(p, closed) for p in paths)
          if len(q) >= (3 if closed else 2)]
    varint(out, len(qs))
    n = 0
    for q in qs:
        varint(out, len(q))
        px = py = 0
        for x, y in q:
            svarint(out, x - px)
            svarint(out, y - py)
            px, py = x, y
        n += len(q)
    return len(qs), n


def mercator(lon, lat):
    """World pixel position at zoom 0 (256 px wide)."""
    lat = max(-85.05, min(85.05, lat))
    s = math.sin(math.radians(lat))
    return ((lon + 180) / 360 * 256,
            (0.5 - math.log((1 + s) / (1 - s)) / (4 * math.pi)) * 256)


def place_cities(features):
    cities = []
    for f in features:
        p = f['properties']
        name = p.get('NAME_EN') or p['NAME']
        lon, lat = f['geometry']['coordinates'][:2]
        cities.append({
            'name': name,
            'lon': lon,
            'lat': lat,
            'capital': bool(p.get('ADM0CAP')),
            'rank': (-(p.get('NATSCALE') or 0), -(p.get('POP_MAX') or 0)),
        })
    cities.sort(key=lambda c: c['rank'])

    placed = []  # (city, min zoom, x0, y0, x1, y1 at zoom 0)
    for c in cities:
        x, y = mercator(c['lon'], c['lat'])
        w = DOT + CHAR_W * len(c['name'])

        def box(z):
            s = 2 ** z
            return (x * s - DOT / 2 - PAD_X, y * s - LABEL_H / 2 - PAD_Y,
                    x * s - DOT / 2 + w + PAD_X, y * s + LABEL_H / 2 + PAD_Y)

        def fits(z):
            a = box(z)
            s = 2 ** z
            for _, mz, ox, oy, ow in placed:
                if mz > z:
                    continue
                b = (ox * s - DOT / 2, oy * s - LABEL_H / 2,
                     ox * s - DOT / 2 + ow, oy * s + LABEL_H / 2)
                # Same check one world east and west, for the wrap.
                for shift in (0, -256 * s, 256 * s):
                    if (a[0] < b[2] + shift and b[0] + shift < a[2]
                            and a[1] < b[3] and b[1] < a[3]):
                        return False
            return True

        for z in range(MIN_ZOOM, MAX_ZOOM + 1):
            if all(fits(zz) for zz in range(z, MAX_ZOOM + 1)):
                placed.append((c, z, x, y, w))
                break
    return [(c, z) for c, z, *_ in placed]


def main():
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    cache = sys.argv[1] if len(sys.argv) > 1 else os.path.join(
        root, 'build', 'natural_earth')
    os.makedirs(cache, exist_ok=True)

    out = bytearray(b'SCM1')
    print('land    %5d rings %6d points' %
          write_paths(out, rings(load(cache, LAND)), True))
    print('lakes   %5d rings %6d points' %
          write_paths(out, rings(load(cache, LAKES)), True))
    print('borders %5d lines %6d points' %
          write_paths(out, lines(load(cache, BORDERS)), False))

    cities = place_cities(load(cache, PLACES))
    varint(out, len(cities))
    for c, z in cities:
        svarint(out, round(c['lon'] * Q))
        svarint(out, round(c['lat'] * Q))
        out.append(z)
        out.append(1 if c['capital'] else 0)
        name = c['name'].encode('utf-8')
        varint(out, len(name))
        out += name
    by_zoom = [sum(1 for _, z in cities if z <= zz)
               for zz in range(MIN_ZOOM, MAX_ZOOM + 1)]
    print('cities  %5d (shown by zoom %d..%d: %s)' %
          (len(cities), MIN_ZOOM, MAX_ZOOM, by_zoom))

    dest = os.path.join(root, 'assets', 'map', 'world.bin')
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    with open(dest, 'wb') as f:
        f.write(out)
    print('wrote %s (%d bytes)' % (os.path.relpath(dest, root), len(out)))


if __name__ == '__main__':
    main()

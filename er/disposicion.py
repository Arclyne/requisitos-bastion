# -*- coding: utf-8 -*-
"""Construye el modelo de un diagrama, en el formato de model.py de la skill
diagrama-er-chen (ENTITIES, RELATIONS, ATTRS...), a partir del esquema
exportado de bd/crear_tablas.sql y de lo que fija diagramas.py.

Reglas de la notación:
- cada tabla es una entidad; las que se identifican por la llave de otra
  (débiles, asociativas y dependientes) llevan doble marco;
- cada llave foránea es una relación; es identificadora (rombo doble) si sus
  columnas forman parte de la llave primaria de la hija;
- los atributos son las columnas que no pertenecen a una llave foránea; las
  de la llave primaria van subrayadas y las calculadas, punteadas.
"""

import math
import random

ENT_H = 110
DW, DH = 260, 130
OVAL_H = 80
CH, PAD = 8.4, 34
SEP_PARALELAS = 300       # separación entre rombos de relaciones entre el mismo par
HOLGURA = 26              # distancia mínima libre entre figuras
MARGEN = 140              # el de render_svg.py
# Espacio de la figura en el documento, en pulgadas: carta con márgenes de 2.5 cm;
# vertical, el ancho del texto por 0.82 del alto; horizontal (landscape), el alto
# del texto por 0.8 del ancho.
PAGINAS = {"vertical": (6.53, 6.97), "horizontal": (8.5, 5.22)}
FACTORES = [1.0, 0.95, 0.9, 0.85, 0.8, 0.75, 0.7, 0.65, 0.6, 0.55, 0.5, 0.45, 0.4, 0.35]


# ---------------------------------------------------------------- medidas
def ancho_ovalo(texto):
    return max(150, len(texto) * CH + PAD * 2)


def ancho_entidad(texto):
    return max(290, round(len(texto) * 15.8 + 56))


def caja(x, y, w, h, m=0):
    return (x - w / 2 - m, y - h / 2 - m, x + w / 2 + m, y + h / 2 + m)


def cruzan(a, b):
    return a[0] < b[2] and b[0] < a[2] and a[1] < b[3] and b[1] < a[3]


def segmento_cruza_caja(p, q, c):
    """Liang-Barsky: ¿el segmento p-q toca la caja c?"""
    x0, y0 = p
    dx, dy = q[0] - x0, q[1] - y0
    t0, t1 = 0.0, 1.0
    for pp, qq in ((-dx, x0 - c[0]), (dx, c[2] - x0), (-dy, y0 - c[1]), (dy, c[3] - y0)):
        if pp == 0:
            if qq < 0:
                return False
        else:
            t = qq / pp
            if pp < 0:
                t0 = max(t0, t)
            else:
                t1 = min(t1, t)
            if t0 > t1:
                return False
    return True


def borde_rect(cx, cy, w, h, tx, ty):
    dx, dy = tx - cx, ty - cy
    if dx == 0 and dy == 0:
        return cx, cy
    sx = (w / 2) / abs(dx) if dx else float("inf")
    sy = (h / 2) / abs(dy) if dy else float("inf")
    s = min(sx, sy)
    return cx + dx * s, cy + dy * s


def borde_rombo(cx, cy, tx, ty):
    dx, dy = tx - cx, ty - cy
    d = abs(dx) / (DW / 2) + abs(dy) / (DH / 2)
    if d == 0:
        return cx, cy
    return cx + dx / d, cy + dy / d


# ---------------------------------------------------------------- esquema
def analizar(esquema):
    tablas = {t["nombre"]: t for t in esquema}
    info = {}
    for t in esquema:
        pk = set(t["pk"])
        # Llave de retorno: apunta a una tabla que se identifica por esta, como lo haría una
        # llave de Partida hacia una de sus Participacion. No identifica a la tabla ni cubre
        # su llave primaria. El esquema actual no tiene ninguna.
        ciclicas = {f["nombre"] for f in t["fks"]
                    if any(g["ref"] == t["nombre"] and set(g["cols"]) <= set(tablas[f["ref"]]["pk"])
                           for g in tablas[f["ref"]]["fks"])}
        todas = {c for f in t["fks"] for c in f["cols"]}
        cubiertas = {c for f in t["fks"] if f["nombre"] not in ciclicas for c in f["cols"]}
        identificadoras = {f["nombre"] for f in t["fks"]
                           if f["nombre"] not in ciclicas and not f["opcional"]
                           and pk & set(f["cols"])}
        atributos = []
        for c in t["columnas"]:
            n = c["nombre"]
            if n in todas and not (n in pk and n not in cubiertas):
                continue            # la columna la representa una relación
            tipo = "key" if n in pk else ("derived" if c["calculada"] else "simple")
            atributos.append((n, tipo))
        info[t["nombre"]] = dict(atributos=atributos, identificadoras=identificadoras,
                                 debil=bool(identificadoras))
    return tablas, info


def extremos(hija, f, verbo, sujeto, papel_padre, papel_hija, total_padre):
    padre = f["ref"]
    muchos = f["card"].endswith("N")
    n = "N" if muchos else "1"
    total_hija = not f["opcional"]
    if sujeto == "padre":
        ends = [(padre, "1", "1", total_padre, True, papel_padre),
                (hija, n, "1", total_hija, False, papel_hija)]
        razon = "1:N" if muchos else "1:1"
    else:
        ends = [(hija, "1", n, total_hija, False, papel_hija),
                (padre, "1", "1", total_padre, True, papel_padre)]
        razon = "N:1" if muchos else "1:1"
    return ends, razon


# ---------------------------------------------------------------- disposición automática
def fuerzas(nombres, aristas, semilla, iteraciones=3000, lado=1450):
    """Posiciones de entidades por un modelo de resortes (vista general): repulsión
    de corto alcance entre todas, atracción por cada relación y una gravedad débil
    hacia la entidad más conectada, que queda fija en el centro."""
    rnd = random.Random(semilla)
    n = len(nombres)
    idx = {k: i for i, k in enumerate(nombres)}
    grado = [0] * n
    for a, b in aristas:
        grado[idx[a]] += 1
        grado[idx[b]] += 1
    hub = max(range(n), key=lambda i: grado[i])
    pos = []
    for i in range(n):
        ang = 2 * math.pi * i / n + rnd.random() * 0.3
        rr = 0 if i == hub else lado * (1.5 + 2 * rnd.random())
        pos.append([rr * math.cos(ang), rr * math.sin(ang)])
    temp = lado
    alcance = 3 * lado
    for it in range(iteraciones):
        disp = [[0.0, 0.0] for _ in range(n)]
        for i in range(n):
            for j in range(i + 1, n):
                dx = pos[i][0] - pos[j][0]
                dy = pos[i][1] - pos[j][1]
                d = math.sqrt(dx * dx + dy * dy) + 1e-3
                if d > alcance:
                    continue
                f = lado * lado / d
                if d < lado * 0.8:
                    f *= 3
                disp[i][0] += dx / d * f
                disp[i][1] += dy / d * f
                disp[j][0] -= dx / d * f
                disp[j][1] -= dy / d * f
        for a, b in aristas:
            i, j = idx[a], idx[b]
            dx = pos[i][0] - pos[j][0]
            dy = pos[i][1] - pos[j][1]
            d = math.hypot(dx, dy) + 1e-3
            f = d * d / lado
            disp[i][0] -= dx / d * f
            disp[i][1] -= dy / d * f
            disp[j][0] += dx / d * f
            disp[j][1] += dy / d * f
        for i in range(n):
            if i == hub:
                continue
            disp[i][0] -= pos[i][0] * 0.04
            disp[i][1] -= pos[i][1] * 0.04
            dx, dy = disp[i]
            d = math.hypot(dx, dy) + 1e-9
            paso = min(d, temp)
            pos[i][0] += dx / d * paso
            pos[i][1] += dy / d * paso
        temp = max(8, temp * 0.998)
    _colocar_aislados(pos, grado, aristas, idx, hub, lado)
    cx, cy = pos[hub]
    return {k: (round(pos[idx[k]][0] - cx), round(pos[idx[k]][1] - cy)) for k in nombres}


def _dist_segmento(p, a, b):
    dx, dy = b[0] - a[0], b[1] - a[1]
    L2 = dx * dx + dy * dy or 1
    t = max(0.0, min(1.0, ((p[0] - a[0]) * dx + (p[1] - a[1]) * dy) / L2))
    return math.hypot(p[0] - a[0] - t * dx, p[1] - a[1] - t * dy)


def _colocar_aislados(pos, grado, aristas, idx, hub, lado):
    """Las entidades sin relaciones no tienen resorte que las retenga: se llevan al
    hueco libre más cercano al centro, lejos de otras entidades y de las líneas."""
    aislados = [i for i in range(len(pos)) if grado[i] == 0]
    if not aislados:
        return
    fijos = [i for i in range(len(pos)) if i not in aislados]
    segs = [(pos[idx[a]], pos[idx[b]]) for a, b in aristas]
    xs = [pos[i][0] for i in fijos]
    ys = [pos[i][1] for i in fijos]
    for i in aislados:
        mejor = None
        for gx in range(int(min(xs)), int(max(xs)) + 1, 200):
            for gy in range(int(min(ys)), int(max(ys)) + 1, 200):
                if min(math.hypot(gx - pos[j][0], gy - pos[j][1]) for j in fijos) < lado * 0.7:
                    continue
                if segs and min(_dist_segmento((gx, gy), a, b) for a, b in segs) < 450:
                    continue
                dc = math.hypot(gx - pos[hub][0], gy - pos[hub][1])
                if mejor is None or dc < mejor[0]:
                    mejor = (dc, gx, gy)
        if mejor:
            pos[i] = [mejor[1], mejor[2]]
            fijos.append(i)


def _choque_rombo(ENTITIES, RELATIONS):
    cajas_e = [caja(e["x"], e["y"], e["w"], e["h"], 24) for e in ENTITIES.values()]

    def choca(r, x, y):
        c = caja(x, y, DW, DH + 60, 12)
        if any(cruzan(c, k) for k in cajas_e):
            return True
        return any(cruzan(c, caja(o["x"], o["y"], DW, DH + 60, 12)) for o in RELATIONS if o is not r)
    return choca


def rombos_encimados(ENTITIES, RELATIONS):
    """Rombos que, aun después de despejar_rombos, caen sobre otra figura."""
    choca = _choque_rombo(ENTITIES, RELATIONS)
    return sum(1 for r in RELATIONS if choca(r, r["x"], r["y"]))


def tramo_minimo(ENTITIES, RELATIONS):
    """Lo que sobra en el tramo más corto entre un rombo y una entidad, después de
    las cifras de cardinalidad (a 175 del borde de la entidad) y del papel (a 130
    del rombo). Negativo: las etiquetas se enciman."""
    sobra = float("inf")
    for r in RELATIONS:
        destinos = [e[0] for e in r["ends"]]
        for (ent, _t, _b, _tot, _fl, papel) in r["ends"]:
            if destinos.count(ent) > 1:
                continue
            en = ENTITIES[ent]
            p1 = borde_rombo(r["x"], r["y"], en["x"], en["y"])
            p2 = borde_rect(en["x"], en["y"], en["w"], en["h"], r["x"], r["y"])
            sobra = min(sobra, math.hypot(p1[0] - p2[0], p1[1] - p2[1]) - (330 if papel else 230))
    return sobra


def despejar_rombos(ENTITIES, RELATIONS, fijos):
    """Desplaza a lo largo de su línea los rombos que caen sobre otra figura."""
    choca = _choque_rombo(ENTITIES, RELATIONS)
    for _ in range(3):
        for r in RELATIONS:
            a, b = r["ends"][0][0], r["ends"][1][0]
            if r["id"] in fijos or a == b or not choca(r, r["x"], r["y"]):
                continue
            ea, eb = ENTITIES[a], ENTITIES[b]
            dx, dy = eb["x"] - ea["x"], eb["y"] - ea["y"]
            L = math.hypot(dx, dy) or 1
            ux, uy = dx / L, dy / L
            hecho = False
            for paso in range(50, int(L * 0.35), 50):
                for s in (1, -1):
                    x, y = r["x"] + ux * paso * s, r["y"] + uy * paso * s
                    if not choca(r, x, y):
                        r["x"], r["y"] = round(x), round(y)
                        hecho = True
                        break
                if hecho:
                    break


def cruces(ENTITIES, RELATIONS):
    """Número de cruces entre líneas de relación y de líneas que atraviesan entidades."""
    segs = []
    for r in RELATIONS:
        for e in r["ends"]:
            en = ENTITIES[e[0]]
            segs.append(((r["x"], r["y"]), (en["x"], en["y"]), e[0], r["id"]))
    n = 0

    def orient(a, b, c):
        return (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0])

    for i in range(len(segs)):
        for j in range(i + 1, len(segs)):
            a, b = segs[i][0], segs[i][1]
            c, d = segs[j][0], segs[j][1]
            if segs[i][2] == segs[j][2] or segs[i][3] == segs[j][3]:
                continue
            if (orient(a, b, c) * orient(a, b, d) < 0) and (orient(c, d, a) * orient(c, d, b) < 0):
                n += 1
    for (p, q, ent, rid) in segs:
        for nombre, e in ENTITIES.items():
            if nombre == ent:
                continue
            if segmento_cruza_caja(p, q, caja(e["x"], e["y"], e["w"], e["h"], 10)):
                n += 5
    return n


# ---------------------------------------------------------------- atributos
def soporte(w, h, ux, uy):
    """Medio ancho de una elipse de ejes w×h en la dirección unitaria (ux, uy)."""
    return math.hypot(w / 2 * ux, h / 2 * uy)


class Espacio:
    """Figuras y líneas ya colocadas, para comprobar choques."""

    def __init__(self):
        self.cajas = []      # (caja, dueño)
        self.lineas = []     # (p, q, dueño)

    def libre(self, c, dueno):
        return all(not cruzan(c, k) for k, d in self.cajas if d != dueno)

    def linea_libre(self, p, q, dueno, ignorar=()):
        for k, d in self.cajas:
            if d == dueno or d in ignorar:
                continue
            if segmento_cruza_caja(p, q, k):
                return False
        return True

    def caja_sin_lineas(self, c, dueno):
        return all(not segmento_cruza_caja(p, q, c) for p, q, d in self.lineas if d != dueno)


def colocar_atributos(nombre, ent, attrs, espacio, r0=440, rmax=1900):
    """Reparte los óvalos de una entidad sobre un anillo o, si son muchos, en
    zigzag sobre dos radios. Primero intenta que quepan todos juntos en el arco
    libre más amplio; si no, los reparte entre todos los huecos que dejan las
    líneas y las figuras ya colocadas."""
    ex, ey = ent["x"], ent["y"]
    anchos = [ancho_ovalo(a[0]) for a in attrs]
    dueno = "a:" + nombre
    propia = caja(ex, ey, ent["w"], ent["h"], HOLGURA)

    def valido(x, y, w):
        c = caja(x, y, w, OVAL_H, HOLGURA / 2)
        if cruzan(c, propia):
            return False
        if not espacio.libre(c, dueno):
            return False
        if not espacio.caja_sin_lineas(caja(x, y, w, OVAL_H, 8), dueno):
            return False
        p = borde_rect(ex, ey, ent["w"], ent["h"], x, y)
        return espacio.linea_libre(p, (x, y), dueno, ignorar=("e:" + nombre,))

    for juntos in (True, False):
        for r in range(r0, rmax, 40):
            for zigzag in (False, True):
                coloc = _barrido(ex, ey, anchos, r, zigzag, valido, juntos)
                if coloc:
                    return coloc
    raise RuntimeError(f"No caben los atributos de {nombre}")


def _arco_libre(ex, ey, r, w, valido):
    """(inicio, fin) en grados del arco libre más largo a radio r, o None."""
    libre = [valido(ex + r * math.cos(math.radians(a)), ey + r * math.sin(math.radians(a)), w)
             for a in range(360)]
    if not any(libre):
        return None
    if all(libre):
        return (270 - 180, 270 + 180)
    mejor, i = None, 0
    arr = libre + libre
    while i < 360:
        if arr[i]:
            j = i
            while arr[j]:
                j += 1
            if mejor is None or j - i > mejor[1] - mejor[0]:
                mejor = (i, j - 1)
            i = j
        else:
            i += 1
    return mejor


def _barrido(ex, ey, anchos, r, zigzag, valido, juntos):
    arco = _arco_libre(ex, ey, r, max(anchos), valido)
    if arco is None:
        return None
    a0, a1 = math.radians(arco[0]), math.radians(arco[1])
    if zigzag:
        if not juntos:
            hecho = _barrido_zigzag(ex, ey, anchos, r, a0, a0 + 2 * math.pi, valido)
            return hecho and hecho[0]
        hecho = _barrido_zigzag(ex, ey, anchos, r, a0, a1, valido)
        if hecho is None:
            return None
        centrado = _barrido_zigzag(ex, ey, anchos, r, a0 + (a1 - hecho[1]) / 2, a1, valido)
        return (centrado or hecho)[0]
    centro = (a0 + a1) / 2
    total = sum(_separacion(centro, r, anchos[i], anchos[i + 1]) for i in range(len(anchos) - 1))
    if juntos:
        if total > a1 - a0:
            return None
        ini, fin = max(a0, centro - total / 2 - math.radians(8)), a1
    else:
        ini = centro - total / 2
        fin = ini + 2 * math.pi
    return _barrido_anillo(ex, ey, anchos, r, ini, fin, valido, [])


def _barrido_zigzag(ex, ey, anchos, r, ini, fin, valido):
    """Óvalos en orden de ángulo, alternando entre el radio r y uno mayor: cada uno
    se coloca en el primer ángulo en que no toca a los anteriores y ninguna línea
    hacia la entidad atraviesa otro óvalo. Devuelve (posiciones, ángulo final)."""
    radios = (r, r + OVAL_H + HOLGURA + 24)
    hechos = []
    ang, k = ini, 0
    while k < len(anchos) and ang <= fin:
        w = anchos[k]
        for rad in (radios if k % 2 == 0 else radios[::-1]):
            x, y = ex + rad * math.cos(ang), ey + rad * math.sin(ang)
            if not valido(x, y, w):
                continue
            c = caja(x, y, w, OVAL_H, HOLGURA / 2)
            if any(cruzan(c, caja(ox, oy, ow, OVAL_H, HOLGURA / 2)) for ox, oy, ow in hechos):
                continue
            if any(segmento_cruza_caja((ex, ey), (x, y), caja(ox, oy, ow, OVAL_H, 8))
                   or segmento_cruza_caja((ex, ey), (ox, oy), caja(x, y, w, OVAL_H, 8))
                   for ox, oy, ow in hechos):
                continue
            hechos.append((x, y, w))
            k += 1
            break
        else:
            ang += math.radians(1)
    if k < len(anchos):
        return None
    return [(round(x), round(y)) for x, y, _ in hechos], ang


def _separacion(ang, r, w1, w2):
    tx, ty = -math.sin(ang), math.cos(ang)
    need = soporte(w1, OVAL_H, tx, ty) + soporte(w2, OVAL_H, tx, ty) + HOLGURA
    return max(math.radians(12) * min(1.0, 700 / r), need / r)


def _barrido_anillo(ex, ey, anchos, r, ini, fin, valido, ocupados):
    n = len(anchos)
    colocados = []
    ang = ini
    k = 0
    while k < n and ang <= fin:
        x, y = ex + r * math.cos(ang), ey + r * math.sin(ang)
        ok = valido(x, y, anchos[k])
        if ok and colocados:
            px, py, pw, pa = colocados[-1]
            ok = ang - pa >= _separacion((ang + pa) / 2, r, pw, anchos[k])
        if ok:
            for (ox, oy, ow) in ocupados:     # anillo interior ya colocado
                ci = caja(ox, oy, ow, OVAL_H, HOLGURA / 2)
                if cruzan(caja(x, y, anchos[k], OVAL_H, HOLGURA / 2), ci) or \
                        segmento_cruza_caja((ex, ey), (x, y), caja(ox, oy, ow, OVAL_H, 6)):
                    ok = False
                    break
        if ok and colocados:
            primero = colocados[0]
            if (primero[3] + 2 * math.pi) - ang < _separacion(ang, r, anchos[k], primero[2]):
                ok = False
        if ok:
            colocados.append((x, y, anchos[k], ang))
            k += 1
        ang += math.radians(1)
    if k < n:
        return None
    return [(round(c[0]), round(c[1])) for c in colocados]


# ---------------------------------------------------------------- construcción
def construir(esquema, diag, verbos, padre_total, semilla=11):
    tablas, info = analizar(esquema)
    if diag.get("areas") is None:
        propias = [t["nombre"] for t in esquema]
    else:
        propias = [t["nombre"] for t in esquema if t["area"] in diag["areas"]]
    fks = [(h, f) for h in propias for f in tablas[h]["fks"]]
    frontera = sorted({f["ref"] for _, f in fks} - set(propias))
    con_atributos = diag.get("atributos", True)

    faltan = [f["nombre"] for _, f in fks if f["nombre"] not in verbos]
    if faltan:
        raise SystemExit(f"Faltan verbos en diagramas.py para: {', '.join(faltan)}")

    pagina = PAGINAS[diag.get("pagina", "vertical")]
    pos = diag.get("posiciones")
    if pos is None:
        # Varias semillas; gana la que no encima figuras ni etiquetas, con menos
        # cruces y, a igualdad, la que ocupa menos página.
        aristas = [(h, f["ref"]) for h, f in fks if h != f["ref"]]
        mejor = None
        for s in range(semilla, semilla + 20):
            p = fuerzas(propias + frontera, aristas, s)
            try:
                prueba = _armar(tablas, info, propias, frontera, fks, p, verbos, padre_total, {},
                                con_atributos)
            except RuntimeError:
                continue
            w, h = medidas(prueba)
            clave = (prueba["encimados"] > 0 or prueba["tramo"] < 0, prueba["cruces"],
                     max(w / pagina[0], h / pagina[1]))
            if mejor is None or clave < mejor[0]:
                mejor = (clave, p)
        pos = mejor[1]
    faltan = [n for n in propias + frontera if n not in pos]
    if faltan:
        raise SystemExit(f"{diag['id']}: faltan posiciones para {', '.join(faltan)}")

    # Compactación: las posiciones se acercan con un mismo factor mientras no se
    # enciman figuras ni etiquetas y no aparecen cruces nuevos; se queda el factor
    # con el que el texto sale más grande en la página del documento.
    rombos = diag.get("rombos", {})
    base, mejor = None, None
    for f in FACTORES:
        esc = lambda d: {k: (round(x * f), round(y * f)) for k, (x, y) in d.items()}  # noqa: E731
        try:
            m = _armar(tablas, info, propias, frontera, fks, esc(pos), verbos, padre_total,
                       esc(rombos), con_atributos)
        except RuntimeError:
            continue
        if base is None:
            base = m
        elif (m["cruces"] > base["cruces"] or m["encimados"] > base["encimados"]
              or m["tramo"] < min(0, base["tramo"])):
            continue
        w, h = medidas(m)
        m["factor"], m["pt"] = f, min(pagina[0] / w, pagina[1] / h) * 72 * 17
        if mejor is None or m["pt"] > mejor["pt"]:
            mejor = m
    return mejor


def medidas(m):
    """Ancho y alto del SVG que dibujará render_svg.py."""
    xs, ys = [], []
    for e in m["ENTITIES"].values():
        xs += [e["x"] - e["w"] / 2, e["x"] + e["w"] / 2]
        ys += [e["y"] - e["h"] / 2, e["y"] + e["h"] / 2]
    for r in m["RELATIONS"]:
        xs += [r["x"] - DW / 2, r["x"] + DW / 2]
        ys += [r["y"] - DH / 2 - 46, r["y"] + DH / 2]
    for a in m["ATTRS"]:
        w = ancho_ovalo(a["label"])
        xs += [a["x"] - w / 2, a["x"] + w / 2]
        ys += [a["y"] - OVAL_H / 2, a["y"] + OVAL_H / 2]
    return max(xs) - min(xs) + 2 * MARGEN, max(ys) - min(ys) + 2 * MARGEN


def _armar(tablas, info, propias, frontera, fks, pos, verbos, padre_total, rombos, con_atributos):
    ENTITIES, RELATIONS = _modelo(tablas, info, propias, frontera, fks, pos, verbos, padre_total,
                                  rombos)

    # figuras y líneas ya fijas
    esp = Espacio()
    for nombre, e in ENTITIES.items():
        esp.cajas.append((caja(e["x"], e["y"], e["w"], e["h"], HOLGURA / 2), "e:" + nombre))
    for r in RELATIONS:
        # rombo más la razón escrita encima
        esp.cajas.append(((r["x"] - DW / 2, r["y"] - DH / 2 - 56, r["x"] + DW / 2, r["y"] + DH / 2), "r:" + r["id"]))
        for (ent, *_rest, papel) in r["ends"]:
            en = ENTITIES[ent]
            p1 = borde_rombo(r["x"], r["y"], en["x"], en["y"])
            p2 = borde_rect(en["x"], en["y"], en["w"], en["h"], r["x"], r["y"])
            esp.lineas.append((p1, p2, "l:" + r["id"]))
            # etiquetas de cardinalidad cerca de la entidad
            dx, dy = p1[0] - p2[0], p1[1] - p2[1]
            L = math.hypot(dx, dy) or 1
            ux, uy = dx / L, dy / L
            bx, by = p2[0] + ux * 175, p2[1] + uy * 175
            nx, ny = -uy, ux
            for s in (1, -1):
                esp.cajas.append((caja(bx + nx * 26 * s, by + ny * 26 * s, 44, 40), "c:" + r["id"]))
            if papel:       # «rol: …» junto al rombo, como en render_svg.py
                mx, my = p1[0] - ux * 130 + nx * 62, p1[1] - uy * 130 + ny * 62
                esp.cajas.append((caja(mx, my, len("rol: " + papel) * 9.5 + 16, 34), "p:" + r["id"]))

    ATTRS = []
    if con_atributos:
        orden = sorted(propias, key=lambda n: -len(info[n]["atributos"]))
        for nombre in orden:
            attrs = info[nombre]["atributos"]
            if not attrs:
                continue
            e = ENTITIES[nombre]
            coloc = colocar_atributos(nombre, e, attrs, esp)
            for (col, tipo), (x, y) in zip(attrs, coloc):
                aid = f"{nombre}.{col}"
                ATTRS.append(dict(id=aid, label=col, x=x, y=y, kind=tipo, owner=nombre))
                w = ancho_ovalo(col)
                esp.cajas.append((caja(x, y, w, OVAL_H, HOLGURA / 2), "a:" + nombre))
                p = borde_rect(e["x"], e["y"], e["w"], e["h"], x, y)
                esp.lineas.append((p, (x, y), "a:" + nombre))

    return dict(ENTITIES=ENTITIES, ENTITY_LABEL={}, RELATIONS=RELATIONS, ATTRS=ATTRS,
                NOTES=[], cruces=cruces(ENTITIES, RELATIONS),
                encimados=rombos_encimados(ENTITIES, RELATIONS),
                tramo=tramo_minimo(ENTITIES, RELATIONS))


def _modelo(tablas, info, propias, frontera, fks, pos, verbos, padre_total, rombos_fijos):
    ENTITIES = {}
    for n in propias + frontera:
        x, y = pos[n]
        ENTITIES[n] = dict(x=x, y=y, w=ancho_entidad(n), h=ENT_H,
                           kind="weak" if info[n]["debil"] else "strong")
    RELATIONS = []
    grupos = {}
    for h, f in fks:
        verbo, sujeto, papel_padre, papel_hija = verbos[f["nombre"]]
        ends, razon = extremos(h, f, verbo, sujeto, papel_padre, papel_hija,
                               f["nombre"] in padre_total)
        tipo = "identifying" if f["nombre"] in info[h]["identificadoras"] else "normal"
        rel = dict(id=f["nombre"], label=verbo, ratio=razon, kind=tipo, ends=ends, x=0, y=0)
        RELATIONS.append(rel)
        grupos.setdefault(tuple(sorted((h, f["ref"]))), []).append(rel)
    for (a, b), rels in grupos.items():
        ea, eb = ENTITIES[a], ENTITIES[b]
        if a == b:
            for i, rel in enumerate(rels):
                rel["x"], rel["y"] = ea["x"] + 700, ea["y"] - 500 - 300 * i
            continue
        mx, my = (ea["x"] + eb["x"]) / 2, (ea["y"] + eb["y"]) / 2
        dx, dy = eb["x"] - ea["x"], eb["y"] - ea["y"]
        L = math.hypot(dx, dy) or 1
        nx, ny = -dy / L, dx / L
        k = len(rels)
        for i, rel in enumerate(rels):
            off = (i - (k - 1) / 2) * SEP_PARALELAS
            rel["x"], rel["y"] = round(mx + nx * off), round(my + ny * off)
    for rel in RELATIONS:
        if rel["id"] in rombos_fijos:
            rel["x"], rel["y"] = rombos_fijos[rel["id"]]
    despejar_rombos(ENTITIES, RELATIONS, rombos_fijos)
    return ENTITIES, RELATIONS

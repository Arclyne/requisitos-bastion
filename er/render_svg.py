# -*- coding: utf-8 -*-
"""Renderiza el modelo E-R a SVG en notación de Chen."""

import math
from xml.sax.saxutils import escape
from model import ENTITIES, ENTITY_LABEL, RELATIONS, ATTRS, ATTR_BY_ID, NOTES

MARGIN = 140
INK = "#12263f"
ACCENT = "#0b5fa5"
CARD = "#b3261e"
ROLE = "#5b6b7c"

DIAMOND_W, DIAMOND_H = 260, 130
CH = 8.4          # ancho aproximado por carácter a 15.5px
PAD = 34
RECURSIVA_SEP = 45   # medio espacio entre las dos líneas de una relación recursiva


def oval_size(label):
    w = max(150, len(label) * CH + PAD * 2)
    return w / 2, 40


# ---------------------------------------------------------------- geometría
def clip_rect(cx, cy, w, h, tx, ty):
    """Punto del borde del rectángulo en dirección a (tx,ty)."""
    dx, dy = tx - cx, ty - cy
    if dx == 0 and dy == 0:
        return cx, cy
    sx = (w / 2) / abs(dx) if dx else float("inf")
    sy = (h / 2) / abs(dy) if dy else float("inf")
    s = min(sx, sy)
    return cx + dx * s, cy + dy * s


def clip_ellipse(cx, cy, rx, ry, tx, ty):
    dx, dy = tx - cx, ty - cy
    d = math.hypot(dx / rx, dy / ry) if (dx or dy) else 1
    return cx + dx / d, cy + dy / d


def clip_diamond(cx, cy, tx, ty):
    dx, dy = tx - cx, ty - cy
    a, b = DIAMOND_W / 2, DIAMOND_H / 2
    d = abs(dx) / a + abs(dy) / b
    if d == 0:
        return cx, cy
    return cx + dx / d, cy + dy / d


def salida(node, sx, sy, dx, dy):
    """Punto donde sale de la figura el rayo que parte de (sx, sy), dentro de ella,
    con dirección unitaria (dx, dy). Lo usan las relaciones recursivas."""
    def dentro(x, y):
        if node["_t"] == "entity":
            return abs(x - node["x"]) <= node["w"] / 2 and abs(y - node["y"]) <= node["h"] / 2
        return abs(x - node["x"]) / (DIAMOND_W / 2) + abs(y - node["y"]) / (DIAMOND_H / 2) <= 1
    lo, hi = 0.0, 1.0
    while dentro(sx + dx * hi, sy + dy * hi):
        hi *= 2
    for _ in range(40):
        mid = (lo + hi) / 2
        if dentro(sx + dx * mid, sy + dy * mid):
            lo = mid
        else:
            hi = mid
    return sx + dx * hi, sy + dy * hi


def clip_for(node, tx, ty):
    if node["_t"] == "entity":
        return clip_rect(node["x"], node["y"], node["w"], node["h"], tx, ty)
    if node["_t"] == "rel":
        return clip_diamond(node["x"], node["y"], tx, ty)
    rx, ry = oval_size(node["label"])
    return clip_ellipse(node["x"], node["y"], rx, ry, tx, ty)


# ---------------------------------------------------------------- primitivas
out = []


def add(s):
    out.append(s)


def line(x1, y1, x2, y2, double=False, arrow=False, wid=2.4, color=INK):
    ax = ' marker-end="url(#arw)"' if arrow else ""
    if not double:
        add(f'<line x1="{x1:.1f}" y1="{y1:.1f}" x2="{x2:.1f}" y2="{y2:.1f}" '
            f'stroke="{color}" stroke-width="{wid}"{ax}/>')
        return
    dx, dy = x2 - x1, y2 - y1
    L = math.hypot(dx, dy) or 1
    ox, oy = -dy / L * 5.5, dx / L * 5.5
    for k in (1, -1):
        a = ' marker-end="url(#arw)"' if (arrow and k == 1) else ""
        add(f'<line x1="{x1+ox*k:.1f}" y1="{y1+oy*k:.1f}" x2="{x2+ox*k:.1f}" '
            f'y2="{y2+oy*k:.1f}" stroke="{color}" stroke-width="{wid}"{a}/>')


def text(x, y, s, size=16, weight="400", color=INK, anchor="middle",
         underline=False, style="", halo=False):
    dec = ' text-decoration="underline"' if underline else ""
    st = f' font-style="{style}"' if style else ""
    if halo:   # copia inferior en blanco para separar el texto de las líneas
        add(f'<text x="{x:.1f}" y="{y:.1f}" font-family="Segoe UI, Arial, sans-serif" '
            f'font-size="{size}" font-weight="{weight}" fill="#ffffff" '
            f'stroke="#ffffff" stroke-width="7" stroke-linejoin="round" '
            f'text-anchor="{anchor}"{st}>{escape(s)}</text>')
    add(f'<text x="{x:.1f}" y="{y:.1f}" font-family="Segoe UI, Arial, sans-serif" '
        f'font-size="{size}" font-weight="{weight}" fill="{color}" '
        f'text-anchor="{anchor}"{dec}{st}>{escape(s)}</text>')


# ---------------------------------------------------------------- nodos
NODES = {}
for name, e in ENTITIES.items():
    NODES[name] = dict(_t="entity", label=ENTITY_LABEL.get(name, name), **e)
for r in RELATIONS:
    NODES[("rel", r["id"])] = dict(_t="rel", label=r["label"], x=r["x"], y=r["y"])
for a in ATTRS:
    NODES[("attr", a["id"])] = dict(_t="attr", label=a["label"], x=a["x"], y=a["y"])


def node_of(owner):
    if isinstance(owner, tuple):
        return NODES[owner]
    return NODES[owner]


# ---------------------------------------------------------------- límites
def _bounds():
    xs, ys = [], []
    for e in ENTITIES.values():
        xs += [e["x"] - e["w"] / 2, e["x"] + e["w"] / 2]
        ys += [e["y"] - e["h"] / 2, e["y"] + e["h"] / 2]
    for rr in RELATIONS:
        xs += [rr["x"] - DIAMOND_W / 2, rr["x"] + DIAMOND_W / 2]
        ys += [rr["y"] - DIAMOND_H / 2 - 46, rr["y"] + DIAMOND_H / 2]
    for aa in ATTRS:
        rx, ry = oval_size(aa["label"])
        xs += [aa["x"] - rx, aa["x"] + rx]
        ys += [aa["y"] - ry, aa["y"] + ry]
    return min(xs), min(ys), max(xs), max(ys)


_x0, _y0, _x1, _y1 = _bounds()
OX, OY = MARGIN - _x0, MARGIN - _y0
W = round(_x1 - _x0 + 2 * MARGIN)
H = round(_y1 - _y0 + 2 * MARGIN)

# ---------------------------------------------------------------- dibujo
add(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" '
    f'height="{H}" font-family="Segoe UI, Arial, sans-serif">')
add('<defs><marker id="arw" viewBox="0 0 12 12" refX="10" refY="6" markerWidth="9" '
    'markerHeight="9" orient="auto-start-reverse">'
    f'<path d="M0 1 L11 6 L0 11 z" fill="{INK}"/></marker></defs>')
add(f'<rect width="{W}" height="{H}" fill="#ffffff"/>')
add(f'<g transform="translate({OX},{OY})">')

# --- líneas atributo -> dueño (primero, para que queden debajo)
for a in ATTRS:
    owner = node_of(a["owner"])
    an = NODES[("attr", a["id"])]
    p1 = clip_for(an, owner["x"], owner["y"])
    p2 = clip_for(owner, an["x"], an["y"])
    line(p1[0], p1[1], p2[0], p2[1], wid=1.8)

# --- líneas relación -> entidad
for r in RELATIONS:
    rn = NODES[("rel", r["id"])]
    destinos = [e[0] for e in r["ends"]]
    vistos = {}
    for (ent, ctop, cbot, total, arrow, role) in r["ends"]:
        en = NODES[ent]
        if destinos.count(ent) > 1:
            # Relación recursiva (las dos puntas en la misma entidad): dos líneas
            # paralelas, una a cada lado del eje rombo-entidad.
            k = vistos.get(ent, 0)
            vistos[ent] = k + 1
            ddx, ddy = en["x"] - rn["x"], en["y"] - rn["y"]
            L0 = math.hypot(ddx, ddy) or 1
            ux, uy = ddx / L0, ddy / L0
            s = RECURSIVA_SEP if k == 0 else -RECURSIVA_SEP
            ox, oy = -uy * s, ux * s
            p1 = salida(rn, rn["x"] + ox, rn["y"] + oy, ux, uy)
            p2 = salida(en, en["x"] + ox, en["y"] + oy, -ux, -uy)
        else:
            p1 = clip_for(rn, en["x"], en["y"])
            p2 = clip_for(en, rn["x"], rn["y"])
        line(p1[0], p1[1], p2[0], p2[1], double=total, arrow=arrow, wid=2.6)

        # etiquetas de cardinalidad junto a la entidad
        dx, dy = p1[0] - p2[0], p1[1] - p2[1]
        L = math.hypot(dx, dy) or 1
        ux, uy = dx / L, dy / L
        bx, by = p2[0] + ux * 175, p2[1] + uy * 175
        nx, ny = -uy, ux
        text(bx + nx * 26, by + ny * 26 + 7, ctop, size=23, weight="700", color=CARD,
             halo=True)
        text(bx - nx * 26, by - ny * 26 + 7, cbot, size=23, weight="700", color=CARD,
             halo=True)

        if role:
            mx = p1[0] - ux * 130 + nx * 62
            my = p1[1] - uy * 130 + ny * 62
            text(mx, my + 6, f"rol: {role}", size=19, color=ROLE, style="italic",
                 halo=True)

# --- atributos
for a in ATTRS:
    rx, ry = oval_size(a["label"])
    x, y, k = a["x"], a["y"], a["kind"]
    dash = ' stroke-dasharray="11 8"' if k == "derived" else ""
    add(f'<ellipse cx="{x}" cy="{y}" rx="{rx:.1f}" ry="{ry}" fill="#ffffff" '
        f'stroke="{INK}" stroke-width="2.4"{dash}/>')
    if k == "multi":
        add(f'<ellipse cx="{x}" cy="{y}" rx="{rx-9:.1f}" ry="{ry-9}" fill="none" '
            f'stroke="{INK}" stroke-width="2"/>')
    text(x, y + 6, a["label"], size=17, weight="700" if k == "key" else "400",
         underline=(k == "key"), style="italic" if k == "derived" else "")

# --- relaciones (rombos)
for r in RELATIONS:
    x, y = r["x"], r["y"]
    a, b = DIAMOND_W / 2, DIAMOND_H / 2
    pts = f"{x},{y-b} {x+a},{y} {x},{y+b} {x-a},{y}"
    add(f'<polygon points="{pts}" fill="#ffffff" stroke="{INK}" stroke-width="2.6"/>')
    if r["kind"] == "identifying":
        a2, b2 = a - 13, b - 13
        add(f'<polygon points="{x},{y-b2} {x+a2},{y} {x},{y+b2} {x-a2},{y}" '
            f'fill="none" stroke="{INK}" stroke-width="2.2"/>')
    text(x, y + 7, r["label"], size=19, weight="600")
    text(x, y - b - 16, r["ratio"], size=23, weight="700", color=ACCENT, halo=True)

# --- entidades
for name, e in ENTITIES.items():
    x, y, w, h = e["x"], e["y"], e["w"], e["h"]
    add(f'<rect x="{x-w/2}" y="{y-h/2}" width="{w}" height="{h}" fill="#ffffff" '
        f'stroke="{INK}" stroke-width="3"/>')
    if e["kind"] == "weak":
        add(f'<rect x="{x-w/2+11}" y="{y-h/2+11}" width="{w-22}" height="{h-22}" '
            f'fill="none" stroke="{INK}" stroke-width="2.4"/>')
    text(x, y + 9, ENTITY_LABEL.get(name, name), size=27, weight="700")

# --- cierre del grupo del diagrama
add("</g>")
add("</svg>")

with open("diagrama_er.svg", "w", encoding="utf-8") as f:
    f.write("\n".join(out))
print(f"diagrama_er.svg escrito ({W}x{H})")

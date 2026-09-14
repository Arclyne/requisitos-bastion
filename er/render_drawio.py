# -*- coding: utf-8 -*-
"""Emite el mismo modelo E-R como archivo .drawio (mxGraph) editable."""

import math
from xml.sax.saxutils import escape
from model import ENTITIES, ENTITY_LABEL, RELATIONS, ATTRS

CH, PAD, OVAL_H = 8.4, 34, 80
DW, DH = 260, 130

cells = []
_n = [0]


def nid(prefix):
    _n[0] += 1
    return f"{prefix}{_n[0]}"


def vertex(cid, label, x, y, w, h, style):
    cells.append(
        f'<mxCell id="{cid}" value="{escape(label)}" style="{style}" vertex="1" '
        f'parent="1"><mxGeometry x="{x:.0f}" y="{y:.0f}" width="{w:.0f}" '
        f'height="{h:.0f}" as="geometry"/></mxCell>'
    )


def edge(cid, src, tgt, style, label="", points=None):
    geo = '<mxGeometry relative="1" as="geometry"/>'
    if points:   # puntos de paso, para separar las líneas de una relación recursiva
        pts = "".join(f'<mxPoint x="{x:.0f}" y="{y:.0f}"/>' for x, y in points)
        geo = f'<mxGeometry relative="1" as="geometry"><Array as="points">{pts}</Array></mxGeometry>'
    cells.append(
        f'<mxCell id="{cid}" value="{escape(label)}" style="{style}" edge="1" '
        f'parent="1" source="{src}" target="{tgt}">{geo}</mxCell>'
    )


def edge_label(parent, text, pos, offset_y):
    cells.append(
        f'<mxCell id="{nid("lb")}" value="{escape(text)}" '
        f'style="edgeLabel;html=1;align=center;verticalAlign=middle;'
        f'fontSize=17;fontStyle=1;fontColor=#B3261E;labelBackgroundColor=#FFFFFF;" '
        f'vertex="1" connectable="0" parent="{parent}">'
        f'<mxGeometry x="{pos}" y="{offset_y}" relative="1" as="geometry">'
        f'<mxPoint as="offset"/></mxGeometry></mxCell>'
    )


def role_label(parent, text, pos):
    cells.append(
        f'<mxCell id="{nid("rl")}" value="{escape(text)}" '
        f'style="edgeLabel;html=1;align=center;verticalAlign=middle;fontSize=13;'
        f'fontStyle=2;fontColor=#5B6B7C;labelBackgroundColor=#FFFFFF;" vertex="1" '
        f'connectable="0" parent="{parent}"><mxGeometry x="{pos}" y="-22" '
        f'relative="1" as="geometry"><mxPoint as="offset"/></mxGeometry></mxCell>'
    )


# ------------------------------------------------------------------ estilos
S_ENTITY = ("rounded=0;whiteSpace=wrap;html=1;fillColor=#FFFFFF;strokeColor=#12263F;"
            "strokeWidth=3;fontSize=22;fontStyle=1;fontColor=#12263F;")
S_WEAK = ("shape=ext;double=1;whiteSpace=wrap;html=1;fillColor=#FFFFFF;"
          "strokeColor=#12263F;strokeWidth=3;fontSize=22;fontStyle=1;"
          "fontColor=#12263F;")
S_REL = ("rhombus;whiteSpace=wrap;html=1;fillColor=#FFFFFF;strokeColor=#12263F;"
         "strokeWidth=2.5;fontSize=16;fontStyle=1;fontColor=#12263F;")
S_REL_ID = ("rhombus;double=1;whiteSpace=wrap;html=1;fillColor=#FFFFFF;"
            "strokeColor=#12263F;strokeWidth=2.5;fontSize=16;fontStyle=1;"
            "fontColor=#12263F;")
S_ATTR = ("ellipse;whiteSpace=wrap;html=1;fillColor=#FFFFFF;strokeColor=#12263F;"
          "strokeWidth=2;fontSize=14;fontColor=#12263F;")
S_ATTR_KEY = S_ATTR + "fontStyle=5;"          # negrita + subrayado
S_ATTR_DER = S_ATTR + "dashed=1;fontStyle=2;"
S_LINE = ("edgeStyle=none;html=1;rounded=0;endArrow=none;strokeColor=#12263F;"
          "strokeWidth=1.5;")
S_REL_LINE = ("edgeStyle=none;html=1;rounded=0;endArrow=none;strokeColor=#12263F;"
              "strokeWidth=2.2;")
S_REL_LINE_A = ("edgeStyle=none;html=1;rounded=0;endArrow=block;endFill=1;"
                "strokeColor=#12263F;strokeWidth=2.2;")

IDS = {}

# ------------------------------------------------------------------ nodos
for name, e in ENTITIES.items():
    cid = nid("e")
    IDS[name] = cid
    style = S_WEAK if e["kind"] == "weak" else S_ENTITY
    vertex(cid, ENTITY_LABEL.get(name, name),
           e["x"] - e["w"] / 2, e["y"] - e["h"] / 2, e["w"], e["h"], style)

for r in RELATIONS:
    cid = nid("r")
    IDS[("rel", r["id"])] = cid
    style = S_REL_ID if r["kind"] == "identifying" else S_REL
    vertex(cid, r["label"], r["x"] - DW / 2, r["y"] - DH / 2, DW, DH, style)
    # etiqueta de razón encima del rombo
    vertex(nid("rt"), r["ratio"], r["x"] - 60, r["y"] - DH / 2 - 52, 120, 40,
           "text;html=1;align=center;verticalAlign=middle;fontSize=19;fontStyle=1;"
           "fontColor=#0B5FA5;")

for a in ATTRS:
    cid = nid("a")
    IDS[("attr", a["id"])] = cid
    w = max(150, len(a["label"]) * CH + PAD * 2)
    style = {"key": S_ATTR_KEY, "derived": S_ATTR_DER}.get(a["kind"], S_ATTR)
    vertex(cid, a["label"], a["x"] - w / 2, a["y"] - OVAL_H / 2, w, OVAL_H, style)

# ------------------------------------------------------------------ aristas
for a in ATTRS:
    owner = a["owner"] if isinstance(a["owner"], tuple) else a["owner"]
    edge(nid("le"), IDS[("attr", a["id"])], IDS[owner], S_LINE)

for r in RELATIONS:
    rid = IDS[("rel", r["id"])]
    destinos = [e[0] for e in r["ends"]]
    vistos = {}
    for (ent, ctop, cbot, total, arrow, role) in r["ends"]:
        eid = nid("re")
        style = S_REL_LINE_A if arrow else S_REL_LINE
        if total:
            style += "shape=link;"
        puntos = None
        if destinos.count(ent) > 1:   # relación recursiva: un punto de paso a cada lado
            k = vistos.get(ent, 0)
            vistos[ent] = k + 1
            ex, ey = ENTITIES[ent]["x"], ENTITIES[ent]["y"]
            ddx, ddy = ex - r["x"], ey - r["y"]
            L0 = math.hypot(ddx, ddy) or 1
            s = 55 if k == 0 else -55
            puntos = [((r["x"] + ex) / 2 - ddy / L0 * s, (r["y"] + ey) / 2 + ddx / L0 * s)]
        edge(eid, rid, IDS[ent], style, points=puntos)
        edge_label(eid, ctop, 0.74, -24)
        edge_label(eid, cbot, 0.74, 24)
        if role:
            role_label(eid, f"rol: {role}", -0.55)

# ------------------------------------------------------------------ archivo
xml = (
    '<mxfile host="app.diagrams.net" modified="2026-09-03T00:00:00.000Z" '
    'agent="Claude" version="24.0.0" type="device">\n'
    '  <diagram id="er-quoridor" name="Modelo E-R">\n'
    '    <mxGraphModel dx="1600" dy="900" grid="0" gridSize="10" guides="1" '
    'tooltips="1" connect="1" arrows="1" fold="1" page="1" pageScale="1" '
    'pageWidth="4681" pageHeight="3300" math="0" shadow="0">\n'
    '      <root>\n'
    '        <mxCell id="0"/>\n'
    '        <mxCell id="1" parent="0"/>\n'
    + "\n".join("        " + c for c in cells) + "\n"
    '      </root>\n'
    '    </mxGraphModel>\n'
    '  </diagram>\n'
    '</mxfile>\n'
)

with open("diagrama_er.drawio", "w", encoding="utf-8") as f:
    f.write(xml)
print(f"diagrama_er.drawio escrito ({len(cells)} celdas)")

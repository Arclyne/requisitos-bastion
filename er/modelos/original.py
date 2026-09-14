# -*- coding: utf-8 -*-
"""Modelo E-R (notación de Chen) para el videojuego tipo Quoridor."""

import math

# ---------------------------------------------------------------- entidades
# kind: 'strong' | 'weak'
ENTITIES = {
    "Usuario":      dict(x=2100, y=1550, w=290, h=110, kind="strong"),
    "Reporte":      dict(x=3550, y=560,  w=290, h=110, kind="strong"),
    "Partida":      dict(x=4000, y=1550, w=290, h=110, kind="strong"),
    "Baneo":        dict(x=3400, y=2600, w=290, h=110, kind="strong"),
    "Estadisticas": dict(x=2100, y=2750, w=330, h=120, kind="weak"),
    "Skin":         dict(x=700,  y=2150, w=290, h=110, kind="strong"),
}

ENTITY_LABEL = {"Estadisticas": "Estadísticas"}

# --------------------------------------------------------------- relaciones
# kind: 'normal' | 'identifying'
# ends: (entidad, card_arriba, card_abajo, total?, flecha?, rol)
RELATIONS = [
    dict(id="tiene", label="Tiene", x=2100, y=2200, ratio="1:1", kind="identifying",
         ends=[("Usuario", "1", "1", False, True, None),
               ("Estadisticas", "1", "1", True, False, None)]),

    dict(id="posee", label="Posee", x=1350, y=1900, ratio="N:M", kind="normal",
         ends=[("Usuario", "1", "N", False, False, None),
               ("Skin", "M", "1", False, False, None)]),

    dict(id="equipa", label="Equipa", x=1620, y=2400, ratio="N:1", kind="normal",
         ends=[("Usuario", "1", "N", False, False, None),
               ("Skin", "1", "1", False, True, None)]),

    dict(id="participa", label="Participa", x=3150, y=1550, ratio="N:M", kind="normal",
         ends=[("Usuario", "1", "2,4", False, False, None),
               ("Partida", "N", "1", True, False, None)]),

    dict(id="emite", label="Emite", x=2620, y=800, ratio="1:N", kind="normal",
         ends=[("Usuario", "1", "1", False, True, "reportante"),
               ("Reporte", "N", "1", True, False, None)]),

    dict(id="senala", label="Señala", x=3120, y=1080, ratio="N:1", kind="normal",
         ends=[("Reporte", "1", "N", True, False, None),
               ("Usuario", "1", "1", False, True, "reportado")]),

    dict(id="sobre", label="Sobre", x=3950, y=870, ratio="N:1", kind="normal",
         ends=[("Reporte", "1", "N", False, False, None),
               ("Partida", "1", "1", False, True, None)]),

    dict(id="recibe", label="Recibe", x=2750, y=2200, ratio="1:N", kind="normal",
         ends=[("Usuario", "1", "1", False, True, None),
               ("Baneo", "N", "1", True, False, None)]),

    dict(id="origina", label="Origina", x=3700, y=2050, ratio="N:1", kind="normal",
         ends=[("Reporte", "1", "N", False, False, None),
               ("Baneo", "1", "1", True, False, None)]),
]

# --------------------------------------------------------------- atributos
# kind: 'key' | 'simple' | 'derived' | 'composite' | 'multi'
# owner: nombre de entidad, o ('rel', id_relacion), o ('attr', id_atributo_padre)
A = []


def arc(cx, cy, r, a0, a1, n):
    """n puntos equiespaciados sobre un arco (ángulos en grados, y invertida)."""
    out = []
    for i in range(n):
        t = a0 if n == 1 else a0 + (a1 - a0) * i / (n - 1)
        rad = math.radians(t)
        out.append((round(cx + r * math.cos(rad)), round(cy - r * math.sin(rad))))
    return out


# ---- Usuario ----------------------------------------------------------
u_names = [
    ("u_id",      "id_usuario",        "key"),
    ("u_nick",    "nickname",          "simple"),
    ("u_correo",  "correo",            "simple"),
    ("u_pass",    "contraseña",        "simple"),
    ("u_estado",  "estado_cuenta",     "simple"),
    ("u_freg",    "fecha_registro",    "simple"),
    ("u_idioma",  "idioma_preferido",  "simple"),
    ("u_region",  "región",            "simple"),
    ("u_nomc",    "nombre_completo",   "composite"),
    ("u_fnac",    "fecha_nacimiento",  "simple"),
    ("u_edad",    "edad",              "derived"),
]
for (aid, lab, k), (x, y) in zip(u_names, arc(2100, 1550, 1230, 86, 176, len(u_names))):
    A.append(dict(id=aid, label=lab, x=x, y=y, kind=k, owner="Usuario"))

# hijos del atributo compuesto nombre_completo
nomc = next(a for a in A if a["id"] == "u_nomc")
for (aid, lab), (x, y) in zip(
    [("u_n1", "nombre"), ("u_n2", "apellido_paterno"), ("u_n3", "apellido_materno")],
    arc(nomc["x"], nomc["y"], 470, 118, 208, 3),
):
    A.append(dict(id=aid, label=lab, x=x, y=y, kind="simple", owner=("attr", "u_nomc")))

# ---- Skin -------------------------------------------------------------
s_names = [
    ("s_id",    "id_skin",     "key"),
    ("s_nom",   "nombre_skin", "simple"),
    ("s_tipo",  "tipo",        "simple"),
    ("s_rar",   "rareza",      "simple"),
    ("s_costo", "costo",       "simple"),
]
for (aid, lab, k), (x, y) in zip(s_names, arc(700, 2150, 500, 128, 248, len(s_names))):
    A.append(dict(id=aid, label=lab, x=x, y=y, kind=k, owner="Skin"))

# ---- Estadisticas -----------------------------------------------------
e_names = [
    ("e_pj",   "partidas_jugadas",     "simple"),
    ("e_pg",   "partidas_ganadas",     "simple"),
    ("e_pp",   "partidas_perdidas",    "simple"),
    ("e_pct",  "porcentaje_victorias", "derived"),
    ("e_bar",  "barreras_colocadas",   "simple"),
    ("e_tmp",  "tiempo_total_jugado",  "simple"),
    ("e_elo",  "puntos_elo",           "simple"),
    ("e_rac",  "racha_actual",         "simple"),
]
for (aid, lab, k), (x, y) in zip(e_names, arc(2100, 2750, 610, 165, 335, len(e_names))):
    A.append(dict(id=aid, label=lab, x=x, y=y, kind=k, owner="Estadisticas"))

# ---- Partida ----------------------------------------------------------
p_names = [
    ("p_est",  "estado_partida",    "simple"),
    ("p_id",   "id_partida",        "key"),
    ("p_ini",  "fecha_hora_inicio", "simple"),
    ("p_fin",  "fecha_hora_fin",    "simple"),
    ("p_dur",  "duración",          "derived"),
    ("p_num",  "num_jugadores",     "simple"),
]
for (aid, lab, k), (x, y) in zip(p_names, arc(4000, 1550, 700, 66, -64, len(p_names))):
    A.append(dict(id=aid, label=lab, x=x, y=y, kind=k, owner="Partida"))

# ---- Reporte ----------------------------------------------------------
r_names = [
    ("r_id",   "id_reporte",     "key"),
    ("r_mot",  "motivo",         "simple"),
    ("r_desc", "descripción",    "simple"),
    ("r_fec",  "fecha_reporte",  "simple"),
    ("r_est",  "estado_reporte", "simple"),
]
for (aid, lab, k), (x, y) in zip(r_names, arc(3550, 560, 560, 150, 6, len(r_names))):
    A.append(dict(id=aid, label=lab, x=x, y=y, kind=k, owner="Reporte"))

# ---- Baneo ------------------------------------------------------------
b_names = [
    ("b_id",   "id_baneo",     "key"),
    ("b_tipo", "tipo_baneo",   "simple"),
    ("b_ini",  "fecha_inicio", "simple"),
    ("b_fin",  "fecha_fin",    "simple"),
    ("b_act",  "activo",       "derived"),
    ("b_nrep", "num_reportes", "derived"),
]
for (aid, lab, k), (x, y) in zip(b_names, arc(3400, 2600, 560, 15, -165, len(b_names))):
    A.append(dict(id=aid, label=lab, x=x, y=y, kind=k, owner="Baneo"))

# ---- atributos de relación -------------------------------------------
A.append(dict(id="po_fec", label="fecha_obtención", x=1350, y=1600, kind="simple",
              owner=("rel", "posee")))
for (aid, lab), (x, y) in zip(
    [("pa_res", "resultado"), ("pa_col", "color_ficha"),
     ("pa_ord", "orden_turno"), ("pa_bar", "barreras_restantes")],
    [(2760, 1900), (3000, 2010), (3240, 2000), (3400, 1830)],
):
    A.append(dict(id=aid, label=lab, x=x, y=y, kind="simple", owner=("rel", "participa")))

ATTRS = A
ATTR_BY_ID = {a["id"]: a for a in ATTRS}

NOTES = [
    ("Restricción no representable en el diagrama:",
     "una Partida admite exactamente 2 o 4 jugadores (nunca 3),",
     "por eso la participación de Usuario se acota con 2,4."),
]

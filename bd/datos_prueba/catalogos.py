# -*- coding: utf-8 -*-
"""Catálogos precargados (D-09). Ningún caso de uso los escribe; se cargan por SQL.

Los valores que fijan los casos de uso se toman de ellos: seis ranuras (D-03),
tres modos con sus muros (CU-21 RN-02), cuatro niveles de IA con su fuerza
(CU-27 RN-02), siete lecciones (CU-41 RN-01), cinco motivos de reporte (CU-42
RN-08) y las divisiones de la tabla de dominios del análisis CRUD. Los códigos,
precios, umbrales y probabilidades que ningún caso fija son de prueba.

Ningún catálogo guarda nombres visibles: cada fila tiene un código que es su
clave en los diccionarios de recursos, donde está su nombre en cada idioma (D-21).
"""

RANURAS = [  # id_ranura, codigo
    (1, "PEON"), (2, "MURO"), (3, "TABLERO"), (4, "TITULO"), (5, "MARCO"), (6, "EMOTES"),
]

# id_objeto, id_ranura, codigo, rareza, precio, nivel_requerido, a_la_venta, activo, es_inicial, es_predeterminado
OBJETOS = [
    (101, 1, "PEON_CLASICO",        "COMUN",      0,   1, 0, 1, 1, 1),
    (102, 1, "PEON_PIEDRA",         "COMUN",      0,   1, 0, 1, 1, 0),
    (103, 1, "PEON_CRISTAL",        "RARO",       250, 3, 1, 1, 0, 0),
    (104, 1, "PEON_DORADO",         "EPICO",      600, 8, 1, 1, 0, 0),
    (105, 1, "PEON_DRAGON",         "LEGENDARIO", 0,   1, 0, 1, 0, 0),
    (106, 1, "PEON_TEMPORADA_1",    "RARO",       0,   1, 0, 0, 0, 0),   # retirado del catálogo
    (201, 2, "MURO_MADERA",         "COMUN",      0,   1, 0, 1, 1, 1),
    (202, 2, "MURO_LADRILLO",       "COMUN",      150, 1, 1, 1, 0, 0),
    (203, 2, "MURO_HIELO",          "RARO",       0,   1, 0, 1, 0, 0),
    (204, 2, "MURO_RUNICO",         "EPICO",      500, 5, 1, 1, 0, 0),
    (301, 3, "TABLERO_CLASICO",     "COMUN",      0,   1, 0, 1, 1, 1),
    (302, 3, "TABLERO_MARMOL",      "RARO",       300, 4, 1, 1, 0, 0),
    (303, 3, "TABLERO_NOCTURNO",    "EPICO",      0,   1, 0, 1, 0, 0),
    (401, 4, "TITULO_NOVATO",       "COMUN",      0,   1, 0, 1, 1, 1),
    (402, 4, "TITULO_CONSTRUCTOR",  "RARO",       0,   3, 0, 1, 0, 0),   # recompensa de nivel
    (403, 4, "TITULO_ESTRATEGA",    "EPICO",      400, 6, 1, 1, 0, 0),
    (501, 5, "MARCO_SENCILLO",      "COMUN",      0,   1, 0, 1, 1, 1),
    (502, 5, "MARCO_PLATA",         "RARO",       200, 2, 1, 1, 0, 0),
    (503, 5, "MARCO_FUEGO",         "LEGENDARIO", 0,   1, 0, 1, 0, 0),
    (601, 6, "EMOTE_SALUDO",        "COMUN",      0,   1, 0, 1, 1, 1),
    (602, 6, "EMOTE_PULGAR_ARRIBA", "COMUN",      0,   1, 0, 1, 1, 0),
    (603, 6, "EMOTE_RISA",          "RARO",       120, 1, 1, 1, 0, 0),
    (604, 6, "EMOTE_APLAUSO",       "EPICO",      0,   1, 0, 1, 0, 0),
]

MODOS = [  # id_modo, codigo, tamano_tablero, num_jugadores, muros_por_jugador, activo
    (1, "CLASICO", 9, 2, 10, 1),
    (2, "CUATRO_JUGADORES", 9, 4, 5, 1),
    (3, "RAPIDA", 7, 2, 6, 1),
]

DIVISIONES = [  # id_division, codigo, elo_minimo, elo_descenso
    (1, "BRONCE", 0, 0),
    (2, "PLATA", 1030, 1010),
    (3, "ORO", 1150, 1130),
    (4, "MURO_PIEDRA", 1300, 1280),
]

NIVELES_IA = [  # id_nivel_ia, codigo, elo_aproximado
    (1, "APRENDIZ", 1000), (2, "CONSTRUCTOR", 1500), (3, "ARQUITECTO", 1900), (4, "BASTION", 2300),
]

LECCIONES = [  # id_leccion, orden, codigo, num_pasos
    (1, 1, "TABLERO_Y_META", 3),
    (2, 2, "MOVER_PEON", 4),
    (3, 3, "SALTAR_RIVAL", 4),
    (4, 4, "COLOCAR_MUROS", 5),
    (5, 5, "MUROS_SIN_ENCIERRO", 4),
    (6, 6, "RELOJ", 3),
    (7, 7, "PARTIDA_CUATRO", 4),
]

TIPOS_CAJA = [  # id_tipo_caja, codigo, precio, activo
    (1, "CAJA_MADERA", 300, 1),
    (2, "CAJA_HIERRO", 700, 1),
    (3, "CAJA_TEMPORADA_1", 500, 0),   # ya no se vende
]

CONTENIDO_CAJA = [  # id_tipo_caja, id_objeto, probabilidad (suman 100 por tipo)
    (1, 202, 30), (1, 603, 30), (1, 502, 20), (1, 203, 12), (1, 303, 5), (1, 604, 3),
    (2, 103, 25), (2, 302, 25), (2, 203, 20), (2, 604, 15), (2, 105, 10), (2, 503, 5),
    (3, 106, 60), (3, 603, 40),
]

PALABRAS = [  # termino, idioma (None: todos los idiomas, CU-28 RN-01), ambito
    ("tonto", "es-MX", "AMBOS"),
    ("idiota", "es-MX", "AMBOS"),
    ("estúpido", "es-MX", "CHAT"),
    ("admin", None, "NICKNAME"),
    ("moderador", "es-MX", "NICKNAME"),
    ("moderator", "en", "NICKNAME"),
    ("idiot", "en", "AMBOS"),
    ("stupid", "en", "CHAT"),
]

MOTIVOS = [  # id_motivo, codigo
    (1, "LENGUAJE_OFENSIVO"),
    (2, "ACOSO"),
    (3, "NOMBRE_INAPROPIADO"),
    (4, "TRAMPAS"),
    (5, "JUEGO_ANTIDEPORTIVO"),
]

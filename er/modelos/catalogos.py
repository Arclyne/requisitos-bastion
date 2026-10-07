# -*- coding: utf-8 -*-
"""Modelo E-R «Catálogos precargados», generado por er/generar.py a partir de
er/esquema.json y er/diagramas.py. Se puede retocar a mano y volver a dibujar
con: python er/generar.py --sin-disposicion catalogos"""

ENTITIES = {'Modo': {'x': 0, 'y': 0, 'w': 290, 'h': 110, 'kind': 'strong'},
 'PalabraProhibida': {'x': 910, 'y': 0, 'w': 309, 'h': 110, 'kind': 'strong'}}

ENTITY_LABEL = {}

RELATIONS = []

ATTRS = [{'id': 'Modo.id_modo', 'label': 'id_modo', 'x': -422, 'y': -126, 'kind': 'key', 'owner': 'Modo'},
 {'id': 'Modo.codigo', 'label': 'codigo', 'x': -370, 'y': -237, 'kind': 'simple', 'owner': 'Modo'},
 {'id': 'Modo.tamano_tablero',
  'label': 'tamano_tablero',
  'x': -261,
  'y': -354,
  'kind': 'simple',
  'owner': 'Modo'},
 {'id': 'Modo.num_jugadores',
  'label': 'num_jugadores',
  'x': -79,
  'y': -433,
  'kind': 'simple',
  'owner': 'Modo'},
 {'id': 'Modo.muros_por_jugador',
  'label': 'muros_por_jugador',
  'x': 141,
  'y': -417,
  'kind': 'simple',
  'owner': 'Modo'},
 {'id': 'Modo.activo', 'label': 'activo', 'x': 304, 'y': -318, 'kind': 'simple', 'owner': 'Modo'},
 {'id': 'PalabraProhibida.id_palabra',
  'label': 'id_palabra',
  'x': 613,
  'y': -325,
  'kind': 'key',
  'owner': 'PalabraProhibida'},
 {'id': 'PalabraProhibida.termino',
  'label': 'termino',
  'x': 749,
  'y': -410,
  'kind': 'simple',
  'owner': 'PalabraProhibida'},
 {'id': 'PalabraProhibida.idioma',
  'label': 'idioma',
  'x': 922,
  'y': -440,
  'kind': 'simple',
  'owner': 'PalabraProhibida'},
 {'id': 'PalabraProhibida.ambito',
  'label': 'ambito',
  'x': 1093,
  'y': -400,
  'kind': 'simple',
  'owner': 'PalabraProhibida'}]

ATTR_BY_ID = {a["id"]: a for a in ATTRS}

NOTES = []

# -*- coding: utf-8 -*-
"""Economía de prueba: compras, recompensas de nivel, cajas y equipamiento.

Las monedas de las partidas no se escriben aquí: el generador crea un
MovimientoMoneda de tipo PARTIDA por participante de cada partida
clasificatoria (CU-25 RN-08) con estas tarifas de prueba.
"""

MONEDAS_2J = {"GANADA": 100, "PERDIDA": 25, "TABLAS": 50}
MONEDAS_4J = {1: 150, 2: 60, 3: 40, 4: 25}          # por posición
CONVERSION = {"COMUN": 20, "RARO": 40, "EPICO": 80, "LEGENDARIO": 150}   # repetidos (CU-39 RN-03)
CADUCIDAD_DIAS = 14                                    # cajas ganadas jugando (CU-39 RN-06)

# usuario, id_objeto, fecha: compra en la tienda (CU-38).
COMPRAS = [
    (3, 603, "2026-07-21 18:00:00"),
    (3, 103, "2026-07-27 18:00:00"),
    (4, 202, "2026-08-16 19:00:00"),
    (5, 603, "2026-08-21 17:00:00"),
]

# usuario, nivel alcanzado, fecha, monedas, objeto, tipo de caja, estado de la caja (CU-25 FA-03).
RECOMPENSAS_NIVEL = [
    (3, 3, "2026-07-20 19:10:00", 100, 402, None, None),
    (4, 2, "2026-07-26 17:40:00", 0, None, 1, "CADUCADA"),
    (4, 3, "2026-08-15 19:10:00", 100, None, None, None),
    (5, 2, "2026-08-20 16:10:00", 100, None, 1, "SIN_ABRIR"),
    (3, 4, "2026-08-26 17:20:00", 100, None, None, None),
]

# usuario, tipo de caja, fecha de compra, fecha de apertura, objetos sorteados (CU-39).
CAJAS_COMPRADAS = [
    (3, 1, "2026-08-27 12:00:00", "2026-08-27 12:01:00", [202, 603, 203]),   # 603 ya lo tenía: se convierte
]

# usuario, id_objeto, fecha: cambios de equipamiento (CU-14). Solo se equipa lo que se posee.
EQUIPAR = [
    (3, 402, "2026-07-20 19:12:00"),
    (3, 603, "2026-07-21 18:01:00"),
    (3, 103, "2026-07-27 18:01:00"),
    (4, 202, "2026-08-16 19:01:00"),
    (5, 603, "2026-08-21 17:01:00"),
]

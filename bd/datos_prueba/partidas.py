# -*- coding: utf-8 -*-
"""Partidas de prueba y sus jugadas.

Notación del tablero: columnas a-i (a-g en 7×7) y filas 1-9 (1-7). El
jugador de orden 1 sale de la fila 1 hacia la última; el de orden 2, de la
última hacia la 1. En cuatro jugadores, el 2 sale de la columna a hacia la i
y el 4, de la i hacia la a. Un muro se nombra por el surco cuya esquina
superior derecha es su centro: "e3" con orientación HORIZONTAL separa e3-f3
de e4-f4; con VERTICAL separa e3-e4 de f3-f4.

Jugadas: ("M", actor, origen, destino) mueve un peón; ("W", actor, surco,
"H" o "V") coloca un muro. El actor es el id del usuario o "IA".
El generador valida las jugadas con las reglas del CU-20 y el CU-21.
"""

AZUL, ROJO, VERDE, AMARILLO = "AZUL", "ROJO", "VERDE", "AMARILLO"
L, M, P, S, I, R = 3, 4, 5, 6, 7, 9          # luis, marta, pedro, sofia, invitado, rayo

PARTIDAS = {
    # --- Serie clasificatoria luis-marta en el modo clásico: cinco partidas,
    #     tras las que los dos entran en una división (CU-25 RN-14).
    1: dict(modo=1, tipo="CLASIFICATORIA", inicio="2026-07-05 17:00:00", minutos=5,
            jugadores=[(L, 1, AZUL), (M, 2, ROJO)],
            jugadas=[("M", L, "e1", "e2"), ("W", M, "a7", "H"), ("M", L, "e2", "e3"), ("M", M, "e9", "d9"),
                     ("M", L, "e3", "e4"), ("W", M, "g7", "H"), ("M", L, "e4", "e5"), ("M", M, "d9", "d8"),
                     ("M", L, "e5", "e6"), ("W", M, "b3", "V"), ("M", L, "e6", "e7"), ("M", M, "d8", "d7"),
                     ("M", L, "e7", "e8"), ("W", M, "h2", "H"), ("M", L, "e8", "e9")],
            forma="META", resultados={L: "GANADA", M: "PERDIDA"}),
    2: dict(modo=1, tipo="CLASIFICATORIA", inicio="2026-07-08 18:00:00", minutos=5,
            jugadores=[(M, 1, AZUL), (L, 2, ROJO)],
            jugadas=[("M", M, "e1", "e2"), ("M", L, "e9", "e8"), ("M", M, "e2", "e3"), ("W", L, "d3", "H"),
                     ("M", M, "e3", "f3"), ("M", L, "e8", "e7")],
            forma="RENDICION", cierre_s=8, resultados={L: "GANADA", M: "PERDIDA"}),
    3: dict(modo=1, tipo="CLASIFICATORIA", inicio="2026-07-12 16:30:00", minutos=5,
            jugadores=[(L, 1, AZUL), (M, 2, ROJO)],
            jugadas=[("M", L, "e1", "f1"), ("M", M, "e9", "e8"), ("M", L, "f1", "f2"), ("M", M, "e8", "e7"),
                     ("W", L, "a5", "H"), ("M", M, "e7", "e6"), ("M", L, "f2", "f3"), ("M", M, "e6", "e5"),
                     ("W", L, "h6", "V"), ("M", M, "e5", "e4"), ("M", L, "f3", "f4"), ("M", M, "e4", "e3"),
                     ("W", L, "c7", "H"), ("M", M, "e3", "e2"), ("M", L, "f4", "f5"), ("M", M, "e2", "e1")],
            forma="META", resultados={L: "PERDIDA", M: "GANADA"}),
    4: dict(modo=1, tipo="CLASIFICATORIA", inicio="2026-07-20 19:00:00", minutos=5,
            jugadores=[(M, 1, AZUL), (L, 2, ROJO)],
            jugadas=[("M", M, "e1", "d1"), ("M", L, "e9", "e8"), ("M", M, "d1", "d2"), ("M", L, "e8", "e7"),
                     ("W", M, "f5", "V"), ("M", L, "e7", "e6"), ("M", M, "d2", "d3"), ("M", L, "e6", "e5"),
                     ("W", M, "b6", "H"), ("M", L, "e5", "e4"), ("M", M, "d3", "c3"), ("M", L, "e4", "e3"),
                     ("M", M, "c3", "c4"), ("M", L, "e3", "e2"), ("W", M, "g2", "H"), ("M", L, "e2", "e1")],
            forma="META", resultados={L: "GANADA", M: "PERDIDA"},
            ofertas=[(L, 4, "CADUCADA", 5)]),   # la jugada 5 de la rival la hace caducar (CU-22 RN-05)
    5: dict(modo=1, tipo="CLASIFICATORIA", inicio="2026-07-26 17:30:00", minutos=5,
            jugadores=[(L, 1, AZUL), (M, 2, ROJO)],
            jugadas=[("M", L, "e1", "e2"), ("M", M, "e9", "e8"), ("M", L, "e2", "e3"), ("M", M, "e8", "e7"),
                     ("M", L, "e3", "e4"), ("M", M, "e7", "e6"), ("M", L, "e4", "e5"), ("W", M, "a2", "V"),
                     ("M", L, "e5", "e7"),   # salta a la rival (CU-20 RN-03)
                     ("M", M, "e6", "e5"), ("M", L, "e7", "e8"), ("M", M, "e5", "e4"), ("M", L, "e8", "e9")],
            forma="META", resultados={L: "GANADA", M: "PERDIDA"}),
    # --- Rápida clasificatoria que termina en tablas acordadas (CU-22).
    6: dict(modo=3, tipo="CLASIFICATORIA", inicio="2026-08-10 18:00:00", minutos=3,
            jugadores=[(P, 1, AZUL), (S, 2, ROJO)],
            jugadas=[("M", P, "d1", "d2"), ("M", S, "d7", "d6"), ("W", P, "c5", "H"), ("M", S, "d6", "e6"),
                     ("M", P, "d2", "d3"), ("W", S, "c2", "H"), ("M", P, "d3", "d4"), ("M", S, "e6", "e5")],
            forma="TABLAS", resultados={P: "TABLAS", S: "TABLAS"},
            ofertas=[(S, 2, "RECHAZADA", 6), (S, 8, "ACEPTADA", 10)]),   # (quien, jugada, estado, segundos hasta la respuesta)
    # --- Cuatro jugadores: tres abandonan y gana el que queda (CU-25 FA-04).
    7: dict(modo=2, tipo="CLASIFICATORIA", inicio="2026-08-15 19:00:00", minutos=10,
            jugadores=[(L, 1, AZUL), (M, 2, ROJO), (P, 3, VERDE), (S, 4, AMARILLO)],
            jugadas=[("M", L, "e1", "e2"), ("M", M, "a5", "b5"), ("M", P, "e9", "e8"), ("M", S, "i5", "h5"),
                     ("M", L, "e2", "e3"), ("W", M, "b6", "H"),
                     ("M", S, "h5", "g5"),   # pedro abandonó en su turno
                     ("M", L, "e3", "e4"), ("M", M, "b5", "c5"),
                     ("M", L, "e4", "e5")],  # sofía abandonó en su turno; marta abandona en el suyo
            forma="ABANDONO", cierre_s=20,
            resultados={L: "GANADA", M: "PERDIDA", P: "PERDIDA", S: "PERDIDA"},
            posiciones={L: 1, M: 2, S: 3, P: 4},
            salidas={P: ("ABANDONO", 6), S: ("ABANDONO", 9), M: ("ABANDONO", 10)}),   # (forma, tras la jugada)
    # --- Contra la IA, sin reloj, con un deshacer y dos sugerencias (CU-27, D-12).
    8: dict(modo=1, tipo="IA", inicio="2026-08-20 16:00:00", minutos=None, nivel_ia=1,
            deshacer=(1, 1), sugerencias=(1, 2),     # (permitido, usados)
            jugadores=[(P, 1, AZUL)],
            jugadas=[("M", P, "e1", "e2"), ("M", "IA", "e9", "e8"), ("M", P, "e2", "e3"), ("W", "IA", "e4", "H"),
                     ("M", P, "e3", "d3"), ("M", "IA", "e8", "e7"),   # las dos se deshacen
                     ("M", P, "e3", "f3"), ("M", "IA", "e8", "e7"), ("M", P, "f3", "f4")],
            deshechas={5, 6}, forma="RENDICION", cierre_s=15, resultados={P: "PERDIDA"}),
    # --- La partida del reporte: luis gana a rayo, que lo insulta en el chat (CU-42).
    9: dict(modo=1, tipo="CLASIFICATORIA", inicio="2026-08-26 17:10:00", minutos=5,
            jugadores=[(L, 1, AZUL), (R, 2, ROJO)],
            jugadas=[("M", L, "e1", "e2"), ("M", R, "e9", "f9"), ("M", L, "e2", "e3"), ("W", R, "e5", "H"),
                     ("M", L, "e3", "e4"), ("M", R, "f9", "f8"), ("M", L, "e4", "e5"), ("W", R, "d6", "V"),
                     ("M", L, "e5", "d5"), ("M", R, "f8", "f7"), ("M", L, "d5", "d6"), ("M", R, "f7", "f6"),
                     ("M", L, "d6", "d7"), ("W", R, "h3", "H"), ("M", L, "d7", "d8"), ("M", R, "f6", "g6"),
                     ("M", L, "d8", "d9")],
            forma="META", resultados={L: "GANADA", R: "PERDIDA"}),
    # --- Privada desde la sala 1: la anfitriona eligió ocho muros (CU-18 RN-04).
    10: dict(modo=3, tipo="PRIVADA", inicio="2026-08-31 16:30:00", minutos=10, sala=1,
             jugadores=[(S, 1, AZUL), (I, 2, ROJO)],
             jugadas=[("M", S, "d1", "d2"), ("M", I, "d7", "c7"), ("M", S, "d2", "d3"), ("W", I, "e3", "V"),
                      ("M", S, "d3", "d4"), ("M", I, "c7", "c6"), ("M", S, "d4", "d5"), ("M", I, "c6", "c5"),
                      ("M", S, "d5", "d6"), ("W", I, "a1", "H"), ("M", S, "d6", "d7")],
             forma="META", resultados={S: "GANADA", I: "PERDIDA"}),
    # --- Rápida clasificatoria que pedro pierde por tiempo: su reloj llega a cero
    #     en su turno, antes de jugar (CU-20 FA-06, CU-25 FA-06).
    11: dict(modo=3, tipo="CLASIFICATORIA", inicio="2026-08-28 18:00:00", minutos=3,
             jugadores=[(M, 1, AZUL), (P, 2, ROJO)],
             jugadas=[("M", M, "d1", "d2"), ("M", P, "d7", "d6"), ("M", M, "d2", "d3"), ("W", P, "c3", "H"),
                      ("M", M, "d3", "e3"), ("M", P, "d6", "d5"), ("M", M, "e3", "e4")],
             forma="TIEMPO_AGOTADO", resultados={M: "GANADA", P: "PERDIDA"}),
    # --- En curso: luis contra sofía, con una oferta de tablas pendiente, un
    #     enlace de espectador y una desconexión ya resuelta de sofía (CU-26).
    12: dict(modo=1, tipo="CLASIFICATORIA", inicio="2026-09-01 17:30:00", minutos=5,
             jugadores=[(L, 1, AZUL), (S, 2, ROJO)],
             jugadas=[("M", L, "e1", "e2"), ("M", S, "e9", "e8"), ("M", L, "e2", "e3"), ("W", S, "e4", "H"),
                      ("M", L, "e3", "e4"), ("M", S, "e8", "e7")],
             en_curso=True, ofertas=[(S, 6, "PENDIENTE", None)],
             desconexiones={S: "2026-09-01 17:38:00"}),
}

# id_sala de las partidas privadas y su configuración (la sala 2 sigue abierta, sin partida).
SALAS = {
    1: dict(codigo="K7MTQ3", anfitrion=S, modo=3, muros=8, minutos=10, espectadores=1,
            creacion="2026-08-31 16:20:00", estado="CERRADA", partida=10),
    2: dict(codigo="QX7PRM", anfitrion=P, modo=1, muros=10, minutos=5, espectadores=1,
            creacion="2026-09-01 17:50:00", estado="ABIERTA", partida=None, actividad="2026-09-01 17:58:30"),
}

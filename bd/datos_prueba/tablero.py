# -*- coding: utf-8 -*-
"""Reglas del tablero para validar las jugadas de prueba (CU-20, CU-21) y cálculo del elo."""

COLUMNAS = "abcdefghi"


class JugadaInvalida(Exception):
    pass


def casilla(texto):
    return COLUMNAS.index(texto[0]), int(texto[1:])


def nombre(c, f):
    return f"{COLUMNAS[c]}{f}"


class Tablero:
    """Estado de una partida: peones, muros y muros restantes de cada actor."""

    def __init__(self, lado, salidas, muros_iniciales):
        self.lado = lado
        self.peones = {a: casilla(s) for a, s in salidas.items()}
        self.muros = set()                     # (columna, fila, "H" o "V")
        self.restantes = {a: muros_iniciales for a in salidas}

    def copia(self):
        t = Tablero.__new__(Tablero)
        t.lado, t.peones, t.muros, t.restantes = self.lado, dict(self.peones), set(self.muros), dict(self.restantes)
        return t

    def dentro(self, c, f):
        return 0 <= c < self.lado and 1 <= f <= self.lado

    def cortado(self, a, b):
        """¿Hay un muro entre dos casillas adyacentes?"""
        (c1, f1), (c2, f2) = sorted([a, b])
        if c1 == c2:        # paso vertical entre f1 y f1+1
            return (c1, f1, "H") in self.muros or (c1 - 1, f1, "H") in self.muros
        return (c1, f1, "V") in self.muros or (c1, f1 - 1, "V") in self.muros

    def ocupada(self, c):
        return c in self.peones.values()

    def mover(self, actor, origen, destino):
        o, d = casilla(origen), casilla(destino)
        if self.peones[actor] != o:
            raise JugadaInvalida(f"{actor} no está en {origen}")
        if not self.dentro(*d) or self.ocupada(d):
            raise JugadaInvalida(f"{destino} está fuera del tablero u ocupada")
        dc, df = d[0] - o[0], d[1] - o[1]
        if abs(dc) + abs(df) == 1:
            if self.cortado(o, d):
                raise JugadaInvalida(f"un muro corta {origen}-{destino}")
        elif abs(dc) + abs(df) == 2 and (dc == 0 or df == 0):
            medio = (o[0] + dc // 2, o[1] + df // 2)          # salto en recto (CU-20 RN-03)
            if not self.ocupada(medio) or self.cortado(o, medio) or self.cortado(medio, d):
                raise JugadaInvalida(f"salto {origen}-{destino} no permitido")
        elif abs(dc) == 1 and abs(df) == 1:
            if not self._diagonal(o, d):
                raise JugadaInvalida(f"salto diagonal {origen}-{destino} no permitido")
        else:
            raise JugadaInvalida(f"{origen}-{destino} no es un paso válido")
        self.peones[actor] = d

    def _diagonal(self, o, d):
        for medio in ((d[0], o[1]), (o[0], d[1])):            # el rival está al lado o delante
            if not self.ocupada(medio) or self.cortado(o, medio) or self.cortado(medio, d):
                continue
            detras = (2 * medio[0] - o[0], 2 * medio[1] - o[1])
            if not self.dentro(*detras) or self.ocupada(detras) or self.cortado(medio, detras):
                return True
        return False

    def poner_muro(self, actor, surco, orientacion):
        c, f = casilla(surco)
        if not (0 <= c < self.lado - 1 and 1 <= f < self.lado):
            raise JugadaInvalida(f"surco {surco} fuera del tablero")
        if self.restantes[actor] <= 0:
            raise JugadaInvalida(f"{actor} no tiene muros")
        otra = "V" if orientacion == "H" else "H"
        choques = [(c, f, otra)]                               # se cruzan en el mismo centro
        if orientacion == "H":
            choques += [(c - 1, f, "H"), (c, f, "H"), (c + 1, f, "H")]
        else:
            choques += [(c, f - 1, "V"), (c, f, "V"), (c, f + 1, "V")]
        if any(m in self.muros for m in choques):
            raise JugadaInvalida(f"el muro {surco} {orientacion} se solapa o se cruza con otro")
        self.muros.add((c, f, orientacion))
        self.restantes[actor] -= 1

    def en_meta(self, actor, meta):
        c, f = self.peones[actor]
        eje, valor = meta
        return (f if eje == "fila" else c + 1) == valor


def salidas_y_metas(lado, n_jugadores):
    """Casilla de salida y meta de cada orden de turno."""
    medio = COLUMNAS[lado // 2]
    base = {1: (f"{medio}1", ("fila", lado)), 2: (f"{medio}{lado}", ("fila", 1))}
    if n_jugadores == 4:
        mitad = lado // 2 + 1
        base = {1: (f"{medio}1", ("fila", lado)), 2: (f"a{mitad}", ("columna", lado)),
                3: (f"{medio}{lado}", ("fila", 1)), 4: (f"{COLUMNAS[lado - 1]}{mitad}", ("columna", 1))}
    return base


def elo_dos(ra, rb, puntos_a, k=32):
    """Elo de dos jugadores; puntos_a es 1, 0.5 o 0. Redondeo a entero, suma cero."""
    esperado = 1 / (1 + 10 ** ((rb - ra) / 400))
    delta = k * (puntos_a - esperado)
    delta = int(delta + 0.5) if delta >= 0 else -int(-delta + 0.5)
    return ra + delta, rb - delta


ELO_CUATRO = {1: 24, 2: 8, 3: -8, 4: -24}   # cambio por posición en cuatro jugadores

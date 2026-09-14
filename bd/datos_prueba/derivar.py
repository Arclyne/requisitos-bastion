# -*- coding: utf-8 -*-
"""Deduce, a partir del escenario, todo lo que el modelo guarda como consecuencia:
fechas de las jugadas, estado del tablero, elo, estadísticas, divisiones,
monedas y saldo, objetos, equipamiento y bitácora de acceso. Así los datos de
prueba cumplen por construcción las redundancias controladas del modelo."""

import math
from datetime import datetime, timedelta

from . import catalogos as cat, comunidad as com, cuentas as cu, economia as eco, partidas as pa
from .tablero import ELO_CUATRO, JugadaInvalida, Tablero, elo_dos, salidas_y_metas


def dt(s):
    return datetime.strptime(s, "%Y-%m-%d %H:%M:%S")


def seg(d):
    """Redondea hacia arriba al segundo (DATETIME2(0))."""
    return d if d.microsecond == 0 else d.replace(microsecond=0) + timedelta(seconds=1)


MODOS = {m[0]: m for m in cat.MODOS}
OBJETOS = {o[0]: o for o in cat.OBJETOS}
AHORA = dt(cu.AHORA)


def simular(pid, g):
    """Valida las jugadas y devuelve jugadas, estado final, fechas y turno."""
    _, _, lado, njug, muros_modo, _ = MODOS[g["modo"]]
    muros = pa.SALAS[g["sala"]]["muros"] if g.get("sala") else muros_modo
    orden = {u: o for u, o, _ in g["jugadores"]}
    if g["tipo"] == "IA":
        orden["IA"] = 2
    sm = salidas_y_metas(lado, njug if g["tipo"] != "IA" else 2)
    t = Tablero(lado, {a: sm[o][0] for a, o in orden.items()}, muros)
    ciclo = sorted(orden, key=orden.get)
    activos, salidas = list(ciclo), g.get("salidas", {})
    deshechas = g.get("deshechas", set())
    turno, reserva, acumulado, filas = ciclo[0], None, 0, []
    inicio = dt(g["inicio"])

    def siguiente(a):
        i = activos.index(a)
        return activos[(i + 1) % len(activos)]

    for n, (clase, actor, x, y) in enumerate(g["jugadas"], 1):
        tiempo = 2500 + (n * 7919 + pid * 104729) % 9000
        acumulado += tiempo
        if n in deshechas and reserva is None:
            reserva = t.copia()
        elif n not in deshechas and actor != turno:
            raise JugadaInvalida(f"partida {pid}, jugada {n}: juega {actor} y el turno es de {turno}")
        try:
            t.mover(actor, x, y) if clase == "M" else t.poner_muro(actor, x, y)
        except JugadaInvalida as e:
            raise JugadaInvalida(f"partida {pid}, jugada {n}: {e}") from None
        filas.append(dict(n=n, actor=actor, clase=clase, x=x, y=y, tiempo=tiempo,
                          fecha=inicio + timedelta(milliseconds=acumulado), deshecha=int(n in deshechas)))
        if n in deshechas:
            if n + 1 not in deshechas:
                t, reserva = reserva, None
            continue
        turno_final = turno = siguiente(actor)
        for a, (_, tras) in salidas.items():
            if tras == n and a in activos:
                if turno == a:
                    turno = siguiente(a)
                activos.remove(a)
    ultima = filas[-1]["fecha"]
    if not g.get("en_curso") and g["forma"] == "META":
        if not t.en_meta(filas[-1]["actor"], sm[orden[filas[-1]["actor"]]][1]):
            raise JugadaInvalida(f"partida {pid}: la última jugada no llega a meta")
    return dict(filas=filas, tablero=t, orden=orden, turno=orden[turno_final], ultima=ultima, muros=muros)


def partidas():
    """Filas de Partida, Participacion, Jugada y OfertaTablas; elo, estadísticas y monedas."""
    elo = {}                                  # (usuario, modo) -> elo vigente
    est = {(u, m[0]): dict(jugadas=0, ganadas=0, perdidas=0, racha=0, mejor=0, tiempo=0, barreras=0,
                           abandonos=0, elo=1000, maximo=1000, ultima=None, division=None)
           for u in cu.USUARIOS for m in cat.MODOS if m[5]}
    r = dict(partidas=[], participaciones=[], jugadas=[], ofertas=[], historial=[], monedas=[], sim={})
    for pid, g in sorted(pa.PARTIDAS.items()):
        s = simular(pid, g)
        r["sim"][pid] = s
        filas, t = s["filas"], s["tablero"]
        clasif, en_curso = g["tipo"] == "CLASIFICATORIA", g.get("en_curso", False)
        ofertas = []
        for k, (quien, n, estado, resp) in enumerate(g.get("ofertas", [])):
            f_oferta = seg(filas[n - 1]["fecha"] + timedelta(seconds=2))
            f_resp = None
            if estado == "CADUCADA":
                f_resp = seg(filas[resp - 1]["fecha"])
            elif estado != "PENDIENTE":
                f_resp = f_oferta + timedelta(seconds=resp)
            ofertas.append((quien, n, f_oferta, estado, f_resp))
        if en_curso:
            fin = None
        elif g["forma"] == "TABLAS":
            fin = max(o[4] for o in ofertas if o[3] == "ACEPTADA")
        elif g["forma"] == "TIEMPO_AGOTADO":
            # el reloj de quien pierde llega a cero en su turno, sin jugada (CU-20 FA-06)
            sin_tiempo = next(u for u, res in g["resultados"].items() if res == "PERDIDA")
            resto = g["minutos"] * 60000 - sum(f["tiempo"] for f in filas if f["actor"] == sin_tiempo)
            fin = seg(s["ultima"] + timedelta(milliseconds=resto))
        else:
            fin = seg(s["ultima"] + timedelta(seconds=g.get("cierre_s", 0)))
        r["ofertas"] += [(pid,) + o for o in ofertas]
        r["partidas"].append(dict(id=pid, g=g, fin=fin, turno=s["turno"]))
        for f in filas:
            r["jugadas"].append((pid, f))
        # elo de la partida (CU-25 RN-04): el de entrada queda en la participación
        entrada = {u: elo.get((u, g["modo"]), 1000) for u, _, _ in g["jugadores"]} if clasif else {}
        salida = {}
        if clasif and not en_curso:
            if len(g["jugadores"]) == 2:
                (a, _, _), (b, _, _) = g["jugadores"]
                puntos = {"GANADA": 1, "PERDIDA": 0, "TABLAS": 0.5}[g["resultados"][a]]
                salida[a], salida[b] = elo_dos(entrada[a], entrada[b], puntos)
            else:
                salida = {u: entrada[u] + ELO_CUATRO[g["posiciones"][u]] for u in entrada}
        for u, o, simbolo in g["jugadores"]:
            reloj = None
            if g["minutos"]:
                reloj = g["minutos"] * 60000 - sum(f["tiempo"] for f in filas if f["actor"] == u)
                if not en_curso and g["forma"] == "TIEMPO_AGOTADO" and g["resultados"][u] == "PERDIDA":
                    reloj = 0
            casilla = "abcdefghi"[t.peones[u][0]] + str(t.peones[u][1])
            res = None if en_curso else g["resultados"][u]
            r["participaciones"].append(dict(
                partida=pid, usuario=u, orden=o, simbolo=simbolo, casilla=casilla, muros=t.restantes[u],
                reloj=reloj, elo_ini=entrada.get(u), elo_fin=salida.get(u), resultado=res,
                posicion=g.get("posiciones", {}).get(u), forma=g.get("salidas", {}).get(u, (None,))[0],
                desconexion=g.get("desconexiones", {}).get(u)))
            if not clasif or en_curso:
                continue
            e = est[(u, g["modo"])]
            e["jugadas"] += 1
            e["ganadas"] += res == "GANADA"
            e["perdidas"] += res == "PERDIDA"
            e["racha"] = e["racha"] + 1 if (res == "GANADA" and g["forma"] == "META") else 0
            e["mejor"] = max(e["mejor"], e["racha"])
            e["tiempo"] += int((fin - dt(g["inicio"])).total_seconds())
            e["barreras"] += sum(1 for f in filas if f["actor"] == u and f["clase"] == "W" and not f["deshecha"])
            e["abandonos"] += (g.get("salidas", {}).get(u, (None,))[0] == "ABANDONO"
                               or (g["forma"] == "ABANDONO" and len(g["jugadores"]) == 2 and res == "PERDIDA"))
            e["elo"] = elo[(u, g["modo"])] = salida[u]
            e["maximo"] = max(e["maximo"], salida[u])
            e["ultima"] = fin
            _division(r, e, u, g["modo"], fin)
            monedas = (eco.MONEDAS_4J[g["posiciones"][u]] if len(g["jugadores"]) == 4
                       else eco.MONEDAS_2J[res])
            r["monedas"].append(dict(usuario=u, tipo="PARTIDA", importe=monedas, fecha=fin, partida=pid))
    r["estadisticas"] = est
    return r


def _division(r, e, usuario, modo, fecha):
    """División tras la partida: hacen falta cinco partidas (CU-25 RN-14)."""
    if e["jugadas"] < 5:
        return
    divs = sorted(cat.DIVISIONES, key=lambda d: d[2])
    nueva = e["division"]
    if nueva is None:
        nueva = max(d[0] for d in divs if d[2] <= e["elo"])
    else:
        actual = next(d for d in divs if d[0] == nueva)
        mayores = [d for d in divs if d[2] > actual[2]]
        if mayores and e["elo"] >= mayores[0][2]:
            nueva = mayores[0][0]
        elif e["elo"] < actual[3] and actual[2] > 0:
            nueva = max(d[0] for d in divs if d[2] < actual[2])
    if nueva != e["division"]:
        r["historial"].append((usuario, modo, e["division"], nueva, fecha))
        e["division"] = nueva


def economia(monedas_partidas):
    """Objetos poseídos, equipamiento, cajas, contenido y movimientos, en orden de fecha."""
    posee = {u: {o[0]: ("INICIAL", dt(v["registro"])) for o in cat.OBJETOS if o[8]} for u, v in cu.USUARIOS.items()}
    movs = list(monedas_partidas)
    cajas, contenido, sin_raro = [], [], {u: 0 for u in cu.USUARIOS}
    eventos = ([("compra", dt(f), u, o) for u, o, f in eco.COMPRAS]
               + [("nivel", dt(r[2]), r[0], r[1:]) for r in eco.RECOMPENSAS_NIVEL]
               + [("caja", dt(c[2]), c[0], c) for c in eco.CAJAS_COMPRADAS])
    for clase, fecha, u, x in sorted(eventos, key=lambda e: e[1]):
        if clase == "compra":
            obj = OBJETOS[x]
            assert obj[6] and obj[7] and x not in posee[u], f"compra inválida {u} {x}"
            assert obj[5] <= cu.USUARIOS[u]["nivel"], f"nivel insuficiente {u} {x}"
            posee[u][x] = ("COMPRA", fecha)
            movs.append(dict(usuario=u, tipo="COMPRA", importe=-obj[4], fecha=fecha, objeto=x))
        elif clase == "nivel":
            _, _, monedas, objeto, tipo_caja, estado = x
            if monedas:
                movs.append(dict(usuario=u, tipo="NIVEL", importe=monedas, fecha=fecha))
            if objeto:
                posee[u][objeto] = ("NIVEL", fecha)
            if tipo_caja:
                cajas.append(dict(id=len(cajas) + 1, usuario=u, tipo=tipo_caja, origen="PARTIDA", estado=estado,
                                  obtencion=fecha, apertura=None,
                                  caducidad=fecha + timedelta(days=eco.CADUCIDAD_DIAS)))
        else:
            _, tipo, f_compra, f_abre, sorteo = x
            posibles = {o for tc, o, _ in cat.CONTENIDO_CAJA if tc == tipo}
            assert set(sorteo) <= posibles, "objeto fuera del tipo de caja"
            cid = len(cajas) + 1
            cajas.append(dict(id=cid, usuario=u, tipo=tipo, origen="COMPRA", estado="ABIERTA",
                              obtencion=fecha, apertura=dt(f_abre), caducidad=None))
            precio = next(t[2] for t in cat.TIPOS_CAJA if t[0] == tipo)
            movs.append(dict(usuario=u, tipo="COMPRA_CAJA", importe=-precio, fecha=fecha, caja=cid))
            raro = False
            for numero, o in enumerate(sorteo, 1):
                conv = None
                if o in posee[u]:
                    conv = eco.CONVERSION[OBJETOS[o][3]]
                    movs.append(dict(usuario=u, tipo="CONVERSION", importe=conv, fecha=dt(f_abre), caja=cid, objeto=o))
                else:
                    posee[u][o] = ("CAJA", dt(f_abre))
                raro |= OBJETOS[o][3] != "COMUN"
                contenido.append((cid, numero, o, conv))
            sin_raro[u] = 0 if raro else sin_raro[u] + 1
    movs.sort(key=lambda m: m["fecha"])
    saldo = {u: 0 for u in cu.USUARIOS}
    for m in movs:
        saldo[m["usuario"]] += m["importe"]
        assert saldo[m["usuario"]] >= 0, f"saldo negativo de {m['usuario']} el {m['fecha']}"
    return dict(posee=posee, movimientos=movs, cajas=cajas, contenido=contenido, saldo=saldo, sin_raro=sin_raro)


def equipamiento_en(usuario, fecha):
    """Objeto equipado en cada ranura en un instante (CU-14): predeterminados y cambios posteriores."""
    eq = {o[1]: o[0] for o in cat.OBJETOS if o[9]}
    for u, o, f in sorted(eco.EQUIPAR, key=lambda e: e[2]):
        if u == usuario and dt(f) <= fecha:
            eq[OBJETOS[o][1]] = o
    return eq


def bitacora_acceso():
    """Altas, verificaciones e inicios de sesión, más los registros explícitos, en orden de fecha."""
    filas = [(u, None,
              "REGISTRO_EXITOSO" if v["tipo"] == "REGISTRADA" else "ALTA_INVITADO",
              next((s[4] for s in cu.SESIONES.values() if s[0] == u), "201.141.5.60"), dt(v["registro"]))
             for u, v in cu.USUARIOS.items()]
    for u, prop, _, gen, estado in cu.TOKENS_VERIFICACION.values():
        if prop == "ALTA" and estado == "USADO":
            ip = next((s[4] for s in cu.SESIONES.values() if s[0] == u), "201.141.5.60")
            filas.append((u, None, "CUENTA_VERIFICADA", ip, dt(gen) + timedelta(minutes=10)))
    for u, inicio, _, _, ip, _, _, _ in cu.SESIONES.values():
        v = cu.USUARIOS[u]
        if v["tipo"] == "REGISTRADA":   # tras la baja no queda el nickname tecleado (D-17)
            filas.append((u, None if v["estado"] == "ELIMINADA" else v["nickname"], "EXITO", ip, dt(inicio)))
    filas += [(u, i, res, ip, dt(f)) for u, i, res, ip, f in com.BITACORA_ACCESO]
    return sorted(filas, key=lambda f: f[4])

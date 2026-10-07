# -*- coding: utf-8 -*-
"""Escribe bd/insertar_datos_prueba.sql (núcleo),
bd/fase_posterior/insertar_datos_prueba_fase_posterior.sql y bd/tex/datos-prueba*.tex
a partir del escenario de bd/datos_prueba/.

Requiere er/esquema.json y er/esquema-fase-posterior.json, que escribe
bd/generar_tablas.ps1: de ellos sale qué tabla va a cada script.

Uso, desde la raíz del repositorio:
    python bd/generar_datos_prueba.py

El escenario (cuentas, partidas con sus jugadas, economía y comunidad) está en
bd/datos_prueba/; lo que el modelo guarda como consecuencia (elo, estadísticas,
divisiones, saldo, estado del tablero, bitácora) lo calcula derivar.py, así que
los datos respetan las redundancias controladas del documento. El script SQL
termina con consultas que lo comprueban en la propia base.
"""

import json
import re
import sys
from datetime import datetime, timedelta
from pathlib import Path

AQUI = Path(__file__).resolve().parent
sys.path.insert(0, str(AQUI))

from datos_prueba import catalogos as cat, comunidad as com, cuentas as cu, partidas as pa  # noqa: E402
from datos_prueba import derivar as de  # noqa: E402


class Crudo(str):
    """Expresión SQL que se escribe tal cual."""


def valor(v):
    if v is None:
        return "NULL"
    if isinstance(v, Crudo):
        return str(v)
    if isinstance(v, bool):
        return str(int(v))
    if isinstance(v, (int, float)):
        return str(v)
    if isinstance(v, datetime):
        ms = f".{v.microsecond // 1000:03d}" if v.microsecond else ""
        return f"'{v:%Y-%m-%dT%H:%M:%S}{ms}'"
    return "N'" + str(v).replace("'", "''") + "'"


def hash_(algoritmo, texto):
    return Crudo(f"HASHBYTES('{algoritmo}', '{texto}')")


def f(s):
    return de.dt(s) if s else None


TABLAS = []          # (tabla, columnas, filas, identidad, comentario)


def tabla(nombre, columnas, filas, identidad=False, comentario=""):
    TABLAS.append((nombre, columnas.split(), filas, identidad, comentario))


def literal_unicode(texto):
    """El texto como expresión SQL que no depende de cómo se lea el archivo: los
    tramos ASCII como literales N'...' y cada carácter fuera de ASCII como
    NCHAR(punto de código). Los mayores de 65535, como los emojis, exigen una
    intercalación _SC, que es la de la base (D-21)."""
    partes, tramo = [], ""
    for c in texto:
        if ord(c) < 128:
            tramo += c
            continue
        if tramo:
            partes.append("N'" + tramo.replace("'", "''") + "'")
            tramo = ""
        partes.append(f"NCHAR({ord(c)})")
    if tramo:
        partes.append("N'" + tramo.replace("'", "''") + "'")
    return " + ".join(partes)


def textos_unicode(tablas=None):
    """Consulta que devuelve cada texto con caracteres fuera de ASCII que no se
    lee idéntico al que se insertó, comparando en binario."""
    textos = {}
    for nombre, columnas, filas, _, _ in (TABLAS if tablas is None else tablas):
        for fila in filas:
            for col, v in zip(columnas, fila):
                if isinstance(v, str) and not isinstance(v, Crudo) and any(ord(c) > 127 for c in v):
                    textos.setdefault((nombre, col), []).append(v)
    bloques = []
    for (nombre, col), valores in textos.items():
        filas = ",\n".join(f"                  ({literal_unicode(v)})" for v in dict.fromkeys(valores))
        bloques.append(f"          SELECT e.v FROM (VALUES\n{filas}) AS e(v)\n"
                       f"          WHERE NOT EXISTS (SELECT 1 FROM dbo.{nombre} AS t "
                       f"WHERE t.{col} = e.v COLLATE Latin1_General_100_BIN2)")
    return "\n          UNION ALL\n".join(bloques), sum(len(set(v)) for v in textos.values())


def fila_partida(p):
    g = p["g"]
    ia = ((g["deshacer"][0], g["sugerencias"][0], g["deshacer"][1], g["sugerencias"][1])
          if g["tipo"] == "IA" else (None, None, None, None))
    return (p["id"], g["modo"], g["tipo"], "EN_CURSO" if p["fin"] is None else "FINALIZADA", g["minutos"],
            f(g["inicio"]), p["fin"], g.get("forma") if p["fin"] else None, p["turno"], g.get("nivel_ia")) + ia


def construir():
    ahora = de.AHORA
    # --- catálogos
    tabla("Ranura", "id_ranura codigo", cat.RANURAS,
          comentario="Cada catálogo guarda el código de cada fila; su nombre está en los diccionarios de recursos (D-21).")
    tabla("ObjetoCosmetico", "id_objeto id_ranura codigo rareza precio nivel_requerido a_la_venta activo es_inicial "
          "es_predeterminado", cat.OBJETOS)
    tabla("Modo", "id_modo codigo tamano_tablero num_jugadores muros_por_jugador activo", cat.MODOS)
    tabla("Division", "id_division codigo elo_minimo elo_descenso", cat.DIVISIONES)
    tabla("NivelIA", "id_nivel_ia codigo elo_aproximado", cat.NIVELES_IA)
    tabla("Leccion", "id_leccion orden codigo num_pasos", cat.LECCIONES)
    tabla("TipoCaja", "id_tipo_caja codigo precio activo", cat.TIPOS_CAJA)
    tabla("TipoCajaObjeto", "id_tipo_caja id_objeto probabilidad", cat.CONTENIDO_CAJA)
    tabla("PalabraProhibida", "id_palabra termino idioma ambito", [(i,) + p for i, p in enumerate(cat.PALABRAS, 1)], True,
          "Un término sin idioma se filtra en todos (CU-18 RN-01).")
    tabla("MotivoReporte", "id_motivo codigo", cat.MOTIVOS)

    part = de.partidas()
    eco = de.economia(part["monedas"])

    # --- cuentas
    filas = []
    for u, v in cu.USUARIOS.items():
        clave = v["clave"]
        filas.append((u, v["tipo"], v["estado"], v["rol"], v["nickname"], v["correo"],
                      hash_("SHA2_512", f"{clave}:{v['nickname']}") if clave else None,
                      hash_("SHA2_256", f"sal:{v['nickname']}") if clave else None,
                      Crudo(f"'{v['nacimiento']}'") if v["nacimiento"] else None, v["idioma"], v["codigo"],
                      v["icono"], v["espectadores"], v["nivel"], v["experiencia"], eco["saldo"][u], eco["sin_raro"][u],
                      v["intentos"], f(v["ultimo_intento"]), f(v["bloqueada"]), v["doble_factor"], f(v["registro"]),
                      f(v["configuracion"]), f(v["envio_verificacion"]), f(v["envio_recuperacion"]), f(v["baja"])))
    tabla("Usuario", "id_usuario tipo_cuenta estado_cuenta rol nickname correo contrasena_hash contrasena_sal "
          "fecha_nacimiento idioma_preferido codigo_amigo id_icono permite_espectadores nivel experiencia "
          "saldo_monedas cajas_sin_raro intentos_fallidos fecha_ultimo_intento_fallido bloqueada_hasta "
          "doble_factor_habilitado fecha_registro fecha_configuracion_inicial fecha_ultimo_envio_verificacion "
          "fecha_ultimo_envio_recuperacion fecha_baja", filas, True,
          "Saldo y cajas sin objeto raro salen de los movimientos y cajas de más abajo.")
    tabla("Sesion", "id_sesion id_usuario token_hash fecha_inicio fecha_expiracion fecha_ultimo_uso fecha_fin "
          "motivo_cierre direccion_ip huella_dispositivo nombre_dispositivo version_cliente",
          [(i, s[0], hash_("SHA2_256", f"sesion:{i}"), f(s[1]), f(s[1]) + timedelta(hours=24), f(s[7]), f(s[2]),
            s[3], s[4], s[5], s[6], "1.0.2") for i, s in cu.SESIONES.items()], True)
    tabla("CodigoSegundoFactor", "id_codigo id_usuario codigo_hash canal fecha_generacion fecha_expiracion intentos estado",
          [(i, c[0], hash_("SHA2_256", f"codigo:{i}"), c[1], f(c[2]), f(c[2]) + timedelta(minutes=5), c[3], c[4])
           for i, c in cu.CODIGOS_2FA.items()], True)
    tabla("TokenVerificacionCorreo", "id_token id_usuario token_hash proposito correo_destino fecha_generacion fecha_expiracion estado",
          [(i, t[0], hash_("SHA2_256", f"verificacion:{i}"), t[1], t[2], f(t[3]), f(t[3]) + timedelta(hours=24), t[4])
           for i, t in cu.TOKENS_VERIFICACION.items()], True)
    tabla("TokenRecuperacion", "id_token id_usuario token_hash fecha_generacion fecha_expiracion intentos estado",
          [(i, t[0], hash_("SHA2_256", f"recuperacion:{i}"), f(t[1]), f(t[1]) + timedelta(minutes=30), t[2], t[3])
           for i, t in cu.TOKENS_RECUPERACION.items()], True)
    tabla("AceptacionTerminos", "id_aceptacion id_usuario version_terminos idioma fecha_aceptacion direccion_ip",
          [(i, a[0], a[1], cu.USUARIOS[a[0]]["idioma"], f(a[2]), a[3]) for i, a in enumerate(cu.ACEPTACIONES, 1)], True,
          "Cada cuenta aceptó el texto en su idioma preferido (CU-02 RN-12).")
    tabla("HistorialNickname", "id_usuario nickname_anterior fecha_cambio", [(u, n, f(x)) for u, n, x in cu.HISTORIAL_NICKNAME])
    tabla("Avatar", "id_avatar id_usuario ruta_imagen formato tamano_bytes fecha_subida vigente",
          [(i, a[0], a[1], a[2], a[3], f(a[4]), a[5]) for i, a in cu.AVATARES.items()], True)
    tabla("EnlaceRed", "id_enlace id_usuario orden url", [(i,) + e for i, e in cu.ENLACES_RED.items()], True)

    # --- perfil: objetos y equipamiento
    tabla("UsuarioObjeto", "id_usuario id_objeto fecha_obtencion origen",
          sorted((u, o, fecha, origen) for u, objs in eco["posee"].items() for o, (origen, fecha) in objs.items()),
          comentario="Los iniciales de toda cuenta (CU-02 RN-08), las compras, las recompensas y lo que salió en cajas.")
    tabla("Equipamiento", "id_usuario id_ranura id_objeto",
          [(u, r, o) for u in cu.USUARIOS for r, o in sorted(de.equipamiento_en(u, ahora).items())])

    # --- partidas
    tabla("Partida", "id_partida id_modo tipo estado minutos_reloj fecha_inicio fecha_fin forma_termino turno_actual "
          "id_nivel_ia permite_deshacer permite_sugerencias deshacer_usados sugerencias_usadas",
          [fila_partida(p) for p in part["partidas"]], True)
    tabla("Participacion", "id_partida id_usuario orden_turno simbolo_peon casilla_actual muros_restantes reloj_restante "
          "elo_inicial elo_final resultado posicion forma_termino conectado fecha_desconexion",
          [(x["partida"], x["usuario"], x["orden"], x["simbolo"], x["casilla"], x["muros"], x["reloj"], x["elo_ini"],
            x["elo_fin"], x["resultado"], x["posicion"], x["forma"], 1, f(x["desconexion"])) for x in part["participaciones"]])
    tabla("ParticipacionObjeto", "id_partida id_usuario id_ranura id_objeto",
          [(x["partida"], x["usuario"], r, o) for x in part["participaciones"]
           for r, o in sorted(de.equipamiento_en(x["usuario"], f(pa.PARTIDAS[x["partida"]]["inicio"])).items())],
          comentario="El aspecto que cada jugador tenía equipado al empezar (DES-07 RN-03).")
    tabla("Jugada", "id_partida numero_jugada id_usuario tipo casilla_origen casilla_destino surco orientacion "
          "tiempo_consumido fecha_jugada deshecha",
          [(pid, j["n"], None if j["actor"] == "IA" else j["actor"], "MOVIMIENTO" if j["clase"] == "M" else "MURO",
            j["x"] if j["clase"] == "M" else None, j["y"] if j["clase"] == "M" else None,
            j["x"] if j["clase"] == "W" else None,
            ("HORIZONTAL" if j["y"] == "H" else "VERTICAL") if j["clase"] == "W" else None,
            j["tiempo"], j["fecha"], j["deshecha"]) for pid, j in part["jugadas"]])
    tabla("OfertaTablas", "id_oferta id_partida id_ofertante numero_jugada fecha_oferta estado fecha_respuesta",
          [(i,) + o for i, o in enumerate(part["ofertas"], 1)], True)
    tabla("EnlaceEspectador", "id_enlace id_partida id_creador token_hash fecha_creacion",
          [(i, e[0], e[1], hash_("SHA2_256", f"espectador:{i}"), f(e[2])) for i, e in com.ENLACES_ESPECTADOR.items()], True)

    # --- salas, chat y cola
    fines = {p["id"]: p["fin"] for p in part["partidas"]}
    tabla("Sala", "id_sala codigo id_anfitrion id_modo muros_por_jugador minutos_reloj permite_espectadores estado "
          "id_partida fecha_creacion fecha_ultima_actividad",
          [(i, s["codigo"], s["anfitrion"], s["modo"], s["muros"], s["minutos"], s["espectadores"], s["estado"],
            s["partida"], f(s["creacion"]), fines[s["partida"]] if s["partida"] else f(s["actividad"]))
           for i, s in pa.SALAS.items()], True)
    tabla("SalaParticipante", "id_usuario id_sala plaza listo fecha_union", [x[:4] + (f(x[4]),) for x in com.SALA_PARTICIPANTES])
    tabla("Invitacion", "id_invitacion id_sala id_emisor id_destinatario fecha_invitacion fecha_expiracion estado",
          [(i, x[0], x[1], x[2], f(x[3]), f(x[3]) + timedelta(seconds=60), x[4]) for i, x in com.INVITACIONES.items()], True)
    tabla("Mensaje", "id_mensaje id_autor canal id_partida id_sala texto fecha_envio",
          [(i,) + m[:5] + (f(m[5]),) for i, m in enumerate(sorted(com.MENSAJES, key=lambda m: m[5]), 1)], True)
    tabla("ColaEmparejamiento", "id_usuario id_modo minutos_reloj fecha_entrada", [x[:3] + (f(x[3]),) for x in com.COLA])

    # --- clasificación y economía
    tabla("EstadisticaModo", "id_usuario id_modo puntos_elo fecha_ultima_partida elo_maximo partidas_jugadas "
          "partidas_ganadas partidas_perdidas racha_actual mejor_racha tiempo_total_jugado barreras_colocadas "
          "abandonos id_division",
          [(u, m, e["elo"], e["ultima"], e["maximo"], e["jugadas"], e["ganadas"], e["perdidas"], e["racha"], e["mejor"],
            e["tiempo"], e["barreras"], e["abandonos"], e["division"]) for (u, m), e in sorted(part["estadisticas"].items())],
          comentario="Una fila por cuenta y modo activo (CU-02 RN-06); los contadores resumen sus partidas clasificatorias.")
    tabla("HistorialDivision", "id_historial_division id_usuario id_modo id_division_anterior id_division_nueva fecha_cambio",
          [(i,) + h for i, h in enumerate(part["historial"], 1)], True)
    tabla("Caja", "id_caja id_usuario id_tipo_caja origen estado fecha_obtencion fecha_apertura fecha_caducidad",
          [(c["id"], c["usuario"], c["tipo"], c["origen"], c["estado"], c["obtencion"], c["apertura"], c["caducidad"])
           for c in eco["cajas"]], True)
    tabla("CajaContenido", "id_caja numero id_objeto monedas_conversion", eco["contenido"])
    tabla("MovimientoMoneda", "id_movimiento id_usuario tipo importe fecha_movimiento id_partida id_objeto id_caja",
          [(i, m["usuario"], m["tipo"], m["importe"], m["fecha"], m.get("partida"), m.get("objeto"), m.get("caja"))
           for i, m in enumerate(eco["movimientos"], 1)], True)

    # --- relaciones entre jugadores y tutorial
    tabla("Amistad", "id_usuario_a id_usuario_b fecha_amistad", [(a, b, f(x)) for a, b, x in com.AMISTADES])
    tabla("Solicitud", "id_solicitud id_solicitante id_destinatario fecha_solicitud",
          [(i, s[0], s[1], f(s[2])) for i, s in com.SOLICITUDES.items()], True)
    tabla("Silencio", "id_usuario id_silenciado fecha_silencio", [(a, b, f(x)) for a, b, x in com.SILENCIOS])
    tabla("Bloqueo", "id_bloqueador id_bloqueado fecha_bloqueo", [(a, b, f(x)) for a, b, x in com.BLOQUEOS])
    tabla("ProgresoTutorial", "id_usuario id_leccion paso_actual fecha_actualizacion fecha_completada",
          [t[:3] + (f(t[3]), f(t[4])) for t in com.TUTORIAL])

    # --- moderación y bitácoras
    tabla("Reporte", "id_reporte id_denunciante id_reportado id_motivo descripcion id_partida fecha_reporte estado "
          "id_moderador fecha_asignacion nota_resolucion fecha_resolucion",
          [(i, r[0], r[1], r[2], r[3], r[4], f(r[5]), r[6], r[7], f(r[8]), r[9], f(r[10])) for i, r in com.REPORTES.items()], True)
    tabla("Sancion", "id_sancion id_usuario id_moderador id_reporte ambito tipo motivo fecha_inicio fecha_fin fecha_retiro "
          "id_sancion_sustituta",
          [(i, s[0], s[1], s[2], s[3], s[4], s[5], f(s[6]), f(s[7]), f(s[8]), None) for i, s in com.SANCIONES.items()], True,
          "La sustituta se enlaza después con UPDATE, cuando ya existe (DES-18 RN-09).")
    tabla("Apelacion", "id_apelacion id_sancion texto marca_lenguaje fecha_apelacion estado id_moderador fecha_asignacion "
          "nota_resolucion fecha_resolucion",
          [(i, a[0], a[1], a[2], f(a[3]), a[4], a[5], f(a[6]), a[7], f(a[8])) for i, a in com.APELACIONES.items()], True)
    tabla("BitacoraModeracion", "id_bitacora id_moderador accion id_usuario_afectado detalle fecha_hora",
          [(i,) + b[:4] + (f(b[4]),) for i, b in enumerate(sorted(com.BITACORA_MODERACION, key=lambda b: b[4]), 1)], True)
    tabla("BitacoraAcceso", "id_bitacora id_usuario identificador_capturado resultado direccion_ip fecha_hora",
          [(i,) + b for i, b in enumerate(de.bitacora_acceso(), 1)], True)
    return part


# ---------------------------------------------------------------------------
# Reparto entre el núcleo y la fase posterior (D-22, D-23, D-24)
#
# El escenario se construye completo, como antes, y aquí se reparte: las filas
# de las tablas del núcleo van a insertar_datos_prueba.sql con las columnas que
# el núcleo tiene; las tablas, columnas y partidas de los agregados van a
# fase_posterior/insertar_datos_prueba_fase_posterior.sql.
# ---------------------------------------------------------------------------

# Columnas del núcleo que se difieren a la fase posterior, por tabla.
DIFERIDAS = {
    "Usuario": ["codigo_amigo", "id_icono", "permite_espectadores", "nivel", "experiencia", "saldo_monedas",
                "cajas_sin_raro", "fecha_configuracion_inicial"],
    "EstadisticaModo": ["elo_maximo", "racha_actual", "mejor_racha", "tiempo_total_jugado", "barreras_colocadas",
                        "id_division"],
    "Sala": ["permite_espectadores"],
    "Partida": ["id_nivel_ia", "permite_deshacer", "permite_sugerencias", "deshacer_usados", "sugerencias_usadas"],
    "Jugada": ["deshecha"],
}
LLAVES = {"Usuario": ["id_usuario"], "EstadisticaModo": ["id_usuario", "id_modo"], "Sala": ["id_sala"]}
# Estado que vive en la memoria del Servidor de partidas (D-24).
EN_MEMORIA = {"ColaEmparejamiento", "SalaParticipante"}


def _esquema(nombre):
    return json.loads((AQUI.parent / "er" / nombre).read_text(encoding="utf-8-sig"))


def _sin(columnas, filas, quitar):
    idx = [i for i, c in enumerate(columnas) if c not in quitar]
    return [columnas[i] for i in idx], [tuple(f[i] for i in idx) for f in filas]


def repartir():
    """Devuelve (núcleo, fase, actualizaciones, retiradas)."""
    nucleo_n = [t["nombre"] for t in _esquema("esquema.json")]
    fase_n = [t["nombre"] for t in _esquema("esquema-fase-posterior.json")]
    orig = {n: (c, f, i, k) for n, c, f, i, k in TABLAS}
    nucleo, fase, act, retiradas = [], [], [], {}

    ids_ia = {f[0] for f in orig["Partida"][1] if f[orig["Partida"][0].index("tipo")] == "IA"}

    for n in EN_MEMORIA:
        retiradas[n] = len(orig[n][1])
    retiradas["MotivoReporte"] = len(orig["MotivoReporte"][1])
    retiradas["AceptacionTerminos"] = len(orig["AceptacionTerminos"][1])
    for n in ("TokenVerificacionCorreo", "TokenRecuperacion", "CodigoSegundoFactor"):
        retiradas[n] = len(orig[n][1])

    def agregar(n, columnas, filas, identidad, comentario, lista):
        lista.append((n, list(columnas), list(filas), identidad, comentario))

    for n in nucleo_n:
        if n == "CodigoVerificacion":
            filas = []
            c, f, _, _ = orig["TokenVerificacionCorreo"]
            for x in f:
                d = dict(zip(c, x))
                filas.append((d["id_usuario"], d["proposito"], d["token_hash"], d["correo_destino"],
                              d["fecha_generacion"], d["fecha_expiracion"], 0, d["estado"]))
            c, f, _, _ = orig["TokenRecuperacion"]
            for x in f:
                d = dict(zip(c, x))
                filas.append((d["id_usuario"], "RECUPERACION", d["token_hash"], None, d["fecha_generacion"],
                              d["fecha_expiracion"], d["intentos"], d["estado"]))
            c, f, _, _ = orig["CodigoSegundoFactor"]
            for x in f:
                d = dict(zip(c, x))
                filas.append((d["id_usuario"], "SEGUNDO_FACTOR", d["codigo_hash"], None, d["fecha_generacion"],
                              d["fecha_expiracion"], d["intentos"], "USADO" if d["estado"] == "CONSUMIDO" else d["estado"]))
            filas.sort(key=lambda r: (r[4], r[0]))
            filas = [(i,) + r for i, r in enumerate(filas, 1)]
            agregar(n, "id_codigo id_usuario proposito codigo_hash correo_destino fecha_generacion fecha_expiracion "
                       "intentos estado".split(), filas, True,
                    "Los tokens de verificación y de recuperación y los códigos del segundo factor, en una sola tabla (D-23).",
                    nucleo)
            continue
        c, f, i, k = orig[n]
        if n == "Usuario":
            ult = {}
            for u, version, fecha, _ in cu.ACEPTACIONES:
                if u not in ult or de.dt(fecha) > ult[u][1]:
                    ult[u] = (version, de.dt(fecha))
            c = list(c) + ["version_terminos", "idioma_terminos", "fecha_aceptacion_terminos"]
            f = [x + ((ult[x[0]][0], cu.USUARIOS[x[0]]["idioma"], ult[x[0]][1]) if x[0] in ult else (None, None, None))
                 for x in f]
            k = (k + " " if k else "") + "La última versión de los términos que aceptó cada cuenta (D-23)."
        if n == "Reporte":
            motivos = dict(cat.MOTIVOS)
            j = c.index("id_motivo")
            c = list(c); c[j] = "motivo"
            f = [x[:j] + (motivos[x[j]],) + x[j + 1:] for x in f]
        if n in ("Partida", "Participacion", "Jugada", "Mensaje"):
            j = c.index("id_partida")
            ia = [x for x in f if x[j] in ids_ia]
            f = [x for x in f if x[j] not in ids_ia]
            if ia:
                agregar(n, c, ia, i, "La partida contra la IA (D-12).", fase)
        if n in DIFERIDAS:
            if n in LLAVES:
                llaves = LLAVES[n]
                cols = [x for x in DIFERIDAS[n] if x in c]
                act.append((n, llaves, cols, [tuple(dict(zip(c, x))[y] for y in llaves + cols) for x in f]))
            c, f = _sin(c, f, set(DIFERIDAS[n]))
        agregar(n, c, f, i, k, nucleo)

    # la partida de la IA se inserta completa en la fase posterior, después de las columnas nuevas
    ia_tablas = [t for t in fase]
    fase = []
    for n in fase_n:
        c, f, i, k = orig[n]
        agregar(n, c, f, i, k, fase)
    return nucleo, fase, ia_tablas, act, retiradas


COMPROBACIONES_NUCLEO = r"""
/*---------------------------------------------------------------------
  Comprobación: cada fila debe mostrar 0 incoherencias. Recalcula en la
  propia base las redundancias controladas y las reglas que los datos de
  prueba deben cumplir.
---------------------------------------------------------------------*/
SELECT comprobacion, incoherencias FROM (
    SELECT 1 AS n, N'Partidas, victorias y derrotas por modo' AS comprobacion, COUNT(*) AS incoherencias
    FROM dbo.EstadisticaModo AS e
    CROSS APPLY (SELECT COUNT(*) AS jugadas,
                        SUM(CASE WHEN p.resultado = 'GANADA' THEN 1 ELSE 0 END) AS ganadas,
                        SUM(CASE WHEN p.resultado = 'PERDIDA' THEN 1 ELSE 0 END) AS perdidas
                 FROM dbo.Participacion AS p JOIN dbo.Partida AS pa ON pa.id_partida = p.id_partida
                 WHERE p.id_usuario = e.id_usuario AND pa.id_modo = e.id_modo
                   AND pa.tipo = 'CLASIFICATORIA' AND p.resultado IS NOT NULL) AS c
    WHERE e.partidas_jugadas <> c.jugadas OR e.partidas_ganadas <> ISNULL(c.ganadas, 0) OR e.partidas_perdidas <> ISNULL(c.perdidas, 0)
    UNION ALL
    SELECT 2, N'Elo vigente igual al último elo final', COUNT(*)
    FROM dbo.EstadisticaModo AS e
    WHERE e.puntos_elo <> ISNULL((SELECT TOP (1) p.elo_final FROM dbo.Participacion AS p
                                  JOIN dbo.Partida AS pa ON pa.id_partida = p.id_partida
                                  WHERE p.id_usuario = e.id_usuario AND pa.id_modo = e.id_modo AND p.elo_final IS NOT NULL
                                  ORDER BY pa.fecha_fin DESC), 1000)
    UNION ALL
    SELECT 3, N'Muros restantes: los iniciales menos los colocados', COUNT(*)
    FROM dbo.Participacion AS p
    JOIN dbo.Partida AS pa ON pa.id_partida = p.id_partida
    JOIN dbo.Modo AS mo ON mo.id_modo = pa.id_modo
    LEFT JOIN dbo.Sala AS s ON s.id_partida = pa.id_partida
    WHERE p.muros_restantes <> COALESCE(s.muros_por_jugador, mo.muros_por_jugador)
          - (SELECT COUNT(*) FROM dbo.Jugada AS j WHERE j.id_partida = p.id_partida AND j.id_usuario = p.id_usuario
             AND j.tipo = 'MURO')
    UNION ALL
    SELECT 4, N'Reloj restante: el inicial menos el consumido, o cero si se agotó', COUNT(*)
    FROM dbo.Participacion AS p JOIN dbo.Partida AS pa ON pa.id_partida = p.id_partida
    WHERE p.reloj_restante <> CASE WHEN pa.forma_termino = 'TIEMPO_AGOTADO' AND p.resultado = 'PERDIDA' THEN 0
          ELSE pa.minutos_reloj * 60000
          - ISNULL((SELECT SUM(j.tiempo_consumido) FROM dbo.Jugada AS j WHERE j.id_partida = p.id_partida AND j.id_usuario = p.id_usuario), 0) END
    UNION ALL
    SELECT 5, N'Casilla actual igual a la de la última jugada', COUNT(*)
    FROM dbo.Participacion AS p
    CROSS APPLY (SELECT TOP (1) j.casilla_destino FROM dbo.Jugada AS j
                 WHERE j.id_partida = p.id_partida AND j.id_usuario = p.id_usuario AND j.tipo = 'MOVIMIENTO'
                 ORDER BY j.numero_jugada DESC) AS ultima
    WHERE p.casilla_actual <> ultima.casilla_destino
    UNION ALL
    SELECT 6, N'Estadísticas de cada cuenta en cada modo activo (CU-02 RN-06)', COUNT(*)
    FROM dbo.Usuario AS u CROSS JOIN dbo.Modo AS m
    WHERE m.activo = 1 AND NOT EXISTS (SELECT 1 FROM dbo.EstadisticaModo AS e WHERE e.id_usuario = u.id_usuario AND e.id_modo = m.id_modo)
    UNION ALL
    SELECT 7, N'Un ganador en cada partida decidida', COUNT(*)
    FROM dbo.Partida AS pa
    WHERE pa.estado = 'FINALIZADA' AND pa.forma_termino <> 'TABLAS'
      AND (SELECT COUNT(*) FROM dbo.Participacion AS p WHERE p.id_partida = pa.id_partida AND p.resultado = 'GANADA') <> 1
    UNION ALL
    SELECT 8, N'Dos o cuatro participantes por partida, según su modo', COUNT(*)
    FROM dbo.Partida AS pa JOIN dbo.Modo AS mo ON mo.id_modo = pa.id_modo
    WHERE (SELECT COUNT(*) FROM dbo.Participacion AS p WHERE p.id_partida = pa.id_partida) <> mo.num_jugadores
    UNION ALL
    SELECT 9, N'Segundo factor activado con un código emitido (CU-04 FA-10)', COUNT(*)
    FROM dbo.Usuario AS u
    WHERE u.doble_factor_habilitado = 1
      AND NOT EXISTS (SELECT 1 FROM dbo.CodigoVerificacion AS c WHERE c.id_usuario = u.id_usuario AND c.proposito = 'SEGUNDO_FACTOR')
    UNION ALL
    SELECT 10, N'Textos con ñ, acentos y emojis idénticos a los insertados (D-21)', COUNT(*)
    FROM (
@TEXTOS_UNICODE@
         ) AS distintos
) AS c
ORDER BY n;

-- Filas cargadas por tabla.
SELECT t.name AS tabla, SUM(p.rows) AS filas
FROM sys.tables AS t
JOIN sys.partitions AS p ON p.object_id = t.object_id AND p.index_id IN (0, 1)
GROUP BY t.name
ORDER BY t.name;
GO
"""

COMPROBACIONES_FASE = r"""
/*---------------------------------------------------------------------
  Comprobación de la fase posterior: cada fila debe mostrar 0.
---------------------------------------------------------------------*/
SELECT comprobacion, incoherencias FROM (
    SELECT 1 AS n, N'Saldo igual a la suma de movimientos (DES-15 RN-02)' AS comprobacion, COUNT(*) AS incoherencias
    FROM dbo.Usuario AS u
    WHERE u.saldo_monedas <> ISNULL((SELECT SUM(m.importe) FROM dbo.MovimientoMoneda AS m WHERE m.id_usuario = u.id_usuario), 0)
    UNION ALL
    SELECT 2, N'Muros colocados en partidas clasificatorias', COUNT(*)
    FROM dbo.EstadisticaModo AS e
    WHERE e.barreras_colocadas <> (SELECT COUNT(*) FROM dbo.Jugada AS j JOIN dbo.Partida AS pa ON pa.id_partida = j.id_partida
                                   WHERE j.id_usuario = e.id_usuario AND pa.id_modo = e.id_modo AND pa.tipo = 'CLASIFICATORIA'
                                     AND pa.estado = 'FINALIZADA' AND j.tipo = 'MURO' AND j.deshecha = 0)
    UNION ALL
    SELECT 3, N'División solo a partir de cinco partidas (CU-16 RN-12)', COUNT(*)
    FROM dbo.EstadisticaModo AS e
    WHERE (e.id_division IS NULL AND e.partidas_jugadas >= 5) OR (e.id_division IS NOT NULL AND e.partidas_jugadas < 5)
    UNION ALL
    SELECT 4, N'Un objeto equipado en cada ranura (DES-07 RN-01)', COUNT(*)
    FROM dbo.Usuario AS u
    WHERE (SELECT COUNT(*) FROM dbo.Equipamiento AS e WHERE e.id_usuario = u.id_usuario) <> (SELECT COUNT(*) FROM dbo.Ranura)
    UNION ALL
    SELECT 5, N'Aspecto fijado en cada ranura por participación', COUNT(*)
    FROM dbo.Participacion AS p
    WHERE (SELECT COUNT(*) FROM dbo.ParticipacionObjeto AS o WHERE o.id_partida = p.id_partida AND o.id_usuario = p.id_usuario)
          <> (SELECT COUNT(*) FROM dbo.Ranura)
    UNION ALL
    SELECT 6, N'Objetos iniciales de cada cuenta (CU-02 RN-08)', COUNT(*)
    FROM dbo.Usuario AS u CROSS JOIN dbo.ObjetoCosmetico AS o
    WHERE o.es_inicial = 1 AND NOT EXISTS (SELECT 1 FROM dbo.UsuarioObjeto AS uo WHERE uo.id_usuario = u.id_usuario AND uo.id_objeto = o.id_objeto)
    UNION ALL
    SELECT 7, N'Probabilidades de cada tipo de caja que suman 100', COUNT(*)
    FROM (SELECT id_tipo_caja FROM dbo.TipoCajaObjeto GROUP BY id_tipo_caja HAVING SUM(probabilidad) <> 100) AS x
    UNION ALL
    SELECT 8, N'Tres objetos en cada caja abierta (DES-14 RN-07)', COUNT(*)
    FROM dbo.Caja AS c
    WHERE c.estado = 'ABIERTA' AND (SELECT COUNT(*) FROM dbo.CajaContenido AS x WHERE x.id_caja = c.id_caja) <> 3
    UNION ALL
    SELECT 9, N'Textos con ñ, acentos y emojis idénticos a los insertados (D-21)', COUNT(*)
    FROM (
@TEXTOS_UNICODE@
         ) AS distintos
) AS c
ORDER BY n;
GO
"""

CABECERA_NUCLEO = """/*=====================================================================
  Bastion - Inserción de datos de prueba del núcleo (3 de 3)
  Motor: SQL Server 2019 o posterior (CON-04).

  Orden de ejecución:
     1. crear_base_datos.sql
     2. crear_tablas.sql
     3. insertar_datos_prueba.sql  <- este archivo

  Archivo generado por bd/generar_datos_prueba.py a partir del escenario de
  bd/datos_prueba/. No editar a mano: se edita el escenario y se vuelve a
  generar.

  Carga los catálogos del núcleo y la parte del escenario de prueba que
  cabe en las @NUM@ tablas del núcleo. Es una fotografía de la base el @AHORA@
  UTC. Lo que el escenario tiene de los agregados (objetos, monedas, cajas,
  divisiones, amigos, la partida contra la IA) se carga después con
  fase_posterior/insertar_datos_prueba_fase_posterior.sql (D-22).
  Lo que el modelo guarda como consecuencia de otras filas (elo,
  estadísticas, estado del tablero) se calculó a partir de ellas, y las
  consultas del final lo comprueban.

  Se ejecuta con una cuenta de administración sobre las tablas recién
  creadas y vacías: fija los identificadores con IDENTITY_INSERT, que
  BastionServerConnection no puede usar. Todo va en una transacción: si
  una fila falla, no se carga ninguna.

  El archivo está en UTF-8: se ejecuta con sqlcmd -f 65001, o se abre en
  SQL Server Management Studio, que lo reconoce por su marca de orden de
  bytes. Los textos van como literales N'...', con sus eñes y acentos, y la
  última comprobación verifica que se guardaron sin pérdida (D-21).
=====================================================================*/
"""

CABECERA_FASE = """/*=====================================================================
  Bastion - Inserción de datos de prueba de la fase posterior
  Motor: SQL Server 2019 o posterior (CON-04).

  Se ejecuta después de fase_posterior/crear_tablas_fase_posterior.sql,
  sobre la base que ya tiene los datos del núcleo. Archivo generado por
  bd/generar_datos_prueba.py; no editar a mano.

  Completa el escenario de prueba con lo que pertenece a los agregados:
  los catálogos de la fase posterior, las columnas que se agregaron a
  Usuario, EstadisticaModo y Sala, la partida contra la IA y las @NUM@
  tablas nuevas.
=====================================================================*/
"""

PREAMBULO = """
USE Bastion;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

BEGIN TRANSACTION;
"""


def _insert(nombre, columnas, filas, identidad, comentario):
    lineas = []
    if comentario:
        lineas.append(f"-- {comentario}")
    if identidad:
        lineas.append(f"SET IDENTITY_INSERT dbo.{nombre} ON;")
    lineas.append(f"INSERT INTO dbo.{nombre} ({', '.join(columnas)}) VALUES")
    lineas.append(",\n".join("    (" + ", ".join(valor(v) for v in fila) + ")" for fila in filas) + ";")
    if identidad:
        lineas.append(f"SET IDENTITY_INSERT dbo.{nombre} OFF;")
    lineas.append("")
    return lineas


def _titulo(area):
    return "/*" + "-" * 69 + "\n  " + area + "\n" + "-" * 69 + "*/\n"


def _escribir(ruta, lineas):
    ruta.write_bytes(b"\xef\xbb\xbf" + "\n".join(lineas).replace("\n", "\r\n").encode("utf-8"))


def escribir_sql(nucleo, fase, ia, act):
    areas = {t["nombre"]: t["area"] for t in _esquema("esquema.json")}
    areas.update({t["nombre"]: t["area"] for t in _esquema("esquema-fase-posterior.json")})

    # --- núcleo
    lineas = [CABECERA_NUCLEO.replace("@NUM@", str(len(nucleo))).replace("@AHORA@", cu.AHORA), PREAMBULO]
    area_actual = None
    for nombre, columnas, filas, identidad, comentario in nucleo:
        if areas[nombre] != area_actual:
            area_actual = areas[nombre]
            lineas.append(_titulo(area_actual))
        if filas:
            lineas += _insert(nombre, columnas, filas, identidad, comentario)
    for i, sust in [(i, s[9]) for i, s in com.SANCIONES.items() if s[9]]:
        lineas.append(f"UPDATE dbo.Sancion SET id_sancion_sustituta = {sust} WHERE id_sancion = {i};")
    lineas += ["", "COMMIT TRANSACTION;", "GO",
               COMPROBACIONES_NUCLEO.replace("@TEXTOS_UNICODE@", textos_unicode(nucleo)[0])]
    _escribir(AQUI / "insertar_datos_prueba.sql", lineas)

    # --- fase posterior: catálogos, columnas agregadas al núcleo, la partida de la IA y tablas nuevas
    lineas = [CABECERA_FASE.replace("@NUM@", str(len(fase))), PREAMBULO]
    catalogos = [t for t in fase if areas[t[0]].startswith("Catálogos")]
    resto = [t for t in fase if not areas[t[0]].startswith("Catálogos")]
    lineas.append(_titulo(areas[catalogos[0][0]]))
    for t in catalogos:
        lineas += _insert(*t)
    lineas.append(_titulo("Columnas que se agregaron al núcleo"))
    for nombre, llaves, cols, filas in act:
        lineas.append(f"-- {nombre}: {', '.join(cols)}.")
        for fila in filas:
            k = fila[:len(llaves)]
            v = fila[len(llaves):]
            sets = ", ".join(f"{c} = {valor(x)}" for c, x in zip(cols, v))
            donde = " AND ".join(f"{c} = {valor(x)}" for c, x in zip(llaves, k))
            lineas.append(f"UPDATE dbo.{nombre} SET {sets} WHERE {donde};")
        lineas.append("")
    lineas.append(_titulo("Partida contra la IA (D-12)"))
    for t in ia:
        lineas += _insert(*t)
    area_actual = None
    for t in resto:
        if areas[t[0]] != area_actual:
            area_actual = areas[t[0]]
            lineas.append(_titulo(area_actual))
        if t[2]:
            lineas += _insert(*t)
    lineas += ["", "COMMIT TRANSACTION;", "GO",
               COMPROBACIONES_FASE.replace("@TEXTOS_UNICODE@", textos_unicode(fase + ia)[0] or
                                           "          SELECT CAST(NULL AS NVARCHAR(10)) AS v WHERE 1 = 0")]
    _escribir(AQUI / "fase_posterior" / "insertar_datos_prueba_fase_posterior.sql", lineas)


def _tabla_filas(esquema, cuenta, aviso):
    areas = {}
    for t in _esquema(esquema):
        areas.setdefault(t["area"], []).append(t["nombre"])
    o = [aviso, r"\begin{center}\small", r"\begin{longtable}{|L{0.40\textwidth}|L{0.12\textwidth}|}",
         r"\hline", r"\textbf{Tabla} & \textbf{Filas} \\ \hline", r"\endfirsthead",
         r"\hline", r"\textbf{Tabla} & \textbf{Filas} \\ \hline", r"\endhead"]
    for area, nombres in areas.items():
        o.append(r"\multicolumn{2}{|l|}{\textbf{" + area.replace("(D-09)", r"(\mbox{D-09})") + r"}} \\ \hline")
        o += [r"\textit{" + n + "} & " + str(cuenta.get(n, 0)) + r" \\ \hline" for n in nombres]
    o += [r"\textbf{Total} & \textbf{" + str(sum(cuenta.get(n, 0) for ns in areas.values() for n in ns)) + r"} \\ \hline",
          r"\end{longtable}", r"\end{center}"]
    return "\n".join(o) + "\n"


def escribir_tex(nucleo, fase, ia, retiradas):
    aviso = "% Archivo generado por bd/generar_datos_prueba.py. No editar a mano."
    cuenta = {n: len(f) for n, _, f, _, _ in nucleo}
    (AQUI / "tex" / "datos-prueba.tex").write_text(_tabla_filas("esquema.json", cuenta, aviso), encoding="utf-8")
    cuenta_f = {n: len(f) for n, _, f, _, _ in fase}
    dir_f = AQUI / "tex" / "fase-posterior"
    dir_f.mkdir(parents=True, exist_ok=True)
    (dir_f / "datos-prueba.tex").write_text(_tabla_filas("esquema-fase-posterior.json", cuenta_f, aviso), encoding="utf-8")
    macros = {
        "dpFecha": cu.AHORA[:10], "dpNumFilas": sum(cuenta.values()), "dpNumUsuarios": cuenta["Usuario"],
        "dpNumPartidas": cuenta["Partida"], "dpNumJugadas": cuenta["Jugada"],
        "dpNumTablasConDatos": sum(1 for v in cuenta.values() if v),
        "dpNumComprobaciones": len(re.findall(r"^\s+SELECT \d+(?: AS n)?, N'", COMPROBACIONES_NUCLEO, re.M)),
        "dpNumTextosUnicode": textos_unicode(nucleo)[1],
        "dpFpNumFilas": sum(cuenta_f.values()) + sum(len(t[2]) for t in ia),
        "dpFpNumComprobaciones": len(re.findall(r"^\s+SELECT \d+(?: AS n)?, N'", COMPROBACIONES_FASE, re.M)),
        "dpNumMovimientos": cuenta_f.get("MovimientoMoneda", 0),
    }
    (AQUI / "tex" / "datos-prueba-resumen.tex").write_text(
        aviso + "\n" + "\n".join(f"\\newcommand{{\\{k}}}{{{v}}}" for k, v in macros.items()) + "\n", encoding="utf-8")


def main():
    construir()
    nucleo, fase, ia, act, retiradas = repartir()
    (AQUI / "fase_posterior").mkdir(exist_ok=True)
    escribir_sql(nucleo, fase, ia, act)
    escribir_tex(nucleo, fase, ia, retiradas)
    print(f"núcleo: {len(nucleo)} tablas, {sum(len(t[2]) for t in nucleo)} filas; "
          f"fase posterior: {len(fase)} tablas, {sum(len(t[2]) for t in fase) + sum(len(t[2]) for t in ia)} filas "
          f"y {sum(len(a[3]) for a in act)} actualizaciones; en memoria o fusionadas: {retiradas}")


if __name__ == "__main__":
    main()

# -*- coding: utf-8 -*-
"""build_partida.py · lienzo «Bastión · Partida en línea (prototipo)».

Sección: el HUD de la partida (GUI_Match) y lo que se abre encima de él: menú de partida,
chat, avisos de jugada, desconexión, tablas y fin de partida. Casos: CU-20, CU-21, CU-22,
CU-23, CU-24, CU-25, CU-26, CU-28, CU-33, CU-42.

Uso: python build_partida.py  → project/*.dc.html, project/canvas.json y r/*.png para revisar.
Los fondos son renders de Blender de los modelos reales (escena.py); en el lienzo son assets
(ASSETS: nombre → /_blob/…), en local se leen de ../escena/render (JPG).
"""
import json
import os
import sys
from pathlib import Path

from lib_bastion import *  # noqa: F401,F403
import kit

AQUI = Path(__file__).resolve().parent
RENDER = Path(os.environ.get("RENDER", AQUI.parent / "escena" / "render"))
ASSETS = json.loads((AQUI / "assets.json").read_text()) if (AQUI / "assets.json").exists() else {}
W, H = 1366, 768


def a_blob(s):
    for k, v in ASSETS.items():
        s = s.replace(f"ASSET:{k}\"", f"{v}\"")
    return s


def a_local(s):
    for k, v in ASSETS.items():
        s = s.replace(f"{v}\"", f"file://{RENDER / (k + '.jpg')}\"")
    for p in RENDER.glob("*.jpg"):
        s = s.replace(f"ASSET:{p.stem}\"", f"file://{p}\"")
    return s


# ---------------------------------------------------------------- datos de ejemplo
def filas2(tu="turno", rival="espera", t_tu="4:12", t_rival="3:58", muros_tu=8, muros_rival=9):
    return [fila_jugador("kobo", "J2", muros_rival, 10, t_rival, rival),
            fila_jugador("marta_muros", "J1", muros_tu, 10, t_tu, tu, tu=True)]


def filas4(estados=("turno", "espera", "espera", "espera")):
    return [fila_jugador("marta_muros", "J1", 4, 5, "8:40", estados[0], tu=True),
            fila_jugador("luis_quo", "J2", 4, 5, "9:02", estados[1]),
            fila_jugador("sofia_salto", "J3", 4, 5, "8:55", estados[2]),
            fila_jugador("pedro_peon", "J4", 4, 5, "9:10", estados[3])]


def hud2(**kw):
    kw.setdefault("muros", kw.get("muros_tu", 8))
    return hud(filas2(**{k: kw.pop(k) for k in list(kw) if k in ("tu", "rival", "t_tu", "t_rival", "muros_tu", "muros_rival")}), **kw)


def surco(c):
    """Centro en pantalla del surco de un muro (esquina superior derecha de la casilla c)."""
    a = cel(c, alto=True)
    b = cel(chr(ord(c[0]) + 1) + str(int(c[1:]) + 1), alto=True)
    return (a[0] + b[0]) / 2, (a[1] + b[1]) / 2


def cursor(x, y, kind="cursor"):
    return kit.at(kit.icon(kind, 30, kit.ANN, 2.2), x - 4, y - 2, 9)


def marca(n, x, y):
    return kit.at(kit.mk(n, "top: 0; left: 0;"), x, y, 9)


def recorte(escena, cx, cy, w, h, s=1.0, extra=""):
    """Trozo del render centrado en (cx, cy) a escala s; extra en coordenadas del recorte."""
    left = -(cx * s - w / 2)
    top = -(cy * s - h / 2)
    return (f'<div style="position: relative; width: {w}px; height: {h}px; overflow: hidden; border-radius: 12px; border: 1.5px solid {T("line")}; background: {T("bg")};">'
            f'<img src="ASSET:{escena}" alt="" style="position: absolute; left: {left:.0f}px; top: {top:.0f}px; width: {W * s:.0f}px; height: {H * s:.0f}px;">{extra}</div>')


def en_rec(px, py, cx, cy, w, h, s):
    return (px - cx) * s + w / 2, (py - cy) * s + h / 2


c = kit.Canvas(str(AQUI / "project"), "Bastión · Partida en línea (prototipo)")
NOTES = {}

# =============================================================== 1 · en el juego y completa
c.board("Main", "1 · En el juego · 1366×768", W, pantalla(W, H, "partida", hud2(), etiqueta="El HUD cubre ~9 % de la pantalla; ninguna casilla queda debajo"), h=H)
NOTES["Main"] = """EN EL JUEGO · 1366×768 (pantalla completa)

Fondo: render de Blender de los modelos reales (tablero_clasico_9x9, peon_clasico, muro_madera) con la cámara de juego desde el lado del jugador 1.

El HUD no es una ventana: son cuatro piezas en las esquinas y abajo, sobre el tablero 3D.
· Panel de jugadores 330×170 px, arriba a la izquierda (24 % × 22 %).
· Chat y menú 98×44 px, arriba a la derecha.
· Barra de acciones ~640×52 px, abajo al centro.
En total ~9 % de la pantalla (panel 330×170, botones 98×44, barra ~650×52 sobre 1366×768) y ninguna pieza pisa una casilla: las piezas viven en las esquinas y en la franja de abajo, fuera del trapecio del tablero.

QUÉ RESUELVE (frente a 20a / 21a)
1 El reloj de cada jugador está junto a su nombre y el de quien juega se invierte (fondo oscuro): antes había un chip "tu turno" aparte, lejos del reloj que corría.
2 Los muros se cuentan con una barra del color del jugador y con número ("8 muros").
3 La acción de muro es un botón grande con su tecla (M) y su contador (8/10); la pista de abajo dice lo que se puede hacer ahora.
4 Sin emotes, monedas ni skins: son de fase posterior.

Lo que dibuja el sistema: nada a pantalla completa. En modo ventana, la barra de título (ver bloque 4)."""

partes = (
    kit.rel(panel_jugadores(filas2()), 1)
    + kit.rel(panel_jugadores(filas4(), "cuatro jugadores 9×9 · clasificatoria"), "1b")
    + kit.rel(barra_derecha(badge=2), 2)
    + kit.rel(barra_acciones(8, 10), 3)
    + kit.rel(barra_acciones(8, 10, "muro"), "3b")
    + kit.rel(menu_partida(), 4)
    + kit.rel(chat([("kobo", "J2", "suerte"), ("marta_muros", "J1", "igualmente"), ("kobo", "J2", "uy, ese muro dolió")]), 5)
)
c.board("Completa", "1 · El HUD completo, pieza por pieza", 1100,
        kit.hoja("El HUD completo, a su tamaño real", f'<div style="display: flex; flex-direction: column; gap: 40px; padding-left: 50px;">{partes}</div>'))
NOTES["Completa"] = """QUÉ RESUELVE

1 Panel de jugadores (2 jugadores): modo y tipo de partida arriba; por jugador, color, nickname, "te toca / le toca", muros restantes y reloj. SE MANTIENE: el orden de 20a (rival arriba, tú abajo, como en el tablero).
1b Cuatro jugadores: mismas filas en orden de turno. Sin cabezas de avatar: los peones son el color.
2 Chat (con mensajes sin leer) y menú de partida. Botones de 44×44 px.
3 Barra de acciones en modo mover. 3b en modo muro: el botón se invierte y la pista cambia a los atajos.
4 Menú de partida (antes 19d): sin emotes; "ofrecer tablas" dice su regla (sin confirmación, una vez cada 5 jugadas tuyas, solo entre 2).
5 Chat de la partida (antes 20c): un solo canal, el de la partida; se cierra con la X o con Esc.

Todos los textos y cantidades son de ejemplo; los reglas salen de CU-20, CU-21, CU-22 y CU-28."""

# =============================================================== 2 · partes y estados
def caps(items, w=330):
    return '<div style="display: flex; flex-wrap: wrap; gap: 28px 36px;">' + "".join(kit.cap(i, t, w) for i, t in items) + "</div>"


est_panel = caps([
    (panel_jugadores(filas2()), "Normal, te toca: tu fila con borde de tu color y el reloj invertido."),
    (panel_jugadores(filas2("espera", "turno")), "Le toca al rival: su fila se marca y su reloj corre."),
    (panel_jugadores(filas2("urgente", "espera", t_tu="0:08")), "Últimos 10 s: el reloj pasa a rojo y dice ¡últimos segundos! (no solo color: texto e icono)."),
    (panel_jugadores(filas2("turno", "desconectado")), "Rival desconectado: ficha con borde discontinuo y el aviso; su reloj sigue."),
    (panel_jugadores(filas2(muros_tu=0)), "Sin muros: la barra vacía y \"0 muros\"."),
    (panel_jugadores([fila_jugador("el_nombre_mas_largo_que_cabe_30", "J2", 9, 10, "3:58", "espera"),
                      fila_jugador("marta_muros", "J1", 8, 10, "4:12", "turno", tu=True)]), "Caso raro: nickname de 30 caracteres; se corta con puntos suspensivos y el reloj no se mueve."),
    (panel_jugadores(filas4(("turno", "abandono", "clasificado", "espera")), "cuatro jugadores 9×9"), "4 jugadores: uno abandonó (atenuado, sus muros se quedan) y otra ya llegó a la meta (1.º, sale del turno)."),
], 330)
c.board("Estados_Panel", "2 · Panel de jugadores: estados", 1180, kit.hoja("Panel de jugadores", kit.state_block("Estados", est_panel)))
NOTES["Estados_Panel"] = """QUÉ RESUELVE

· Cada estado se distingue por algo más que el color: texto ("te toca", "desconectado", "abandonó"), icono de reloj o atenuado.
· El nickname puede medir 30 caracteres (CU-02 RN-01): se corta a 150 px sin empujar el reloj.
· En 4 jugadores el que abandona sigue en la lista, atenuado, porque sus muros siguen en el tablero (CU-24, CU-25 RN-10).

ERROR ENCONTRADO Y CORREGIDO: en 8e el jugador que abandonó salía en una caja discontinua aparte, fuera del orden de turno; ahora queda en su sitio, atenuado."""

est_bot = caps([
    (boton_icono("menu", "Menú"), "Normal."), (boton_icono("menu", "Menú", estado="hover"), "Ratón encima: fondo cálido."),
    (boton_icono("menu", "Menú", estado="pulsado"), "Pulsado."), (boton_icono("menu", "Menú", estado="foco"), "Foco de teclado (Tab): anillo terracota."),
    (boton_icono("chat", "Chat", badge=3), "Chat con 3 mensajes sin leer."), (boton_icono("chat", "Chat", badge="9+"), "Más de 9: \"9+\"."),
], 150) + '<div style="height: 24px;"></div>' + caps([
    (barra_acciones(8, 10), "Modo mover (por omisión)."),
    (barra_acciones(8, 10, "muro"), "Modo muro: botón invertido y pista con atajos."),
    (barra_acciones(0, 10, muro_estado="deshabilitado", pista="no te quedan muros: mueve tu peón"), "Sin muros: el botón se apaga y la pista lo dice."),
    (barra_acciones(8, 10, pista="espera tu turno · puedes girar la cámara con clic derecho"), "No es tu turno: la pista cambia y el botón de muro no responde."),
], 680)
c.board("Estados_Botones", "2 · Botones y barra de acciones: estados", 1520, kit.hoja("Botones del HUD y barra de acciones", kit.state_block("Estados", est_bot)))
NOTES["Estados_Botones"] = """QUÉ RESUELVE

· Todos los botones miden al menos 44×44 px y tienen foco de teclado visible: la partida se puede jugar con teclado (M muro, R girar, Enter colocar, Esc cancelar).
· El botón de muro lleva su contador: antes (20a) el contador era una tarjeta aparte con un número pequeño.
· Cuando no es tu turno, la barra no desaparece (no salta la interfaz), solo cambia la pista.

POR CONFIRMAR EN EL CÓDIGO: la tecla M y la R son propuesta; CU-21 solo fija que hay atajos."""

mens = [("kobo", "J2", "suerte"), ("marta_muros", "J1", "igualmente"), ("kobo", "J2", "uy, ese muro dolió")]
est_chat = caps([
    (chat(mens), "Normal."), (chat([], estado="vacio"), "Vacío: recuerda que el chat se modera."),
    (chat(mens, estado="filtrado", borrador="eres un ████"), "Mensaje filtrado (CU-28 RN-02): no dice qué palabra saltó; el texto se queda en el campo para corregirlo."),
    (chat(mens, estado="restringido"), "Chat restringido por una sanción (CU-44): se lee, no se escribe; la partida sigue."),
], 340)
c.board("Estados_Chat", "2 · Chat de la partida: estados", 1580, kit.hoja("Chat de la partida", kit.state_block("Estados", est_chat)))
NOTES["Estados_Chat"] = """QUÉ RESUELVE

· Un solo canal en el núcleo: el de la partida (y el de la sala en la sala de espera). Global, amigos y espectadores son de fase posterior.
· El filtro del servidor (CON-09) avisa sin decir qué término saltó, como piden CU-28 RN-02 y la Matriz 5.
· Clic derecho sobre un mensaje: silenciar, bloquear o reportar (ver 3b · Chat).

SE MANTIENE: el chat es un panel que se abre desde su icono, no una columna fija (se descartó 1b)."""

est_menu = caps([
    (menu_partida("disponible"), "Tablas disponibles."), (menu_partida("espera"), "Ofreciste hace poco: faltan 3 jugadas tuyas (CU-22 RN-03)."),
    (menu_partida("pendiente"), "Oferta enviada, esperando al rival."), (menu_partida("no_aplica"), "4 jugadores: no hay tablas (D-14)."),
], 330)
c.board("Estados_Menu", "2 · Menú de partida: estados", 1560, kit.hoja("Menú de partida", kit.state_block("Estados de \"ofrecer tablas\"", est_menu)))
NOTES["Estados_Menu"] = """QUÉ RESUELVE

ERROR ENCONTRADO Y CORREGIDO: 19d decía "tablas solo desde la jugada 10"; CU-22 permite ofrecerlas en cualquier momento, una vez cada cinco jugadas propias. La fila dice ahora cuándo vuelve a estar disponible.
· En 4 jugadores la opción se queda visible pero apagada y dice por qué, en vez de desaparecer.
· "Rendirse" pide confirmación (CU-23); "ofrecer tablas" no (CU-22 RN-06)."""

# =============================================================== 3 · conceptos
RW, RH, S = 360, 250, 1.1


def paso_mover(esc, cx, cy, extra_fn, s=S):
    return recorte(esc, cx, cy, RW, RH, s, extra_fn(lambda px, py: en_rec(px, py, cx, cy, RW, RH, s)))


e3 = cel("e3", alto=True)
e4 = cel("e4", alto=True)
C_mover = kit.pasos(
    kit.step("1 · Clic en tu peón", paso_mover("partida", 683, 425, lambda f: kit.cursor_at(f"left: {f(*e3)[0]:.0f}px; top: {f(*e3)[1]:.0f}px;"))),
    kit.step_arrow(),
    kit.step("2 · Se marcan las casillas", paso_mover("mover", 683, 425, lambda f: kit.cursor_at(f"left: {f(*e3)[0]:.0f}px; top: {f(*e3)[1]:.0f}px;"))),
    kit.step_arrow(),
    kit.step("3 · Clic en una casilla marcada", paso_mover("mover", 683, 425, lambda f: kit.path(
        f"M {f(*e3)[0]:.0f} {f(*e3)[1]:.0f} Q {f(*e3)[0] + 30:.0f} {f(*e4)[1] - 20:.0f} {f(*e4)[0]:.0f} {f(*e4)[1]:.0f}", RW, RH)
        + kit.cursor_at(f"left: {f(*e4)[0]:.0f}px; top: {f(*e4)[1]:.0f}px;"))),
    kit.step_arrow(),
    kit.step("4 · Pasa el turno", f'<div style="display: flex; flex-direction: column; gap: 8px;">{panel_jugadores(filas2("espera", "turno", t_tu="4:05"), w=300)}</div>'),
)
c.board("C_Mover", "3 · Concepto: mover el peón", 1780, kit.hoja("Concepto · mover el peón (CU-20)", C_mover + kit.note_box(
    "El peón salta de su casilla a la nueva con un arco corto de 0,25 s y se asienta con un rebote pequeño. La jugada se manda al soltar el clic; el peón se mueve en cuanto el servidor la acepta.", "max-width: 900px;")))
NOTES["C_Mover"] = """ANIMACIÓN

Qué la dispara: clic en el peón propio (o Tab + Enter) y después clic en una casilla marcada. Las casillas alcanzables son las ortogonales sin muro y las de salto (CU-20 RN-02, RN-03).
Cuánto dura: el arco del peón 0,25 s; el paso del turno (el borde del panel cambia de fila) 0,15 s.
Si se interrumpe: si el servidor rechaza la jugada (desfase, reloj agotado), el peón no se ha movido todavía y aparece el aviso junto al cursor (ver 3b). Doble clic no manda dos jugadas: tras el primero las marcas se quitan hasta la respuesta (CU-20 RN-06, número de jugada).
Qué no se anima: el reloj no hace cuenta atrás animada; solo cambia de fila.
Sin movimiento (reducir animaciones): el peón aparece en su casilla nueva y la casilla de origen parpadea una vez en gris."""

e4b, e5b, e6b = cel("e4", alto=True), cel("e5", alto=True), cel("e6", alto=True)
d5b = cel("d5", alto=True)
C_salto = kit.pasos(
    kit.step("1 · Rival delante: salto recto", paso_mover("salto", 683, 355, lambda f: kit.path(
        f"M {f(*e4b)[0]:.0f} {f(*e4b)[1]:.0f} Q {f(*e5b)[0] + 40:.0f} {f(*e5b)[1] - 50:.0f} {f(*e6b)[0]:.0f} {f(*e6b)[1]:.0f}", RW, RH)
        + kit.cursor_at(f"left: {f(*e6b)[0]:.0f}px; top: {f(*e6b)[1]:.0f}px;"))),
    kit.step_arrow(),
    kit.step("2 · Muro detrás: salto en diagonal", paso_mover("salto_diag", 683, 355, lambda f: kit.path(
        f"M {f(*e4b)[0]:.0f} {f(*e4b)[1]:.0f} Q {f(*e5b)[0] - 10:.0f} {f(*e5b)[1] - 50:.0f} {f(*d5b)[0]:.0f} {f(*d5b)[1]:.0f}", RW, RH)
        + kit.cursor_at(f"left: {f(*d5b)[0]:.0f}px; top: {f(*d5b)[1]:.0f}px;"))),
)
c.board("C_Salto", "3 · Concepto: el salto", 1000, kit.hoja("Concepto · el salto (CU-20 RN-03)", C_salto + kit.note_box(
    "El salto usa el mismo arco que el movimiento, más alto (pasa por encima del rival). Las casillas de salto se marcan igual que las normales: el jugador no tiene que saber la regla para verla.", "max-width: 820px;")))
NOTES["C_Salto"] = """ANIMACIÓN

Qué la dispara: lo mismo que mover; la diferencia la calcula el cliente al marcar casillas y la vuelve a validar el servidor (CU-20 RN-07).
Cuánto dura: 0,35 s, arco más alto que un paso.
Qué no se anima: el rival no se aparta.
SE MANTIENE: 8c y 8d explicaban el salto con flechas; aquí las flechas son la trayectoria del concepto, no parte de la GUI."""

d6 = cel("d6", alto=True)
b8 = cel("b8", alto=True)
C_muro = kit.pasos(
    kit.step("1 · Pulsar M (o el botón)", f'<div style="padding-top: 60px;">{barra_acciones(8, 10, "muro")}</div>'),
    kit.step_arrow(),
    kit.step("2 · El muro sigue al ratón", recorte("muro_ok", 640, 315, 380, RH, S,
                                                   kit.at(cartel_muro(True), 20, RH - 70) + kit.cursor_at(f"left: {en_rec(*surco('d6'), 640, 315, 380, RH, S)[0]:.0f}px; top: {en_rec(*surco('d6'), 640, 315, 380, RH, S)[1]:.0f}px;"))),
    kit.step_arrow(),
    kit.step("2b · Si encierra a alguien: rojo", recorte("muro_mal", 470, 215, 380, RH, S,
                                                         kit.at(cartel_muro(False, surco="b8 vertical"), 20, RH - 70) + kit.cursor_at(f"left: {en_rec(*surco('b8'), 470, 215, 380, RH, S)[0]:.0f}px; top: {en_rec(*surco('b8'), 470, 215, 380, RH, S)[1]:.0f}px;"))),
    kit.step_arrow(),
    kit.step("3 · Enter o clic: cae", recorte("partida", 646, 300, 300, RH, S, "")),
)
c.board("C_Muro", "3 · Concepto: colocar un muro", 2240, kit.hoja("Concepto · colocar un muro (CU-21)", C_muro + kit.note_box(
    "El fantasma del muro es translúcido y del color del jugador si es válido, rojo si no. El cartel dice el surco y cómo cambia el camino del rival (CU-21 RN-09). Al confirmar, el muro baja al surco en 0,2 s.", "max-width: 1000px;")))
NOTES["C_Muro"] = """ANIMACIÓN

Qué la dispara: M, el botón de muro o arrastrar desde él. El fantasma se engancha al surco más cercano al ratón; R lo gira (antes 21a lo hacía con un cartel de iconos pequeños).
Cuánto dura: el enganche es instantáneo; al confirmar, el muro baja 0,2 s y el contador pasa de 8/10 a 7/10.
Si se interrumpe: Esc o clic derecho cancelan sin gastar muro. Si el servidor lo rechaza (otro muro llegó antes), el fantasma vuelve a rojo con el aviso y el contador no baja.
Qué no se anima: el camino más corto no se dibuja entero (taparía el tablero); solo su longitud en el cartel.
Sin movimiento: el muro aparece colocado.

ERROR ENCONTRADO Y CORREGIDO: en 7b el aviso de "encerraría al rival" salía después de soltar; ahora el fantasma ya es rojo antes de confirmar y Enter no hace nada (CU-21 RN-05)."""

C_turno = kit.pasos(
    kit.step("1 · Tu turno", panel_jugadores(filas2(t_tu="0:42"), w=300)),
    kit.step_arrow(),
    kit.step("2 · Quedan 10 s: pulso rojo", panel_jugadores(filas2("urgente", t_tu="0:09"), w=300)),
    kit.step_arrow(),
    kit.step("3 · Se agota: fin por tiempo", tarjeta(f'<div style="font: 900 26px {T("hf")};">se acabó tu tiempo</div>'
                                                      f'<div style="font: 700 14px {T("bf")}; color: {T("ink2")};">kobo gana por tiempo · 1842 → 1829 (−13 elo)</div>', 300)),
)
c.board("C_Turno", "3 · Concepto: turno y reloj", 1320, kit.hoja("Concepto · turno y reloj (CU-20 FA-06, CU-25)", C_turno))
NOTES["C_Turno"] = """ANIMACIÓN

El reloj lo lleva el servidor; el cliente solo lo muestra. A los 10 s el reloj pasa a rojo, dice "¡últimos segundos!" y late una vez por segundo (escala 1,00 → 1,06). Con "reducir movimiento" no late: solo cambia a rojo.
Si el tiempo se agota, el servidor cierra la partida con TIEMPO_AGOTADO (CU-25) y el cliente enseña el fin de partida. Una jugada que llega tarde no se guarda (CU-20 FA-06).
Qué no se anima: el reloj del rival no late aunque le queden pocos segundos, para no distraer."""

C_desc = kit.pasos(
    kit.step("1 · Se cae kobo", banner(f'{ico("wifi", 22, ERR)}<div style="flex-grow: 1;"><div style="font: 800 15px {T("bf")};">kobo se desconectó</div>'
                                         f'<div style="font: 600 13px {T("bf")}; color: {T("ink2")};">su reloj sigue corriendo · puedes reclamar en 0:59</div></div>', 420)),
    kit.step_arrow(),
    kit.step("2 · Pasan 60 s", banner(f'{ico("wifi", 22, ERR)}<div style="flex-grow: 1;"><div style="font: 800 15px {T("bf")};">kobo sigue sin volver</div>'
                                        f'<div style="font: 600 13px {T("bf")}; color: {T("ink2")};">puedes esperar o reclamar la victoria</div></div>{boton("reclamar", "prim")}', 460)),
    kit.step_arrow(),
    kit.step("2b · Si vuelve antes", banner(f'{ico("check", 22, OK)}<div style="font: 800 15px {T("bf")};">kobo volvió · la partida sigue</div>', 330)),
)
c.board("C_Desconexion", "3 · Concepto: desconexión y reconexión", 1500, kit.hoja("Concepto · el rival se desconecta (CU-24, CU-26, D-15)", C_desc))
NOTES["C_Desconexion"] = """FLUJO

Qué lo dispara: el servidor detecta que la conexión TCP del rival se cayó y avisa al resto.
Cuánto dura: el aviso se queda arriba al centro mientras dure la desconexión; el botón "reclamar" aparece a los 60 s (D-15, CU-24 RN-06).
Si vuelve: el aviso cambia a "volvió" 2 s y se va. El que se reconecta ve 6e ("tienes una partida en curso").
ERROR ENCONTRADO Y CORREGIDO: 6f ofrecía "reclamar victoria" con 0:42 todavía en la cuenta atrás. Ahora el botón no existe hasta los 60 s."""

C_tablas = kit.pasos(
    kit.step("1 · Ofreces (sin confirmar)", menu_partida("disponible", 300)),
    kit.step_arrow(),
    kit.step("2 · Kobo lo ve arriba", banner(f'{ico("igual", 22)}<div style="flex-grow: 1; font: 800 15px {T("bf")};">marta_muros ofrece tablas</div>'
                                              f'{boton("rechazar")}{boton("aceptar", "prim")}', 470)),
    kit.step_arrow(),
    kit.step("3 · Si kobo juega: caduca", banner(f'<div style="font: 700 14px {T("bf")}; color: {T("ink2")};">kobo jugó: tu oferta de tablas caducó</div>', 330)),
)
c.board("C_Tablas", "3 · Concepto: ofrecer tablas", 1560, kit.hoja("Concepto · ofrecer y aceptar tablas (CU-22)", C_tablas))
NOTES["C_Tablas"] = """FLUJO

Ofrecer no pide confirmación (CU-22 RN-06). Al rival le aparece un aviso arriba, que no tapa el tablero ni bloquea: puede seguir jugando, y jugar sin aceptar caduca la oferta (RN-05). Si los dos ofrecen, es aceptación (RN-04).
Qué no se anima: nada vuela; el aviso entra desde arriba en 0,2 s.
Solo en partidas de 2 (D-14)."""

C_meta = kit.pasos(
    kit.step("1 · El peón llega a la meta", recorte("meta", 683, 215, RW, RH, S, "")),
    kit.step_arrow(),
    kit.step("2 · Tarjeta sobre el tablero", tarjeta(
        f'<div style="font: 900 34px {T("hf")}; text-align: center;">¡victoria!</div>'
        f'<div style="font: 700 14px {T("bf")}; color: {T("ink2")}; text-align: center;">llegaste a la meta · 37 jugadas · 4:12</div>'
        f'<div style="display: flex; justify-content: center;"><span style="padding: 6px 14px; border-radius: 12px; border: 1.5px solid {T("line")}; font: 900 22px {T("bf")};">1842 → 1861 <span style="color: {OK}; font-size: 15px;">+19</span></span></div>'
        f'<div style="display: flex; gap: 10px; justify-content: center;">{boton("volver al menú")}{boton("buscar otra", "prim")}</div>', 380)),
)
c.board("C_Meta", "3 · Concepto: fin de partida", 1000, kit.hoja("Concepto · llegada a la meta (CU-25)", C_meta))
NOTES["C_Meta"] = """ANIMACIÓN

El peón que llega a la meta se ilumina y la cámara se acerca un poco (0,6 s). Después entra la tarjeta del resultado; el tablero sigue a la vista detrás.
El elo sube de 1842 a 1861 con un contador de 0,5 s; en privadas no hay elo (D-16) y la tarjeta lo dice.
Sin monedas, racha, repetición ni revancha: son de fase posterior o no existen en los casos (antes 2g)."""

# =============================================================== 3b · en la pantalla real
R = {}
R["R_Mover"] = pantalla(W, H, "mover", hud2(pista="elige una casilla marcada · Esc cancela"), cursor(*cel("e4")))
NOTES["R_Mover"] = """QUÉ SE REVISA (peor fotograma: casillas marcadas y cursor encima del destino)

1 Las casillas marcadas se ven sobre el terracota (crema claro) y no dependen solo del color: son las únicas planas y claras.
2 El cursor no tapa el peón: está sobre la casilla destino.
3 La barra de abajo no pisa la fila 1 del tablero.
ERROR ENCONTRADO Y CORREGIDO: la pista inicial decía "haz clic en tu peón" aunque ya estuviera elegido; ahora cambia a "elige una casilla marcada".
Resultado: se lee."""

R["R_Salto"] = pantalla(W, H, "salto_diag", hud2(pista="muro detrás de kobo: puedes saltar en diagonal"), cursor(*cel("d5")))
NOTES["R_Salto"] = """QUÉ SE REVISA

1 Con el muro detrás del rival se marcan las dos diagonales (d5, f5) además de d4, f4 y e3.
2 La pista explica por qué aparecen casillas en diagonal, sin nombrar la regla.
Resultado: correcto. POR CONFIRMAR: el texto de la pista es propuesta."""

R["R_MuroOk"] = pantalla(W, H, "muro_ok", hud2(modo="muro"), kit.at(cartel_muro(True), 720, 96) + cursor(*surco("d6")))
NOTES["R_MuroOk"] = """QUÉ SE REVISA (peor fotograma: fantasma enganchado y cartel abierto)

1 El fantasma es translúcido y del color de quien lo coloca (naranja de marta), así se distingue de los muros ya puestos.
2 El cartel se abre arriba, en la franja libre sobre el tablero, sin tapar el surco, al rival ni los muros de alrededor.

ERROR ENCONTRADO Y CORREGIDO: la primera versión pintaba el fantasma en verde (el color de kobo): parecía un muro del rival.
ERROR ENCONTRADO Y CORREGIDO: el cartel estaba pegado a la cabeza del peón de kobo y, al moverlo a la derecha, tapaba el muro vertical de f4; se movió arriba, a la franja libre sobre el tablero.
ERROR ENCONTRADO Y CORREGIDO: el camino decía "8 → 11" pasos con kobo a 6 casillas de su meta; ahora "6 → 8".
Resultado: se lee."""

R["R_MuroMal"] = pantalla(W, H, "muro_mal", hud2(modo="muro"), kit.at(cartel_muro(False, surco="b8 vertical"), 520, 190) + cursor(*surco("b8")))
NOTES["R_MuroMal"] = """QUÉ SE REVISA

1 El fantasma rojo y el cartel dicen que el muro encerraría a kobo; Enter no aparece entre los atajos.
2 El aviso está junto al cursor, sin ventana (CU-20 RN-09 aplicado a los muros).
Resultado: correcto."""

R["R_Urgente"] = pantalla(W, H, "partida", hud2(tu="urgente", t_tu="0:07"))
NOTES["R_Urgente"] = """QUÉ SE REVISA

El reloj en rojo con texto se ve en el panel sin tapar nada del tablero.
ERROR ENCONTRADO Y CORREGIDO: 8b ponía una barra roja a todo lo ancho arriba; tapaba la fila 9 en tableros 7×7. Ahora el aviso vive en la fila del jugador."""

R["R_Desconexion"] = pantalla(W, H, "partida", hud2(rival="desconectado", tu="turno"),
                              kit.at(banner(f'{ico("wifi", 22, ERR)}<div style="flex-grow: 1;"><div style="font: 800 15px {T("bf")};">kobo se desconectó</div>'
                                            f'<div style="font: 600 13px {T("bf")}; color: {T("ink2")};">su reloj sigue corriendo · puedes reclamar en 0:42</div></div>', 430), 468, 18))
NOTES["R_Desconexion"] = """QUÉ SE REVISA

1 El aviso va arriba al centro, entre el panel y los botones, sin pisarlos (430 px caben entre 334 y 1250).
2 No hay botón de reclamar todavía (D-15).
3 Puedes seguir jugando tu turno mientras tanto.
Resultado: correcto."""

R["R_Tablas"] = pantalla(W, H, "partida", hud(
    [fila_jugador("marta_muros", "J1", 8, 10, "4:12", "espera"), fila_jugador("kobo (tú)", "J2", 9, 10, "3:58", "turno")]),
    kit.at(banner(f'{ico("igual", 22)}<div style="flex-grow: 1; font: 800 15px {T("bf")};">marta_muros ofrece tablas</div>{boton("rechazar")}{boton("aceptar", "prim")}', 470), 448, 18))
NOTES["R_Tablas"] = """QUÉ SE REVISA (vista de kobo)

1 La oferta no bloquea: kobo puede mover y la oferta caduca.
2 Los botones miden 44 px de alto.
Resultado: correcto."""

R["R_Menu"] = pantalla(W, H, "partida", hud2(menu_estado="pulsado"), kit.at(menu_partida("espera"), W - 16 - 330, 70))
NOTES["R_Menu"] = """QUÉ SE REVISA

1 El menú se abre hacia abajo y a la izquierda, dentro de la pantalla, desde el botón ≡.
2 No hay velo: el reloj sigue corriendo y el tablero se ve (CU-20: el reloj no se detiene).
ERROR ENCONTRADO Y CORREGIDO: 19d oscurecía toda la pantalla como si fuera una pausa; la partida en línea no se pausa."""

R["R_Chat"] = pantalla(W, H, "partida", hud2(badge=None),
                       kit.at(chat(mens, w=300, h=250, estado="filtrado", borrador="eres un ████"), W - 16 - 300, 70)
                       + kit.at(f'<div style="width: 190px; {panel_bg("padding: 4px; box-sizing: border-box;")}">'
                                + "".join(f'<div style="display: flex; gap: 10px; align-items: center; height: 40px; padding: 0 10px; font: 800 14px {T("bf")};">{ico(i, 18)}{t}</div>'
                                          for i, t in [("silenciar", "silenciar a kobo"), ("bloquear", "bloquear a kobo"), ("bandera", "reportar a kobo")]) + '</div>', W - 16 - 300 - 196, 150)
                       + cursor(W - 16 - 300 + 40, 164))
NOTES["R_Chat"] = """QUÉ SE REVISA (peor fotograma: chat abierto, mensaje filtrado y menú contextual abierto)

1 El chat no tapa casillas: 300×250 px desde x=1050, y=70; ahí el borde derecho del tablero está en x≈1000–1030.
2 El menú contextual (clic derecho sobre el mensaje de kobo) se abre hacia la izquierda, fuera del chat, para no tapar el aviso del filtro ni el mensaje señalado. Dice a quién afecta ("silenciar a kobo").
3 El aviso del filtro no dice qué palabra saltó y el texto se queda en el campo.

ERROR ENCONTRADO Y CORREGIDO: la primera versión del chat medía 340×360 y tapaba las casillas de las columnas h e i de las filas 5 a 9. Se redujo a 300×250.
ERROR ENCONTRADO Y CORREGIDO: el menú contextual se abría encima del chat y tapaba el aviso del filtro; ahora sale a la izquierda.
ERROR ENCONTRADO Y CORREGIDO: el menú decía solo "silenciar / bloquear / reportar" sin decir a quién; con varios jugadores en el chat no quedaba claro."""

R["R_Cuatro"] = pantalla(W, H, "cuatro", hud(filas4(("turno", "abandono", "espera", "espera")), "cuatro jugadores 9×9 · clasificatoria", muros=4, total=5))
NOTES["R_Cuatro"] = """QUÉ SE REVISA

1 Con 4 filas el panel mide 330×310 px y no toca el tablero: termina en x=346 y la esquina superior izquierda del tablero empieza en x≈375.
2 luis_quo abandonó: su fila sigue, atenuada y con texto; su peón ya no está en el tablero y sus muros verdes se quedan (CU-25 FA-04, RN-10).
3 Nunca hay 3 jugadores: el modo de 4 no empieza con plazas libres.

ERROR ENCONTRADO Y CORREGIDO: la primera escena dejaba el peón verde en el tablero aunque el panel dijera que luis abandonó; CU-25 FA-04 lo retira. Se quitó del render.
ERROR ENCONTRADO Y CORREGIDO: pedro aparecía como "llegó a la meta" con su peón a mitad de tablero; ese estado solo se muestra en la hoja de estados."""

R["R_Meta"] = pantalla(W, H, "meta", "", kit.at(tarjeta(
    f'<div style="font: 900 40px {T("hf")}; text-align: center;">¡victoria!</div>'
    f'<div style="font: 700 15px {T("bf")}; color: {T("ink2")}; text-align: center;">llegaste a la meta · 37 jugadas · 4:12 · 3 muros sin usar</div>'
    f'<div style="display: flex; justify-content: center;"><span style="padding: 6px 16px; border-radius: 12px; border: 1.5px solid {T("line")}; font: 900 26px {T("bf")};">1842 → 1861 <span style="color: {OK}; font-size: 16px;">+19 elo</span></span></div>'
    f'<div style="font: 700 12px {T("bf")}; color: {T("muted")}; text-align: center;">clásico 9×9 · clasificatoria</div>'
    f'<div style="display: flex; gap: 12px; justify-content: center;">{boton("volver al menú")}{boton("buscar otra", "prim")}</div>'
    f'<div style="font: 700 13px {T("bf")}; color: {T("ink2")}; text-align: center;">reportar a kobo</div>', 460), (W - 460) // 2, 300))
NOTES["R_Meta"] = """QUÉ SE REVISA

1 La tarjeta (460 px) va abajo del centro para que el peón en la meta (fila 9, arriba) siga a la vista.
2 El HUD se oculta al terminar: ya no hay turno ni reloj.
ERROR ENCONTRADO Y CORREGIDO: centrada en la pantalla, la tarjeta tapaba el peón que acababa de llegar; se bajó a y=300.
Resultado: se ve el peón y el resultado a la vez."""

for k, v in R.items():
    c.board(k, "3b · " + k[2:], W, v, h=H)

# =============================================================== 4 · computadora
ESC = 720 / 768
peor = pantalla(1280, 720, "cuatro",
                f'<div style="position: absolute; inset: 0; zoom: {ESC:.4f};">'
                + hud(filas4(("turno", "abandono", "desconectado", "espera")), "cuatro jugadores 9×9", muros=4, total=5, W=1366, H=768)
                + kit.at(chat(mens, w=300, h=250), 1366 - 16 - 300, 70) + '</div>',
                etiqueta="1280×720: HUD a escala 720/768, panel de 4 y chat abierto")
c.board("PC_1280", "4 · Portátil 1280×720 (peor caso)", 1280, peor, h=720)
NOTES["PC_1280"] = """QUÉ SE REVISA (el peor caso: pantalla más chica, 4 jugadores y chat abierto)

1 El HUD escala con la altura (referencia 768 px → ×0,9375 a 720 px) y el render se escala igual; nada cambia de sitio.
2 El panel de 4 jugadores (309×249 px a esta escala) sigue fuera del tablero.

ERROR ENCONTRADO Y CORREGIDO: sin escalar, el panel de 4 jugadores pisaba el borde izquierdo del tablero en las filas 7 y 8, y el chat de 340 px tapaba la columna i. Con el HUD escalado y el chat de 300×250 queda libre.
POR CONFIRMAR EN EL CÓDIGO: el motor lo decide la sesión de arquitectura; aquí solo se fija que la UI tiene 768 px de altura de referencia y escala por altura."""

fhd = pantalla(1366, 768, "partida", hud2(), etiqueta="1920×1080: la misma UI escalada ×1,4", zoom=1.4056)
c.board("PC_1920", "4 · Full HD 1920×1080", 1920, f'<div style="width: 1920px; height: 1080px; overflow: hidden;">{fhd}</div>', h=1080)
NOTES["PC_1920"] = """QUÉ SE REVISA

La interfaz se diseña a 1366×768 y escala por altura (×1,406 a 1080p): los textos de 12 px pasan a 17 px, los botones de 44 a 62 px. Nada cambia de sitio.
Resultado: correcto."""

ven = pantalla(1366, 768, "partida", hud2(), ventana=True, etiqueta="modo ventana: la barra de título del sistema ocupa 32 px")
c.board("PC_Ventana", "4 · Modo ventana", W, ven, h=H)
NOTES["PC_Ventana"] = """QUÉ SE REVISA

Es lo único que "dibuja el sistema" en un juego de escritorio: la barra de título. Ocupa 32 px arriba y el HUD baja con el área útil (no queda debajo).
Celular y TV: no aplican a Bastión (juego de escritorio en C#). Se dejan fuera en vez de dibujarlos por costumbre."""

# =============================================================== colocar
y = c.block("t1", 0, "1 · Partida: en el juego y completa", [["Main"], ["Completa"]], NOTES)
y = c.block("t2", y, "2 · Partes del HUD y sus estados", [["Estados_Panel"], ["Estados_Botones"], ["Estados_Chat"], ["Estados_Menu"]], NOTES)
y = c.block("t3", y, "3 · Interacciones y animaciones (conceptos)",
            [["C_Mover"], ["C_Salto", "C_Meta"], ["C_Muro"], ["C_Turno"], ["C_Desconexion"], ["C_Tablas"]], NOTES)
y = c.block("t3b", y, "3b · Las mismas interacciones en la pantalla real",
            [["R_Mover", "R_Salto"], ["R_MuroOk", "R_MuroMal"], ["R_Urgente", "R_Desconexion"], ["R_Tablas", "R_Menu"], ["R_Chat", "R_Cuatro"], ["R_Meta"]], NOTES)
y = c.block("t4", y, "4 · Computadora: 1280×720, 1920×1080 y ventana", [["PC_1280"], ["PC_1920"], ["PC_Ventana"]], NOTES)

files = c.write(swap=a_blob)
if "--render" in sys.argv:
    rep = c.render(out=str(AQUI / "r"), to_local=a_local)
    print(json.dumps(rep, ensure_ascii=False, indent=0)[:3000])
c.close()
print(len(files), "tableros")

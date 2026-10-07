# -*- coding: utf-8 -*-
"""lib_bastion.py · estilo y componentes de la GUI de Bastión para los lienzos de prototipos.

Bastión es un juego de escritorio en C# (no Roblox): no hay CoreGui. Lo que dibuja
"el sistema" encima del juego es, como mucho, la barra de título de la ventana cuando
el juego corre en modo ventana; a pantalla completa no hay nada. La paleta sale de los
modelos reales de modelos-3d/ (tablero terracota, muro de madera, colores de jugador del
LEEME) y del fondo crema de sus vistas previas.
"""
import json
from pathlib import Path

import kit
from kit import *  # noqa: F401,F403

AQUI = Path(__file__).resolve().parent
NUNITO = AQUI / "node_modules/@fontsource/nunito/files"

kit.THEME.update({
    "bg": "#F6F1E6", "surf": "#FFFDF8", "line": "#E2D6C3", "ink": "#2A1F1A", "ink2": "#5A4A40", "muted": "#7A6A5E",
    "acc": "#9C4F3E", "navy": "#2A1F1A", "hf": "'Nunito', sans-serif", "bf": "'Nunito', sans-serif",
    "fonts_link": '<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Nunito:wght@400;600;700;800;900&amp;display=swap">',
    "fonts_local_css": "".join(
        f"@font-face{{font-family:'Nunito';font-weight:{w};src:url('file://{NUNITO}/nunito-latin-{w}-normal.woff2') format('woff2')}}"
        for w in (400, 600, 700, 800, 900)),
})
T = kit.T
J = {"J1": "#D85A30", "J2": "#1D9E75", "J3": "#7F77DD", "J4": "#EF9F27"}
TXT_J = {"J1": "#A8401C", "J2": "#11704F", "J3": "#5149B0", "J4": "#9A5A00"}   # versión oscura para texto (4.5:1 sobre crema)
MADERA = "#F0C488"
TABLERO = "#9C4F3E"
ERR = "#B3261E"
OK = "#11704F"

COORDS = json.loads((AQUI / "coords.json").read_text())


def cel(c, n=9, alto=False):
    """Coordenadas en pantalla (1366×768) del centro de una casilla en el render de la escena."""
    return COORDS[str(n)][c + ("_alto" if alto else "")]


kit.ICONS.update({
    "menu": '<path d="M4 7h16"></path><path d="M4 12h16"></path><path d="M4 17h16"></path>',
    "chat": '<path d="M4 5h16v11H9l-5 4z"></path>',
    "muro": '<rect x="3" y="9" width="18" height="6" rx="1.5"></rect><path d="M3 12h18"></path>',
    "reloj": '<circle cx="12" cy="13" r="8"></circle><path d="M12 9v4l3 2"></path><path d="M10 2h4"></path>',
    "bandera": '<path d="M5 21V4"></path><path d="M5 4h11l-2 4 2 4H5"></path>',
    "igual": '<path d="M5 9h14"></path><path d="M5 15h14"></path>',
    "centrar": '<circle cx="12" cy="12" r="3"></circle><path d="M12 2v4M12 18v4M2 12h4M18 12h4"></path>',
    "vista": '<rect x="4" y="4" width="16" height="16" rx="2"></rect><path d="M4 12h16M12 4v16"></path>',
    "sonido": '<path d="M4 10v4h4l5 4V6L8 10z"></path><path d="M16 9a4 4 0 010 6"></path>',
    "ayuda": '<circle cx="12" cy="12" r="9"></circle><path d="M9.5 9.5a2.5 2.5 0 114 2c-1 .7-1.5 1.2-1.5 2.5"></path><path d="M12 17h.01"></path>',
    "rotar": '<path d="M20 12a8 8 0 11-3-6.2"></path><path d="M20 4v5h-5"></path>',
    "x": '<path d="M6 6l12 12M18 6L6 18"></path>',
    "check": '<path d="M5 12l5 5 9-10"></path>',
    "alerta": '<path d="M12 3l10 18H2z"></path><path d="M12 10v5"></path><path d="M12 18h.01"></path>',
    "wifi": '<path d="M2 9a15 15 0 0120 0"></path><path d="M5 13a10 10 0 0114 0"></path><path d="M8.5 16.5a5 5 0 017 0"></path><path d="M12 20h.01"></path>',
    "enviar": '<path d="M4 12l16-8-6 16-2-7z"></path>',
    "silenciar": '<path d="M4 10v4h4l5 4V6L8 10z"></path><path d="M16 9l5 6M21 9l-5 6"></path>',
    "bloquear": '<circle cx="12" cy="12" r="9"></circle><path d="M5.6 5.6l12.8 12.8"></path>',
})


# ---------------------------------------------------------------- fondo: el tablero real
def fondo(escena, W=1366, H=768):
    """Render de Blender de los modelos reales (ASSET:<escena>), a pantalla completa como la cámara del juego."""
    return (f'<img src="ASSET:{escena}" alt="" style="position: absolute; left: 0; top: 0; width: {W}px; height: {H}px; object-fit: cover; display: block;">')


def barra_ventana(W):
    """Lo único que dibuja el sistema operativo encima del juego: la barra de título en modo ventana."""
    return (f'<div style="position: absolute; left: 0; top: 0; width: {W}px; height: 32px; background: rgba(30,30,30,0.86); color: #FFFFFF; '
            f'display: flex; align-items: center; justify-content: space-between; padding: 0 12px; box-sizing: border-box; font: 600 12px {T("bf")}; z-index: 5;">'
            f'<span>Bastión</span><span style="letter-spacing: 14px;">–□×</span></div>')


def pantalla(W, H, escena, hud, overlay="", ventana=False, velo=0.0, etiqueta="", zoom=None):
    """Equivalente de en_juego() para escritorio: el tablero 3D de fondo, el HUD encima y, si corre en ventana,
    la barra de título del sistema. etiqueta = texto de cobertura (anotación)."""
    d = f'<div style="position: absolute; inset: 0; background: rgba(42,31,26,{velo}); z-index: 1;"></div>' if velo else ""
    top = 32 if ventana else 0
    lab = (f'<div style="position: absolute; left: 12px; bottom: 10px; z-index: 9;"><span style="display: inline-flex; padding: 3px 10px; border-radius: 8px; '
           f'background: {kit.ANN}; color: #FFFFFF; font: 700 13px {T("bf")}; white-space: nowrap;">{etiqueta}</span></div>') if etiqueta else ""
    inner = (f'<div style="position: relative; width: {W}px; height: {H}px; overflow: hidden; background: {T("bg")};">'
             f'<div style="position: absolute; left: 0; top: {top}px; width: {W}px; height: {H - top}px; overflow: hidden;">'
             f'{fondo(escena, W, H - top) if escena else ""}{d}<div style="position: absolute; inset: 0; z-index: 2;">{hud}</div></div>'
             f'{barra_ventana(W) if ventana else ""}{overlay}{lab}</div>')
    return inner if zoom is None else f'<div style="width: {W}px; height: {H}px; zoom: {zoom};">{inner}</div>'


# ---------------------------------------------------------------- piezas
def ico(n, s=20, c=None, sw=2):
    return kit.icon(n, s, c or T("ink"), sw)


def panel_bg(extra=""):
    return f"background: rgba(255,253,248,0.94); border: 1.5px solid {T('line')}; border-radius: 14px; box-shadow: 0 6px 18px rgba(42,31,26,0.12); {extra}"


def boton_icono(n, etiqueta, badge=None, estado="normal"):
    """Botón cuadrado de 44×44 del HUD. estado: normal | hover | pulsado | foco | deshabilitado."""
    bg = {"normal": T("surf"), "hover": "#FFF4E6", "pulsado": "#EFE3D2", "foco": T("surf"), "deshabilitado": "#EFEAE1"}[estado]
    ring = f"box-shadow: 0 0 0 3px {T('bg')}, 0 0 0 6px {TABLERO};" if estado == "foco" else "box-shadow: 0 3px 10px rgba(42,31,26,0.12);"
    op = "opacity: 0.5;" if estado == "deshabilitado" else ""
    b = (f'<span style="position: absolute; top: -6px; right: -6px; min-width: 20px; height: 20px; border-radius: 10px; background: {J["J1"]}; color: #FFFFFF; '
         f'font: 800 12px {T("bf")}; display: flex; align-items: center; justify-content: center; padding: 0 5px; box-sizing: border-box;">{badge}</span>') if badge else ""
    return (f'<button type="button" aria-label="{etiqueta}" style="position: relative; width: 44px; height: 44px; border-radius: 12px; border: 1.5px solid {T("line")}; '
            f'background: {bg}; display: flex; align-items: center; justify-content: center; padding: 0; {ring} {op}">{ico(n, 22)}{b}</button>')


def reloj(t, activo=False, urgente=False, apagado=False):
    if apagado:
        return f'<span style="font: 800 18px {T("bf")}; color: {T("muted")}; font-variant-numeric: tabular-nums; white-space: nowrap;">{t}</span>'
    bg = ERR if urgente else (T("ink") if activo else "transparent")
    fg = "#FFFFFF" if (activo or urgente) else T("ink2")
    bd = "none" if (activo or urgente) else f"1.5px solid {T('line')}"
    return (f'<span style="display: inline-flex; align-items: center; gap: 5px; padding: 3px 10px; border-radius: 9px; background: {bg}; color: {fg}; border: {bd}; '
            f'font: 800 18px {T("bf")}; font-variant-numeric: tabular-nums; white-space: nowrap;">{ico("reloj", 15, fg, 2.4) if (activo or urgente) else ""}{t}</span>')


def muros_barra(n, total=10, color="#000"):
    s = "".join(f'<span style="width: 5px; height: 12px; border-radius: 2px; background: {color if i < n else "transparent"}; border: 1.5px solid {color}; box-sizing: border-box;"></span>' for i in range(total))
    return f'<span style="display: inline-flex; gap: 2px; align-items: center;">{s}</span>'


def fila_jugador(nombre, jug, muros, total, t, estado="espera", tu=False):
    """estado: turno | espera | urgente | desconectado | abandono | clasificado"""
    c = J[jug]
    turno = estado in ("turno", "urgente")
    borde = f"box-shadow: inset 4px 0 0 {c};" if turno else ""
    fondo_f = "#FFF6EE" if turno else "transparent"
    sub = {"turno": "le toca", "espera": "", "urgente": "¡últimos segundos!", "desconectado": "desconectado · su reloj corre",
           "abandono": "abandonó · sus muros se quedan", "clasificado": "llegó a la meta · 1.º"}[estado]
    if tu and estado == "turno":
        sub = "te toca"
    op = "opacity: 0.55;" if estado == "abandono" else ""
    ficha = (f'<span style="width: 18px; height: 18px; border-radius: 9px; background: {c}; flex-shrink: 0; '
             + ("border: 2px dashed #FFFFFF; box-shadow: 0 0 0 2px " + c + ";" if estado == "desconectado" else "") + '"></span>')
    subh = f'<span style="font: 700 12px {T("bf")}; color: {ERR if estado == "urgente" else TXT_J[jug]}; white-space: nowrap;">{sub}</span>' if sub else ""
    tu_h = f'<span style="font: 700 12px {T("bf")}; color: {T("muted")}; white-space: nowrap;">tú</span>' if tu else ""
    nombre_h = (f'<span style="font: 800 15px {T("bf")}; color: {T("ink")}; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; max-width: 170px;">'
                f'{nombre}</span>{tu_h}')
    rel = reloj(t, activo=estado == "turno", urgente=estado == "urgente", apagado=estado in ("abandono", "clasificado"))
    return (f'<div style="display: flex; align-items: center; gap: 10px; padding: 8px 12px; border-radius: 10px; background: {fondo_f}; {borde} {op}">'
            f'{ficha}<div style="display: flex; flex-direction: column; gap: 3px; flex-grow: 1; min-width: 0;">'
            f'<div style="display: flex; align-items: baseline; gap: 6px; min-width: 0;">{nombre_h}</div>'
            f'<div style="display: flex; align-items: center; gap: 6px;">{muros_barra(muros, total, c)}<span style="font: 700 12px {T("bf")}; color: {T("ink2")}; white-space: nowrap;">{muros} muros</span></div>{subh}</div>'
            f'{rel}</div>')


def panel_jugadores(filas, modo="clásico 9×9 · clasificatoria", w=330):
    return (f'<div style="width: {w}px; {panel_bg("padding: 8px; box-sizing: border-box;")} display: flex; flex-direction: column; gap: 4px;">'
            f'<div style="font: 700 11px {T("bf")}; color: {T("muted")}; text-transform: uppercase; letter-spacing: 0.6px; padding: 2px 6px;">{modo}</div>{"".join(filas)}</div>')


def barra_derecha(badge=None, menu_estado="normal"):
    return (f'<div style="display: flex; gap: 10px;">{boton_icono("chat", "Abrir el chat de la partida", badge)}'
            f'{boton_icono("menu", "Menú de la partida", None, menu_estado)}</div>')


def barra_acciones(muros=7, total=10, modo="mover", muro_estado="normal", pista=None):
    """Barra inferior: colocar muro (con cuántos quedan) y la pista de lo que se puede hacer ahora."""
    activo = modo == "muro"
    bg = T("ink") if activo else T("surf")
    fg = "#FFFFFF" if activo else T("ink")
    if muro_estado == "deshabilitado":
        bg, fg = "#EFEAE1", T("muted")
    boton = (f'<button type="button" style="display: flex; align-items: center; gap: 10px; height: 52px; padding: 0 16px; border-radius: 14px; border: 1.5px solid {T("line")}; '
             f'background: {bg}; color: {fg}; font: 800 16px {T("bf")}; white-space: nowrap; box-shadow: 0 4px 12px rgba(42,31,26,0.12);">'
             f'{ico("muro", 22, fg)}<span>{"colocando muro" if activo else ("sin muros" if muro_estado == "deshabilitado" else "muro")}</span>'
             f'<span style="padding: 2px 8px; border-radius: 8px; background: {"rgba(255,255,255,0.18)" if activo else "#F3EADC"}; font: 800 14px {T("bf")};">{muros}/{total}</span>'
             f'<span style="font: 700 12px {T("bf")}; opacity: 0.75;">M</span></button>')
    p = pista or ("haz clic en tu peón para moverlo, o pulsa M para colocar un muro" if modo == "mover" else
                  "mueve el ratón para elegir el surco · R gira · clic o Enter confirma · Esc cancela")
    return (f'<div style="display: flex; align-items: center; gap: 12px;">{boton}'
            f'<span style="padding: 8px 14px; border-radius: 12px; background: rgba(255,253,248,0.9); border: 1.5px dashed {T("line")}; font: 700 14px {T("bf")}; color: {T("ink2")}; white-space: nowrap;">{p}</span></div>')


def hud(filas, modo_txt="clásico 9×9 · clasificatoria", muros=7, total=10, modo="mover", badge=None, pista=None, muro_estado="normal",
        W=1366, H=768, menu_estado="normal", mostrar_acciones=True):
    acc = (f'<div style="position: absolute; left: 50%; bottom: 18px; transform: translateX(-50%);">'
           f'{barra_acciones(muros, total, modo, muro_estado, pista)}</div>') if mostrar_acciones else ""
    return (f'<div style="position: absolute; left: 16px; top: 16px;">{panel_jugadores(filas, modo_txt)}</div>'
            f'<div style="position: absolute; right: 16px; top: 16px;">{barra_derecha(badge, menu_estado)}</div>{acc}')


def aviso_cursor(texto, x, y, tipo="error"):
    """Aviso junto al cursor, sin ventana ni bloqueo (CU-20 RN-09). Se abre hacia dentro de la pantalla."""
    c = ERR if tipo == "error" else OK
    return kit.at(f'<div style="display: flex; align-items: center; gap: 8px; padding: 8px 12px; border-radius: 10px; background: {T("ink")}; color: #FFFFFF; '
                  f'font: 700 14px {T("bf")}; white-space: nowrap; box-shadow: 0 6px 16px rgba(0,0,0,0.25); border-left: 4px solid {c};">'
                  f'{ico("alerta" if tipo == "error" else "check", 16, "#FFFFFF")}{texto}</div>', x, y, 8)


def cartel_muro(valido=True, camino_rival="6 → 8 pasos", surco="d6 horizontal"):
    c = OK if valido else ERR
    txt = (f'camino de kobo: {camino_rival}' if valido else 'encerraría a kobo: no se puede')
    return (f'<div style="display: flex; flex-direction: column; gap: 6px; padding: 8px 10px; border-radius: 12px; {panel_bg()} border-color: {c};">'
            f'<div style="font: 800 13px {T("bf")}; color: {c}; white-space: nowrap;">{surco} · {txt}</div>'
            f'<div style="display: flex; gap: 6px;">'
            + "".join(f'<span style="padding: 2px 8px; border-radius: 7px; border: 1.5px solid {T("line")}; font: 700 12px {T("bf")}; color: {T("ink2")}; white-space: nowrap;">{k}</span>'
                      for k in (["R girar", "Esc cancelar", "Enter colocar"] if valido else ["R girar", "Esc cancelar"]))
            + '</div></div>')


def boton(t, tipo="sec", w=None, estado="normal"):
    st = {"prim": f"background: {T('ink')}; color: #FFFFFF; border: none;",
          "sec": f"background: {T('surf')}; color: {T('ink')}; border: 1.5px solid {T('line')};",
          "peligro": f"background: {T('surf')}; color: {ERR}; border: 1.5px solid #E6B8B3;"}[tipo]
    if estado == "deshabilitado":
        st = f"background: #EFEAE1; color: {T('muted')}; border: 1.5px solid {T('line')};"
    ww = f"width: {w}px;" if w else ""
    return (f'<button type="button" style="height: 44px; padding: 0 18px; border-radius: 12px; {st} font: 800 15px {T("bf")}; white-space: nowrap; {ww}">{t}</button>')


def tarjeta(inner, w, pad=22):
    return f'<div style="width: {w}px; {panel_bg(f"padding: {pad}px; box-sizing: border-box; border-radius: 18px;")} display: flex; flex-direction: column; gap: 14px;">{inner}</div>'


def banner(inner, w=520):
    return f'<div style="width: {w}px; {panel_bg("padding: 12px 16px; box-sizing: border-box;")} display: flex; align-items: center; gap: 12px;">{inner}</div>'


def menu_partida(tablas="disponible", w=330):
    """tablas: disponible | espera (1 vez cada 5 jugadas) | pendiente (ya ofreciste) | no_aplica (4 jugadores)"""
    tab_sub = {"disponible": "sin confirmación", "espera": "en 3 jugadas tuyas", "pendiente": "esperando a kobo",
               "no_aplica": "solo en partidas de 2"}[tablas]
    tab_off = tablas != "disponible"
    items = [("centrar", "recentrar cámara", "doble clic", False), ("vista", "vista superior (2D)", "V", False),
             ("sonido", "sonido", "activado", False), ("igual", "ofrecer tablas", tab_sub, tab_off),
             ("bandera", "rendirse", "pide confirmar", False), ("ayuda", "cómo jugar", "F1", False)]
    filas = "".join(
        f'<button type="button" style="display: flex; align-items: center; gap: 12px; width: 100%; height: 46px; padding: 0 12px; border: none; border-bottom: 1px solid {T("line")}; '
        f'background: transparent; font: 800 15px {T("bf")}; color: {T("muted") if off else T("ink")}; {"opacity: 0.7;" if off else ""} text-align: left;">'
        f'{ico(i, 20, T("muted") if off else T("ink"))}<span style="flex-grow: 1;">{t}</span>'
        f'<span style="font: 700 12px {T("bf")}; color: {T("muted")}; white-space: nowrap;">{s}</span></button>'
        for i, t, s, off in items)
    return f'<div style="width: {w}px; {panel_bg("padding: 6px; box-sizing: border-box;")}">{filas}</div>'


def chat(mensajes, w=340, h=360, estado="normal", borrador=""):
    """estado: normal | vacio | restringido | filtrado"""
    cuerpo = "".join(f'<div style="font: 600 14px {T("bf")}; color: {T("ink")};"><b style="color: {TXT_J[j]};">{q}:</b> {m}</div>' for q, j, m in mensajes)
    if estado == "vacio":
        cuerpo = f'<div style="font: 600 14px {T("bf")}; color: {T("muted")}; text-align: center; margin-top: 40px;">todavía no hay mensajes.<br>sé amable: el chat se modera.</div>'
    extra = ""
    if estado == "filtrado":
        extra = (f'<div style="padding: 6px 10px; border-radius: 8px; background: #FBEDEB; color: {ERR}; font: 700 12px {T("bf")};">'
                 f'tu mensaje no se envió: tiene una palabra que no se permite.</div>')
    if estado == "restringido":
        campo = (f'<div style="flex-grow: 1; height: 40px; border-radius: 10px; border: 1.5px dashed {T("line")}; display: flex; align-items: center; padding: 0 10px; '
                 f'font: 600 13px {T("bf")}; color: {T("muted")};">chat restringido 18:42 · puedes seguir jugando</div>')
    else:
        campo = (f'<label style="flex-grow: 1; height: 40px; border-radius: 10px; border: 1.5px solid {T("line")}; display: flex; align-items: center; padding: 0 10px; '
                 f'font: 600 14px {T("bf")}; color: {T("ink") if borrador else T("muted")}; background: #FFFFFF;">{borrador or "escribe un mensaje…"}</label>'
                 f'{boton_icono("enviar", "Enviar")}')
    return (f'<div style="width: {w}px; height: {h}px; {panel_bg("box-sizing: border-box;")} display: flex; flex-direction: column; overflow: hidden;">'
            f'<div style="display: flex; justify-content: space-between; align-items: center; padding: 10px 14px; border-bottom: 1px solid {T("line")};">'
            f'<span style="font: 800 15px {T("bf")};">chat de la partida</span>{ico("x", 18)}</div>'
            f'<div style="flex-grow: 1; padding: 10px 14px; display: flex; flex-direction: column; gap: 8px; overflow: hidden;">{cuerpo}{extra}</div>'
            f'<div style="display: flex; gap: 8px; padding: 10px; border-top: 1px solid {T("line")};">{campo}</div></div>')

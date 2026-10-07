# -*- coding: utf-8 -*-
"""build_acceso.py · lienzo «Bastión · Acceso con segundo factor (prototipo)».

Sección: entrar, registrarse, código del segundo factor, cuenta sin verificar y bloqueo por
intentos (CU-01, CU-02, CU-03, CU-04, CON-08). La GUI es una tarjeta sobre el tablero del menú.
Uso: python build_acceso.py [--render]
"""
import json
import os
import sys
from pathlib import Path

from lib_bastion import *  # noqa: F401,F403
import kit

AQUI = Path(__file__).resolve().parent
RENDER = Path(os.environ.get("RENDER", AQUI.parent / "escena" / "render"))
ASSETS = json.loads((AQUI / "assets_acceso.json").read_text()) if (AQUI / "assets_acceso.json").exists() else {}
W, H = 1366, 768
GW, GH = 440, 520
GX, GY = 96, (H - GH) // 2


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


def campo(etq, valor="", estado="normal", tipo="text", ayuda=""):
    """estado: normal | foco | error | deshabilitado"""
    bd = {"normal": f"1.5px solid {T('line')}", "foco": f"2px solid {TABLERO}", "error": f"2px solid {ERR}",
          "deshabilitado": f"1.5px dashed {T('line')}"}[estado]
    bg = "#F3EEE6" if estado == "deshabilitado" else "#FFFFFF"
    ring = f"box-shadow: 0 0 0 3px rgba(156,79,62,0.18);" if estado == "foco" else ""
    txt = ("•" * len(valor)) if tipo == "password" else valor
    color = T("ink") if valor else T("muted")
    ay = (f'<span style="font: 700 12px {T("bf")}; color: {ERR if estado == "error" else T("muted")};">{ay_icon(estado)}{ayuda}</span>') if ayuda else ""
    return (f'<label style="display: flex; flex-direction: column; gap: 6px;"><span style="font: 800 13px {T("bf")}; color: {T("ink2")};">{etq}</span>'
            f'<span style="height: 46px; border-radius: 12px; border: {bd}; background: {bg}; {ring} display: flex; align-items: center; padding: 0 14px; '
            f'font: 700 16px {T("bf")}; color: {color}; box-sizing: border-box;">{txt or "…"}</span>{ay}</label>')


def ay_icon(estado):
    return ico("alerta", 13, ERR) + " " if estado == "error" else ""


def boton_full(t, tipo="prim", estado="normal"):
    st = {"prim": f"background: {T('ink')}; color: #FFFFFF; border: none;", "sec": f"background: {T('surf')}; color: {T('ink')}; border: 1.5px solid {T('line')};"}[tipo]
    if estado == "cargando":
        t = f'<span style="width: 16px; height: 16px; border-radius: 8px; border: 2.5px solid rgba(255,255,255,0.35); border-top-color: #FFFFFF;"></span>{t}'
    if estado == "deshabilitado":
        st = f"background: #E9E2D6; color: {T('muted')}; border: none;"
    return f'<button type="button" style="width: 100%; height: 50px; border-radius: 14px; {st} font: 900 17px {T("bf")}; display: flex; align-items: center; justify-content: center; gap: 10px;">{t}</button>'


def digitos(vals, estado="normal"):
    bd = {"normal": T("line"), "error": ERR, "ok": OK}[estado]
    out = ""
    for i, v in enumerate(vals):
        foco = estado == "normal" and i == len([x for x in vals if x])
        out += (f'<span style="width: 48px; height: 58px; border-radius: 12px; border: {"2.5px solid " + TABLERO if foco else "1.5px solid " + bd}; background: #FFFFFF; '
                f'display: flex; align-items: center; justify-content: center; font: 900 26px {T("bf")};">{v}</span>')
    return f'<div style="display: flex; gap: 8px;">{out}</div>'


def marca():
    return (f'<div style="display: flex; align-items: baseline; justify-content: space-between;"><span style="font: 900 34px {T("hf")}; color: {T("ink")};">Bastión</span>'
            f'<span style="padding: 3px 10px; border-radius: 9px; border: 1.5px solid {T("line")}; font: 800 13px {T("bf")};">es-MX ▾</span></div>')


def tarjeta_gui(inner):
    return f'<div style="width: {GW}px; min-height: {GH}px; {panel_bg("padding: 28px; box-sizing: border-box; border-radius: 22px;")} background: #FFFDF8; display: flex; flex-direction: column; gap: 16px;">{inner}</div>'


def login(usuario="marta_muros", clave="Marta#Mu", estado_u="normal", estado_c="normal", boton_estado="normal", aviso=""):
    av = (f'<div style="padding: 10px 12px; border-radius: 10px; background: #FBEDEB; color: {ERR}; font: 700 13px {T("bf")};">{aviso}</div>') if aviso else ""
    return tarjeta_gui(
        marca() + f'<div style="font: 700 15px {T("bf")}; color: {T("ink2")}; margin-top: -8px;">muros y caminos</div>'
        + campo("nickname o correo", usuario, estado_u) + campo("contraseña", clave, estado_c, "password") + av
        + f'<div style="display: flex; justify-content: flex-end;"><a href="#" style="font: 800 13px {T("bf")}; color: {TABLERO};">¿olvidaste tu contraseña?</a></div>'
        + boton_full("entrar", "prim", boton_estado) + boton_full("crear cuenta", "sec")
        + f'<div style="font: 600 12px {T("bf")}; color: {T("muted")}; text-align: center;">si activaste el segundo factor, después te pediremos un código</div>')


def segundo_factor(vals=("4", "8", "1", "", "", ""), estado="normal", t="4:36", intentos=3, aviso=""):
    av = (f'<div style="padding: 10px 12px; border-radius: 10px; background: #FBEDEB; color: {ERR}; font: 700 13px {T("bf")};">{aviso}</div>') if aviso else ""
    return tarjeta_gui(
        marca() + f'<div style="font: 900 22px {T("hf")};">código de verificación</div>'
        + f'<div style="font: 600 14px {T("bf")}; color: {T("ink2")};">te enviamos un código de 6 dígitos a m••••@correo.mx</div>'
        + digitos(vals, estado) + av
        + f'<div style="display: flex; justify-content: space-between; font: 700 13px {T("bf")}; color: {T("ink2")};"><span>vence en {t}{"" if aviso else f" · {intentos} intentos"}</span>'
        f'<a href="#" style="color: {TABLERO};">reenviar código</a></div>'
        + boton_full("verificar", "prim", "normal" if all(vals) else "deshabilitado") + boton_full("cancelar", "sec"))


def pendiente():
    return tarjeta_gui(
        marca() + f'<div style="font: 900 22px {T("hf")};">activa tu cuenta</div>'
        + f'<div style="font: 600 14px {T("bf")}; color: {T("ink2")};">enviamos un enlace a m••••@correo.mx. vale 24 horas. mira también el spam.</div>'
        + f'<div style="flex-grow: 1;"></div>' + boton_full("reenviar en 4:12", "sec", "deshabilitado") + boton_full("volver a entrar", "prim"))


def registro(fecha="01/07/2009", estado_fecha="normal", ayuda_fecha="mínimo 8 años"):
    return (f'<div style="width: 520px; {panel_bg("padding: 26px; box-sizing: border-box; border-radius: 22px;")} background: #FFFDF8; display: flex; flex-direction: column; gap: 12px;">'
            + marca() + f'<div style="font: 900 22px {T("hf")};">crear cuenta</div>'
            + campo("nickname", "marta_muros", "normal", ayuda="de 3 a 30 caracteres, sin espacios · ✓ disponible")
            + campo("correo", "marta@correo.mx")
            + f'<div style="display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 12px;">{campo("contraseña", "Marta#Muros9", "normal", "password")}{campo("repítela", "Marta#Muros9", "normal", "password")}</div>'
            + f'<div style="display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 12px;">{campo("fecha de nacimiento", fecha, estado_fecha, ayuda=ayuda_fecha)}{campo("idioma", "español (México) ▾")}</div>'
            + f'<label style="display: flex; gap: 10px; align-items: center; font: 700 14px {T("bf")};"><span style="width: 22px; height: 22px; border-radius: 6px; background: {T("ink")}; color: #FFFFFF; display: flex; align-items: center; justify-content: center;">{ico("check", 14, "#FFFFFF", 3)}</span>acepto los términos de uso (2026.2)</label>'
            + boton_full("crear cuenta", "prim", "deshabilitado" if estado_fecha == "error" else "normal") + '</div>')


def en_menu(gui, x=GX, y=GY, gw=GW, gh=GH, W_=W, H_=H, velo=0.35, etiqueta=None, overlay="", ventana=False, zoom=None):
    lab = etiqueta or f"La tarjeta cubre {round(gw * 100 / W_)} % del ancho × {round(gh * 100 / H_)} % del alto"
    return pantalla(W_, H_, "menu", kit.at(gui, x, y, 3), overlay=overlay, velo=velo, etiqueta=lab, ventana=ventana, zoom=zoom)


c = kit.Canvas(str(AQUI / "project_acceso"), "Bastión · Acceso con segundo factor (prototipo)")
N = {}

c.board("Main", "1 · Entrar · 1366×768", W, en_menu(login()), h=H)
N["Main"] = f"""EN EL JUEGO · 1366×768

La tarjeta mide {GW}×{GH} px ({round(GW * 100 / W)} % × {round(GH * 100 / H)} %) y va a la izquierda, centrada en alto. El tablero del menú (render de los modelos reales) queda a la derecha, con un velo del 35 % para que la tarjeta se lea.
ERROR ENCONTRADO Y CORREGIDO: la tarjeta era translúcida (94 %) y las líneas del tablero se veían detrás de los campos; ahora es opaca. También medía 600 px de alto y dejaba 120 px vacíos abajo: baja a 520.

QUÉ RESUELVE (frente a 6c)
1 Campos de nickname o correo y contraseña: 6c no tenía (diferencia registrada).
2 "¿olvidaste tu contraseña?" junto al campo al que ayuda (CU-03).
3 Sin "jugar como invitado": es de fase posterior y esquivaría el segundo factor.
4 Idioma arriba a la derecha (CU-05 RN-03): se cambia antes de entrar.
SE MANTIENE: "crear cuenta" como segunda acción."""

partes = (kit.rel(login(), 1) + kit.rel(segundo_factor(), 2) + kit.rel(pendiente(), 3) + kit.rel(registro(), 4))
c.board("Completa", "1 · Las pantallas de acceso completas", 2200,
        kit.hoja("Pantallas de acceso a su tamaño real", f'<div style="display: flex; gap: 70px; padding-left: 50px; align-items: flex-start;">{partes}</div>'))
N["Completa"] = """QUÉ RESUELVE

1 Entrar (GUI_Login).
2 Código del segundo factor (GUI_SecondFactor, CU-01 RN-09): 6 casillas, vigencia visible, intentos, reenviar y cancelar. No existía prototipo; es la restricción CON-08 del profesor.
3 Cuenta sin verificar (GUI_PendingVerification): el CU-01 no deja entrar a una cuenta PENDIENTE.
4 Registro (CU-02): los campos exactos de CU-02 RN-01 a RN-05 y D-06; no se piden apellidos ni región."""

est_campo = '<div style="display: flex; gap: 28px; flex-wrap: wrap;">' + "".join(kit.cap(f'<div style="width: 300px;">{campo("contraseña", v, e, "password", a)}</div>', t, 300) for v, e, a, t in [
    ("", "normal", "", "Vacío."), ("Marta#", "foco", "", "Con foco: borde terracota y halo."),
    ("Marta#Mu", "error", "nickname o contraseña incorrectos", "Error: no dice cuál de los dos falló (CU-01 RN-01)."),
    ("", "deshabilitado", "espera 5 minutos para volver a intentar", "Bloqueado por intentos: 5, 30 y 60 min (CU-01 RN-03).")]) + "</div>"
est_boton = '<div style="display: flex; gap: 28px;">' + "".join(kit.cap(f'<div style="width: 300px;">{boton_full("entrar", "prim", e)}</div>', t, 300) for e, t in [
    ("normal", "Normal."), ("cargando", "Esperando al servidor: no se puede pulsar dos veces."), ("deshabilitado", "Deshabilitado (bloqueo o campos vacíos).")]) + "</div>"
est_cod = '<div style="display: flex; gap: 28px; flex-wrap: wrap;">' + "".join(kit.cap(digitos(v, e), t, 330) for v, e, t in [
    (("", "", "", "", "", ""), "normal", "Vacío: el foco en la primera casilla."), (("4", "8", "1", "", "", ""), "normal", "A medias: el foco avanza solo; pegar el código llena las 6."),
    (("4", "8", "1", "0", "2", "7"), "error", "Incorrecto: te quedan 2 intentos."), (("4", "8", "1", "0", "2", "9"), "ok", "Correcto: entra.")]) + "</div>"
c.board("Estados", "2 · Campos, botón y código: estados", 1460,
        kit.hoja("Partes del acceso y sus estados", kit.state_block("Campo", est_campo) + kit.state_block("Botón entrar", est_boton) + kit.state_block("Código de 6 dígitos", est_cod)))
N["Estados"] = """QUÉ RESUELVE

· Cada error se distingue por texto e icono, no solo por el rojo.
· El error de credenciales no dice si falló el nickname o la contraseña (CU-01 RN-01).
· El bloqueo escalonado (5, 30 y 60 minutos) se ve en el campo: antes (7e) decía 60 segundos, que no es lo que fijan los casos.
· El botón "entrar" pasa a "cargando" y no admite un segundo clic mientras el servidor responde (CU-01 manda un LOGIN_REQUEST por intento)."""

flujo = kit.pasos(
    kit.step("1 · Contraseña correcta", login()),
    kit.step_arrow(),
    kit.step("2 · Se pide el código", segundo_factor(("", "", "", "", "", ""), t="5:00")),
    kit.step_arrow(),
    kit.step("3 · Código correcto: menú", f'<div style="width: 300px; padding-top: 120px;">{kit.note_box("Se abre el menú principal (3b corregido). La sesión dura 24 h (CU-01 RN-07).")}</div>'),
)
c.board("C_Entrar", "3 · Concepto: entrar con segundo factor", 1500, kit.hoja("Concepto · entrar con segundo factor (CU-01, CON-08)", flujo))
N["C_Entrar"] = """FLUJO

Qué lo dispara: "entrar" con credenciales válidas en una cuenta que tiene doble_factor_habilitado (se activa en CU-09 FA-10).
Cuánto dura: la tarjeta cambia de contenido en 0,2 s (fundido); no hay ventana nueva.
Si se interrumpe: "cancelar" manda ABORT_LOGIN_REQUEST y vuelve a la tarjeta de entrar; cerrar el juego deja el código vigente 5 minutos y luego vence. Tres códigos incorrectos lo invalidan y hay que pedir otro (CU-01 RN-09).
Sin movimiento: el cambio es instantáneo."""

c.board("R_Codigo", "3b · Código incorrecto", W, en_menu(segundo_factor(("4", "8", "1", "0", "2", "7"), "error", "3:12", 2, "código incorrecto: te quedan 2 intentos")), h=H)
N["R_Codigo"] = """QUÉ SE REVISA (peor fotograma: código incorrecto con aviso)

1 El aviso cabe dentro de la tarjeta sin empujar los botones fuera de los 520 px.
2 Los intentos que quedan se dicen una sola vez, en el aviso.
ERROR ENCONTRADO Y CORREGIDO: el aviso decía «te quedan 2 intentos» y la línea de vigencia repetía «2 intentos» (doble confirmación); con aviso, la línea solo muestra la vigencia.
ERROR ENCONTRADO Y CORREGIDO: con el aviso encima de las casillas, el foco quedaba oculto; el aviso va debajo de ellas.
Resultado: se lee."""

c.board("R_Bloqueo", "3b · Bloqueo por intentos", W, en_menu(login("marta_muros", "", "normal", "deshabilitado", "deshabilitado", "demasiados intentos: espera 5 minutos (4:51)")), h=H)
N["R_Bloqueo"] = """QUÉ SE REVISA

1 El bloqueo apaga el campo de contraseña y el botón, y dice cuánto falta.
2 "¿olvidaste tu contraseña?" sigue activo: es la salida.
ERROR ENCONTRADO Y CORREGIDO: al bajar la tarjeta a 520 px, el aviso de bloqueo aplastaba los botones (32 px de alto, área de clic chica); la tarjeta tiene alto mínimo de 520 y crece con el aviso.
Resultado: correcto. POR CONFIRMAR EN EL CÓDIGO: que la cuenta atrás la mande el servidor (bloqueada_hasta) y no el reloj del equipo."""

c.board("R_Pendiente", "3b · Cuenta sin verificar", W, en_menu(pendiente()), h=H)
N["R_Pendiente"] = """QUÉ SE REVISA

El reenvío está limitado (CU-01 RN-10): el botón muestra la espera. No se puede entrar sin activar (Q-04 resuelta así en CU-01)."""

c.board("R_Registro", "3b · Registro con error de edad", W, en_menu(registro("01/07/2020", "error", "necesitas tener al menos 8 años"),
                                                                     x=96, y=40, gw=520, gh=688), h=H)
N["R_Registro"] = """QUÉ SE REVISA

1 El registro mide 520×688 px: es la pantalla más alta del acceso y cabe en 768 sin scroll.
2 El aviso de edad mínima (CU-02 RN-05) va bajo su campo, en rojo y con icono (no solo color), y «crear cuenta» se apaga hasta corregirlo.
ERROR ENCONTRADO Y CORREGIDO: la primera versión de este tablero ponía una fecha de 2020 (6 años) con el campo en estado normal y el botón activo: el error no se veía.
ERROR ENCONTRADO Y CORREGIDO: con la tarjeta de entrar (440 px) el registro no cabía; pasa a 520 de ancho y dos columnas en contraseña y fecha."""

c.board("PC_1280", "4 · Portátil 1280×720", 1280, en_menu(f'<div style="zoom: 0.9375;">{registro()}</div>', x=90, y=20, gw=488, gh=645, W_=1280, H_=720), h=720)
N["PC_1280"] = """QUÉ SE REVISA

El registro (la pantalla más alta) a 1280×720 con la UI escalada por altura (×0,9375): cabe con 20 px de margen arriba y abajo.
Celular y TV no aplican."""

c.board("PC_Ventana", "4 · Modo ventana", W, en_menu(login(), ventana=True, etiqueta="en ventana, la barra de título del sistema ocupa 32 px"), h=H)
N["PC_Ventana"] = """QUÉ SE REVISA

En ventana la tarjeta se centra en el alto útil (768 − 32). Es lo único que dibuja el sistema encima del juego."""

y = c.block("t1", 0, "1 · Acceso: en el juego y completo", [["Main"], ["Completa"]], N)
y = c.block("t2", y, "2 · Partes y estados", [["Estados"]], N)
y = c.block("t3", y, "3 · Interacciones (conceptos)", [["C_Entrar"]], N)
y = c.block("t3b", y, "3b · En la pantalla real", [["R_Codigo", "R_Bloqueo"], ["R_Pendiente", "R_Registro"]], N)
y = c.block("t4", y, "4 · Computadora", [["PC_1280", "PC_Ventana"]], N)
c.write(swap=a_blob)
if "--render" in sys.argv:
    print(json.dumps(c.render(out=str(AQUI / "r_acceso"), to_local=a_local), ensure_ascii=False)[:1500])
c.close()

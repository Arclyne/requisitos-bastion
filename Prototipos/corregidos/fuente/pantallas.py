# -*- coding: utf-8 -*-
"""Pantallas corregidas: id -> (ancho, alto, HTML del cuerpo).

Qué cambió en cada una y por qué está en Prototipos/corregidos/CAMBIOS.md y en la
sección "Prototipos corregidos" del documento.
"""


def tablero(n=9, s=26, walls=(), pawns=(), marcas=(), gris=False, ancho=None):
    """Tablero isométrico en SVG. walls: (i, j, 'h'|'v'); pawns: (i, j, relleno); marcas: casillas resaltadas."""
    cx = n * s * 0.9
    pts = []

    def p(i, j):
        return (cx + (i - j) * s * 0.9, 20 + (i + j) * s * 0.52)
    col = "#b9b9b9" if gris else "#1b1b1b"
    for i in range(n):
        for j in range(n):
            a, b, c, d = p(i + .08, j + .08), p(i + .92, j + .08), p(i + .92, j + .92), p(i + .08, j + .92)
            fill = "#cfcfcf" if (i, j) in marcas else "#fbfaf7"
            pts.append(f'<polygon points="{a[0]:.1f},{a[1]:.1f} {b[0]:.1f},{b[1]:.1f} {c[0]:.1f},{c[1]:.1f} {d[0]:.1f},{d[1]:.1f}" '
                       f'fill="{fill}" stroke="{col}" stroke-width="1.6"/>')
    for i, j, o in walls:
        a, b = (p(i + 1, j), p(i + 1, j + 2)) if o == "v" else (p(i, j + 1), p(i + 2, j + 1))
        pts.append(f'<line x1="{a[0]:.1f}" y1="{a[1]:.1f}" x2="{b[0]:.1f}" y2="{b[1]:.1f}" stroke="#1b1b1b" stroke-width="5" stroke-linecap="round"/>')
    for i, j, rel in pawns:
        x, y = p(i + .5, j + .5)
        pts.append(f'<ellipse cx="{x:.1f}" cy="{y - 4:.1f}" rx="6" ry="4" fill="{rel}" stroke="#1b1b1b" stroke-width="2"/>'
                   f'<rect x="{x - 4:.1f}" y="{y - 20:.1f}" width="8" height="16" rx="4" fill="{rel}" stroke="#1b1b1b" stroke-width="2"/>'
                   f'<circle cx="{x:.1f}" cy="{y - 24:.1f}" r="5.5" fill="{rel}" stroke="#1b1b1b" stroke-width="2"/>')
    w = 2 * cx
    h = 40 + n * s * 1.04
    style = f' style="width:{ancho or round(w)}px"'
    return f'<svg viewBox="0 0 {w:.0f} {h:.0f}"{style} xmlns="http://www.w3.org/2000/svg">{"".join(pts)}</svg>'


def hud_partida(turno="tu turno"):
    return f'''
<div class="caja fina" style="position:absolute;left:18px;top:16px;width:270px;padding:8px 10px">
  <div class="fila entre"><div class="fila"><div class="circ" style="width:26px;height:26px;border-width:2px"></div>
    <div><div class="peq">kobo</div><div class="mini gris">7 muros ▮▮▮▮▮▮▮</div></div></div><span class="chip">3:58</span></div>
  <div class="fila entre" style="margin-top:6px"><div class="fila"><div class="circ" style="width:26px;height:26px;border-width:2px"></div>
    <div><div class="peq">tú</div><div class="mini gris">10 muros ▮▮▮▮▮▮▮▮▮▮</div></div></div><span class="chip on">4:58</span></div>
</div>
<div class="fila" style="position:absolute;right:18px;top:16px"><span class="chip on">{turno}</span><span class="btn" style="padding:2px 10px">≡</span></div>'''


BASE_MENU = f'''
<div class="fila entre"><div class="fila"><div class="circ" style="width:64px;height:64px"></div>
  <div><h2 style="margin:0">marta_muros</h2><div class="peq gris">elo 1842 · clásico 9×9</div></div></div>
  <div class="fila"><span class="btn" style="padding:6px 12px">⚙ ajustes</span></div></div>
<div style="position:absolute;left:210px;top:120px;opacity:.35">{tablero(9, 30, gris=True)}</div>
'''

PANTALLAS = {}

# ------------------------------------------------------------------ 3b menú principal
PANTALLAS["3b"] = (1000, 720, BASE_MENU + '''
<div class="col" style="position:absolute;left:300px;top:190px;width:400px">
  <div class="btn full" style="font-size:28px;padding:18px">buscar partida</div>
  <div class="fila"><div class="btn" style="flex:1">crear sala privada</div><div class="btn" style="flex:1">unirse con código</div></div>
</div>
<div class="fila" style="position:absolute;left:24px;bottom:24px"><span class="btn sec">cómo jugar</span><span class="btn sec">moderación</span></div>
<div class="peq gris" style="position:absolute;right:24px;bottom:30px">el botón moderación solo lo ve quien tiene ese rol</div>
''')

# ------------------------------------------------------------------ 6c inicio de sesión
PANTALLAS["6c"] = (760, 800, '''
<div class="fila entre"><span></span><span class="chip">es-MX ▾</span></div>
<div class="marca" style="margin-top:4px">bastión</div>
<div class="gris" style="text-align:center;margin-bottom:18px">muros y caminos</div>
<div class="lbl">nickname o correo</div><div class="campo lleno">marta_muros</div>
<div class="lbl">contraseña</div><div class="campo lleno">••••••••••</div>
<div class="fila entre" style="margin:10px 0 18px"><span class="peq">¿olvidaste tu contraseña?</span><span class="peq gris">entra con tu nickname o tu correo</span></div>
<div class="btn prim full" style="font-size:22px;padding:14px">entrar</div>
<div class="btn full" style="margin-top:12px;font-size:20px;padding:12px">crear cuenta</div>
<div class="peq gris" style="text-align:center;position:absolute;bottom:24px;left:0;right:0">si activaste el segundo factor, después te pediremos un código</div>
''')

# ------------------------------------------------------------------ 22a registro
PANTALLAS["22a"] = (760, 800, '''
<div class="peq gris">◀ volver a entrar</div>
<h1 style="margin-top:8px">crear cuenta</h1>
<div class="lbl">nickname · de 3 a 30 caracteres, sin espacios</div><div class="campo lleno">marta_muros</div>
<div class="peq" style="margin-top:4px">✓ disponible</div>
<div class="lbl">correo</div><div class="campo lleno">marta@correo.mx</div>
<div class="fila" style="gap:14px">
  <div style="flex:1"><div class="lbl">contraseña</div><div class="campo lleno">••••••••••</div></div>
  <div style="flex:1"><div class="lbl">repítela</div><div class="campo lleno">••••••••••</div></div></div>
<div class="peq gris" style="margin-top:4px">al menos 8 caracteres y 3 de: minúsculas, mayúsculas, números, signos</div>
<div class="fila" style="gap:14px">
  <div style="flex:1"><div class="lbl">fecha de nacimiento · mínimo 8 años</div><div class="campo lleno">01 / 07 / 2009</div></div>
  <div style="flex:1"><div class="lbl">idioma</div><div class="campo lleno">español (México) ▾</div></div></div>
<div class="fila" style="margin:16px 0"><span class="chip on">✓</span><span>acepto los <u>términos de uso</u> (versión 2026.2)</span></div>
<div class="btn prim full" style="font-size:20px;padding:12px">crear cuenta</div>
<div class="peq gris" style="text-align:center;margin-top:10px">te mandaremos un correo para activarla</div>
''')

# ------------------------------------------------------------------ 22c cuenta pendiente
PANTALLAS["22c"] = (760, 560, '''
<div class="marca" style="font-size:40px">bastión</div>
<div class="caja" style="margin-top:24px;text-align:center">
  <h2>revisa tu correo</h2>
  <div class="gris">enviamos un enlace a m••••@correo.mx para activar tu cuenta.<br>el enlace vale 24 horas.</div>
  <div class="fila" style="justify-content:center;margin-top:18px"><span class="btn sec">reenviar en 4:12</span><span class="btn">ya lo activé, entrar</span></div>
</div>
<div class="peq gris" style="text-align:center;margin-top:18px">mira también el spam · no puedes jugar hasta activarla</div>
''')

# ------------------------------------------------------------------ 22b segundo factor
PANTALLAS["22b"] = (760, 600, '''
<div class="marca" style="font-size:40px">bastión</div>
<div class="caja" style="margin-top:18px">
  <h2>código de verificación</h2>
  <div class="gris">te enviamos un código de 6 dígitos a m••••@correo.mx</div>
  <div class="digitos" style="margin:18px 0"><span>4</span><span>8</span><span>1</span><span>0</span><span></span><span></span></div>
  <div class="fila entre"><span class="peq">vence en 4:36 · te quedan 3 intentos</span><span class="peq"><u>reenviar código</u></span></div>
  <div class="fila" style="margin-top:18px"><span class="btn">cancelar</span><span class="btn prim" style="flex:1">verificar</span></div>
</div>
''')

# ------------------------------------------------------------------ 1f buscando rival
PANTALLAS["1f"] = (1000, 720, BASE_MENU + '''<div class="velo"></div>
<div class="modal" style="left:230px;top:210px;width:540px">
  <h1>buscando rival…</h1>
  <div style="height:16px;border:3px solid #1b1b1b;border-radius:8px;overflow:hidden"><div style="width:55%;height:100%;background:#1b1b1b"></div></div>
  <div class="gris" style="margin:10px 0 4px">clásico 9×9 · reloj 5 min · 00:48</div>
  <div class="peq gris">buscando rivales con elo entre 1742 y 1942 · la ventana se amplía sola mientras esperas</div>
  <div class="fila" style="margin-top:16px"><span class="btn">cancelar búsqueda</span></div>
</div>''')

# ------------------------------------------------------------------ 1h partida privada
PANTALLAS["1h"] = (1000, 720, '''
<h1>partida privada</h1>
<div class="fila" style="align-items:stretch;gap:18px">
  <div class="caja" style="flex:1"><h2>crear sala</h2>
    <div class="peq gris">el código aparece al crearla</div>
    <div class="lbl">modo</div><div><span class="chip on">clásico 9×9 · 2</span><span class="chip">9×9 · 4</span><span class="chip">rápida 7×7 · 2</span></div>
    <div class="fila" style="margin-top:10px"><div style="flex:1"><div class="lbl">muros por jugador (1 a 20)</div><div class="campo lleno">10</div></div>
      <div style="flex:1"><div class="lbl">reloj</div><span class="chip">3</span><span class="chip on">5</span><span class="chip">10 min</span></div></div>
    <div class="peq gris" style="margin-top:10px">las partidas privadas no dan elo</div>
    <div class="btn prim full" style="margin-top:14px">crear sala</div></div>
  <div class="caja" style="flex:1"><h2>unirse</h2>
    <div class="lbl">código de 6 caracteres</div><div class="campo lleno" style="letter-spacing:6px;font-size:22px">K7MTQ3</div>
    <div class="peq gris" style="margin-top:6px">letras y números, sin 0, O, 1 ni I</div>
    <div class="btn prim full" style="margin-top:14px">entrar</div></div>
</div>
<div class="btn" style="position:absolute;left:24px;bottom:24px">volver</div>
''')

# ------------------------------------------------------------------ 5d sala 2 jugadores
PANTALLAS["5d"] = (1000, 720, '''
<div class="fila entre"><h1>sala privada · clásico 9×9</h1><span class="dash" style="font-size:26px;letter-spacing:6px;color:#1b1b1b;border-color:#1b1b1b">K7MTQ3</span></div>
<div class="fila" style="gap:18px">
  <div class="caja fila" style="flex:1"><div class="circ"></div><div><h2 style="margin:0">tú</h2><div class="peq gris">anfitriona · lista ✓</div></div></div>
  <div class="caja fila" style="flex:1"><div class="circ"></div><div><h2 style="margin:0">nico_nuevo</h2><div class="peq gris">no está listo</div></div></div>
</div>
<div class="caja" style="margin-top:18px"><div class="peq gris">ajustes · solo la anfitriona</div>
  <div style="margin-top:6px"><span class="chip on">clásico 9×9 · 2</span><span class="chip">9×9 · 4</span><span class="chip">rápida 7×7</span></div>
  <div style="margin-top:8px"><span class="chip sec">muros 10</span><span class="chip sec">reloj 5 min</span><span class="chip sec">sin elo</span></div></div>
<div class="caja fina" style="margin-top:14px;height:150px;background:#efeeea"><div class="peq gris">chat de la sala</div>
  <div class="peq" style="margin-top:6px">nico_nuevo: ¿empezamos?</div><div class="peq gris" style="position:absolute;margin-top:60px">mensaje…</div></div>
<div class="fila entre" style="position:absolute;left:24px;right:24px;bottom:24px"><span class="btn">salir · cierra la sala</span>
  <span class="peq gris">comparte el código para que entren</span><span class="btn off">empezar · faltan listos</span></div>
''')

# ------------------------------------------------------------------ 5e sala 4 plazas
PANTALLAS["5e"] = (1000, 720, '''
<div class="fila entre"><h1>sala · 9×9 · 4 jugadores</h1><span class="dash" style="font-size:26px;letter-spacing:6px;color:#1b1b1b;border-color:#1b1b1b">QX7PRM</span></div>
<div style="display:grid;grid-template-columns:1fr 1fr;gap:14px">
  <div class="caja fila"><div class="circ"></div><div><h2 style="margin:0">tú</h2><div class="peq gris">anfitrión · listo ✓</div></div></div>
  <div class="caja fila"><div class="circ"></div><div><h2 style="margin:0">sofia_salto</h2><div class="peq gris">lista ✓</div></div></div>
  <div class="caja fila"><div class="circ"></div><div><h2 style="margin:0">luis_quo</h2><div class="peq gris">listo ✓</div></div></div>
  <div class="dash fila"><div class="circ" style="border:2px dashed #a8a8a8"></div><div><h2 style="margin:0" class="gris">plaza libre</h2><div class="peq gris">comparte el código</div></div></div>
</div>
<div class="caja fina" style="margin-top:14px;height:170px;background:#efeeea"><div class="peq gris">chat de la sala · se filtra y se puede reportar</div>
  <div class="peq" style="margin-top:6px">sofia_salto: falta uno</div><div class="peq">luis_quo: le paso el código a pedro</div>
  <div class="campo" style="margin-top:40px;padding:6px 10px;font-size:14px">mensaje…</div></div>
<div class="fila entre" style="position:absolute;left:24px;right:24px;bottom:24px"><span class="btn">salir</span><span class="peq gris">3 / 4 listos · una partida de 4 necesita las 4 plazas</span><span class="btn off">empezar</span></div>
''')

# ------------------------------------------------------------------ 19d menú de partida
PANTALLAS["19d"] = (1000, 720, hud_partida() + f'''
<div style="position:absolute;left:180px;top:130px">{tablero(9, 30, walls=[(3, 4, "h"), (5, 2, "v")], pawns=[(4, 1, "#fbfaf7"), (4, 6, "#1b1b1b")])}</div>
<div class="velo"></div>
<div class="modal" style="right:24px;top:70px;width:430px;padding:10px 20px">
  <div class="item"><span>⌖ recentrar cámara</span><span class="peq gris">doble clic</span></div>
  <div class="item"><span>▤ vista superior (2D)</span><span class="peq gris">tecla V</span></div>
  <div class="item"><span>♪ sonido</span><span class="peq gris">activado</span></div>
  <div class="item"><span>= ofrecer tablas</span><span class="peq gris">1 vez cada 5 jugadas tuyas</span></div>
  <div class="item"><span>⚐ rendirse</span><span class="peq gris">pide confirmar</span></div>
  <div class="item" style="border:0"><span>? cómo jugar</span><span></span></div>
</div>
<div class="peq gris" style="position:absolute;left:24px;bottom:22px">tablas: solo en partidas de 2 jugadores, en cualquier momento · el reloj no se detiene con el menú abierto</div>
''')

# ------------------------------------------------------------------ 2g fin de partida
PANTALLAS["2g"] = (1000, 720, f'''
<div style="position:absolute;left:180px;top:120px;opacity:.3">{tablero(9, 30, gris=True)}</div>
<div class="modal" style="left:190px;top:130px;width:620px;text-align:center">
  <div class="marca" style="font-size:46px">¡victoria!</div>
  <div class="gris">llegaste a la meta · 37 jugadas · 4:12 · 3 muros sin usar</div>
  <div class="caja" style="display:inline-block;margin:16px 0;font-size:26px">1842 → 1861 <span class="peq">+19 elo</span></div>
  <div class="peq gris">clásico 9×9 · clasificatoria</div>
  <div class="fila" style="justify-content:center;margin-top:16px"><span class="btn">volver al menú</span><span class="btn prim">buscar otra</span></div>
  <div class="peq gris" style="margin-top:12px">⚐ reportar a kobo</div>
</div>''')

# ------------------------------------------------------------------ 6f rival desconectado
PANTALLAS["6f"] = (1000, 720, hud_partida("turno de kobo") + f'''
<div class="caja fila" style="position:absolute;left:320px;top:16px;width:360px;padding:8px 12px">
  <div class="circ" style="width:34px;height:34px;border-style:dashed"></div>
  <div><div>kobo se desconectó</div><div class="peq gris">su reloj sigue corriendo · 0:42 para reclamar</div></div></div>
<div style="position:absolute;left:200px;top:130px">{tablero(9, 28, walls=[(3, 4, "h")], pawns=[(4, 1, "#fbfaf7"), (4, 6, "#1b1b1b")])}</div>
<div class="fila" style="position:absolute;left:0;right:0;bottom:26px;justify-content:center"><span class="btn">esperar</span><span class="btn off">reclamar victoria · en 0:42</span></div>
<div class="peq gris" style="position:absolute;left:24px;bottom:84px">si kobo vuelve, la partida sigue donde estaba</div>
''')

# ------------------------------------------------------------------ 20c chat en partida
PANTALLAS["20c"] = (1000, 720, hud_partida() + f'''
<div style="position:absolute;left:60px;top:150px">{tablero(9, 26, walls=[(3, 4, "h")], pawns=[(4, 1, "#fbfaf7"), (4, 6, "#1b1b1b")])}</div>
<div class="caja fina" style="position:absolute;right:24px;top:170px;width:400px;height:470px;padding:0">
  <div class="fila entre" style="border-bottom:2px solid #1b1b1b"><span class="tab on">chat de la partida</span><span class="peq gris" style="padding-right:10px">jugadas ▾</span></div>
  <div style="padding:10px 14px" class="peq">
    <div>kobo: buena esa</div><div>tú: gracias, iba justo</div><div>kobo: te quedan pocos muros</div>
    <div class="gris" style="margin-top:8px">sistema: un mensaje tuyo no se envió porque incluye una palabra no permitida</div>
  </div>
  <div class="fila" style="position:absolute;left:12px;right:12px;bottom:12px"><div class="campo" style="flex:1;padding:6px 10px;font-size:14px">mensaje… (máx. 200)</div><span class="btn" style="padding:4px 10px">➤</span></div>
</div>
<div class="peq gris" style="position:absolute;left:24px;bottom:22px">clic derecho en un mensaje: silenciar · bloquear · reportar</div>
''')

# ------------------------------------------------------------------ 10a menú de un jugador
PANTALLAS["10a"] = (1000, 620, '''
<div class="caja fina" style="height:520px;background:#efeeea;padding:14px">
  <div class="caja fila" style="width:520px;padding:8px 12px"><div class="circ" style="width:36px;height:36px"></div><span style="font-size:20px">kobo: gané con dos muros de sobra</span></div>
  <div class="modal" style="position:relative;margin:6px 0 0 24px;width:380px;padding:8px 18px">
    <div class="item"><span>✕ silenciar en el chat</span></div>
    <div class="item"><span>⊘ bloquear</span></div>
    <div class="item" style="border:0"><span>⚐ reportar</span></div>
  </div>
  <div class="peq gris" style="margin-top:220px">silenciar solo oculta sus mensajes para ti · bloquear además impide que os emparejen · reportar lo manda a moderación</div>
</div>''')

# ------------------------------------------------------------------ 10b reportar
PANTALLAS["10b"] = (760, 900, '''
<div class="fila"><div class="circ"></div><div><h2 style="margin:0">reportar a kobo</h2><div class="peq gris">partida de hace 4 min · clásico 9×9</div></div></div>
<div class="lbl">motivo</div>
<div class="col" style="gap:8px">
  <div class="caja fila" style="padding:8px 12px"><span class="chip on" style="width:18px;height:18px;padding:0"></span><div><div>lenguaje ofensivo</div><div class="mini gris">insultos o groserías en el chat</div></div></div>
  <div class="caja fina fila" style="padding:8px 12px"><span class="chip" style="width:18px;height:18px;padding:0"></span><div><div>acoso</div><div class="mini gris">te molesta una y otra vez</div></div></div>
  <div class="caja fina fila" style="padding:8px 12px"><span class="chip" style="width:18px;height:18px;padding:0"></span><div><div>nombre inapropiado</div><div class="mini gris">su nickname ofende o se hace pasar por otro</div></div></div>
  <div class="caja fina fila" style="padding:8px 12px"><span class="chip" style="width:18px;height:18px;padding:0"></span><div><div>trampas</div><div class="mini gris">juega con ayuda externa</div></div></div>
  <div class="caja fina fila" style="padding:8px 12px"><span class="chip" style="width:18px;height:18px;padding:0"></span><div><div>juego antideportivo</div><div class="mini gris">abandona o alarga la partida a propósito</div></div></div>
</div>
<div class="lbl">cuéntalo (opcional, máx. 500)</div><div class="campo" style="height:64px">…</div>
<div class="dash" style="margin-top:10px"><div class="peq gris">se adjunta por referencia</div><span class="chip">jugadas de la partida</span><span class="chip">chat de la partida</span></div>
<div class="peq gris" style="margin-top:8px">un reporte falso repetido puede sancionarte a ti</div>
<div class="fila entre" style="position:absolute;left:24px;right:24px;bottom:24px"><span class="btn">cancelar</span><span class="btn prim">enviar reporte</span></div>
''')

# ------------------------------------------------------------------ 10c silenciados y bloqueados
PANTALLAS["10c"] = (1000, 620, '''
<h1>silenciados y bloqueados</h1>
<div><span class="chip on">silenciados 2</span><span class="chip">bloqueados 1</span></div>
<div class="item"><div class="fila"><div class="circ" style="width:36px;height:36px"></div><div><div>ruidoso_99</div><div class="mini gris">silenciado · hace 2 días</div></div></div><span class="btn" style="padding:2px 12px;font-size:14px">quitar</span></div>
<div class="item"><div class="fila"><div class="circ" style="width:36px;height:36px"></div><div><div>spam_bot_4</div><div class="mini gris">silenciado · hace 1 semana</div></div></div><span class="btn" style="padding:2px 12px;font-size:14px">quitar</span></div>
<div class="item"><div class="fila"><div class="circ" style="width:36px;height:36px"></div><div><div>tramposo_x</div><div class="mini gris">bloqueado · no os empareja</div></div></div><span class="btn" style="padding:2px 12px;font-size:14px">quitar</span></div>
<div class="dash" style="margin-top:20px"><div class="peq gris">diferencia</div><div class="peq">silenciado: no lees sus mensajes, podéis coincidir en partida. bloqueado: además no os empareja ni podéis estar en la misma sala.</div></div>
''')

# ------------------------------------------------------------------ 10d chat restringido
PANTALLAS["10d"] = (1000, 620, '''
<div class="caja fila entre" style="padding:10px 14px"><div class="fila"><span class="circ" style="width:30px;height:30px;text-align:center;line-height:24px">!</span>
  <div><div>tu chat está restringido 24 h</div><div class="peq gris">por lenguaje ofensivo en el chat de una partida · queda 18:42</div></div></div><span class="btn">ver motivo</span></div>
<div style="margin-top:12px;border-bottom:2px solid #1b1b1b"><span class="tab on">chat de la partida</span></div>
<div class="peq gris" style="padding:14px 4px;line-height:2">kobo: buena esa<br>kobo: ¿revancha?</div>
<div class="fila" style="position:absolute;left:24px;right:24px;bottom:56px"><div class="campo" style="flex:1;border-style:dashed;border-color:#a8a8a8">no puedes escribir hasta que termine la restricción</div><span class="btn off">➤</span></div>
<div class="peq" style="position:absolute;left:24px;bottom:22px">puedes seguir leyendo y jugando con normalidad</div>
''')

# ------------------------------------------------------------------ 9a recuperar contraseña
PANTALLAS["9a"] = (760, 640, '''
<div class="peq gris">◀ volver a entrar</div>
<h1 style="margin-top:10px">recuperar contraseña</h1>
<div class="gris">te enviamos un código de 6 dígitos al correo de la cuenta. vale 30 minutos.</div>
<div class="lbl">correo</div><div class="campo">tu@correo.com</div>
<div class="btn prim full" style="margin-top:16px;font-size:20px;padding:12px">enviar código</div>
<div class="peq gris" style="margin-top:12px">por seguridad, el mensaje es el mismo exista o no una cuenta con ese correo. puedes pedir otro cada 5 minutos.</div>
''')

# ------------------------------------------------------------------ 9b nueva contraseña
PANTALLAS["9b"] = (760, 720, '''
<h1>código enviado</h1>
<div class="gris">revisa m••••@correo.mx. mira también el spam.</div>
<div class="digitos" style="margin:14px 0"><span>7</span><span>2</span><span>9</span><span>4</span><span>1</span><span>6</span></div>
<div class="fila entre"><span class="peq">vence en 27:10 · 3 intentos</span><span class="btn sec" style="padding:2px 12px;font-size:14px">reenviar en 4:44</span></div>
<div style="border-top:2px dashed #cfcfcf;margin:16px 0"></div>
<h2>nueva contraseña</h2>
<div class="campo lleno">••••••••••••</div>
<div class="fila" style="gap:6px;margin:8px 0"><div style="flex:1;height:8px;background:#1b1b1b;border-radius:4px"></div><div style="flex:1;height:8px;background:#1b1b1b;border-radius:4px"></div><div style="flex:1;height:8px;border:2px solid #1b1b1b;border-radius:4px"></div></div>
<div class="campo lleno">••••••••••••</div>
<div class="peq gris" style="margin-top:8px">al guardarla se cierran todas tus sesiones abiertas</div>
<div class="btn prim full" style="margin-top:14px;font-size:20px;padding:12px">guardar y entrar</div>
''')

# ------------------------------------------------------------------ 9f ajustes de cuenta
MENU_AJ = '''<div style="position:absolute;left:0;top:0;bottom:0;width:210px;border-right:3px solid #1b1b1b;padding:22px 20px">
<h1>ajustes</h1><div class="col gris" style="font-size:17px">{items}</div></div>'''


def menu_aj(sel):
    items = ""
    for x in ["tablero 3D", "audio", "cuenta", "idioma", "accesibilidad"]:
        items += f'<span class="tab on" style="border-radius:8px">{x}</span>' if x == sel else f"<span>{x}</span>"
    return MENU_AJ.format(items=items)


PANTALLAS["9f"] = (1000, 720, menu_aj("cuenta") + '''
<div style="margin-left:220px">
<div class="caja fila entre"><div class="fila"><div class="circ"></div><div><h2 style="margin:0">marta_muros</h2><div class="peq gris">m••••@correo.mx · verificado</div></div></div></div>
<div class="item"><div><div>contraseña</div><div class="mini gris">cambiada hace 3 meses · pide la actual</div></div><span class="btn" style="padding:2px 12px;font-size:14px">cambiar</span></div>
<div class="item"><div><div>correo</div><div class="mini gris">el nuevo se confirma con un enlace; hasta entonces sigue el actual</div></div><span class="btn" style="padding:2px 12px;font-size:14px">cambiar</span></div>
<div class="item"><div><div>segundo factor</div><div class="mini gris">activado · te pediremos un código al entrar</div></div><span class="btn" style="padding:2px 12px;font-size:14px">desactivar</span></div>
<div class="item"><div><div>sesiones activas</div><div class="mini gris">2 dispositivos · laptop y celular</div></div><span class="btn" style="padding:2px 12px;font-size:14px">ver y cerrar</span></div>
<div class="btn full" style="margin-top:24px">cerrar sesión</div>
</div>''')

# ------------------------------------------------------------------ 22d activar segundo factor
PANTALLAS["22d"] = (1000, 720, menu_aj("cuenta") + '''
<div style="margin-left:220px;opacity:.35">
<div class="caja">marta_muros</div><div class="item">contraseña</div><div class="item">correo</div><div class="item">segundo factor</div></div>
<div class="velo" style="left:210px"></div>
<div class="modal" style="left:300px;top:110px;width:600px">
  <h2>activar el segundo factor</h2>
  <div class="gris peq">al entrar desde cualquier dispositivo te pediremos, además de tu contraseña, un código de 6 dígitos que llega a tu correo.</div>
  <div class="lbl">tu contraseña actual</div><div class="campo lleno">••••••••••</div>
  <div class="lbl">escribe el código de prueba que te acabamos de enviar</div>
  <div class="digitos"><span>3</span><span>0</span><span>5</span><span>9</span><span>8</span><span></span></div>
  <div class="fila entre" style="margin-top:18px"><span class="btn">cancelar</span><span class="btn prim">activar</span></div>
</div>''')

# ------------------------------------------------------------------ 12c idioma
PANTALLAS["12c"] = (1000, 720, menu_aj("idioma") + '''
<div style="margin-left:220px">
<div class="peq gris">idioma de la interfaz y de los correos · se guarda en tu cuenta</div>
<div class="item"><div class="fila"><span class="circ" style="width:22px;height:22px;background:#1b1b1b"></span>español (México)</div><span class="peq gris">actual</span></div>
<div class="item"><div class="fila"><span class="circ" style="width:22px;height:22px"></span>english</div><span></span></div>
<div class="peq gris" style="margin-top:14px">el chat no se traduce: cada quien escribe en su idioma</div>
<div class="fila entre" style="position:absolute;left:244px;right:24px;bottom:30px"><div><div>notación del tablero</div><div class="mini gris">e4 · muro f3v</div></div><div><span class="chip on">letras</span><span class="chip">números</span></div></div>
</div>''')

# ------------------------------------------------------------------ 7e errores de cuenta
PANTALLAS["7e"] = (1000, 620, '''
<div class="peq gris">bajo el campo o en el sitio de la acción</div>
<div class="aviso"><i>!</i>ese nickname ya está en uso. prueba con otro.</div>
<div class="aviso"><i>!</i>el nickname admite de 3 a 30 caracteres, sin espacios.</div>
<div class="aviso"><i>!</i>ese nickname no está permitido. elige otro.</div>
<div class="aviso"><i>!</i>nickname o contraseña incorrectos.</div>
<div class="aviso"><i>!</i>demasiados intentos. espera 5 minutos. (la siguiente vez, 30; después, 60)</div>
<div class="aviso"><i>!</i>tu cuenta aún no está activada. revisa tu correo o pide otro enlace.</div>
<div class="aviso"><i>!</i>código incorrecto. te quedan 2 intentos.</div>
<div class="aviso"><i>!</i>el código venció. pide uno nuevo.</div>
<div class="aviso"><i>!</i>la contraseña necesita 8 caracteres y 3 de: minúsculas, mayúsculas, números, signos.</div>
<div class="aviso"><i>!</i>para crear una cuenta necesitas tener al menos 8 años.</div>
''')

# ------------------------------------------------------------------ 7d errores de salas
PANTALLAS["7d"] = (1000, 620, '''
<div class="peq gris">bajo el campo o en el sitio de la acción</div>
<div class="caja" style="margin:8px 0"><div class="peq gris">unirse con código</div><div class="campo lleno" style="letter-spacing:5px">K7MTQ3</div>
<div class="aviso" style="border:0"><i>!</i>esa sala no existe o ya se cerró.</div></div>
<div class="aviso"><i>!</i>la sala está completa. pide al anfitrión que cree otra.</div>
<div class="aviso"><i>!</i>la partida ya empezó. no se puede entrar a mitad.</div>
<div class="aviso"><i>!</i>ese código no es válido: son 6 letras o números, sin 0, O, 1 ni I.</div>
<div class="aviso"><i>!</i>ya estás en una partida. vuelve a ella antes de entrar aquí.</div>
<div class="aviso"><i>!</i>seguimos buscando: ampliamos el rango de elo mientras esperas.</div>
<div class="aviso"><i>!</i>el anfitrión cerró la sala.</div>
''')

# ------------------------------------------------------------------ 22e cola de moderación
PANTALLAS["22e"] = (1000, 720, '''
<div class="fila entre"><h1>moderación</h1><div><span class="chip on">reportes 4</span><span class="chip">apelaciones 1</span></div></div>
<table class="tabla">
<tr><th>motivo</th><th>reportado</th><th>reportes que acumula</th><th>antigüedad</th><th>estado</th><th></th></tr>
<tr><td>lenguaje ofensivo</td><td>rayo_veloz</td><td>3</td><td>hace 2 h</td><td>pendiente</td><td><span class="btn prim" style="padding:2px 12px;font-size:14px">tomar</span></td></tr>
<tr><td>nombre inapropiado</td><td>4dm1n_oficial</td><td>2</td><td>hace 5 h</td><td>pendiente</td><td><span class="btn prim" style="padding:2px 12px;font-size:14px">tomar</span></td></tr>
<tr class="sel"><td>acoso</td><td>kobo</td><td>1</td><td>hace 1 día</td><td>en revisión · tú</td><td><span class="btn" style="padding:2px 12px;font-size:14px">abrir</span></td></tr>
<tr><td>juego antideportivo</td><td>p_veloz</td><td>1</td><td>hace 2 días</td><td>en revisión · ana</td><td class="gris peq">vuelve a la cola en 12 min</td></tr>
</table>
<div class="peq gris" style="margin-top:16px">no ves los reportes en los que eres denunciante o reportado · un reporte tomado vuelve a la cola a los 30 minutos sin resolver</div>
''')

# ------------------------------------------------------------------ 22f revisar reporte
PANTALLAS["22f"] = (1000, 720, '''
<div class="fila entre"><h1>reporte · lenguaje ofensivo</h1><span class="chip">en revisión · tú</span></div>
<div class="fila" style="align-items:stretch;gap:16px">
  <div class="col" style="flex:1.2">
    <div class="caja fina"><div class="peq gris">denunciante: luis_quo · reportado: <b>rayo_veloz</b> · partida del 26 ago</div>
      <div class="peq" style="margin-top:6px">"me insultó dos veces en el chat"</div></div>
    <div class="caja fina" style="background:#efeeea"><div class="peq gris">chat de la partida · resaltado el reportado</div>
      <div class="peq">luis_quo: suerte</div><div class="peq" style="background:#d8d7d2">rayo_veloz: ███████ ███</div><div class="peq" style="background:#d8d7d2">rayo_veloz: ██████</div></div>
    <div class="caja fina peq"><span class="gris">jugadas:</span> 17 · <u>ver la partida jugada a jugada</u></div>
  </div>
  <div class="col" style="flex:1">
    <div class="caja fina"><div class="peq gris">sanciones previas de rayo_veloz</div><div class="peq">chat · temporal 24 h · 12 ago</div></div>
    <div class="lbl">nota de resolución (obligatoria)</div><div class="campo" style="height:90px">…</div>
    <div class="btn">resolver sin sanción</div>
    <div class="btn prim">sancionar…</div>
    <div class="btn sec">liberar reporte</div>
  </div>
</div>''')

# ------------------------------------------------------------------ 22g aplicar sanción
PANTALLAS["22g"] = (1000, 720, '''
<h1>sancionar a rayo_veloz</h1>
<div class="peq gris">origen: reporte por lenguaje ofensivo · 1 sanción previa (chat, 24 h)</div>
<div class="fila" style="gap:18px;margin-top:10px;align-items:stretch">
  <div class="caja" style="flex:1"><div class="lbl" style="margin-top:0">ámbito</div><span class="chip on">chat</span><span class="chip">cuenta</span>
    <div class="peq gris" style="margin-top:6px">chat: no puede escribir, sí jugar. cuenta: no puede entrar; se cierran sus sesiones.</div></div>
  <div class="caja" style="flex:1"><div class="lbl" style="margin-top:0">tipo</div><span class="chip on">temporal</span><span class="chip">permanente</span>
    <div class="lbl">duración</div><span class="chip">24 h</span><span class="chip on">7 días</span><span class="chip">30 días</span></div>
</div>
<div class="lbl">motivo (lo verá el jugador)</div><div class="campo lleno" style="height:80px">insultos repetidos en el chat de la partida del 26 de agosto</div>
<div class="modal" style="left:170px;bottom:24px;width:660px;padding:14px 20px">
  <div>vas a restringir el chat de rayo_veloz durante 7 días.</div>
  <div class="fila entre" style="margin-top:10px"><span class="btn">cancelar</span><span class="btn prim">aplicar</span></div></div>
''')

# ------------------------------------------------------------------ 22h agregar moderador
PANTALLAS["22h"] = (1000, 620, '''
<div class="fila entre"><h1>administración · moderadores</h1><span class="chip on">agregar</span></div>
<div class="lbl">buscar jugador por nickname</div><div class="campo lleno">sofia_salto</div>
<div class="caja fila entre" style="margin-top:10px"><div class="fila"><div class="circ"></div><div><div>sofia_salto</div><div class="peq gris">cuenta registrada, activa · sin sanciones activas</div></div></div><span class="btn prim">dar rol de moderador</span></div>
<div class="lbl">motivo (obligatorio, queda en la bitácora)</div><div class="campo" style="height:60px">…</div>
<table class="tabla" style="margin-top:14px"><tr><th>moderadores actuales</th><th>desde</th><th>reportes en revisión</th><th></th></tr>
<tr><td>ana_modera</td><td>2 jun 2026</td><td>1</td><td><span class="btn sec" style="padding:2px 12px;font-size:14px">retirar rol</span></td></tr></table>
<div class="peq gris" style="margin-top:10px">solo cuentas registradas, activas y sin sanciones activas pueden ser moderadoras</div>
''')

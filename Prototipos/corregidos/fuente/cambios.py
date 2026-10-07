# -*- coding: utf-8 -*-
"""Qué cambió en cada prototipo corregido y por qué. De aquí salen
Prototipos/corregidos/CAMBIOS.md y los .tex que incluye prototipos-corregidos.tex.

Uso: python Prototipos/corregidos/fuente/cambios.py
"""
from pathlib import Path

AQUI = Path(__file__).resolve().parent

# id, pantalla, casos, [(cambio, motivo)]
CAMBIOS = [
    ("3b", "Menú principal", "CU-01, CU-17, CU-18, CU-19", [
        ("Se quitan tienda, personalizar, ranking, historial, amigos, el chat global, las monedas y la racha.", "Son agregados de fase posterior (CU-12 a CU-16, CU-29 a CU-41)."),
        ("Quedan buscar partida, crear sala privada y unirse con código, más ajustes.", "Son los casos Must de partida en línea."),
        ("Se añade \"cómo jugar\" y un acceso a moderación visible solo para ese rol.", "El tutorial es fase posterior; las reglas en texto bastan. La moderación (CU-43) no tenía entrada."),
    ]),
    ("6c", "Inicio de sesión", "CU-01, CU-02, CU-03", [
        ("Se añaden los campos de nickname o correo y contraseña, y el enlace para recuperar la contraseña.", "Diferencia registrada: la pantalla no tenía campos (CU-01)."),
        ("Se quita \"jugar como invitado\".", "CU-06 es fase posterior y esquivaría el segundo factor."),
        ("Se añade el selector de idioma y el aviso del segundo factor.", "CU-05 RN-03 y CON-08."),
    ]),
    ("22a", "Registro (nueva)", "CU-02", [
        ("Pantalla nueva: nickname de 3 a 30, correo, contraseña con su regla, fecha de nacimiento (mínimo 8 años), idioma y términos.", "El formulario de registro no estaba prototipado (diferencia registrada); campos de CU-02 RN-01 a RN-05 y D-06."),
    ]),
    ("22b", "Código de segundo factor (nueva)", "CU-01", [
        ("Pantalla nueva: código de 6 dígitos, tiempo restante, intentos, reenviar y cancelar.", "GUI_SecondFactor de CU-01 (RN-09: 5 minutos, 3 intentos). Es la restricción CON-08 del profesor y no tenía prototipo."),
    ]),
    ("22c", "Cuenta pendiente de verificar (nueva)", "CU-01, CU-04", [
        ("Pantalla nueva: aviso de correo enviado, reenviar con espera y entrar.", "GUI_PendingVerification de CU-01; sin verificar no se entra (Matriz 2)."),
    ]),
    ("22d", "Activar el segundo factor (nueva)", "CU-09", [
        ("Diálogo nuevo: contraseña actual y código de prueba para activar el segundo factor.", "CU-09 FA-10; el segundo factor lo exige el profesor y no había dónde activarlo."),
    ]),
    ("1f", "Buscando rival", "CU-17", [
        ("Se quita el botón \"ampliar rango\"; se explica que la ventana de elo se amplía sola.", "CU-17 RN-03: la ampliación es automática."),
        ("Se muestra el reloj elegido.", "El modo y el reloj definen la cola."),
    ]),
    ("1h", "Partida privada: crear o unirse", "CU-18, CU-19", [
        ("El código pasa a seis caracteres sin 0, O, 1 ni I (K7MTQ3).", "CU-18 RN-01; el prototipo usaba K4M-92."),
        ("El código aparece al crear la sala; muros de 1 a 20 y aviso de que no da elo.", "CU-18 RN-04 y D-16."),
    ]),
    ("5d", "Sala de espera, 2 jugadores", "CU-18, CU-19", [
        ("Se quita \"invitar amigo\".", "CU-32 es fase posterior."),
        ("Código de seis caracteres; \"salir\" avisa que cierra la sala; \"empezar\" inactivo mientras falten listos.", "CU-18 RN-01, RN-07 y CU-19 RN-03."),
    ]),
    ("5e", "Sala de espera, 4 plazas", "CU-18, CU-19, CU-28", [
        ("Se quitan \"eligiendo peón\" y \"abrir a público\".", "Los cosméticos son fase posterior y ningún caso abre una sala al público."),
        ("El chat de la sala avisa que se filtra y se puede reportar.", "Moderación de chat (CON-09, CU-28)."),
    ]),
    ("19d", "Menú de partida", "CU-22, CU-23", [
        ("Se quita \"emotes\".", "CU-29 es fase posterior."),
        ("\"Ofrecer tablas\" dice una vez cada cinco jugadas propias y solo en partidas de dos; se quita \"desde la jugada 10\".", "Diferencia registrada; CU-22 RN-03 y D-14."),
    ]),
    ("2g", "Fin de partida", "CU-25", [
        ("Se quitan las monedas, la racha, \"ver repetición\" y \"revancha\".", "Monedas, rachas y repeticiones son fase posterior; la revancha no está en ningún caso."),
        ("Quedan el resultado, la forma de término, el cambio de elo, \"buscar otra\", \"volver al menú\" y \"reportar\".", "CU-25 pasos 17 a 20 del núcleo y CU-42."),
    ]),
    ("6f", "Rival desconectado", "CU-24, CU-26", [
        ("\"Reclamar victoria\" queda inactivo con la cuenta atrás hasta los sesenta segundos.", "D-15 y CU-24 RN-06: el rival puede reclamarla solo a los 60 s."),
    ]),
    ("20c", "Chat en partida", "CU-28, CU-33, CU-42", [
        ("Se quitan las pestañas global y amigos, y el aviso de espectador.", "Canales y espectador de fase posterior."),
        ("Se añade el aviso de mensaje filtrado y el acceso a silenciar, bloquear y reportar.", "CU-28 RN-02, CU-33 y CU-42."),
    ]),
    ("10a", "Menú de un jugador", "CU-33, CU-42", [
        ("Se quitan ver perfil, retar, añadir amigo y ver su partida.", "Perfil, amigos y espectador son fase posterior."),
        ("Quedan silenciar, bloquear y reportar.", "Moderación del núcleo. \"Eliminar amigo\" (CU-49) se añadirá con los amigos."),
    ]),
    ("10b", "Reportar", "CU-42", [
        ("Los motivos pasan a los cinco del dominio: lenguaje ofensivo, acoso, nombre inapropiado, trampas y juego antideportivo.", "CU-42 RN-08 y D-23; el prototipo tenía \"abandono repetido\" y \"otro\" y no tenía acoso."),
        ("Se adjuntan las jugadas y el chat de la partida por referencia; se quita la repetición y los enlaces del perfil.", "CU-42 RN-01; repeticiones y enlaces son fase posterior."),
    ]),
    ("10c", "Silenciados y bloqueados", "CU-33", [
        ("La explicación dice que el bloqueo impide compartir sala en lugar de invitar.", "Las invitaciones son fase posterior (CU-32)."),
    ]),
    ("10d", "Chat restringido", "CU-28, CU-44", [
        ("La restricción se muestra sobre el chat de la partida; se quitan las pestañas global y amigos y la mención a los emotes.", "Canales y emotes de fase posterior."),
    ]),
    ("9a", "Recuperar contraseña: pedir el código", "CU-03", [
        ("Se envía un código de 6 dígitos, no un enlace; se añade el aviso de que la respuesta es la misma exista o no la cuenta y el límite de 5 minutos.", "CU-03 RN-01, RN-04 y RN-06."),
        ("Se quita el recuadro del invitado.", "CU-06 es fase posterior."),
    ]),
    ("9b", "Recuperar contraseña: código y nueva contraseña", "CU-03", [
        ("Se añade el campo del código con su vigencia y sus 3 intentos, y la confirmación de la contraseña.", "CU-03 RN-04 y RN-09."),
    ]),
    ("9f", "Ajustes de cuenta", "CU-05, CU-09, CU-10", [
        ("Se añade el segundo factor con su estado.", "CU-09 FA-10 y CON-08."),
        ("Se quitan código de amigo, descargar mis datos y borrar cuenta.", "Amigos y baja son fase posterior; descargar datos se retiró del alcance (diferencia registrada)."),
    ]),
    ("12c", "Ajustes: idioma", "CU-12 (solo idioma)", [
        ("Solo quedan español (México) e inglés.", "D-21: los idiomas admitidos son es-MX y en; el prototipo ofrecía portugués, francés, alemán y catalán."),
    ]),
    ("7e", "Errores de cuenta", "CU-01, CU-02", [
        ("El nickname admite de 3 a 30 caracteres; el bloqueo es de 5, 30 y 60 minutos.", "Diferencia registrada; CU-01 RN-03 y CU-02 RN-01."),
        ("Se quitan los errores de monedas, skins y amigos; se añaden los de cuenta sin activar, código incorrecto o vencido y edad mínima.", "Agregados fuera; errores de CU-01, CU-02 y CU-04."),
    ]),
    ("7d", "Errores de salas y emparejamiento", "CU-17, CU-19", [
        ("El código de ejemplo y el mensaje de formato pasan a seis caracteres sin 0, O, 1 ni I.", "Diferencia registrada; CU-18 RN-01."),
        ("\"Prueba a ampliar el rango\" pasa a \"ampliamos el rango mientras esperas\".", "CU-17 RN-03."),
    ]),
    ("22e", "Cola de moderación (nueva)", "CU-43", [
        ("Pantalla nueva: reportes y apelaciones pendientes, con motivo, reportado, reportes que acumula, antigüedad y estado.", "GUI_ModerationQueue; la moderación es obligatoria y no tenía prototipo."),
    ]),
    ("22f", "Revisar un reporte (nueva)", "CU-43", [
        ("Pantalla nueva: descripción, chat con el reportado resaltado, jugadas, sanciones previas, nota obligatoria y las tres salidas.", "GUI_ReportReview de CU-43 (RN-07: nota obligatoria)."),
    ]),
    ("22g", "Aplicar una sanción (nueva)", "CU-44", [
        ("Pantalla nueva: ámbito, tipo, duración, motivo y confirmación en una frase.", "GUI_ApplySanction de CU-44 (RN-03, RN-06 y RN-08) y D-05."),
    ]),
    ("22h", "Agregar un moderador (nueva)", "CU-46, CU-47", [
        ("Pantalla nueva: buscar la cuenta, requisitos, motivo obligatorio y la lista de moderadores con \"retirar rol\".", "GUI_AdminPanel de CU-46 (RN-02, RN-05) y CU-47."),
    ]),
]

SIN_CORREGIR = [
    ("6d", "Primera vez: nombre, peón e icono", "CU-08 es fase posterior. Al retomarla, quitar el campo del nombre (D-13)."),
    ("9e", "Invitado: vincular cuenta", "CU-07 es fase posterior. Al retomarla, pedir también nickname definitivo y fecha de nacimiento."),
    ("2c, 16c", "Ranking y evolución del elo", "CU-35 y CU-15 son fase posterior. Al retomarlas, quitar las temporadas."),
    ("18f", "Errores de modos, IA y búsqueda", "La IA y los perfiles son fase posterior. Al retomarla, quitar el límite de cinco sugerencias y los perfiles privados."),
    ("16a, 1g, 20a, 21a, 6e, 8e, 10e", "Elegir modo, VS, partida, muro, reconexión, cuatro jugadores y aviso de sanción", "Ya coinciden con los casos del núcleo: se usan tal como están."),
]


def tex(s):
    return (s.replace("\\", "\\textbackslash{}").replace("_", "\\_").replace("%", "\\%").replace("&", "\\&")
            .replace('"', "``", 1).replace('"', "''", 1).replace('"', "``", 1).replace('"', "''", 1)
            .replace('"', "``", 1).replace('"', "''", 1))


def main():
    md = ["# Prototipos corregidos", "",
          "Versiones corregidas de las pantallas del núcleo, en el mismo estilo de boceto. Los originales en `Prototipos/` no se tocaron.",
          "Se regeneran con `python Prototipos/corregidos/fuente/generar.py` (necesita Playwright) y esta lista con `python Prototipos/corregidos/fuente/cambios.py`.",
          "Las pantallas `22a` a `22h` son nuevas: cubren casos obligatorios que no tenían prototipo.", ""]
    for pid, nombre, casos, cambios in CAMBIOS:
        md += [f"## {pid} · {nombre}", f"Casos: {casos}", ""]
        md += [f"- **{c}** Motivo: {m}" for c, m in cambios]
        md.append("")
    md += ["## Sin corregir", ""]
    md += [f"- **{p} · {n}.** {m}" for p, n, m in SIN_CORREGIR]
    (AQUI.parent / "CAMBIOS.md").write_text("\n".join(md) + "\n", encoding="utf-8")

    o = ["% Archivo generado por Prototipos/corregidos/fuente/cambios.py. No editar a mano.",
         r"\begin{center}\small",
         r"\begin{longtable}{|L{0.1\textwidth}|L{0.13\textwidth}|L{0.335\textwidth}|L{0.32\textwidth}|}",
         r"\hline", r"\textbf{Pantalla} & \textbf{Casos} & \textbf{Qué cambió} & \textbf{Por qué} \\ \hline", r"\endfirsthead",
         r"\hline", r"\textbf{Pantalla} & \textbf{Casos} & \textbf{Qué cambió} & \textbf{Por qué} \\ \hline", r"\endhead"]
    import re
    def mb(s):
        return re.sub(r"\b((?:CU|RN|FA|D|CON)-\d{2})\b", r"\\mbox{\1}", s)
    for pid, nombre, casos, cambios in CAMBIOS:
        for k, (c, m) in enumerate(cambios):
            izq = f"\\textbf{{{pid}}} {tex(nombre)}" if k == 0 else ""
            cas = mb(tex(casos)) if k == 0 else ""
            o.append(f"{izq} & {cas} & {mb(tex(c))} & {mb(tex(m))} \\\\ " + (r"\hline" if k == len(cambios) - 1 else r"\cline{3-4}"))
    o += [r"\end{longtable}", r"\end{center}"]
    s = [r"\begin{center}\small", r"\begin{longtable}{|L{0.16\textwidth}|L{0.25\textwidth}|L{0.49\textwidth}|}", r"\hline",
         r"\textbf{Pantalla} & \textbf{Qué muestra} & \textbf{Por qué no se corrigió} \\ \hline", r"\endfirsthead", r"\hline",
         r"\textbf{Pantalla} & \textbf{Qué muestra} & \textbf{Por qué no se corrigió} \\ \hline", r"\endhead"]
    s += [f"{p} & {tex(n)} & {mb(tex(m))} \\\\ \\hline" for p, n, m in SIN_CORREGIR]
    s += [r"\end{longtable}", r"\end{center}"]
    fig = []
    for i, (pid, nombre, _, _) in enumerate(CAMBIOS):
        lado = r"\hfill" if i % 2 == 0 else ""
        if i % 2 == 0:
            fig.append(r"\par\medskip\noindent")
        fig.append(r"\begin{minipage}[t]{0.48\textwidth}" + "\n" + rf"\includegraphics[width=\linewidth]{{Prototipos/corregidos/{pid}}}\par\smallskip"
                   + "\n" + rf"{{\footnotesize\RaggedRight \textbf{{{pid} corregido: {tex(nombre)}}}\par}}" + "\n" + r"\end{minipage}" + lado)
        if i % 2 == 1:
            fig.append(r"\par")
    dest = AQUI.parent
    (dest / "tabla-cambios.tex").write_text("\n".join(o) + "\n", encoding="utf-8")
    (dest / "sin-corregir.tex").write_text("% Archivo generado por cambios.py. No editar a mano.\n" + "\n".join(s) + "\n", encoding="utf-8")
    (dest / "figuras.tex").write_text("% Archivo generado por cambios.py. No editar a mano.\n" + "\n".join(fig) + "\n", encoding="utf-8")

if __name__ == "__main__":
    main()

# -*- coding: utf-8 -*-
"""Relaciones entre jugadores, salas, chat, tutorial, moderación y bitácoras."""

AMISTADES = [(3, 4, "2026-06-20 18:00:00"), (3, 5, "2026-06-25 17:00:00"),   # (menor, mayor, fecha)
             (2, 5, "2026-07-01 12:00:00"), (4, 6, "2026-07-03 19:00:00")]
SOLICITUDES = {1: (6, 5, "2026-08-29 20:00:00")}          # id: solicitante, destinatario, fecha
SILENCIOS = [(4, 9, "2026-08-25 21:05:00")]               # quien silencia, silenciado, fecha
BLOQUEOS = [(3, 9, "2026-08-26 17:25:00")]                # bloqueador, bloqueado, fecha

# usuario, lección, paso_actual, fecha_actualizacion, fecha_completada (CU-41).
TUTORIAL = [
    (5, 1, 3, "2026-06-15 12:20:00", "2026-06-15 12:20:00"),
    (5, 2, 4, "2026-06-15 12:35:00", "2026-06-15 12:35:00"),
    (5, 3, 2, "2026-06-16 18:00:00", None),
    (6, 1, 3, "2026-06-18 20:10:00", "2026-06-18 20:10:00"),
    (6, 2, 4, "2026-06-18 20:20:00", "2026-06-18 20:20:00"),
    (6, 3, 4, "2026-06-19 17:00:00", "2026-06-19 17:00:00"),
    (6, 4, 5, "2026-06-19 17:15:00", "2026-06-19 17:15:00"),
    (7, 1, 3, "2026-08-30 16:10:00", "2026-08-30 16:10:00"),
]

# Plazas de la sala abierta: usuario, sala, plaza, listo, fecha_union (el anfitrión nace listo).
SALA_PARTICIPANTES = [(5, 2, 1, 1, "2026-09-01 17:50:00"), (7, 2, 2, 0, "2026-09-01 17:52:00")]

# id: sala, emisor, destinatario, fecha, estado (vigencia de 60 s, CU-32 RN-04).
INVITACIONES = {
    1: (1, 6, 4, "2026-08-31 16:21:00", "EXPIRADA"),
    2: (1, 6, 4, "2026-08-31 16:23:00", "RECHAZADA"),
    4: (1, 6, 7, "2026-08-31 16:24:00", "ACEPTADA"),     # el invitado entra sin el código (CU-32 RN-05)
    3: (2, 5, 2, "2026-09-01 17:59:40", "PENDIENTE"),
}

COLA = [(4, 3, 3, "2026-09-01 17:55:00")]                  # usuario, modo, minutos_reloj, fecha_entrada

# autor, canal, id_partida, id_sala, texto, fecha_envio (CU-28).
MENSAJES = [
    (9, "GLOBAL", None, None, "Nadie aquí sabe jugar", "2026-08-25 21:00:00"),
    (9, "PARTIDA", 9, None, "Juegas horrible, mejor ni lo intentes", "2026-08-26 17:11:05"),
    (3, "PARTIDA", 9, None, "Tranquilo, es solo un juego", "2026-08-26 17:11:20"),
    (6, "SALA", None, 1, "Welcome! We can start whenever you want", "2026-08-31 16:25:00"),
    (3, "AMIGOS", None, None, "¿Jugamos más tarde?", "2026-09-01 17:15:00"),
    (6, "PARTIDA", 12, None, "¡Suerte!", "2026-09-01 17:30:05"),
    (3, "PARTIDA", 12, None, "Igualmente, compañera 👍", "2026-09-01 17:30:12"),
    (2, "ESPECTADORES", 12, None, "Buen muro de sofía", "2026-09-01 17:31:00"),
    (5, "SALA", None, 2, "¿Listos?", "2026-09-01 17:53:00"),
    (7, "SALA", None, 2, "Ya casi", "2026-09-01 17:53:30"),
    (4, "GLOBAL", None, None, "¿Alguien para una rápida?", "2026-09-01 17:56:00"),
]

ENLACES_ESPECTADOR = {1: (12, 3, "2026-09-01 17:40:00")}   # id: partida, creador, fecha

# id: denunciante, reportado, motivo, descripción, partida, fecha, estado, moderador,
#     fecha_asignacion, nota_resolucion, fecha_resolucion (CU-42, CU-43).
REPORTES = {
    1: (3, 9, 1, "Me insultó en el chat de la partida.", 9, "2026-08-26 17:20:00", "RESUELTO_CON_SANCION", 2,
        "2026-08-27 09:50:00", "Insultos comprobados en el chat de la partida.", "2026-08-27 10:00:00"),
    2: (4, 9, 2, "Molesta a todos en el chat global.", None, "2026-08-25 21:06:00", "PENDIENTE", None,
        None, None, None),
    3: (6, 3, 5, "Creo que esperó a que abandonáramos.", 7, "2026-08-15 19:30:00", "EN_REVISION", 2,
        "2026-09-01 17:40:00", None, None),
    4: (3, 11, 3, "Su nickname imita al del administrador.", None, "2026-08-22 20:30:00", "RESUELTO_CON_SANCION", 2,
        "2026-08-23 09:55:00", "El nickname suplanta al equipo del juego.", "2026-08-23 10:00:00"),
    5: (4, 3, 4, "Me saltó y llegó a la meta muy rápido; creo que usa un programa.", 5, "2026-07-26 17:40:00",
        "RESUELTO_SIN_SANCION", 2, "2026-07-27 09:00:00",
        "La repetición muestra jugadas legales; el salto es válido (CU-20 RN-03).", "2026-07-27 09:20:00"),
}

# id: sancionado, moderador, reporte, ámbito, tipo, motivo, inicio, fin, retiro, sustituta (CU-44).
SANCIONES = {
    1: (9, 2, 1, "CUENTA", "TEMPORAL", "Insultos en el chat de una partida.",
        "2026-08-27 10:00:00", "2026-08-28 10:00:00", "2026-08-27 16:00:00", 2),
    2: (9, 2, 1, "CUENTA", "TEMPORAL", "Insultos reiterados; se amplía la suspensión.",
        "2026-08-27 16:00:00", "2026-09-03 16:00:00", None, None),
    3: (5, 2, None, "CHAT", "TEMPORAL", "Mensajes repetidos para molestar.",
        "2026-07-10 12:00:00", "2026-07-11 12:00:00", None, None),          # vencida sin retiro
    4: (6, 2, None, "CHAT", "PERMANENTE", "Lenguaje ofensivo en el chat global.",
        "2026-08-05 18:00:00", None, "2026-08-06 12:00:00", None),          # retirada por apelación
    5: (11, 2, 4, "CUENTA", "PERMANENTE", "Suplanta al equipo del juego con su nickname.",
        "2026-08-23 10:00:00", None, None, None),                           # la cuenta queda BANEADA
}

# id: sanción, texto, marca_lenguaje, fecha, estado, moderador, asignación, nota, resolución (CU-45).
APELACIONES = {
    1: (4, "Fue un malentendido con una palabra en inglés.", 0, "2026-08-05 20:00:00", "ACEPTADA", 1,
        "2026-08-06 11:30:00", "La palabra no era un insulto en su contexto.", "2026-08-06 12:00:00"),
    2: (2, "No fue para tanto, solo le dije que jugaba tonto.", 1, "2026-08-29 10:00:00", "PENDIENTE", None,
        None, None, None),
    3: (3, "Solo repetí el mensaje porque nadie me contestaba.", 0, "2026-07-10 13:00:00", "RECHAZADA", 1,
        "2026-07-10 15:00:00", "Los mensajes repetidos para molestar constan en el chat.", "2026-07-10 15:10:00"),
}

# moderador, acción, afectado, detalle, fecha (CU-48 RN-04).
BITACORA_MODERACION = [
    (1, "ROL_OTORGADO", 2, "Rol MODERADOR otorgado.", "2026-06-05 10:00:00"),
    (2, "SANCION_APLICADA", 5, "Sanción 3: chat, temporal.", "2026-07-10 12:00:00"),
    (1, "APELACION_RESUELTA", 5, "Apelación 3 rechazada; se mantiene la sanción 3.", "2026-07-10 15:10:00"),
    (2, "REPORTE_TOMADO", 3, "Reporte 5.", "2026-07-27 09:00:00"),
    (2, "REPORTE_RESUELTO", 3, "Reporte 5 resuelto sin sanción.", "2026-07-27 09:20:00"),
    (2, "SANCION_APLICADA", 6, "Sanción 4: chat, permanente.", "2026-08-05 18:00:00"),
    (1, "APELACION_RESUELTA", 6, "Apelación 1 aceptada; sanción 4 retirada.", "2026-08-06 12:00:00"),
    (2, "REPORTE_TOMADO", 11, "Reporte 4.", "2026-08-23 09:55:00"),
    (2, "SANCION_APLICADA", 11, "Sanción 5: cuenta, permanente.", "2026-08-23 10:00:00"),
    (2, "REPORTE_RESUELTO", 11, "Reporte 4 resuelto con sanción.", "2026-08-23 10:00:00"),
    (2, "REPORTE_TOMADO", 9, "Reporte 2.", "2026-08-26 10:00:00"),
    (2, "REPORTE_LIBERADO", 9, "Reporte 2: vuelve a la cola a los treinta minutos (CU-43 RN-03).", "2026-08-26 10:30:00"),
    (2, "REPORTE_TOMADO", 9, "Reporte 1.", "2026-08-27 09:50:00"),
    (2, "SANCION_APLICADA", 9, "Sanción 1: cuenta, temporal.", "2026-08-27 10:00:00"),
    (2, "REPORTE_RESUELTO", 9, "Reporte 1 resuelto con sanción.", "2026-08-27 10:00:00"),
    (2, "SANCION_APLICADA", 9, "Sanción 2: sustituye a la 1.", "2026-08-27 16:00:00"),
    (4, "INTENTO_SIN_PERMISO", None, "Intentó abrir la cola de reportes.", "2026-08-30 18:00:00"),
    (1, "CONSULTA_BITACORA", None, "Bitácora de acceso, últimos siete días.", "2026-08-31 09:00:00"),
    (2, "REPORTE_TOMADO", 3, "Reporte 3.", "2026-09-01 17:40:00"),
]

# Registros de acceso que no se deducen de otras filas: usuario, identificador tecleado,
# resultado, ip, fecha. Las altas, verificaciones e inicios de sesión los añade el generador.
BITACORA_ACCESO = [
    (None, "admin", "REGISTRO_RECHAZADO", "201.141.5.61", "2026-08-29 12:00:00"),   # nickname prohibido
    (9, "rayo_veloz", "CUENTA_SANCIONADA", "201.141.90.33", "2026-08-30 19:00:00"),
    (11, "4dm1n_oficial", "CUENTA_SANCIONADA", "201.141.33.8", "2026-08-24 18:00:00"),
    (1, "admin_bastion", "CONTRASENA_INCORRECTA", "189.203.14.20", "2026-09-01 09:00:00"),
    (1, "admin_bastion", "CONTRASENA_INCORRECTA", "189.203.14.20", "2026-09-01 09:01:00"),
    (1, "admin_bastion", "CONTRASENA_INCORRECTA", "189.203.14.20", "2026-09-01 09:02:10"),
    (1, "admin_bastion", "BLOQUEO_VIGENTE", "189.203.14.20", "2026-09-01 09:04:00"),
    (8, "nico_nuevo", "CUENTA_PENDIENTE", "201.141.5.60", "2026-09-01 11:55:00"),
    (None, "luis_qou", "USUARIO_INEXISTENTE", "189.203.55.9", "2026-09-01 17:04:30"),
    (4, "marta_muros", "SEGUNDO_FACTOR_ACTIVADO", "187.190.3.41", "2026-08-01 19:06:00"),
    (4, "marta_muros", "SEGUNDO_FACTOR_FALLIDO", "187.190.3.41", "2026-08-15 20:03:00"),
    (2, None, "CAMBIO_CONTRASENA", "201.141.22.7", "2026-07-15 12:00:00"),
    (6, None, "RECUPERACION_SOLICITADA", "187.190.66.5", "2026-08-20 10:55:00"),
    (None, "pepe@correo.mx", "RECUPERACION_CORREO_INEXISTENTE", "201.141.8.14", "2026-08-29 13:00:00"),
    (6, None, "RECUPERACION_EXITOSA", "187.190.66.5", "2026-08-20 11:05:00"),
    (3, None, "CAMBIO_CORREO_SOLICITADO", "189.203.55.9", "2026-09-01 17:20:00"),
    (1, None, "RECUPERACION_SOLICITADA", "189.203.14.20", "2026-09-01 17:40:00"),
    (1, None, "RECUPERACION_SOLICITADA", "189.203.14.20", "2026-09-01 17:46:00"),
    (1, None, "CIERRE_VOLUNTARIO", "189.203.14.20", "2026-08-31 12:00:00"),
    (4, None, "CIERRE_VOLUNTARIO", "187.190.3.41", "2026-08-01 20:30:00"),
    (3, None, "CIERRE_REMOTO", "189.203.55.9", "2026-09-01 17:10:00"),
    (10, None, "CUENTA_ELIMINADA", "189.203.77.8", "2026-08-02 13:00:00"),
]

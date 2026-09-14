# -*- coding: utf-8 -*-
"""Cuentas de prueba y todo lo que depende directamente de ellas.

Once usuarios cubren todos los tipos, estados y roles del modelo: un
administrador, una moderadora, cinco jugadores activos, un invitado, una
cuenta pendiente de verificar, una suspendida, una baneada y una dada de baja. Las fechas son UTC y ninguna es
posterior a AHORA, el instante en que se toma la fotografía de la base.
"""

AHORA = "2026-09-01 18:00:00"

# id: nickname, tipo_cuenta, estado_cuenta, rol, correo, contraseña de prueba,
#     fecha_nacimiento, idioma, codigo_amigo, id_icono, permite_espectadores,
#     nivel, experiencia, intentos_fallidos, fecha_ultimo_intento_fallido,
#     bloqueada_hasta, doble_factor, fecha_registro, fecha_configuracion_inicial,
#     fecha_ultimo_envio_verificacion, fecha_ultimo_envio_recuperacion, fecha_baja
USUARIOS = {
    1: dict(nickname="admin_bastion", tipo="REGISTRADA", estado="ACTIVA", rol="ADMINISTRADOR",
            correo="admin@bastion.mx", clave="Admin#2026", nacimiento="1990-05-12", idioma="es-MX",
            codigo="ADM7KQ2P", icono=1, espectadores=1, nivel=1, experiencia=0,
            intentos=3, ultimo_intento="2026-09-01 09:02:10", bloqueada="2026-09-01 09:07:10", doble_factor=0,
            registro="2026-06-01 10:00:00", configuracion="2026-06-01 10:05:00",
            envio_verificacion="2026-06-01 10:00:00", envio_recuperacion="2026-09-01 17:46:00", baja=None),
    2: dict(nickname="ana_modera", tipo="REGISTRADA", estado="ACTIVA", rol="MODERADOR",
            correo="ana.moderadora@correo.mx", clave="Ana#Modera26", nacimiento="1995-02-20", idioma="es-MX",
            codigo="ANA4M9QX", icono=7, espectadores=1, nivel=1, experiencia=150,
            intentos=0, ultimo_intento=None, bloqueada=None, doble_factor=0,
            registro="2026-06-02 09:00:00", configuracion="2026-06-02 09:04:00",
            envio_verificacion="2026-06-02 09:00:00", envio_recuperacion=None, baja=None),
    3: dict(nickname="luis_quo", tipo="REGISTRADA", estado="ACTIVA", rol="JUGADOR",
            correo="luis.quo@correo.mx", clave="Luis#Quo2026", nacimiento="2008-03-15", idioma="es-MX",
            codigo="LQ8R2T6W", icono=12, espectadores=1, nivel=4, experiencia=1650,
            intentos=0, ultimo_intento=None, bloqueada=None, doble_factor=0,
            registro="2026-06-10 16:00:00", configuracion="2026-06-10 16:06:00",
            envio_verificacion="2026-09-01 17:20:00", envio_recuperacion=None, baja=None),
    4: dict(nickname="marta_muros", tipo="REGISTRADA", estado="ACTIVA", rol="JUGADOR",
            correo="marta@correo.mx", clave="Marta#Muros9", nacimiento="2009-07-01", idioma="es-MX",
            codigo="MM3P7Z4K", icono=5, espectadores=1, nivel=3, experiencia=900,
            intentos=0, ultimo_intento=None, bloqueada=None, doble_factor=1,
            registro="2026-06-12 18:30:00", configuracion="2026-06-12 18:35:00",
            envio_verificacion="2026-06-12 18:30:00", envio_recuperacion=None, baja=None),
    5: dict(nickname="pedro_peon", tipo="REGISTRADA", estado="ACTIVA", rol="JUGADOR",
            correo="pedro@correo.mx", clave="Pedro#Peon13", nacimiento="2012-11-30", idioma="es-MX",
            codigo="PP6N2C8V", icono=3, espectadores=0, nivel=2, experiencia=420,
            intentos=0, ultimo_intento=None, bloqueada=None, doble_factor=0,
            registro="2026-06-15 12:00:00", configuracion="2026-06-15 12:10:00",
            envio_verificacion="2026-06-15 12:00:00", envio_recuperacion=None, baja=None),
    6: dict(nickname="sofia_salto", tipo="REGISTRADA", estado="ACTIVA", rol="JUGADOR",
            correo="sofia@correo.mx", clave="Sofia#Salto8", nacimiento="2011-04-18", idioma="en",
            codigo="SS9H3J5D", icono=20, espectadores=1, nivel=2, experiencia=380,
            intentos=0, ultimo_intento=None, bloqueada=None, doble_factor=0,
            registro="2026-06-18 20:00:00", configuracion="2026-06-18 20:03:00",
            envio_verificacion="2026-06-18 20:00:00", envio_recuperacion="2026-08-20 10:55:00", baja=None),
    7: dict(nickname="Invitado_4821", tipo="INVITADO", estado="ACTIVA", rol="JUGADOR",
            correo=None, clave=None, nacimiento=None, idioma="es-MX",
            codigo=None, icono=1, espectadores=1, nivel=1, experiencia=60,
            intentos=0, ultimo_intento=None, bloqueada=None, doble_factor=0,
            registro="2026-08-30 16:00:00", configuracion=None,
            envio_verificacion=None, envio_recuperacion=None, baja=None),
    8: dict(nickname="nico_nuevo", tipo="REGISTRADA", estado="PENDIENTE", rol="JUGADOR",
            correo="nico@correo.mx", clave="Nico#Nuevo26", nacimiento="2010-09-09", idioma="es-MX",
            codigo="NN5T8B2R", icono=1, espectadores=1, nivel=1, experiencia=0,
            intentos=0, ultimo_intento=None, bloqueada=None, doble_factor=0,
            registro="2026-08-28 19:00:00", configuracion=None,
            envio_verificacion="2026-09-01 12:00:00", envio_recuperacion=None, baja=None),
    9: dict(nickname="rayo_veloz", tipo="REGISTRADA", estado="SUSPENDIDA", rol="JUGADOR",
            correo="rayo@correo.mx", clave="Rayo#Veloz77", nacimiento="2007-12-01", idioma="es-MX",
            codigo="RV2K9X4M", icono=9, espectadores=1, nivel=1, experiencia=90,
            intentos=0, ultimo_intento=None, bloqueada=None, doble_factor=0,
            registro="2026-06-20 15:00:00", configuracion="2026-06-20 15:02:00",
            envio_verificacion="2026-06-20 15:00:00", envio_recuperacion=None, baja=None),
    # Cuenta dada de baja: anonimizada en la misma transacción (D-17, CU-11).
    10: dict(nickname="anonimo_10", tipo="REGISTRADA", estado="ELIMINADA", rol="JUGADOR",
             correo="anonimo_10", clave=None, nacimiento=None, idioma="es-MX",
             codigo=None, icono=1, espectadores=1, nivel=1, experiencia=200,
             intentos=0, ultimo_intento=None, bloqueada=None, doble_factor=0,
             registro="2026-06-22 11:00:00", configuracion="2026-06-22 11:05:00",
             envio_verificacion="2026-06-22 11:00:00", envio_recuperacion=None, baja="2026-08-02 13:00:00"),
    # Cuenta baneada: su nickname esquivó el filtro imitando al administrador y un
    # reporte terminó en una sanción permanente de cuenta (CU-42, CU-44).
    11: dict(nickname="4dm1n_oficial", tipo="REGISTRADA", estado="BANEADA", rol="JUGADOR",
             correo="cuatro.admin@correo.mx", clave="Adm1n#Falso6", nacimiento="2006-01-10", idioma="es-MX",
             codigo="FK4D9M2N", icono=2, espectadores=1, nivel=1, experiencia=0,
             intentos=0, ultimo_intento=None, bloqueada=None, doble_factor=0,
             registro="2026-08-22 19:00:00", configuracion="2026-08-22 19:18:00",
             envio_verificacion="2026-08-22 19:00:00", envio_recuperacion=None, baja=None),
}

# id_sesion: usuario, fecha_inicio, fecha_fin, motivo_cierre, ip, huella, dispositivo, fecha_ultimo_uso.
# La vigencia es de veinticuatro horas (CU-01 RN-07). La 12 y la 14 expiraron sin cierre
# explícito; el invitado usó la 14 para la partida 10.
SESIONES = {
    1:  (1, "2026-08-31 08:00:00", "2026-08-31 12:00:00", "CIERRE_VOLUNTARIO", "189.203.14.20", "hw-admin-01", "Laptop de oficina", "2026-08-31 11:58:00"),
    2:  (2, "2026-09-01 17:00:00", None, None, "201.141.22.7", "hw-ana-01", "PC de escritorio", "2026-09-01 17:59:00"),
    3:  (3, "2026-08-31 20:00:00", "2026-09-01 17:10:00", "CIERRE_REMOTO", "189.203.55.3", "hw-luis-tab", "Tableta", "2026-08-31 22:30:00"),
    4:  (3, "2026-09-01 17:05:00", None, None, "189.203.55.9", "hw-luis-pc", "PC de escritorio", "2026-09-01 17:59:00"),
    5:  (4, "2026-08-01 19:00:00", "2026-08-01 20:30:00", "CIERRE_VOLUNTARIO", "187.190.3.41", "hw-marta-01", "Laptop", "2026-08-01 20:29:00"),
    6:  (4, "2026-09-01 17:54:00", None, None, "187.190.3.41", "hw-marta-01", "Laptop", "2026-09-01 17:59:00"),
    7:  (5, "2026-09-01 17:45:00", None, None, "201.141.80.12", "hw-pedro-01", "PC familiar", "2026-09-01 17:59:00"),
    8:  (6, "2026-08-19 18:00:00", "2026-08-20 11:05:00", "CAMBIO_CREDENCIALES", "187.190.66.5", "hw-sofia-01", "Celular", "2026-08-19 21:00:00"),
    9:  (6, "2026-09-01 17:25:00", None, None, "187.190.66.5", "hw-sofia-01", "Celular", "2026-09-01 17:59:00"),
    10: (9, "2026-08-26 17:00:00", "2026-08-27 10:00:00", "SANCION", "201.141.90.33", "hw-rayo-01", "Laptop", "2026-08-26 19:00:00"),
    11: (10, "2026-08-02 12:30:00", "2026-08-02 13:00:00", "BAJA_CUENTA", "189.203.77.8", "hw-diez-01", "PC", "2026-08-02 12:59:00"),
    12: (7, "2026-08-30 16:00:00", None, None, "189.203.40.2", "hw-invitado-4821", "Celular", "2026-08-30 17:30:00"),
    13: (7, "2026-09-01 17:48:00", None, None, "189.203.40.2", "hw-invitado-4821", "Celular", "2026-09-01 17:59:00"),
    14: (7, "2026-08-31 16:20:00", None, None, "189.203.40.2", "hw-invitado-4821", "Celular", "2026-08-31 16:40:00"),
    15: (11, "2026-08-22 19:15:00", "2026-08-23 10:00:00", "SANCION", "201.141.33.8", "hw-once-01", "PC", "2026-08-22 21:00:00"),
}

# id_token: usuario, proposito, correo_destino, fecha_generacion, estado (vigencia de 24 h, CU-04 RN-02).
# Los de alta usados se verificaron diez minutos después de generarse.
TOKENS_VERIFICACION = {
    1: (1, "ALTA", None, "2026-06-01 10:00:00", "USADO"),
    2: (2, "ALTA", None, "2026-06-02 09:00:00", "USADO"),
    3: (3, "ALTA", None, "2026-06-10 16:00:00", "USADO"),
    4: (4, "ALTA", None, "2026-06-12 18:30:00", "USADO"),
    5: (5, "ALTA", None, "2026-06-15 12:00:00", "USADO"),
    6: (6, "ALTA", None, "2026-06-18 20:00:00", "USADO"),
    7: (9, "ALTA", None, "2026-06-20 15:00:00", "USADO"),
    8: (10, "ALTA", None, "2026-06-22 11:00:00", "USADO"),
    9: (8, "ALTA", None, "2026-08-28 19:00:00", "INVALIDADO"),   # sustituido por el reenvío
    10: (8, "ALTA", None, "2026-09-01 12:00:00", "PENDIENTE"),
    11: (3, "CAMBIO_CORREO", "luis.quo.nuevo@correo.mx", "2026-09-01 17:20:00", "PENDIENTE"),
    12: (11, "ALTA", None, "2026-08-22 19:00:00", "USADO"),
}

# id_token: usuario, fecha_generacion, intentos, estado (vigencia de 30 min, CU-03 RN-04).
# El administrador pidió el código dos veces, con cinco minutos de diferencia: el
# segundo invalidó el primero y sigue vigente (CU-03 RN-05, RN-06).
TOKENS_RECUPERACION = {
    1: (6, "2026-08-20 10:55:00", 1, "USADO"),
    2: (1, "2026-09-01 17:40:00", 0, "INVALIDADO"),
    3: (1, "2026-09-01 17:46:00", 0, "PENDIENTE"),
}

# id_codigo: usuario, canal, fecha_generacion, intentos, estado (vigencia de 5 min, CU-01 RN-09).
CODIGOS_2FA = {
    1: (4, "CORREO", "2026-08-01 19:05:00", 0, "CONSUMIDO"),    # código de prueba al activarlo
    2: (4, "CORREO", "2026-08-15 20:00:00", 3, "INVALIDADO"),   # tres intentos fallidos
    3: (4, "CORREO", "2026-09-01 17:53:00", 0, "CONSUMIDO"),
    4: (4, "CORREO", "2026-09-01 17:58:00", 0, "PENDIENTE"),    # entra desde otro dispositivo (D-01)
}

# usuario, version_terminos, fecha_aceptacion, ip. El invitado acepta al vincularse (CU-07).
ACEPTACIONES = [
    (1, "2026.1", "2026-06-01 10:00:00", "189.203.14.20"),
    (2, "2026.1", "2026-06-02 09:00:00", "201.141.22.7"),
    (3, "2026.1", "2026-06-10 16:00:00", "189.203.55.3"),
    (3, "2026.2", "2026-08-01 10:00:00", "189.203.55.9"),
    (4, "2026.1", "2026-06-12 18:30:00", "187.190.3.41"),
    (5, "2026.1", "2026-06-15 12:00:00", "201.141.80.12"),
    (6, "2026.1", "2026-06-18 20:00:00", "187.190.66.5"),
    (8, "2026.2", "2026-08-28 19:00:00", "201.141.5.60"),    # desde el 1 de agosto rige la 2026.2
    (9, "2026.1", "2026-06-20 15:00:00", "201.141.90.33"),
    (10, "2026.1", "2026-06-22 11:00:00", "189.203.77.8"),
    (11, "2026.2", "2026-08-22 19:00:00", "201.141.33.8"),
]

HISTORIAL_NICKNAME = [(6, "sofi_123", "2026-07-02 19:00:00")]   # usuario, nickname_anterior, fecha

AVATARES = {  # id: usuario, ruta, formato, tamano_bytes, fecha_subida, vigente
    1: (4, "/avatares/4/1.png", "PNG", 480000, "2026-06-20 12:00:00", 0),
    2: (4, "/avatares/4/2.jpg", "JPG", 350000, "2026-08-05 17:00:00", 1),
    3: (10, "/avatares/10/1.jpg", "JPG", 200000, "2026-06-23 09:00:00", 0),   # invalidado por la baja
}

ENLACES_RED = {  # id: usuario, orden, url
    1: (3, 1, "https://www.youtube.com/@luisquo"),
    2: (3, 2, "https://www.twitch.tv/luisquo"),
}

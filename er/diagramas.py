# -*- coding: utf-8 -*-
"""Qué dibuja cada diagrama entidad-relación y cómo se lee cada relación.

Entidades, atributos, llaves y relaciones salen de esquema.json, que genera
bd/generar_tablas.ps1 a partir de bd/crear_tablas.sql. Aquí va solo lo que el
script SQL no dice: el verbo de cada relación, quién es el sujeto de la
frase, los papeles, la participación total del lado del padre y dónde se
coloca cada entidad. Rombos y atributos los coloca disposicion.py.

Lectura de los pares de cardinalidad (notación de Chen): la cifra de arriba
se lee siguiendo la frase del rombo, de sujeto a objeto; la de abajo, al
revés. El sujeto lleva arriba siempre 1.
"""

# ---------------------------------------------------------------- relaciones
# llave foránea: (verbo, sujeto, papel del padre, papel de la hija)
#   sujeto "padre": se lee «Padre verbo Hija»   (razón 1:N o 1:1)
#   sujeto "hija":  se lee «Hija verbo Padre»   (razón N:1 o 1:1)
VERBOS = {
    # Catálogos
    "FK_ObjetoCosmetico_Ranura":            ("Pertenece a", "hija", None, None),
    "FK_TipoCajaObjeto_TipoCaja":           ("Ofrece", "padre", None, None),
    "FK_TipoCajaObjeto_ObjetoCosmetico":    ("Sortea", "hija", None, None),
    # Cuenta y acceso
    "FK_Sesion_Usuario":                    ("Abre", "padre", None, None),
    "FK_CodigoVerificacion_Usuario":        ("Recibe", "padre", None, None),
    # Perfil y personalización
    "FK_HistorialNickname_Usuario":         ("Cambia nombre", "padre", None, None),
    "FK_Avatar_Usuario":                    ("Sube", "padre", None, None),
    "FK_EnlaceRed_Usuario":                 ("Publica", "padre", None, None),
    "FK_UsuarioObjeto_Usuario":             ("Posee", "padre", None, None),
    "FK_UsuarioObjeto_ObjetoCosmetico":     ("Corresponde a", "hija", None, None),
    "FK_Equipamiento_UsuarioObjeto":        ("Usa", "hija", None, None),
    "FK_Equipamiento_ObjetoCosmetico":      ("Muestra", "hija", None, None),
    "FK_Equipamiento_Ranura":               ("Ocupa", "hija", None, None),
    # Partida
    "FK_Partida_Modo":                      ("Se juega en", "hija", None, None),
    "FK_Partida_NivelIA":                   ("Enfrenta", "hija", None, None),
    "FK_Participacion_Partida":             ("Reúne", "padre", None, None),
    "FK_Participacion_Usuario":             ("Participa", "padre", None, None),
    "FK_ParticipacionObjeto_Participacion": ("Fija", "padre", None, None),
    "FK_ParticipacionObjeto_ObjetoCosmetico": ("Luce", "hija", None, None),
    "FK_Jugada_Partida":                    ("Registra", "padre", None, None),
    "FK_Jugada_Participacion":              ("Hace", "padre", None, None),
    "FK_OfertaTablas_Participacion":        ("Ofrece", "padre", None, None),
    "FK_EnlaceEspectador_Participacion":    ("Comparte", "padre", None, None),
    # Emparejamiento, salas y chat
    "FK_Sala_Anfitrion":                    ("Crea", "padre", "anfitrión", None),
    "FK_Sala_Modo":                         ("Usa", "hija", None, None),
    "FK_Sala_Partida":                      ("Inicia", "hija", None, None),
    "FK_Invitacion_Sala":                   ("Da acceso a", "hija", None, None),
    "FK_Invitacion_Emisor":                 ("Envía", "padre", "emisor", None),
    "FK_Invitacion_Destinatario":           ("Recibe", "padre", "destinatario", None),
    "FK_Mensaje_Autor":                     ("Escribe", "padre", "autor", None),
    "FK_Mensaje_Partida":                   ("Pertenece a", "hija", None, None),
    "FK_Mensaje_Sala":                      ("Pertenece a", "hija", None, None),
    # Clasificación y economía
    "FK_EstadisticaModo_Usuario":           ("Tiene", "padre", None, None),
    "FK_EstadisticaModo_Modo":              ("Mide", "hija", None, None),
    "FK_EstadisticaModo_Division":          ("Ubica en", "hija", None, None),
    "FK_HistorialDivision_EstadisticaModo": ("Acumula", "padre", None, None),
    "FK_HistorialDivision_Anterior":        ("Sale de", "hija", "anterior", None),
    "FK_HistorialDivision_Nueva":           ("Llega a", "hija", "nueva", None),
    "FK_Caja_Usuario":                      ("Obtiene", "padre", None, None),
    "FK_Caja_TipoCaja":                     ("Es de tipo", "hija", None, None),
    "FK_CajaContenido_Caja":                ("Contiene", "padre", None, None),
    "FK_CajaContenido_ObjetoCosmetico":     ("Entrega", "hija", None, None),
    "FK_MovimientoMoneda_Usuario":          ("Mueve", "padre", None, None),
    "FK_MovimientoMoneda_Partida":          ("Paga", "padre", None, None),
    "FK_MovimientoMoneda_ObjetoCosmetico":  ("Paga", "hija", None, None),
    "FK_MovimientoMoneda_Caja":             ("Origina", "padre", None, None),
    # Relaciones entre jugadores y tutorial
    "FK_Amistad_UsuarioA":                  ("Es amigo", "padre", "menor", None),
    "FK_Amistad_UsuarioB":                  ("Es amigo", "padre", "mayor", None),
    "FK_Solicitud_Solicitante":             ("Envía", "padre", "solicitante", None),
    "FK_Solicitud_Destinatario":            ("Recibe", "padre", "destinatario", None),
    "FK_Silencio_Usuario":                  ("Silencia", "padre", "quien silencia", None),
    "FK_Silencio_Silenciado":               ("Es silenciado", "padre", "silenciado", None),
    "FK_Bloqueo_Bloqueador":                ("Bloquea", "padre", "bloqueador", None),
    "FK_Bloqueo_Bloqueado":                 ("Es bloqueado", "padre", "bloqueado", None),
    "FK_ProgresoTutorial_Usuario":          ("Avanza", "padre", None, None),
    "FK_ProgresoTutorial_Leccion":          ("Cubre", "hija", None, None),
    # Moderación y bitácoras
    "FK_Reporte_Denunciante":               ("Emite", "padre", "reportante", None),
    "FK_Reporte_Reportado":                 ("Señala", "hija", "reportado", None),
    "FK_Reporte_ParticipacionDenunciante":  ("Sobre", "hija", "del reportante", None),
    "FK_Reporte_ParticipacionReportado":    ("Sobre", "hija", "del reportado", None),
    "FK_Reporte_Moderador":                 ("Revisa", "padre", "moderador", None),
    "FK_Sancion_Usuario":                   ("Recibe", "padre", "sancionado", None),
    "FK_Sancion_Moderador":                 ("Aplica", "padre", "moderador", None),
    "FK_Sancion_Reporte":                   ("Origina", "padre", None, None),
    "FK_Sancion_Sustituta":                 ("Sustituye", "padre", "sustituta", "sustituida"),
    "FK_Apelacion_Sancion":                 ("Se apela", "padre", None, None),
    "FK_Apelacion_Moderador":               ("Resuelve", "padre", "moderador", None),
    "FK_BitacoraModeracion_Moderador":      ("Registra", "padre", "autor", None),
    "FK_BitacoraModeracion_Afectado":       ("Afecta", "hija", "afectado", None),
    "FK_BitacoraAcceso_Usuario":            ("Registra", "padre", None, None),
}

# Llaves foráneas en las que toda fila del padre tiene al menos una hija
# (participación total del padre, doble línea de su lado).
PADRE_TOTAL = {
    "FK_ObjetoCosmetico_Ranura",             # cada ranura tiene su objeto predeterminado (CU-02 PRE-05)
    "FK_TipoCajaObjeto_TipoCaja",            # un tipo de caja tiene al menos un objeto posible
    "FK_UsuarioObjeto_Usuario",              # el alta otorga los objetos iniciales (CU-02 RN-08)
    "FK_EstadisticaModo_Usuario",            # una fila por modo desde el alta (CU-02 RN-06)
    "FK_Participacion_Partida",              # una partida tiene al menos un participante
    "FK_ParticipacionObjeto_Participacion",  # una fila por ranura al empezar (CU-07 RN-06)
}

# ---------------------------------------------------------------- diagramas
# posiciones: centro de cada entidad. Las entidades de otras áreas que
# aparecen porque una relación del área las toca se dibujan sin atributos.
# rombos: posición fija para un rombo concreto (opcional).
# pagina: orientación de la página del documento en que va el diagrama; la
# compactación de disposicion.py busca el tamaño de texto mayor en ella.
# esquema: "nucleo" (er/esquema.json) o "fase" (núcleo y fase posterior juntos; las
# entidades del núcleo aparecen solo como frontera, sin atributos).
DIAGRAMAS = [
    # El diagrama de partida, tal como se dibujó antes de los casos de uso. Su
    # modelo (modelos/original.py) está escrito a mano y no se recalcula.
    dict(id="original", titulo="Diagrama original", fijo=True),
    # ------------------------------------------------------------ núcleo (D-22)
    dict(id="general", pagina="vertical", titulo="Vista general del núcleo", areas=None, atributos=False,
         posiciones=None),
    dict(
        id="catalogos", pagina="horizontal", titulo="Catálogos precargados",
        areas=["Catálogos precargados (D-09)"],
        posiciones={"Modo": (0, 0), "PalabraProhibida": (2600, 0)},
    ),
    dict(
        id="cuenta", pagina="horizontal", titulo="Cuenta y acceso",
        areas=["Cuenta y acceso"],
        posiciones={"Usuario": (0, 0), "Sesion": (2900, -900), "CodigoVerificacion": (2900, 1100)},
    ),
    dict(
        id="partida", pagina="horizontal", titulo="Partida",
        areas=["Partida"],
        posiciones={
            "Partida": (0, 0), "Participacion": (2600, 0),
            "Modo": (-1800, 1300), "Jugada": (1300, 2100), "Usuario": (3900, 1700),
            "OfertaTablas": (4600, -600),
        },
    ),
    dict(
        id="salas", pagina="horizontal", titulo="Salas y chat",
        areas=["Salas y chat"],
        posiciones={"Usuario": (0, 0), "Sala": (2600, 0), "Partida": (5200, 0), "Modo": (2600, -2000),
                    "Mensaje": (2600, 2000)},
    ),
    dict(
        id="jugadores", pagina="horizontal", titulo="Clasificación y relaciones entre jugadores",
        areas=["Clasificación", "Relaciones entre jugadores"],
        posiciones={"Usuario": (0, 0), "EstadisticaModo": (-2600, 0), "Modo": (-5000, 0),
                    "Silencio": (2000, -1200), "Bloqueo": (2000, 1200)},
    ),
    dict(
        id="moderacion", pagina="vertical", titulo="Moderación y bitácoras",
        areas=["Moderación y bitácoras"],
        posiciones={
            "Usuario": (0, 0),
            "Reporte": (2600, -1700), "Participacion": (5200, -1700),
            "Sancion": (2600, 1600), "Apelacion": (2600, 3700),
            "BitacoraModeracion": (-2500, -1300), "BitacoraAcceso": (-2500, 1400),
        },
        rombos={"FK_Sancion_Sustituta": (4300, 1600)},
    ),
    # ------------------------------------------------------------ fase posterior (D-22)
    dict(
        id="fp-catalogos", esquema="fase", pagina="horizontal", titulo="Catálogos de la fase posterior",
        areas=["Catálogos precargados de la fase posterior (D-09)"],
        posiciones={
            "Ranura": (0, 0), "ObjetoCosmetico": (2300, 0), "TipoCajaObjeto": (4500, 0), "TipoCaja": (6600, 0),
            "Division": (1150, 2700), "NivelIA": (3400, 2700), "Leccion": (5600, 2700),
        },
    ),
    dict(
        id="fp-perfil", esquema="fase", pagina="horizontal", titulo="Perfil y personalización",
        areas=["Perfil y personalización"],
        posiciones={
            "Usuario": (0, 0),
            "HistorialNickname": (-1700, -1100), "Avatar": (-1700, 1100), "EnlaceRed": (0, -1500),
            "UsuarioObjeto": (1800, 0), "ObjetoCosmetico": (3600, 0),
            "Equipamiento": (2700, 1500), "Ranura": (4500, 1500),
        },
    ),
    dict(
        id="fp-partida", esquema="fase", pagina="horizontal", titulo="Aspecto en partida, espectador e invitaciones",
        areas=["Aspecto en partida y espectador", "Invitaciones"],
        posiciones={
            "Participacion": (0, 0), "ParticipacionObjeto": (2400, -900), "ObjetoCosmetico": (4800, -900),
            "EnlaceEspectador": (2400, 1000),
            "Invitacion": (-2600, 1600), "Sala": (-2600, 3600), "Usuario": (-5000, 1600),
        },
    ),
    dict(
        id="fp-economia", esquema="fase", pagina="horizontal", titulo="Clasificación y economía",
        areas=["Clasificación y economía"],
        posiciones={
            "Usuario": (0, 0),
            "EstadisticaModo": (-2600, 0), "Division": (-5000, 0),
            "HistorialDivision": (-3900, 1900),
            "Caja": (2500, 0), "TipoCaja": (2500, -2000), "CajaContenido": (4700, 0),
            "ObjetoCosmetico": (4700, 2300), "MovimientoMoneda": (2000, 2200),
            "Partida": (0, 3000),
        },
    ),
    dict(
        id="fp-social", esquema="fase", pagina="vertical", titulo="Relaciones entre jugadores y tutorial",
        areas=["Relaciones entre jugadores y tutorial"],
        posiciones={
            "Usuario": (0, 0),
            "Amistad": (-1600, -1150), "Solicitud": (1600, -1150),
            "ProgresoTutorial": (0, 1500), "Leccion": (0, 2900),
        },
    ),
]

/*=====================================================================
  Bastion - Creación de tablas del núcleo (2 de 3)
  Motor: SQL Server 2019 o posterior (CON-04).

  Orden de ejecución:
     1. crear_base_datos.sql
     2. crear_tablas.sql          <- este archivo
     3. insertar_datos_prueba.sql
  Después, solo cuando empiece la fase posterior:
     4. fase_posterior/crear_tablas_fase_posterior.sql
     5. fase_posterior/insertar_datos_prueba_fase_posterior.sql

  Crea, en la base Bastion vacía, las tablas del núcleo: las que exigen
  los casos obligatorios del cliente y los de jugabilidad (sección
  "Priorización de requisitos y casos de uso"). Las de los agregados del
  equipo (cosméticos, tienda, cajas, monedas, divisiones, amigos,
  espectador, IA, tutorial, perfil) están en fase_posterior/ y no se
  crean aquí (D-22).

  Contenido:
     1. Catálogos precargados (D-09)
     2. Cuenta y acceso
     3. Partida
     4. Salas y chat
     5. Clasificación
     6. Relaciones entre jugadores
     7. Moderación y bitácoras
     8. Procedimientos para las eliminaciones físicas

  Convenciones:
    - Tablas en singular y PascalCase; columnas en snake_case, sin
      acentos ni eñes, igual que en los casos de uso.
    - Restricciones con prefijo de su clase: PK_ llave primaria,
      FK_ llave foránea, UQ_ única, CK_ comprobación; UX_ índice único
      filtrado, IX_ índice.
    - Fechas en UTC con DATETIME2(0).
    - Texto que escribe o lee una persona en NVARCHAR (CON-05). La base
      usa la intercalación Modern_Spanish_100_CI_AS_SC_UTF8, así que
      todo texto admite la ñ, los acentos y cualquier carácter Unicode.
    - Nada se guarda traducido: los catálogos y los dominios guardan un
      código que es la clave de su nombre en los diccionarios de
      recursos (D-21).
    - Cada columna lleva un comentario. Las tablas de atributos del
      documento se generan a partir de este archivo con
      bd/generar_tablas.ps1, así que el comentario es la descripción
      que aparece en el documento.
=====================================================================*/

USE Bastion;
GO
-- Los índices filtrados y las columnas calculadas exigen estas opciones al
-- crear las tablas y al modificarlas; sqlcmd las trae apagadas por omisión.
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/*---------------------------------------------------------------------
  1. Catálogos precargados (D-09)
  Ningún caso de uso los escribe: se cargan por SQL.
---------------------------------------------------------------------*/

-- @entidad Modo | Catálogo de modos de juego; cada modo fija tablero, jugadores y muros (D-04).
-- @fn Llave simple; `codigo` es llave candidata. Recoge num_jugadores, que en el diagrama estaba en *Partida* y dependía de ella a través del modo.
CREATE TABLE dbo.Modo (
    id_modo            TINYINT        NOT NULL,  -- Identificador del modo.
    codigo             VARCHAR(40)    NOT NULL,  -- Clave del modo en los diccionarios de recursos (D-21): `CLASICO`, `CUATRO_JUGADORES` o `RAPIDA`.
    tamano_tablero     TINYINT        NOT NULL,  -- Casillas por lado: 7 o 9.
    num_jugadores      TINYINT        NOT NULL,  -- Plazas de la partida: 2 o 4, nunca 3 (CU-07 RN-02).
    muros_por_jugador  TINYINT        NOT NULL,  -- Muros de cada jugador: 10, 5 o 6 (CU-12 RN-02).
    activo             BIT            NOT NULL DEFAULT (1),  -- Solo los modos activos reciben estadísticas al dar de alta (CU-02).
    CONSTRAINT PK_Modo PRIMARY KEY (id_modo),
    CONSTRAINT UQ_Modo_codigo UNIQUE (codigo),  -- Dos modos no tienen la misma clave.
    CONSTRAINT CK_Modo_parametros CHECK (tamano_tablero IN (7, 9) AND num_jugadores IN (2, 4) AND muros_por_jugador BETWEEN 1 AND 20)
);
GO

-- @entidad PalabraProhibida | Catálogo del filtro de palabras que se aplica en el servidor al nickname y al chat (CON-09).
-- @fn Llave sustituta; la natural (`termino`, `idioma`, `ambito`) se declara única. Sin indicador de activo: ninguna tabla referencia el catálogo, así que un término que deja de filtrarse se borra por SQL (D-09).
CREATE TABLE dbo.PalabraProhibida (
    id_palabra         INT IDENTITY(1,1) NOT NULL,  -- Identificador del término.
    termino            NVARCHAR(100) COLLATE Latin1_General_100_CI_AI_SC_UTF8 NOT NULL,  -- Término prohibido, con sus eñes y acentos; se compara sin mayúsculas ni acentos.
    idioma             VARCHAR(10)    NULL,  -- Idioma del término: `es-MX` o `en`; nulo si se filtra en todos los idiomas (CU-18 RN-01).
    ambito             VARCHAR(10)    NOT NULL,  -- `NICKNAME`, `CHAT` o `AMBOS`.
    CONSTRAINT PK_PalabraProhibida PRIMARY KEY (id_palabra),
    CONSTRAINT UQ_PalabraProhibida_termino UNIQUE (termino, idioma, ambito),  -- Un término no se repite en el mismo idioma y ámbito.
    CONSTRAINT CK_PalabraProhibida_idioma CHECK (idioma IN ('es-MX','en')),  -- Idiomas admitidos (D-21); un nulo pasa la comprobación.
    CONSTRAINT CK_PalabraProhibida_ambito CHECK (ambito IN ('NICKNAME','CHAT','AMBOS'))
);
GO

/*---------------------------------------------------------------------
  2. Cuenta y acceso
---------------------------------------------------------------------*/

-- @entidad Usuario | Cuenta de un jugador, moderador o administrador. Es la entidad central: casi todas las demás dependen de ella y su fila nunca se borra (D-07, D-17).
-- @fn Llave simple; `nickname` es llave candidata. Sin el atributo compuesto nombre_completo ni el derivado edad del diagrama. La aceptación de los términos vive aquí: solo se consulta la última versión aceptada, que depende de la cuenta (D-23).
CREATE TABLE dbo.Usuario (
    id_usuario                       INT IDENTITY(1,1) NOT NULL,  -- Identificador de la cuenta; no cambia al vincular un invitado (D-02).
    tipo_cuenta                      VARCHAR(10)    NOT NULL DEFAULT ('REGISTRADA'),  -- `REGISTRADA`, o `INVITADO` en la fase posterior (CU-03). Se conserva desde el núcleo porque volver nulo el `correo` después obligaría a rehacer su índice único (D-22).
    estado_cuenta                    VARCHAR(10)    NOT NULL DEFAULT ('PENDIENTE'),  -- `PENDIENTE`, `ACTIVA`, `SUSPENDIDA`, `BANEADA` o `ELIMINADA` (CU-01 RN-04).
    rol                              VARCHAR(13)    NOT NULL DEFAULT ('JUGADOR'),  -- `JUGADOR`, `MODERADOR` o `ADMINISTRADOR`; exactamente uno (DES-20 RN-03).
    nickname                         NVARCHAR(30) COLLATE Latin1_General_100_CI_AI_SC_UTF8 NOT NULL,  -- Nombre visible, de 3 a 30 caracteres; único sin distinguir mayúsculas ni acentos (CU-02 RN-01).
    correo                           NVARCHAR(254)  NULL,  -- Correo normalizado a minúsculas; nulo solo en invitados (CU-02 RN-02).
    contrasena_hash                  VARBINARY(64)  NULL,  -- Resumen criptográfico de la contraseña; nunca en claro (CU-01 RN-02).
    contrasena_sal                   VARBINARY(32)  NULL,  -- Sal del resumen.
    fecha_nacimiento                 DATE           NULL,  -- Para comprobar la edad mínima de ocho años; la edad no se guarda (CU-02).
    idioma_preferido                 VARCHAR(10)    NOT NULL DEFAULT ('es-MX'),  -- Idioma de la interfaz y de los correos, `es-MX` o `en` (D-21); viaja con el jugador a cualquier dispositivo (CU-05 RN-05).
    intentos_fallidos                TINYINT        NOT NULL DEFAULT (0),  -- Intentos fallidos consecutivos de inicio de sesión (CU-01 RN-03).
    fecha_ultimo_intento_fallido     DATETIME2(0)   NULL,  -- Para restablecer el contador a las 24 horas (CU-01 RN-03).
    bloqueada_hasta                  DATETIME2(0)   NULL,  -- Fin del bloqueo escalonado vigente.
    doble_factor_habilitado          BIT            NOT NULL DEFAULT (0),  -- Si la cuenta pide segundo factor (CU-01 RN-08).
    fecha_registro                   DATETIME2(0)   NOT NULL DEFAULT (SYSUTCDATETIME()),  -- Alta de la cuenta.
    fecha_ultimo_envio_verificacion  DATETIME2(0)   NULL,  -- Último correo de verificación que sí se envió; limita el reenvío (CU-01 RN-10). No sale del token: si el envío falla, el token existe y esta fecha no cambia.
    fecha_ultimo_envio_recuperacion  DATETIME2(0)   NULL,  -- Último correo de recuperación que sí se envió; limita el envío (DES-01 RN-06).
    version_terminos                 VARCHAR(20)    NULL,  -- Última versión de los términos de uso que aceptó la cuenta (CU-02 RN-12); sustituye a la tabla AceptacionTerminos (D-23). Nula solo en invitados.
    idioma_terminos                  VARCHAR(10)    NULL,  -- Idioma en que se mostró el texto aceptado, `es-MX` o `en` (D-21).
    fecha_aceptacion_terminos        DATETIME2(0)   NULL,  -- Momento de la aceptación.
    fecha_baja                       DATETIME2(0)   NULL,  -- Momento de la baja, que es definitiva: la cuenta se anonimiza en la misma transacción (D-07, D-17).
    CONSTRAINT PK_Usuario PRIMARY KEY (id_usuario),
    CONSTRAINT UQ_Usuario_nickname UNIQUE (nickname),  -- El nickname es identificador de acceso (CU-01 RN-14).
    CONSTRAINT CK_Usuario_tipo_cuenta CHECK (tipo_cuenta IN ('INVITADO','REGISTRADA')),
    CONSTRAINT CK_Usuario_estado_cuenta CHECK (estado_cuenta IN ('PENDIENTE','ACTIVA','SUSPENDIDA','BANEADA','ELIMINADA')),
    CONSTRAINT CK_Usuario_rol CHECK (rol IN ('JUGADOR','MODERADOR','ADMINISTRADOR')),
    CONSTRAINT CK_Usuario_idioma CHECK (idioma_preferido IN ('es-MX','en')),  -- Idiomas admitidos (D-21); otro se rechaza (CU-05 FA-05).
    CONSTRAINT CK_Usuario_credenciales CHECK (
        (tipo_cuenta = 'INVITADO' AND correo IS NULL AND contrasena_hash IS NULL AND contrasena_sal IS NULL)
        OR (tipo_cuenta = 'REGISTRADA' AND correo IS NOT NULL)),
    CONSTRAINT CK_Usuario_rol_registrada CHECK (rol = 'JUGADOR' OR tipo_cuenta = 'REGISTRADA'),
    CONSTRAINT CK_Usuario_baja CHECK (
        (estado_cuenta = 'ELIMINADA' AND fecha_baja IS NOT NULL)
        OR (estado_cuenta <> 'ELIMINADA' AND fecha_baja IS NULL)),
    CONSTRAINT CK_Usuario_idioma_terminos CHECK (idioma_terminos IN ('es-MX','en')),  -- Idiomas admitidos (D-21).
    CONSTRAINT CK_Usuario_terminos CHECK (
        (tipo_cuenta = 'REGISTRADA' AND version_terminos IS NOT NULL AND idioma_terminos IS NOT NULL AND fecha_aceptacion_terminos IS NOT NULL)
        OR (tipo_cuenta = 'INVITADO' AND version_terminos IS NULL AND idioma_terminos IS NULL AND fecha_aceptacion_terminos IS NULL))  -- Toda cuenta registrada aceptó los términos; el invitado los acepta al vincularse (DES-02).
);
GO
CREATE UNIQUE INDEX UX_Usuario_correo ON dbo.Usuario (correo) WHERE correo IS NOT NULL;  -- El correo es único entre las cuentas que lo tienen (CU-02 RN-02).
GO

-- @entidad Sesion | Sesión abierta desde un dispositivo. Una cuenta puede tener varias a la vez (D-01); al cerrarse no se borra.
-- @fn Llave simple; `token_hash` es llave candidata.
CREATE TABLE dbo.Sesion (
    id_sesion          INT IDENTITY(1,1) NOT NULL,  -- Identificador de la sesión.
    id_usuario         INT            NOT NULL,  -- Cuenta dueña de la sesión.
    token_hash         VARBINARY(32)  NOT NULL,  -- Resumen del token de sesión.
    fecha_inicio       DATETIME2(0)   NOT NULL DEFAULT (SYSUTCDATETIME()),  -- Apertura de la sesión.
    fecha_expiracion   DATETIME2(0)   NOT NULL,  -- Vigencia máxima de veinticuatro horas (CU-01 RN-07).
    fecha_ultimo_uso   DATETIME2(0)   NOT NULL DEFAULT (SYSUTCDATETIME()),  -- Para reconocer sesiones olvidadas (DES-04); se actualiza por minutos.
    fecha_fin          DATETIME2(0)   NULL,  -- Cierre explícito; nula mientras está abierta.
    motivo_cierre      VARCHAR(20)    NULL,  -- `CIERRE_VOLUNTARIO`, `CIERRE_REMOTO`, `CAMBIO_CREDENCIALES`, `BAJA_CUENTA` o `SANCION`.
    direccion_ip       VARCHAR(45)    NOT NULL,  -- Dirección de red de origen.
    huella_dispositivo VARCHAR(128)   NOT NULL,  -- Huella del dispositivo.
    nombre_dispositivo NVARCHAR(100)  NULL,  -- Nombre legible del dispositivo (D-01).
    version_cliente    VARCHAR(20)    NOT NULL,  -- Versión del cliente que abrió la sesión.
    CONSTRAINT PK_Sesion PRIMARY KEY (id_sesion),
    CONSTRAINT UQ_Sesion_token UNIQUE (token_hash),  -- Un token identifica una sola sesión.
    CONSTRAINT FK_Sesion_Usuario FOREIGN KEY (id_usuario) REFERENCES dbo.Usuario (id_usuario),  -- 1:N | Un usuario abre muchas sesiones; cada sesión es de un usuario.
    CONSTRAINT CK_Sesion_motivo CHECK (motivo_cierre IN ('CIERRE_VOLUNTARIO','CIERRE_REMOTO','CAMBIO_CREDENCIALES','BAJA_CUENTA','SANCION')),
    CONSTRAINT CK_Sesion_cierre CHECK ((fecha_fin IS NULL AND motivo_cierre IS NULL) OR (fecha_fin IS NOT NULL AND motivo_cierre IS NOT NULL)),
    CONSTRAINT CK_Sesion_vigencia CHECK (fecha_expiracion > fecha_inicio)
);
GO
CREATE INDEX IX_Sesion_abiertas ON dbo.Sesion (id_usuario) WHERE fecha_fin IS NULL;
GO

-- @entidad CodigoVerificacion | Código o enlace de un solo uso que se envía a la cuenta: verificar el alta, confirmar un cambio de correo, recuperar la contraseña o completar el segundo factor. Sustituye a TokenVerificacionCorreo, TokenRecuperacion y CodigoSegundoFactor (D-23).
-- @fn Llave simple; `proposito` discrimina si aplica `correo_destino`. Las tres tablas que sustituye tenían las mismas columnas y el mismo ciclo de vida.
CREATE TABLE dbo.CodigoVerificacion (
    id_codigo          INT IDENTITY(1,1) NOT NULL,  -- Identificador del código.
    id_usuario         INT            NOT NULL,  -- Cuenta a la que se envió.
    proposito          VARCHAR(15)    NOT NULL,  -- `ALTA`, `CAMBIO_CORREO`, `RECUPERACION` o `SEGUNDO_FACTOR`. Discrimina la vigencia y si aplica `correo_destino`.
    codigo_hash        VARBINARY(32)  NOT NULL,  -- Resumen del código o del token del enlace; nunca en claro (CU-01 RN-02, CU-02 RN-06).
    correo_destino     NVARCHAR(254)  NULL,  -- Correo nuevo; solo en `CAMBIO_CORREO` (D-20). En los demás es el de la cuenta y no se repite.
    fecha_generacion   DATETIME2(0)   NOT NULL DEFAULT (SYSUTCDATETIME()),  -- Emisión.
    fecha_expiracion   DATETIME2(0)   NOT NULL,  -- Veinticuatro horas en `ALTA` y `CAMBIO_CORREO` (CU-02 RN-02), treinta minutos en `RECUPERACION` (DES-01 RN-04) y cinco en `SEGUNDO_FACTOR` (CU-01 RN-09).
    intentos           TINYINT        NOT NULL DEFAULT (0),  -- Intentos de verificación de un código tecleado; máximo tres (CU-01 RN-09, DES-01 RN-09).
    estado             VARCHAR(10)    NOT NULL DEFAULT ('PENDIENTE'),  -- `PENDIENTE`, `USADO` o `INVALIDADO`.
    CONSTRAINT PK_CodigoVerificacion PRIMARY KEY (id_codigo),
    CONSTRAINT FK_CodigoVerificacion_Usuario FOREIGN KEY (id_usuario) REFERENCES dbo.Usuario (id_usuario),  -- 1:N | Un usuario recibe muchos códigos a lo largo del tiempo.
    CONSTRAINT CK_CodigoVerificacion_proposito CHECK (
        (proposito = 'CAMBIO_CORREO' AND correo_destino IS NOT NULL)
        OR (proposito IN ('ALTA','RECUPERACION','SEGUNDO_FACTOR') AND correo_destino IS NULL)),
    CONSTRAINT CK_CodigoVerificacion_intentos CHECK (intentos BETWEEN 0 AND 3),
    CONSTRAINT CK_CodigoVerificacion_estado CHECK (estado IN ('PENDIENTE','USADO','INVALIDADO')),
    CONSTRAINT CK_CodigoVerificacion_vigencia CHECK (fecha_expiracion > fecha_generacion)
);
GO
CREATE UNIQUE INDEX UX_CodigoVerificacion_vigente ON dbo.CodigoVerificacion (id_usuario, proposito) WHERE estado = 'PENDIENTE';  -- Un solo código vigente por cuenta y propósito (CU-01 RN-09, DES-01 RN-05, CU-02 RN-03).
CREATE UNIQUE INDEX UX_CodigoVerificacion_enlace ON dbo.CodigoVerificacion (codigo_hash) WHERE proposito IN ('ALTA','CAMBIO_CORREO');  -- El enlace de un correo identifica un solo código; los códigos tecleados son cortos y pueden repetirse entre cuentas.
GO

/*---------------------------------------------------------------------
  3. Partida
---------------------------------------------------------------------*/

-- @entidad Partida | Partida clasificatoria o privada. Se guarda completa porque de ella dependen el historial, la repetición, la reconexión y los reportes.
-- @fn Llave simple. Sin num_jugadores ni la duración del diagrama (dependencia transitiva y dato derivado). `tipo` distingue la clasificatoria, que da elo, de la privada. Sin ganador: es la participación con resultado `GANADA`. `turno_actual` es redundancia controlada del estado vigente; mandan las *Jugada*.
CREATE TABLE dbo.Partida (
    id_partida           INT IDENTITY(1,1) NOT NULL,  -- Identificador de la partida.
    id_modo              TINYINT        NOT NULL,  -- Modo; de él salen tablero, plazas y muros, que no se repiten aquí.
    tipo                 VARCHAR(15)    NOT NULL,  -- `CLASIFICATORIA` o `PRIVADA`; la fase posterior añade `IA` (DES-09).
    estado               VARCHAR(20)    NOT NULL DEFAULT ('EN_CURSO'),  -- `EN_CURSO`, `PENDIENTE_DE_CIERRE` o `FINALIZADA` (CU-16 RN-11).
    minutos_reloj        TINYINT        NOT NULL,  -- 3, 5 o 10. En la fase posterior admite nulo para la IA sin reloj (DES-09 RN-06).
    fecha_inicio         DATETIME2(0)   NOT NULL DEFAULT (SYSUTCDATETIME()),  -- Inicio. La duración se calcula y no se guarda (CU-24 RN-02).
    fecha_fin            DATETIME2(0)   NULL,  -- Cierre de la partida.
    forma_termino        VARCHAR(15)    NULL,  -- `META`, `TIEMPO_AGOTADO`, `RENDICION`, `TABLAS` o `ABANDONO` (CU-16 RN-01).
    turno_actual         TINYINT        NOT NULL DEFAULT (1),  -- `orden_turno` del participante que tiene el turno. Redundancia controlada: se deduce de las *Jugada*, que mandan si discrepan.
    CONSTRAINT PK_Partida PRIMARY KEY (id_partida),
    CONSTRAINT FK_Partida_Modo FOREIGN KEY (id_modo) REFERENCES dbo.Modo (id_modo),  -- 1:N | Un modo se juega en muchas partidas; cada partida es de un modo.
    CONSTRAINT CK_Partida_tipo CHECK (tipo IN ('CLASIFICATORIA','PRIVADA')),
    CONSTRAINT CK_Partida_estado CHECK (estado IN ('EN_CURSO','PENDIENTE_DE_CIERRE','FINALIZADA')),
    CONSTRAINT CK_Partida_forma CHECK (forma_termino IN ('META','TIEMPO_AGOTADO','RENDICION','TABLAS','ABANDONO')),
    CONSTRAINT CK_Partida_reloj CHECK (minutos_reloj IN (3, 5, 10)),
    CONSTRAINT CK_Partida_cierre CHECK (
        (estado = 'EN_CURSO' AND fecha_fin IS NULL AND forma_termino IS NULL)
        OR (estado = 'PENDIENTE_DE_CIERRE' AND fecha_fin IS NULL AND forma_termino IS NOT NULL)
        OR (estado = 'FINALIZADA' AND fecha_fin IS NOT NULL AND forma_termino IS NOT NULL))
);
GO

-- @entidad Participacion | Participación de un jugador en una partida; es la relación N:M entre Usuario y Partida (relación Participa del diagrama). 
-- @fn Llaves candidatas (id_partida, id_usuario) e (id_partida, orden_turno). `diferencia_elo` y `terminada` son calculadas: dependían de otras columnas de la fila. `casilla_actual`, `muros_restantes` y `reloj_restante` son redundancia controlada del estado vigente; mandan las *Jugada*.
CREATE TABLE dbo.Participacion (
    id_partida           INT            NOT NULL,  -- Partida.
    id_usuario           INT            NOT NULL,  -- Jugador.
    orden_turno          TINYINT        NOT NULL,  -- Orden en que juega, de 1 a 4.
    simbolo_peon         VARCHAR(10)    NOT NULL,  -- Símbolo y color que distinguen su peón (color_ficha en el diagrama).
    casilla_actual       VARCHAR(3)     NOT NULL,  -- Casilla que ocupa el peón, en notación de tablero. Redundancia controlada: es la de su última jugada.
    muros_restantes      TINYINT        NOT NULL,  -- Muros que le quedan; nace con los del modo o de la sala (CU-08). Redundancia controlada: los iniciales menos sus jugadas de tipo `MURO`.
    reloj_restante       INT            NULL,  -- Milisegundos que le quedan; nulo solo en la fase posterior, en la IA sin reloj. Redundancia controlada: el reloj inicial menos el tiempo consumido en sus jugadas, o cero para quien pierde por tiempo, porque la jugada que llegó tarde no se guarda (CU-11 FA-06).
    elo_inicial          SMALLINT       NULL,  -- Elo con el que entró; base del cálculo (CU-07 RN-04, CU-16 RN-04).
    elo_final            SMALLINT       NULL,  -- Elo resultante; solo en partidas clasificatorias.
    diferencia_elo       AS (elo_final - elo_inicial),  -- Cambio de elo que muestra el historial (CU-24 RN-03). Calculada y no almacenada: depende de otras dos columnas de la fila.
    resultado            VARCHAR(10)    NULL,  -- `GANADA`, `PERDIDA` o `TABLAS`; nulo mientras no termina.
    posicion             TINYINT        NULL,  -- Posición en el modo de cuatro jugadores, de 1 a 4 (CU-16 RN-02); nula en las de dos jugadores, donde el resultado ya la dice.
    forma_termino        VARCHAR(15)    NULL,  -- Forma en que salió antes que la partida, en cuatro jugadores: `META`, `RENDICION`, `ABANDONO` o `TIEMPO_AGOTADO`.
    conectado            BIT            NOT NULL DEFAULT (1),  -- Estado de conexión; se guarda para sobrevivir a un reinicio (CU-17).
    fecha_desconexion    DATETIME2(0)   NULL,  -- Inicio de la última desconexión, para el plazo de sesenta segundos (CU-15 RN-06); no se borra al reconectar, así que no sustituye a `conectado`.
    terminada            AS (CASE WHEN resultado IS NULL THEN CAST(0 AS BIT) ELSE CAST(1 AS BIT) END),  -- Si la participación está cerrada (D-11). Calculada: es exactamente que `resultado` no sea nulo.
    CONSTRAINT PK_Participacion PRIMARY KEY (id_partida, id_usuario),
    CONSTRAINT UQ_Participacion_turno UNIQUE (id_partida, orden_turno),  -- Dos jugadores no comparten turno en la misma partida.
    CONSTRAINT FK_Participacion_Partida FOREIGN KEY (id_partida) REFERENCES dbo.Partida (id_partida),  -- 1:N | Una partida tiene 2 o 4 participaciones, según su modo.
    CONSTRAINT FK_Participacion_Usuario FOREIGN KEY (id_usuario) REFERENCES dbo.Usuario (id_usuario),  -- 1:N | Un usuario participa en muchas partidas.
    CONSTRAINT CK_Participacion_resultado CHECK (resultado IN ('GANADA','PERDIDA','TABLAS')),
    CONSTRAINT CK_Participacion_forma CHECK (forma_termino IN ('META','TIEMPO_AGOTADO','RENDICION','ABANDONO')),
    CONSTRAINT CK_Participacion_rangos CHECK (orden_turno BETWEEN 1 AND 4 AND posicion BETWEEN 1 AND 4 AND muros_restantes <= 20),
    CONSTRAINT CK_Participacion_conexion CHECK (conectado = 1 OR fecha_desconexion IS NOT NULL)
);
GO
CREATE UNIQUE INDEX UX_Participacion_sin_terminar ON dbo.Participacion (id_usuario) WHERE resultado IS NULL;  -- Una sola participación sin terminar por jugador, (D-11). Filtra por `resultado` porque un índice filtrado no admite columnas calculadas.
GO

-- @entidad Jugada | Movimiento de peón o colocación de muro, en orden. El tablero se reconstruye sumando las jugadas; los muros no tienen tabla propia (CU-12).
-- @fn Llave compuesta; cada atributo describe la jugada entera. `tipo` discrimina qué casillas aplican.
CREATE TABLE dbo.Jugada (
    id_partida           INT            NOT NULL,  -- Partida.
    numero_jugada        SMALLINT       NOT NULL,  -- Número consecutivo dentro de la partida (CU-11 RN-06).
    id_usuario           INT            NOT NULL,  -- Jugador que la hizo. La fase posterior lo vuelve nulo para las jugadas de la IA (DES-09 RN-03).
    tipo                 VARCHAR(10)    NOT NULL,  -- `MOVIMIENTO` o `MURO`. Discrimina qué casillas aplican.
    casilla_origen       VARCHAR(3)     NULL,  -- Casilla de salida del peón; solo en `MOVIMIENTO`.
    casilla_destino      VARCHAR(3)     NULL,  -- Casilla de llegada del peón; solo en `MOVIMIENTO`.
    surco                VARCHAR(3)     NULL,  -- Surco donde se colocó el muro; solo en `MURO`.
    orientacion          VARCHAR(10)    NULL,  -- `HORIZONTAL` o `VERTICAL`; solo en `MURO`.
    tiempo_consumido     INT            NOT NULL,  -- Milisegundos que tardó el jugador.
    fecha_jugada         DATETIME2(3)   NOT NULL DEFAULT (SYSUTCDATETIME()),  -- Momento en que se registró.
    CONSTRAINT PK_Jugada PRIMARY KEY (id_partida, numero_jugada),
    CONSTRAINT FK_Jugada_Partida FOREIGN KEY (id_partida) REFERENCES dbo.Partida (id_partida),  -- 1:N | Una partida tiene muchas jugadas.
    CONSTRAINT FK_Jugada_Participacion FOREIGN KEY (id_partida, id_usuario) REFERENCES dbo.Participacion (id_partida, id_usuario),  -- 1:N | Un participante hace muchas jugadas.
    CONSTRAINT CK_Jugada_tipo CHECK (
        (tipo = 'MOVIMIENTO' AND casilla_origen IS NOT NULL AND casilla_destino IS NOT NULL AND surco IS NULL AND orientacion IS NULL)
        OR (tipo = 'MURO' AND surco IS NOT NULL AND orientacion IN ('HORIZONTAL','VERTICAL') AND casilla_origen IS NULL AND casilla_destino IS NULL)),
    CONSTRAINT CK_Jugada_rangos CHECK (numero_jugada >= 1 AND tiempo_consumido >= 0)
);
GO

-- @entidad OfertaTablas | Oferta de tablas en una partida de dos jugadores (CU-13). Se guarda para la reconexión y como prueba de acoso.
-- @fn Llave simple.
CREATE TABLE dbo.OfertaTablas (
    id_oferta            INT IDENTITY(1,1) NOT NULL,  -- Identificador de la oferta.
    id_partida           INT            NOT NULL,  -- Partida.
    id_ofertante         INT            NOT NULL,  -- Participante que la ofrece.
    numero_jugada        SMALLINT       NOT NULL,  -- Jugada tras la que se ofreció; limita una oferta cada cinco jugadas (CU-13 RN-03).
    fecha_oferta         DATETIME2(0)   NOT NULL DEFAULT (SYSUTCDATETIME()),  -- Momento de la oferta.
    estado               VARCHAR(10)    NOT NULL DEFAULT ('PENDIENTE'),  -- `PENDIENTE`, `ACEPTADA`, `RECHAZADA` o `CADUCADA`.
    fecha_respuesta      DATETIME2(0)   NULL,  -- Momento en que se aceptó, rechazó o caducó.
    CONSTRAINT PK_OfertaTablas PRIMARY KEY (id_oferta),
    CONSTRAINT FK_OfertaTablas_Participacion FOREIGN KEY (id_partida, id_ofertante) REFERENCES dbo.Participacion (id_partida, id_usuario),  -- 1:N | Un participante hace muchas ofertas en su partida.
    CONSTRAINT CK_OfertaTablas_estado CHECK (estado IN ('PENDIENTE','ACEPTADA','RECHAZADA','CADUCADA')),
    CONSTRAINT CK_OfertaTablas_respuesta CHECK ((estado = 'PENDIENTE' AND fecha_respuesta IS NULL) OR (estado <> 'PENDIENTE' AND fecha_respuesta IS NOT NULL))
);
GO
CREATE UNIQUE INDEX UX_OfertaTablas_pendiente ON dbo.OfertaTablas (id_partida) WHERE estado = 'PENDIENTE';  -- A lo sumo una oferta pendiente por partida; la segunda es aceptación (CU-13 RN-04).
GO

/*---------------------------------------------------------------------
  4. Salas y chat
  La cola de emparejamiento y las plazas de cada sala viven en la memoria
  del Servidor de partidas: mueren con las conexiones TCP (D-24).
---------------------------------------------------------------------*/

-- @entidad Sala | Sala privada con código, con los ajustes que elige el anfitrión (CU-08).
-- @fn Llave simple. `codigo` solo es único entre las salas no cerradas, así que no es llave candidata.
CREATE TABLE dbo.Sala (
    id_sala                 INT IDENTITY(1,1) NOT NULL,  -- Identificador de la sala.
    codigo                  CHAR(6)        NOT NULL,  -- Seis caracteres sin 0, O, 1 ni I; único entre las salas no cerradas (CU-08 RN-01).
    id_anfitrion            INT            NOT NULL,  -- Jugador que creó la sala.
    id_modo                 TINYINT        NOT NULL,  -- Modo, que fija el tablero y las plazas.
    muros_por_jugador       TINYINT        NOT NULL,  -- De 1 a 20, elegido por el anfitrión (CU-08 RN-04).
    minutos_reloj           TINYINT        NOT NULL,  -- 3, 5 o 10.
    estado                  VARCHAR(10)    NOT NULL DEFAULT ('ABIERTA'),  -- `ABIERTA`, `EN_PARTIDA` o `CERRADA`.
    id_partida              INT            NULL,  -- Partida que se inició desde la sala.
    fecha_creacion          DATETIME2(0)   NOT NULL DEFAULT (SYSUTCDATETIME()),  -- Creación de la sala.
    fecha_ultima_actividad  DATETIME2(0)   NOT NULL DEFAULT (SYSUTCDATETIME()),  -- Para cerrar la sala a los treinta minutos sin actividad (CU-08 RN-08).
    CONSTRAINT PK_Sala PRIMARY KEY (id_sala),
    CONSTRAINT FK_Sala_Anfitrion FOREIGN KEY (id_anfitrion) REFERENCES dbo.Usuario (id_usuario),  -- 1:N | Un usuario es anfitrión de muchas salas a lo largo del tiempo.
    CONSTRAINT FK_Sala_Modo FOREIGN KEY (id_modo) REFERENCES dbo.Modo (id_modo),  -- 1:N | Un modo se juega en muchas salas.
    CONSTRAINT FK_Sala_Partida FOREIGN KEY (id_partida) REFERENCES dbo.Partida (id_partida),  -- 1:0..1 | Una sala inicia a lo sumo una partida; una partida privada viene de una sala.
    CONSTRAINT CK_Sala_codigo CHECK (codigo LIKE '[A-HJ-NP-Z2-9][A-HJ-NP-Z2-9][A-HJ-NP-Z2-9][A-HJ-NP-Z2-9][A-HJ-NP-Z2-9][A-HJ-NP-Z2-9]' COLLATE Latin1_General_100_BIN2),
    CONSTRAINT CK_Sala_ajustes CHECK (muros_por_jugador BETWEEN 1 AND 20 AND minutos_reloj IN (3, 5, 10)),
    CONSTRAINT CK_Sala_estado CHECK (estado IN ('ABIERTA','EN_PARTIDA','CERRADA')),
    CONSTRAINT CK_Sala_partida CHECK (estado <> 'EN_PARTIDA' OR id_partida IS NOT NULL)
);
GO
CREATE UNIQUE INDEX UX_Sala_codigo ON dbo.Sala (codigo) WHERE estado <> 'CERRADA';  -- El código es único entre las salas no cerradas y puede reutilizarse después (CU-08 RN-01).
CREATE UNIQUE INDEX UX_Sala_partida ON dbo.Sala (id_partida) WHERE id_partida IS NOT NULL;  -- Una partida viene de una sola sala.
GO

-- @entidad Mensaje | Mensaje de chat. Se guarda porque el reporte lo adjunta como prueba (CU-18, CU-25).
-- @fn Llave simple; `canal` discrimina si aplica partida o sala.
CREATE TABLE dbo.Mensaje (
    id_mensaje           BIGINT IDENTITY(1,1) NOT NULL,  -- Identificador del mensaje.
    id_autor             INT            NOT NULL,  -- Jugador que lo escribió.
    canal                VARCHAR(12)    NOT NULL,  -- `PARTIDA` o `SALA` en el núcleo. El CHECK admite ya `ESPECTADORES`, `GLOBAL` y `AMIGOS`, de la fase posterior, porque no necesitan columnas nuevas. Discrimina a qué pertenece el mensaje.
    id_partida           INT            NULL,  -- Partida; solo en los canales `PARTIDA` y `ESPECTADORES`.
    id_sala              INT            NULL,  -- Sala; solo en el canal `SALA`.
    texto                NVARCHAR(500)  NOT NULL,  -- Texto tal como se escribió, en Unicode y sin traducir (CU-18 RN-09).
    fecha_envio          DATETIME2(3)   NOT NULL DEFAULT (SYSUTCDATETIME()),  -- Momento del envío.
    CONSTRAINT PK_Mensaje PRIMARY KEY (id_mensaje),
    CONSTRAINT FK_Mensaje_Autor FOREIGN KEY (id_autor) REFERENCES dbo.Usuario (id_usuario),  -- 1:N | Un usuario escribe muchos mensajes.
    CONSTRAINT FK_Mensaje_Partida FOREIGN KEY (id_partida) REFERENCES dbo.Partida (id_partida),  -- 1:N | Una partida tiene muchos mensajes de jugadores y de espectadores.
    CONSTRAINT FK_Mensaje_Sala FOREIGN KEY (id_sala) REFERENCES dbo.Sala (id_sala),  -- 1:N | Una sala tiene muchos mensajes de espera.
    CONSTRAINT CK_Mensaje_canal CHECK (
        (canal IN ('PARTIDA','ESPECTADORES') AND id_partida IS NOT NULL AND id_sala IS NULL)
        OR (canal = 'SALA' AND id_sala IS NOT NULL AND id_partida IS NULL)
        OR (canal IN ('GLOBAL','AMIGOS') AND id_partida IS NULL AND id_sala IS NULL)),
    CONSTRAINT CK_Mensaje_texto CHECK (LEN(texto) > 0)
);
GO
CREATE INDEX IX_Mensaje_canal ON dbo.Mensaje (canal, id_partida, id_sala, fecha_envio);
GO

/*---------------------------------------------------------------------
  5. Clasificación
---------------------------------------------------------------------*/

-- @entidad EstadisticaModo | Estadísticas y elo de cada cuenta en cada modo, solo de partidas clasificatorias (CU-16 RN-12); es la relación N:M entre Usuario y Modo (relación Tiene del diagrama, ahora por modo, D-04).
-- @fn Llave compuesta usuario-modo; cada contador depende de los dos. Sustituye a la entidad Estadísticas 1:1 del diagrama, que habría obligado a repetir los contadores de cada modo. Sin el derivado porcentaje_victorias. Los contadores son redundancia controlada. En el núcleo guarda solo lo que usan el emparejamiento y la moderación; rachas, máximos y división llegan con la fase posterior (D-22).
CREATE TABLE dbo.EstadisticaModo (
    id_usuario           INT            NOT NULL,  -- Cuenta.
    id_modo              TINYINT        NOT NULL,  -- Modo.
    puntos_elo           SMALLINT       NOT NULL DEFAULT (1000),  -- Elo actual en el modo; lo escribe solo el CU-16.
    fecha_ultima_partida DATETIME2(0)   NULL,  -- Fin de la última partida clasificatoria del modo: cuándo se alcanzó el elo actual; desempata el ranking (CU-23 RN-05).
    partidas_jugadas     INT            NOT NULL DEFAULT (0),  -- Partidas clasificatorias, incluidas las tablas, que no son victoria ni derrota (CU-16 FA-03).
    partidas_ganadas     INT            NOT NULL DEFAULT (0),  -- Victorias. El porcentaje se calcula y no se guarda (DES-08 RN-01).
    partidas_perdidas    INT            NOT NULL DEFAULT (0),  -- Derrotas, incluidas rendiciones y abandonos.
    abandonos            INT            NOT NULL DEFAULT (0),  -- Abandonos en partidas en línea, para la moderación (CU-15 RN-05).
    CONSTRAINT PK_EstadisticaModo PRIMARY KEY (id_usuario, id_modo),
    CONSTRAINT FK_EstadisticaModo_Usuario FOREIGN KEY (id_usuario) REFERENCES dbo.Usuario (id_usuario),  -- 1:N | Un usuario tiene una fila de estadísticas por cada modo.
    CONSTRAINT FK_EstadisticaModo_Modo FOREIGN KEY (id_modo) REFERENCES dbo.Modo (id_modo),  -- 1:N | Un modo tiene estadísticas de muchos usuarios.
    CONSTRAINT CK_EstadisticaModo_contadores CHECK (partidas_ganadas + partidas_perdidas <= partidas_jugadas
        AND partidas_ganadas >= 0 AND partidas_perdidas >= 0 AND abandonos >= 0)
);
GO
CREATE INDEX IX_EstadisticaModo_ranking ON dbo.EstadisticaModo (id_modo, puntos_elo DESC, fecha_ultima_partida) INCLUDE (partidas_jugadas);
GO

/*---------------------------------------------------------------------
  6. Relaciones entre jugadores
---------------------------------------------------------------------*/

-- @entidad Silencio | Jugador silenciado por otro; solo lo consulta quien silenció (DES-10).
-- @fn Llave compuesta; `fecha_silencio` depende del par completo.
CREATE TABLE dbo.Silencio (
    id_usuario           INT            NOT NULL,  -- Jugador que silencia.
    id_silenciado        INT            NOT NULL,  -- Jugador silenciado.
    fecha_silencio       DATETIME2(0)   NOT NULL DEFAULT (SYSUTCDATETIME()),  -- Momento del silencio.
    CONSTRAINT PK_Silencio PRIMARY KEY (id_usuario, id_silenciado),
    CONSTRAINT FK_Silencio_Usuario FOREIGN KEY (id_usuario) REFERENCES dbo.Usuario (id_usuario),  -- 1:N | Un usuario silencia a muchos (rol quien silencia).
    CONSTRAINT FK_Silencio_Silenciado FOREIGN KEY (id_silenciado) REFERENCES dbo.Usuario (id_usuario),  -- 1:N | Un usuario es silenciado por muchos (rol silenciado).
    CONSTRAINT CK_Silencio_distintos CHECK (id_usuario <> id_silenciado)
);
GO

-- @entidad Bloqueo | Bloqueo entre dos jugadores; impide emparejar, invitar, buscar, solicitar y compartir sala (DES-10 RN-05).
-- @fn Llave compuesta; `fecha_bloqueo` depende del par completo.
CREATE TABLE dbo.Bloqueo (
    id_bloqueador        INT            NOT NULL,  -- Jugador que bloquea.
    id_bloqueado         INT            NOT NULL,  -- Jugador bloqueado.
    fecha_bloqueo        DATETIME2(0)   NOT NULL DEFAULT (SYSUTCDATETIME()),  -- Momento del bloqueo.
    CONSTRAINT PK_Bloqueo PRIMARY KEY (id_bloqueador, id_bloqueado),
    CONSTRAINT FK_Bloqueo_Bloqueador FOREIGN KEY (id_bloqueador) REFERENCES dbo.Usuario (id_usuario),  -- 1:N | Un usuario bloquea a muchos (rol bloqueador).
    CONSTRAINT FK_Bloqueo_Bloqueado FOREIGN KEY (id_bloqueado) REFERENCES dbo.Usuario (id_usuario),  -- 1:N | Un usuario es bloqueado por muchos (rol bloqueado).
    CONSTRAINT CK_Bloqueo_distintos CHECK (id_bloqueador <> id_bloqueado)
);
GO
CREATE INDEX IX_Bloqueo_bloqueado ON dbo.Bloqueo (id_bloqueado);
GO

/*---------------------------------------------------------------------
  7. Moderación y bitácoras
  Nada de lo que produce la moderación se elimina.
---------------------------------------------------------------------*/

-- @entidad Reporte | Denuncia de un jugador contra otro. Las pruebas se adjuntan por referencia a la partida, no por copia (CU-25 RN-01).
-- @fn Llave simple. El motivo es un dominio cerrado con `CHECK`: un catálogo de cinco códigos sin más atributos no aportaba nada (D-23). La partida adjunta se valida con llaves foráneas compuestas hacia *Participacion* (CU-25 RN-09).
CREATE TABLE dbo.Reporte (
    id_reporte           INT IDENTITY(1,1) NOT NULL,  -- Identificador del reporte.
    id_denunciante       INT            NOT NULL,  -- Jugador que reporta (rol reportante del diagrama).
    id_reportado         INT            NOT NULL,  -- Jugador reportado.
    motivo               VARCHAR(25)    NOT NULL,  -- `LENGUAJE_OFENSIVO`, `ACOSO`, `NOMBRE_INAPROPIADO`, `TRAMPAS` o `JUEGO_ANTIDEPORTIVO` (CU-25 RN-08); es la clave de su descripción en los diccionarios de recursos (D-21, D-23).
    descripcion          NVARCHAR(500)  NULL,  -- Texto opcional del denunciante.
    id_partida           INT            NULL,  -- Partida de la que salen las pruebas, si se adjunta; la jugaron el denunciante y el reportado (CU-25 RN-09).
    fecha_reporte        DATETIME2(0)   NOT NULL DEFAULT (SYSUTCDATETIME()),  -- Envío.
    estado               VARCHAR(20)    NOT NULL DEFAULT ('PENDIENTE'),  -- `PENDIENTE`, `EN_REVISION`, `RESUELTO_SIN_SANCION` o `RESUELTO_CON_SANCION`.
    id_moderador         INT            NULL,  -- Moderador que lo tiene en revisión o lo resolvió.
    fecha_asignacion     DATETIME2(0)   NULL,  -- Momento en que se tomó; a los treinta minutos vuelve a la cola (DES-17 RN-03).
    nota_resolucion      NVARCHAR(1000) NULL,  -- Nota obligatoria al resolver (DES-17 RN-07).
    fecha_resolucion     DATETIME2(0)   NULL,  -- Momento de la resolución.
    CONSTRAINT PK_Reporte PRIMARY KEY (id_reporte),
    CONSTRAINT FK_Reporte_Denunciante FOREIGN KEY (id_denunciante) REFERENCES dbo.Usuario (id_usuario),  -- 1:N | Un usuario emite muchos reportes (relación Emite del diagrama).
    CONSTRAINT FK_Reporte_Reportado FOREIGN KEY (id_reportado) REFERENCES dbo.Usuario (id_usuario),  -- 1:N | Un usuario recibe muchos reportes (relación Señala del diagrama).
    CONSTRAINT FK_Reporte_ParticipacionDenunciante FOREIGN KEY (id_partida, id_denunciante) REFERENCES dbo.Participacion (id_partida, id_usuario),  -- 1:N | La partida adjunta es una que jugó el denunciante (CU-25 RN-09; relación Sobre del diagrama).
    CONSTRAINT FK_Reporte_ParticipacionReportado FOREIGN KEY (id_partida, id_reportado) REFERENCES dbo.Participacion (id_partida, id_usuario),  -- 1:N | La partida adjunta es una que jugó el reportado (CU-25 RN-09).
    CONSTRAINT FK_Reporte_Moderador FOREIGN KEY (id_moderador) REFERENCES dbo.Usuario (id_usuario),  -- 1:N | Un moderador revisa muchos reportes.
    CONSTRAINT CK_Reporte_distintos CHECK (id_denunciante <> id_reportado),
    CONSTRAINT CK_Reporte_motivo CHECK (motivo IN ('LENGUAJE_OFENSIVO','ACOSO','NOMBRE_INAPROPIADO','TRAMPAS','JUEGO_ANTIDEPORTIVO')),
    CONSTRAINT CK_Reporte_estado CHECK (
        (estado = 'PENDIENTE' AND id_moderador IS NULL AND fecha_asignacion IS NULL AND fecha_resolucion IS NULL)
        OR (estado = 'EN_REVISION' AND id_moderador IS NOT NULL AND fecha_asignacion IS NOT NULL AND fecha_resolucion IS NULL)
        OR (estado IN ('RESUELTO_SIN_SANCION','RESUELTO_CON_SANCION') AND id_moderador IS NOT NULL
            AND nota_resolucion IS NOT NULL AND fecha_resolucion IS NOT NULL))
);
GO
CREATE UNIQUE INDEX UX_Reporte_partida ON dbo.Reporte (id_denunciante, id_reportado, id_partida) WHERE id_partida IS NOT NULL;  -- No se reporta dos veces al mismo jugador por la misma partida (CU-25 RN-03).
CREATE INDEX IX_Reporte_cola ON dbo.Reporte (estado, fecha_reporte);
GO

-- @entidad Sancion | Sanción aplicada por un moderador, de ámbito de cuenta o de chat (D-05). Sustituye al Baneo del diagrama; al retirarse se desactiva, no se borra.
-- @fn Llave simple. `activa` pasó a calculada porque dependía de `fecha_retiro`. Sin num_reportes ni activo del Baneo del diagrama, que eran derivados. `tipo` es discriminador.
CREATE TABLE dbo.Sancion (
    id_sancion             INT IDENTITY(1,1) NOT NULL,  -- Identificador de la sanción.
    id_usuario             INT            NOT NULL,  -- Jugador sancionado.
    id_moderador           INT            NOT NULL,  -- Moderador que la aplicó; la conserva aunque se le retire el rol (DES-21 RN-03).
    id_reporte             INT            NULL,  -- Reporte que la originó, si lo hay.
    ambito                 VARCHAR(10)    NOT NULL,  -- `CUENTA` o `CHAT` (DES-18 RN-03).
    tipo                   VARCHAR(10)    NOT NULL,  -- `TEMPORAL` o `PERMANENTE`. Discrimina si aplica `fecha_fin`.
    motivo                 NVARCHAR(500)  NOT NULL,  -- Lo que comprobó el moderador (DES-18 RN-06).
    fecha_inicio           DATETIME2(0)   NOT NULL DEFAULT (SYSUTCDATETIME()),  -- Inicio de la sanción.
    fecha_fin              DATETIME2(0)   NULL,  -- Fin de una sanción temporal; nula si es permanente (DES-18 RN-04).
    fecha_retiro           DATETIME2(0)   NULL,  -- Retiro manual por apelación o por sustitución (DES-17 RN-06).
    id_sancion_sustituta   INT            NULL,  -- Sanción del mismo ámbito que la sustituyó (DES-18 RN-09).
    activa                 AS (CASE WHEN fecha_retiro IS NULL THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END),  -- Si no fue retirada. Calculada: es exactamente que `fecha_retiro` sea nula. Que surta efecto hoy depende además de `fecha_fin`.
    CONSTRAINT PK_Sancion PRIMARY KEY (id_sancion),
    CONSTRAINT FK_Sancion_Usuario FOREIGN KEY (id_usuario) REFERENCES dbo.Usuario (id_usuario),  -- 1:N | Un usuario recibe muchas sanciones (relación Recibe del diagrama).
    CONSTRAINT FK_Sancion_Moderador FOREIGN KEY (id_moderador) REFERENCES dbo.Usuario (id_usuario),  -- 1:N | Un moderador aplica muchas sanciones.
    CONSTRAINT FK_Sancion_Reporte FOREIGN KEY (id_reporte) REFERENCES dbo.Reporte (id_reporte),  -- 1:N | Un reporte origina ninguna, una o varias sanciones (relación Origina del diagrama).
    CONSTRAINT FK_Sancion_Sustituta FOREIGN KEY (id_sancion_sustituta) REFERENCES dbo.Sancion (id_sancion),  -- 1:0..1 | Una sanción puede ser sustituida por otra posterior.
    CONSTRAINT CK_Sancion_ambito CHECK (ambito IN ('CUENTA','CHAT')),
    CONSTRAINT CK_Sancion_tipo CHECK (
        (tipo = 'TEMPORAL' AND fecha_fin IS NOT NULL AND fecha_fin > fecha_inicio)
        OR (tipo = 'PERMANENTE' AND fecha_fin IS NULL)),
    CONSTRAINT CK_Sancion_sustitucion CHECK (id_sancion_sustituta IS NULL OR fecha_retiro IS NOT NULL),
    CONSTRAINT CK_Sancion_distintos CHECK (id_usuario <> id_moderador)
);
GO
CREATE INDEX IX_Sancion_usuario ON dbo.Sancion (id_usuario, ambito) WHERE fecha_retiro IS NULL;
GO

-- @entidad Apelacion | Apelación de una sanción por parte del sancionado; hay a lo sumo una por sanción (DES-19 RN-01).
-- @fn Llave sustituta; `id_sancion` es llave candidata.
CREATE TABLE dbo.Apelacion (
    id_apelacion         INT IDENTITY(1,1) NOT NULL,  -- Identificador de la apelación.
    id_sancion           INT            NOT NULL,  -- Sanción apelada.
    texto                NVARCHAR(1000) NOT NULL,  -- Texto del sancionado; no se rechaza por lenguaje (DES-19 RN-04).
    marca_lenguaje       BIT            NOT NULL DEFAULT (0),  -- Si el filtro de palabras encontró un término, como aviso al moderador.
    fecha_apelacion      DATETIME2(0)   NOT NULL DEFAULT (SYSUTCDATETIME()),  -- Envío.
    estado               VARCHAR(12)    NOT NULL DEFAULT ('PENDIENTE'),  -- `PENDIENTE`, `EN_REVISION`, `ACEPTADA` o `RECHAZADA`.
    id_moderador         INT            NULL,  -- Moderador que la revisa; distinto del que aplicó la sanción (DES-19 RN-06).
    fecha_asignacion     DATETIME2(0)   NULL,  -- Momento en que se tomó; a los treinta minutos vuelve a la cola (DES-17 RN-03).
    nota_resolucion      NVARCHAR(1000) NULL,  -- Nota obligatoria al resolver.
    fecha_resolucion     DATETIME2(0)   NULL,  -- Momento de la resolución.
    CONSTRAINT PK_Apelacion PRIMARY KEY (id_apelacion),
    CONSTRAINT UQ_Apelacion_sancion UNIQUE (id_sancion),  -- Una sola apelación por sanción (DES-19 RN-01).
    CONSTRAINT FK_Apelacion_Sancion FOREIGN KEY (id_sancion) REFERENCES dbo.Sancion (id_sancion),  -- 1:0..1 | Una sanción tiene a lo sumo una apelación.
    CONSTRAINT FK_Apelacion_Moderador FOREIGN KEY (id_moderador) REFERENCES dbo.Usuario (id_usuario),  -- 1:N | Un moderador resuelve muchas apelaciones.
    CONSTRAINT CK_Apelacion_estado CHECK (
        (estado = 'PENDIENTE' AND id_moderador IS NULL AND fecha_asignacion IS NULL AND fecha_resolucion IS NULL)
        OR (estado = 'EN_REVISION' AND id_moderador IS NOT NULL AND fecha_asignacion IS NOT NULL AND fecha_resolucion IS NULL)
        OR (estado IN ('ACEPTADA','RECHAZADA') AND id_moderador IS NOT NULL AND nota_resolucion IS NOT NULL AND fecha_resolucion IS NOT NULL))
);
GO

-- @entidad BitacoraModeracion | Registro de cada acción de moderación y administración, incluida la consulta de las bitácoras (DES-22 RN-04). Solo admite inserción.
-- @fn Llave simple; solo admite inserción.
CREATE TABLE dbo.BitacoraModeracion (
    id_bitacora          BIGINT IDENTITY(1,1) NOT NULL,  -- Identificador del registro.
    id_moderador         INT            NOT NULL,  -- Usuario que actuó: moderador, administrador o quien intentó actuar sin rol.
    accion               VARCHAR(30)    NOT NULL,  -- `REPORTE_TOMADO`, `REPORTE_LIBERADO`, `REPORTE_RESUELTO`, `SANCION_APLICADA`, `APELACION_RESUELTA`, `ROL_OTORGADO`, `ROL_RETIRADO`, `CONSULTA_BITACORA` o `INTENTO_SIN_PERMISO`.
    id_usuario_afectado  INT            NULL,  -- Usuario sobre el que se actuó, si lo hay.
    detalle              NVARCHAR(1000) NULL,  -- Motivo, reporte, sanción o filtros de la acción.
    fecha_hora           DATETIME2(0)   NOT NULL DEFAULT (SYSUTCDATETIME()),  -- Momento de la acción.
    CONSTRAINT PK_BitacoraModeracion PRIMARY KEY (id_bitacora),
    CONSTRAINT FK_BitacoraModeracion_Moderador FOREIGN KEY (id_moderador) REFERENCES dbo.Usuario (id_usuario),  -- 1:N | Un usuario realiza muchas acciones registradas (rol autor).
    CONSTRAINT FK_BitacoraModeracion_Afectado FOREIGN KEY (id_usuario_afectado) REFERENCES dbo.Usuario (id_usuario),  -- 1:N | Un usuario es objeto de muchas acciones (rol afectado).
    CONSTRAINT CK_BitacoraModeracion_accion CHECK (accion IN ('REPORTE_TOMADO','REPORTE_LIBERADO','REPORTE_RESUELTO','SANCION_APLICADA',
        'APELACION_RESUELTA','ROL_OTORGADO','ROL_RETIRADO','CONSULTA_BITACORA','INTENTO_SIN_PERMISO'))
);
GO

-- @entidad BitacoraAcceso | Registro de cada intento de acceso y de cada cambio de credenciales, exitoso o no. Nunca contiene contraseñas ni códigos (DES-22 RN-05).
-- @fn Llave simple; solo admite inserción.
CREATE TABLE dbo.BitacoraAcceso (
    id_bitacora             BIGINT IDENTITY(1,1) NOT NULL,  -- Identificador del registro.
    id_usuario              INT            NULL,  -- Cuenta, si se identificó; nula en intentos contra cuentas inexistentes.
    identificador_capturado NVARCHAR(254)  NULL,  -- Nickname o correo tecleado; único rastro de un intento contra una cuenta inexistente (DES-22 RN-06).
    resultado               VARCHAR(40)    NOT NULL,  -- Uno de los 26 resultados de la tabla de dominios del análisis CRUD, por ejemplo `EXITO`, `CONTRASENA_INCORRECTA` o `CUENTA_ELIMINADA`.
    direccion_ip            VARCHAR(45)    NOT NULL,  -- Dirección de red de origen.
    fecha_hora              DATETIME2(0)   NOT NULL DEFAULT (SYSUTCDATETIME()),  -- Momento del intento.
    CONSTRAINT PK_BitacoraAcceso PRIMARY KEY (id_bitacora),
    CONSTRAINT FK_BitacoraAcceso_Usuario FOREIGN KEY (id_usuario) REFERENCES dbo.Usuario (id_usuario),  -- 1:N | Una cuenta acumula muchos registros de acceso.
    CONSTRAINT CK_BitacoraAcceso_resultado CHECK (resultado IN ('EXITO','USUARIO_INEXISTENTE','BLOQUEO_VIGENTE','CONTRASENA_INCORRECTA','CUENTA_PENDIENTE','CUENTA_SANCIONADA',
        'SEGUNDO_FACTOR_FALLIDO','ABANDONADO','SUSPENSION_VENCIDA','REGISTRO_EXITOSO','REGISTRO_RECHAZADO','REGISTRO_SIN_CORREO',
        'ALTA_INVITADO','VINCULACION_EXITOSA','CUENTA_VERIFICADA','RECUPERACION_SOLICITADA','RECUPERACION_CORREO_INEXISTENTE',
        'RECUPERACION_EXITOSA','CIERRE_VOLUNTARIO','CIERRE_REMOTO','CAMBIO_CONTRASENA','CAMBIO_CORREO_SOLICITADO',
        'CAMBIO_CORREO_CONFIRMADO','SEGUNDO_FACTOR_ACTIVADO','SEGUNDO_FACTOR_DESACTIVADO','CUENTA_ELIMINADA'))
);
GO
CREATE INDEX IX_BitacoraAcceso_fecha ON dbo.BitacoraAcceso (fecha_hora, direccion_ip);
GO

/*---------------------------------------------------------------------
  8. Procedimientos para las eliminaciones físicas
  El usuario de conexión no tiene permiso DELETE. Las únicas filas que
  la aplicación borra en el núcleo (silencios y bloqueos) se borran con
  estos procedimientos, que pertenecen a dbo igual que las tablas: por el
  encadenamiento de propiedad, SQL Server no comprueba el permiso
  DELETE de quien ejecuta, solo su permiso EXECUTE.
---------------------------------------------------------------------*/

-- CU-08 FA-09, CU-16 paso 10: la sala se cierra por inactividad, al salir el anfitrión o al terminar su partida.
-- Quién ocupa cada plaza lo lleva el Servidor de partidas en memoria (D-24).
CREATE PROCEDURE dbo.usp_Sala_Cerrar
    @id_sala INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.Sala SET estado = 'CERRADA' WHERE id_sala = @id_sala AND estado <> 'CERRADA';
    SELECT @@ROWCOUNT AS filas_actualizadas;
END;
GO

-- DES-10 FA-07: dejar de silenciar.
CREATE PROCEDURE dbo.usp_Silencio_Eliminar
    @id_usuario    INT,
    @id_silenciado INT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM dbo.Silencio WHERE id_usuario = @id_usuario AND id_silenciado = @id_silenciado;
    SELECT @@ROWCOUNT AS filas_eliminadas;
END;
GO

-- DES-10 FA-07: desbloquear. No restaura la amistad eliminada (DES-10 RN-06).
CREATE PROCEDURE dbo.usp_Bloqueo_Eliminar
    @id_bloqueador INT,
    @id_bloqueado  INT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM dbo.Bloqueo WHERE id_bloqueador = @id_bloqueador AND id_bloqueado = @id_bloqueado;
    SELECT @@ROWCOUNT AS filas_eliminadas;
END;
GO

-- DES-10 pasos 7 a 9: bloquear. En el núcleo solo registra el bloqueo; la fase posterior
-- redefine el procedimiento para borrar además la amistad, las solicitudes y las invitaciones
-- del par. Si comparten sala, el Servidor de partidas retira a uno de los dos en memoria (D-24).
CREATE PROCEDURE dbo.usp_Bloqueo_Aplicar
    @id_bloqueador INT,
    @id_bloqueado  INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM dbo.Bloqueo WHERE id_bloqueador = @id_bloqueador AND id_bloqueado = @id_bloqueado)
        INSERT INTO dbo.Bloqueo (id_bloqueador, id_bloqueado) VALUES (@id_bloqueador, @id_bloqueado);
END;
GO

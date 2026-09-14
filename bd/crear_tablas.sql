/*=====================================================================
  Bastion - Creación de tablas (2 de 3)
  Motor: SQL Server 2019 o posterior (CON-04); probado en SQL Server 2025.

  Orden de ejecución:
     1. crear_base_datos.sql
     2. crear_tablas.sql          <- este archivo
     3. insertar_datos_prueba.sql

  Crea, en la base Bastion vacía, las tablas con sus llaves primarias y
  foráneas, sus restricciones NOT NULL, UNIQUE, CHECK y DEFAULT, los
  índices y los procedimientos almacenados. Las tablas van en orden de
  dependencias: ninguna llave foránea apunta a una tabla que aún no
  exista.

  Contenido:
     1. Catálogos precargados (D-09)
     2. Cuenta y acceso
     3. Perfil y personalización
     4. Partida
     5. Emparejamiento, salas y chat
     6. Clasificación y economía
     7. Relaciones entre jugadores y tutorial
     8. Moderación y bitácoras
     9. Procedimientos para las eliminaciones físicas

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
    - Nada se guarda traducido: los catálogos guardan un `codigo` que
      es la clave de su nombre en los diccionarios de recursos (D-21).
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

-- @entidad Ranura | Catálogo de las seis ranuras de personalización: peón, muro, tablero, título, marco y emotes (D-03).
-- @fn Llave simple; `codigo` depende solo de ella y es llave candidata.
CREATE TABLE dbo.Ranura (
    id_ranura          TINYINT        NOT NULL,  -- Identificador de la ranura.
    codigo             VARCHAR(20)    NOT NULL,  -- Clave de la ranura en los diccionarios de recursos (D-21): `PEON`, `MURO`, `TABLERO`, `TITULO`, `MARCO` o `EMOTES`. Sin CHECK: añadir una ranura es insertar una fila (CU-14).
    CONSTRAINT PK_Ranura PRIMARY KEY (id_ranura),
    CONSTRAINT UQ_Ranura_codigo UNIQUE (codigo)  -- Dos ranuras no tienen la misma clave.
);
GO

-- @entidad ObjetoCosmetico | Catálogo de objetos cosméticos. Cada objeto pertenece a una sola ranura (D-03).
-- @fn Llave simple; `codigo` es llave candidata. De la ranura se guarda solo su llave, no sus datos. (id_objeto, id_ranura) es superllave, no llave candidata: existe para las llaves foráneas compuestas.
CREATE TABLE dbo.ObjetoCosmetico (
    id_objeto          INT            NOT NULL,  -- Identificador del objeto.
    id_ranura          TINYINT        NOT NULL,  -- Ranura en la que se equipa.
    codigo             VARCHAR(40)    NOT NULL,  -- Clave del objeto en los diccionarios de recursos, como `PEON_CLASICO`; con ella el cliente muestra su nombre en el idioma del usuario (D-21).
    rareza             VARCHAR(10)    NOT NULL,  -- `COMUN`, `RARO`, `EPICO` o `LEGENDARIO`.
    precio             INT            NOT NULL DEFAULT (0),  -- Precio en monedas del juego; el válido es este y no el del cliente (CU-38 RN-03).
    nivel_requerido    SMALLINT       NOT NULL DEFAULT (1),  -- Nivel mínimo para comprarlo (CU-38 RN-04).
    a_la_venta         BIT            NOT NULL DEFAULT (0),  -- Si se ofrece en la tienda.
    activo             BIT            NOT NULL DEFAULT (1),  -- En falso, retirado del catálogo; quien lo tiene equipado lo conserva (CU-14 RN-04).
    es_inicial         BIT            NOT NULL DEFAULT (0),  -- Se otorga al dar de alta la cuenta.
    es_predeterminado  BIT            NOT NULL DEFAULT (0),  -- Se equipa al dar de alta; exactamente uno por ranura.
    CONSTRAINT PK_ObjetoCosmetico PRIMARY KEY (id_objeto),
    CONSTRAINT UQ_ObjetoCosmetico_codigo UNIQUE (codigo),  -- Dos objetos no tienen la misma clave.
    CONSTRAINT UQ_ObjetoCosmetico_objeto_ranura UNIQUE (id_objeto, id_ranura),  -- Superclave que usan Equipamiento y ParticipacionObjeto para exigir que el objeto sea de la ranura.
    CONSTRAINT FK_ObjetoCosmetico_Ranura FOREIGN KEY (id_ranura) REFERENCES dbo.Ranura (id_ranura),  -- 1:N | Una ranura agrupa muchos objetos; cada objeto pertenece a una ranura.
    CONSTRAINT CK_ObjetoCosmetico_rareza CHECK (rareza IN ('COMUN','RARO','EPICO','LEGENDARIO')),
    CONSTRAINT CK_ObjetoCosmetico_rangos CHECK (precio >= 0 AND nivel_requerido >= 1),
    CONSTRAINT CK_ObjetoCosmetico_predeterminado CHECK (es_predeterminado = 0 OR es_inicial = 1),
    CONSTRAINT CK_ObjetoCosmetico_venta CHECK (a_la_venta = 0 OR activo = 1)  -- Un objeto retirado no se vende: los dos indicadores no pueden contradecirse.
);
GO
CREATE UNIQUE INDEX UX_ObjetoCosmetico_predeterminado ON dbo.ObjetoCosmetico (id_ranura) WHERE es_predeterminado = 1;  -- Un solo objeto predeterminado por ranura (CU-02 PRE-05).
GO

-- @entidad Modo | Catálogo de modos de juego; cada modo fija tablero, jugadores y muros (D-04).
-- @fn Llave simple; `codigo` es llave candidata. Recoge num_jugadores, que en el diagrama estaba en *Partida* y dependía de ella a través del modo.
CREATE TABLE dbo.Modo (
    id_modo            TINYINT        NOT NULL,  -- Identificador del modo.
    codigo             VARCHAR(40)    NOT NULL,  -- Clave del modo en los diccionarios de recursos (D-21): `CLASICO`, `CUATRO_JUGADORES` o `RAPIDA`.
    tamano_tablero     TINYINT        NOT NULL,  -- Casillas por lado: 7 o 9.
    num_jugadores      TINYINT        NOT NULL,  -- Plazas de la partida: 2 o 4 (CU-17 RN-02).
    muros_por_jugador  TINYINT        NOT NULL,  -- Muros de cada jugador: 10, 5 o 6 (CU-21 RN-02).
    activo             BIT            NOT NULL DEFAULT (1),  -- Solo los modos activos reciben estadísticas al dar de alta (CU-02).
    CONSTRAINT PK_Modo PRIMARY KEY (id_modo),
    CONSTRAINT UQ_Modo_codigo UNIQUE (codigo),  -- Dos modos no tienen la misma clave.
    CONSTRAINT CK_Modo_parametros CHECK (tamano_tablero IN (7, 9) AND num_jugadores IN (2, 4) AND muros_por_jugador BETWEEN 1 AND 20)
);
GO

-- @entidad Division | Catálogo de divisiones del ranking con sus umbrales de ascenso y descenso.
-- @fn Llave simple; `codigo` y `elo_minimo` son llaves candidatas. El orden de las divisiones es el de `elo_minimo`; guardar además una posición repetiría ese dato.
CREATE TABLE dbo.Division (
    id_division        TINYINT        NOT NULL,  -- Identificador de la división.
    codigo             VARCHAR(40)    NOT NULL,  -- Clave de la división en los diccionarios de recursos (D-21), como `BRONCE` o `MURO_PIEDRA`.
    elo_minimo         SMALLINT       NOT NULL,  -- Elo con el que se asciende a esta división; ordena las divisiones de la más baja a la más alta.
    elo_descenso       SMALLINT       NOT NULL,  -- Elo por debajo del cual se desciende; es el umbral visible (CU-25 RN-07).
    CONSTRAINT PK_Division PRIMARY KEY (id_division),
    CONSTRAINT UQ_Division_codigo UNIQUE (codigo),  -- Dos divisiones no tienen la misma clave.
    CONSTRAINT UQ_Division_elo_minimo UNIQUE (elo_minimo),  -- Dos divisiones no empiezan en el mismo elo, así que el orden no tiene empates.
    CONSTRAINT CK_Division_umbral CHECK (elo_descenso <= elo_minimo)
);
GO

-- @entidad NivelIA | Catálogo de los cuatro niveles de la IA (CU-27 RN-02).
-- @fn Llave simple; `codigo` es llave candidata.
CREATE TABLE dbo.NivelIA (
    id_nivel_ia        TINYINT        NOT NULL,  -- Identificador del nivel.
    codigo             VARCHAR(40)    NOT NULL,  -- Clave del nivel en los diccionarios de recursos (D-21): `APRENDIZ`, `CONSTRUCTOR`, `ARQUITECTO` o `BASTION`.
    elo_aproximado     SMALLINT       NOT NULL,  -- Fuerza aproximada: 1000, 1500, 1900 o 2300.
    CONSTRAINT PK_NivelIA PRIMARY KEY (id_nivel_ia),
    CONSTRAINT UQ_NivelIA_codigo UNIQUE (codigo)  -- Dos niveles no tienen la misma clave.
);
GO

-- @entidad Leccion | Catálogo de las siete lecciones del tutorial (CU-41 RN-01).
-- @fn Llave simple; `codigo` y `orden` son llaves candidatas.
CREATE TABLE dbo.Leccion (
    id_leccion         TINYINT        NOT NULL,  -- Identificador de la lección.
    codigo             VARCHAR(40)    NOT NULL,  -- Clave de la lección en los diccionarios de recursos (D-21), como `MOVER_PEON`; los textos de sus pasos también están en ellos.
    orden              TINYINT        NOT NULL,  -- Posición en el índice del tutorial.
    num_pasos          TINYINT        NOT NULL,  -- Pasos de la lección.
    CONSTRAINT PK_Leccion PRIMARY KEY (id_leccion),
    CONSTRAINT UQ_Leccion_codigo UNIQUE (codigo),  -- Dos lecciones no tienen la misma clave.
    CONSTRAINT UQ_Leccion_orden UNIQUE (orden),  -- Dos lecciones no ocupan la misma posición.
    CONSTRAINT CK_Leccion_pasos CHECK (num_pasos > 0)
);
GO

-- @entidad TipoCaja | Catálogo de tipos de caja que se venden o se otorgan (CU-39).
-- @fn Llave simple; `codigo` es llave candidata.
CREATE TABLE dbo.TipoCaja (
    id_tipo_caja       TINYINT        NOT NULL,  -- Identificador del tipo de caja.
    codigo             VARCHAR(40)    NOT NULL,  -- Clave del tipo de caja en los diccionarios de recursos (D-21), como `CAJA_MADERA`.
    precio             INT            NOT NULL,  -- Precio en monedas del juego.
    activo             BIT            NOT NULL DEFAULT (1),  -- En falso, ya no se vende.
    CONSTRAINT PK_TipoCaja PRIMARY KEY (id_tipo_caja),
    CONSTRAINT UQ_TipoCaja_codigo UNIQUE (codigo),  -- Dos tipos de caja no tienen la misma clave.
    CONSTRAINT CK_TipoCaja_precio CHECK (precio >= 0)
);
GO

-- @entidad TipoCajaObjeto | Objetos que puede contener cada tipo de caja y su probabilidad; es la relación N:M entre TipoCaja y ObjetoCosmetico.
-- @fn Llave compuesta; `probabilidad` depende del par completo: el mismo objeto tiene probabilidades distintas en cajas distintas.
CREATE TABLE dbo.TipoCajaObjeto (
    id_tipo_caja       TINYINT        NOT NULL,  -- Tipo de caja.
    id_objeto          INT            NOT NULL,  -- Objeto que puede salir.
    probabilidad       DECIMAL(6,3)   NOT NULL,  -- Porcentaje exacto que se muestra antes de comprar (CU-39 RN-01).
    CONSTRAINT PK_TipoCajaObjeto PRIMARY KEY (id_tipo_caja, id_objeto),
    CONSTRAINT FK_TipoCajaObjeto_TipoCaja FOREIGN KEY (id_tipo_caja) REFERENCES dbo.TipoCaja (id_tipo_caja),  -- 1:N | Un tipo de caja tiene muchos objetos posibles.
    CONSTRAINT FK_TipoCajaObjeto_ObjetoCosmetico FOREIGN KEY (id_objeto) REFERENCES dbo.ObjetoCosmetico (id_objeto),  -- 1:N | Un objeto puede salir en muchos tipos de caja.
    CONSTRAINT CK_TipoCajaObjeto_probabilidad CHECK (probabilidad > 0 AND probabilidad <= 100)
);
GO

-- @entidad PalabraProhibida | Catálogo del filtro de palabras que se aplica en el servidor al nickname y al chat (CON-09).
-- @fn Llave sustituta; la natural (`termino`, `idioma`, `ambito`) se declara única. Sin indicador de activo: ninguna tabla referencia el catálogo, así que un término que deja de filtrarse se borra por SQL (D-09).
CREATE TABLE dbo.PalabraProhibida (
    id_palabra         INT IDENTITY(1,1) NOT NULL,  -- Identificador del término.
    termino            NVARCHAR(100) COLLATE Latin1_General_100_CI_AI_SC_UTF8 NOT NULL,  -- Término prohibido, con sus eñes y acentos; se compara sin mayúsculas ni acentos.
    idioma             VARCHAR(10)    NULL,  -- Idioma del término: `es-MX` o `en`; nulo si se filtra en todos los idiomas (CU-28 RN-01).
    ambito             VARCHAR(10)    NOT NULL,  -- `NICKNAME`, `CHAT` o `AMBOS`.
    CONSTRAINT PK_PalabraProhibida PRIMARY KEY (id_palabra),
    CONSTRAINT UQ_PalabraProhibida_termino UNIQUE (termino, idioma, ambito),  -- Un término no se repite en el mismo idioma y ámbito.
    CONSTRAINT CK_PalabraProhibida_idioma CHECK (idioma IN ('es-MX','en')),  -- Idiomas admitidos (D-21); un nulo pasa la comprobación.
    CONSTRAINT CK_PalabraProhibida_ambito CHECK (ambito IN ('NICKNAME','CHAT','AMBOS'))
);
GO

-- @entidad MotivoReporte | Catálogo de los cinco motivos de reporte (CU-42 RN-08).
-- @fn Llave simple; `codigo` es llave candidata. Sustituye al texto `motivo` del *Reporte* del diagrama, que repetía la misma descripción en cada reporte.
CREATE TABLE dbo.MotivoReporte (
    id_motivo          TINYINT        NOT NULL,  -- Identificador del motivo.
    codigo             VARCHAR(40)    NOT NULL,  -- Clave del motivo en los diccionarios de recursos (D-21), como `LENGUAJE_OFENSIVO`; con ella el cliente muestra su descripción.
    CONSTRAINT PK_MotivoReporte PRIMARY KEY (id_motivo),
    CONSTRAINT UQ_MotivoReporte_codigo UNIQUE (codigo)  -- Dos motivos no tienen la misma clave.
);
GO

/*---------------------------------------------------------------------
  2. Cuenta y acceso
---------------------------------------------------------------------*/

-- @entidad Usuario | Cuenta de un jugador, invitado, moderador o administrador. Es la entidad central: casi todas las demás dependen de ella y su fila nunca se borra (D-07, D-17).
-- @fn Llave simple; `nickname` es llave candidata. Sin el atributo compuesto nombre_completo ni el derivado edad del diagrama. `saldo_monedas` es redundancia controlada.
CREATE TABLE dbo.Usuario (
    id_usuario                       INT IDENTITY(1,1) NOT NULL,  -- Identificador de la cuenta; no cambia al vincular un invitado (D-02).
    tipo_cuenta                      VARCHAR(10)    NOT NULL,  -- `INVITADO` o `REGISTRADA`. Discrimina qué credenciales aplican.
    estado_cuenta                    VARCHAR(10)    NOT NULL DEFAULT ('PENDIENTE'),  -- `PENDIENTE`, `ACTIVA`, `SUSPENDIDA`, `BANEADA` o `ELIMINADA` (CU-01 RN-04).
    rol                              VARCHAR(13)    NOT NULL DEFAULT ('JUGADOR'),  -- `JUGADOR`, `MODERADOR` o `ADMINISTRADOR`; exactamente uno (CU-46 RN-03).
    nickname                         NVARCHAR(30) COLLATE Latin1_General_100_CI_AI_SC_UTF8 NOT NULL,  -- Nombre visible, de 3 a 30 caracteres; único sin distinguir mayúsculas ni acentos (CU-02 RN-01).
    correo                           NVARCHAR(254)  NULL,  -- Correo normalizado a minúsculas; nulo solo en invitados (CU-02 RN-02).
    contrasena_hash                  VARBINARY(64)  NULL,  -- Resumen criptográfico de la contraseña; nunca en claro (CU-01 RN-02).
    contrasena_sal                   VARBINARY(32)  NULL,  -- Sal del resumen.
    fecha_nacimiento                 DATE           NULL,  -- Para comprobar la edad mínima de ocho años; la edad no se guarda (CU-02).
    idioma_preferido                 VARCHAR(10)    NOT NULL DEFAULT ('es-MX'),  -- Idioma de la interfaz y de los correos, `es-MX` o `en` (D-21); viaja con el jugador a cualquier dispositivo (CU-12 RN-08).
    codigo_amigo                     CHAR(8)        NULL,  -- Código para encontrar al jugador sin su nickname (CU-30 RN-06).
    id_icono                         TINYINT        NOT NULL DEFAULT (1),  -- Icono predefinido, de 1 a 32 (CU-08 RN-03).
    permite_espectadores             BIT            NOT NULL DEFAULT (1),  -- Si admite espectadores en sus partidas (CU-34 RN-02).
    nivel                            SMALLINT       NOT NULL DEFAULT (1),  -- Nivel alcanzado.
    experiencia                      INT            NOT NULL DEFAULT (0),  -- Experiencia acumulada.
    saldo_monedas                    INT            NOT NULL DEFAULT (0),  -- Copia de la suma de *MovimientoMoneda*; redundancia controlada (CU-40 RN-02).
    cajas_sin_raro                   TINYINT        NOT NULL DEFAULT (0),  -- Cajas seguidas sin objeto raro, para la garantía (CU-39 RN-05).
    intentos_fallidos                TINYINT        NOT NULL DEFAULT (0),  -- Intentos fallidos consecutivos de inicio de sesión (CU-01 RN-03).
    fecha_ultimo_intento_fallido     DATETIME2(0)   NULL,  -- Para restablecer el contador a las 24 horas (CU-01 RN-03).
    bloqueada_hasta                  DATETIME2(0)   NULL,  -- Fin del bloqueo escalonado vigente.
    doble_factor_habilitado          BIT            NOT NULL DEFAULT (0),  -- Si la cuenta pide segundo factor (CU-01 RN-08).
    fecha_registro                   DATETIME2(0)   NOT NULL DEFAULT (SYSUTCDATETIME()),  -- Alta de la cuenta.
    fecha_configuracion_inicial      DATETIME2(0)   NULL,  -- Marca de la configuración de primera vez (CU-08 RN-01).
    fecha_ultimo_envio_verificacion  DATETIME2(0)   NULL,  -- Último correo de verificación que sí se envió; limita el reenvío (CU-01 RN-10). No sale del token: si el envío falla, el token existe y esta fecha no cambia.
    fecha_ultimo_envio_recuperacion  DATETIME2(0)   NULL,  -- Último correo de recuperación que sí se envió; limita el envío (CU-03 RN-06).
    fecha_baja                       DATETIME2(0)   NULL,  -- Momento de la baja, que es definitiva: la cuenta se anonimiza en la misma transacción (D-07, D-17).
    CONSTRAINT PK_Usuario PRIMARY KEY (id_usuario),
    CONSTRAINT UQ_Usuario_nickname UNIQUE (nickname),  -- El nickname es identificador de acceso (CU-01 RN-14).
    CONSTRAINT CK_Usuario_tipo_cuenta CHECK (tipo_cuenta IN ('INVITADO','REGISTRADA')),
    CONSTRAINT CK_Usuario_estado_cuenta CHECK (estado_cuenta IN ('PENDIENTE','ACTIVA','SUSPENDIDA','BANEADA','ELIMINADA')),
    CONSTRAINT CK_Usuario_rol CHECK (rol IN ('JUGADOR','MODERADOR','ADMINISTRADOR')),
    CONSTRAINT CK_Usuario_idioma CHECK (idioma_preferido IN ('es-MX','en')),  -- Idiomas admitidos (D-21); otro se rechaza (CU-12 FA-07).
    CONSTRAINT CK_Usuario_credenciales CHECK (
        (tipo_cuenta = 'INVITADO' AND correo IS NULL AND contrasena_hash IS NULL AND contrasena_sal IS NULL)
        OR (tipo_cuenta = 'REGISTRADA' AND correo IS NOT NULL)),
    CONSTRAINT CK_Usuario_rol_registrada CHECK (rol = 'JUGADOR' OR tipo_cuenta = 'REGISTRADA'),
    CONSTRAINT CK_Usuario_baja CHECK (
        (estado_cuenta = 'ELIMINADA' AND fecha_baja IS NOT NULL)
        OR (estado_cuenta <> 'ELIMINADA' AND fecha_baja IS NULL)),
    CONSTRAINT CK_Usuario_rangos CHECK (id_icono BETWEEN 1 AND 32 AND nivel >= 1 AND experiencia >= 0
        AND saldo_monedas >= 0 AND cajas_sin_raro BETWEEN 0 AND 10)
);
GO
CREATE UNIQUE INDEX UX_Usuario_correo ON dbo.Usuario (correo) WHERE correo IS NOT NULL;  -- El correo es único entre las cuentas que lo tienen (CU-02 RN-02).
CREATE UNIQUE INDEX UX_Usuario_codigo_amigo ON dbo.Usuario (codigo_amigo) WHERE codigo_amigo IS NOT NULL;  -- El código de amigo es único por cuenta (CU-30 RN-06).
GO

-- @entidad Sesion | Sesión abierta desde un dispositivo. Una cuenta puede tener varias a la vez (D-01); al cerrarse no se borra.
-- @fn Llave simple; `token_hash` es llave candidata.
CREATE TABLE dbo.Sesion (
    id_sesion          INT IDENTITY(1,1) NOT NULL,  -- Identificador de la sesión.
    id_usuario         INT            NOT NULL,  -- Cuenta dueña de la sesión.
    token_hash         VARBINARY(32)  NOT NULL,  -- Resumen del token de sesión.
    fecha_inicio       DATETIME2(0)   NOT NULL DEFAULT (SYSUTCDATETIME()),  -- Apertura de la sesión.
    fecha_expiracion   DATETIME2(0)   NOT NULL,  -- Vigencia máxima de veinticuatro horas (CU-01 RN-07).
    fecha_ultimo_uso   DATETIME2(0)   NOT NULL DEFAULT (SYSUTCDATETIME()),  -- Para reconocer sesiones olvidadas (CU-10); se actualiza por minutos.
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

-- @entidad CodigoSegundoFactor | Código del segundo factor emitido en un inicio de sesión (CU-01 RN-08, RN-09).
-- @fn Llave simple. `estado` sustituye a dos indicadores, consumido e invalidado, que no pueden ser verdaderos a la vez.
CREATE TABLE dbo.CodigoSegundoFactor (
    id_codigo          INT IDENTITY(1,1) NOT NULL,  -- Identificador del código.
    id_usuario         INT            NOT NULL,  -- Cuenta que inicia sesión.
    codigo_hash        VARBINARY(32)  NOT NULL,  -- Resumen del código; nunca en claro (CU-01 RN-02).
    canal              VARCHAR(20)    NOT NULL,  -- Mecanismo de entrega que usó el proveedor del segundo factor.
    fecha_generacion   DATETIME2(0)   NOT NULL DEFAULT (SYSUTCDATETIME()),  -- Emisión del código.
    fecha_expiracion   DATETIME2(0)   NOT NULL,  -- Vigencia de cinco minutos.
    intentos           TINYINT        NOT NULL DEFAULT (0),  -- Intentos de verificación; máximo tres.
    estado             VARCHAR(10)    NOT NULL DEFAULT ('PENDIENTE'),  -- `PENDIENTE`, `CONSUMIDO` o `INVALIDADO`.
    CONSTRAINT PK_CodigoSegundoFactor PRIMARY KEY (id_codigo),
    CONSTRAINT FK_CodigoSegundoFactor_Usuario FOREIGN KEY (id_usuario) REFERENCES dbo.Usuario (id_usuario),  -- 1:N | Un usuario recibe muchos códigos a lo largo del tiempo.
    CONSTRAINT CK_CodigoSegundoFactor_intentos CHECK (intentos BETWEEN 0 AND 3),
    CONSTRAINT CK_CodigoSegundoFactor_estado CHECK (estado IN ('PENDIENTE','CONSUMIDO','INVALIDADO'))
);
GO
CREATE UNIQUE INDEX UX_CodigoSegundoFactor_vigente ON dbo.CodigoSegundoFactor (id_usuario) WHERE estado = 'PENDIENTE';  -- Un solo código vigente por cuenta (CU-01 RN-09).
GO

-- @entidad TokenVerificacionCorreo | Token del enlace que verifica el correo del alta o confirma un cambio de correo (CU-04, D-20).
-- @fn Llave simple; `token_hash` es llave candidata. En `ALTA` no guarda el correo, que sería una copia del de *Usuario*; el correo pendiente vive aquí y no en *Usuario* (CU-09).
CREATE TABLE dbo.TokenVerificacionCorreo (
    id_token           INT IDENTITY(1,1) NOT NULL,  -- Identificador del token.
    id_usuario         INT            NOT NULL,  -- Cuenta a la que pertenece.
    token_hash         VARBINARY(32)  NOT NULL,  -- Resumen del token del enlace (CU-04 RN-06).
    proposito          VARCHAR(15)    NOT NULL,  -- `ALTA` o `CAMBIO_CORREO`.
    correo_destino     NVARCHAR(254)  NULL,  -- Correo nuevo; solo en `CAMBIO_CORREO`. En `ALTA` es el de la cuenta y no se repite.
    fecha_generacion   DATETIME2(0)   NOT NULL DEFAULT (SYSUTCDATETIME()),  -- Emisión del token.
    fecha_expiracion   DATETIME2(0)   NOT NULL,  -- Vigencia de veinticuatro horas (CU-04 RN-02).
    estado             VARCHAR(10)    NOT NULL DEFAULT ('PENDIENTE'),  -- `PENDIENTE`, `USADO` o `INVALIDADO`.
    CONSTRAINT PK_TokenVerificacionCorreo PRIMARY KEY (id_token),
    CONSTRAINT UQ_TokenVerificacionCorreo_token UNIQUE (token_hash),  -- El enlace identifica un solo token.
    CONSTRAINT FK_TokenVerificacionCorreo_Usuario FOREIGN KEY (id_usuario) REFERENCES dbo.Usuario (id_usuario),  -- 1:N | Un usuario recibe muchos tokens de verificación.
    CONSTRAINT CK_TokenVerificacionCorreo_proposito CHECK (
        (proposito = 'ALTA' AND correo_destino IS NULL)
        OR (proposito = 'CAMBIO_CORREO' AND correo_destino IS NOT NULL)),
    CONSTRAINT CK_TokenVerificacionCorreo_estado CHECK (estado IN ('PENDIENTE','USADO','INVALIDADO'))
);
GO
CREATE UNIQUE INDEX UX_TokenVerificacionCorreo_vigente ON dbo.TokenVerificacionCorreo (id_usuario) WHERE estado = 'PENDIENTE';  -- Un solo token de verificación vigente por cuenta (CU-04 RN-03).
GO

-- @entidad TokenRecuperacion | Código enviado por correo para recuperar la contraseña (CU-03).
-- @fn Llave simple.
CREATE TABLE dbo.TokenRecuperacion (
    id_token           INT IDENTITY(1,1) NOT NULL,  -- Identificador del token.
    id_usuario         INT            NOT NULL,  -- Cuenta que se recupera.
    token_hash         VARBINARY(32)  NOT NULL,  -- Resumen del código (CU-03 RN-08).
    fecha_generacion   DATETIME2(0)   NOT NULL DEFAULT (SYSUTCDATETIME()),  -- Emisión del código.
    fecha_expiracion   DATETIME2(0)   NOT NULL,  -- Vigencia de treinta minutos (CU-03 RN-04).
    intentos           TINYINT        NOT NULL DEFAULT (0),  -- Intentos de verificación; máximo tres (CU-03 RN-09).
    estado             VARCHAR(10)    NOT NULL DEFAULT ('PENDIENTE'),  -- `PENDIENTE`, `USADO` o `INVALIDADO`.
    CONSTRAINT PK_TokenRecuperacion PRIMARY KEY (id_token),
    CONSTRAINT FK_TokenRecuperacion_Usuario FOREIGN KEY (id_usuario) REFERENCES dbo.Usuario (id_usuario),  -- 1:N | Un usuario solicita muchas recuperaciones a lo largo del tiempo.
    CONSTRAINT CK_TokenRecuperacion_intentos CHECK (intentos BETWEEN 0 AND 3),
    CONSTRAINT CK_TokenRecuperacion_estado CHECK (estado IN ('PENDIENTE','USADO','INVALIDADO'))
);
GO
CREATE UNIQUE INDEX UX_TokenRecuperacion_vigente ON dbo.TokenRecuperacion (id_usuario) WHERE estado = 'PENDIENTE';  -- Un solo código de recuperación vigente por cuenta (CU-03 RN-05).
GO

-- @entidad AceptacionTerminos | Registro de la versión de los términos de uso que aceptó cada cuenta (CU-02 RN-12).
-- @fn Llave sustituta; (id_usuario, version_terminos) es llave candidata.
CREATE TABLE dbo.AceptacionTerminos (
    id_aceptacion      INT IDENTITY(1,1) NOT NULL,  -- Identificador de la aceptación.
    id_usuario         INT            NOT NULL,  -- Cuenta que aceptó.
    version_terminos   VARCHAR(20)    NOT NULL,  -- Versión del texto aceptado.
    idioma             VARCHAR(10)    NOT NULL,  -- Idioma en que se mostró el texto, `es-MX` o `en`: cada versión existe en los dos, y lo que se aceptó es esa versión en ese idioma (CU-02 RN-12, D-21).
    fecha_aceptacion   DATETIME2(0)   NOT NULL DEFAULT (SYSUTCDATETIME()),  -- Momento de la aceptación.
    direccion_ip       VARCHAR(45)    NOT NULL,  -- Dirección de red desde la que se aceptó.
    CONSTRAINT PK_AceptacionTerminos PRIMARY KEY (id_aceptacion),
    CONSTRAINT UQ_AceptacionTerminos_version UNIQUE (id_usuario, version_terminos),  -- Una cuenta acepta cada versión una sola vez.
    CONSTRAINT FK_AceptacionTerminos_Usuario FOREIGN KEY (id_usuario) REFERENCES dbo.Usuario (id_usuario),  -- 1:N | Un usuario acepta una o más versiones de los términos.
    CONSTRAINT CK_AceptacionTerminos_idioma CHECK (idioma IN ('es-MX','en'))  -- Idiomas admitidos (D-21).
);
GO

/*---------------------------------------------------------------------
  3. Perfil y personalización
---------------------------------------------------------------------*/

-- @entidad HistorialNickname | Cambio de nombre de una cuenta, para que un jugador reportado no se vuelva irreconocible (CU-13 RN-03). Se borra al dar de baja la cuenta (CU-11).
-- @fn La llave es la llave foránea: relación 1:0..1 con *Usuario*. El nombre vigente se lee de *Usuario*; aquí queda solo el que ya no está (CU-13). No guarda el nombre nuevo: como el cambio es único, sería siempre una copia del `nickname` de *Usuario*.
CREATE TABLE dbo.HistorialNickname (
    id_usuario         INT            NOT NULL,  -- Cuenta que cambió su nombre. Como llave primaria, impide un segundo cambio (CU-13 RN-01).
    nickname_anterior  NVARCHAR(30)   NOT NULL,  -- Nombre antes del cambio.
    fecha_cambio      DATETIME2(0)   NOT NULL DEFAULT (SYSUTCDATETIME()),  -- Momento del cambio.
    CONSTRAINT PK_HistorialNickname PRIMARY KEY (id_usuario),
    CONSTRAINT FK_HistorialNickname_Usuario FOREIGN KEY (id_usuario) REFERENCES dbo.Usuario (id_usuario)  -- 1:1 | Un usuario tiene a lo sumo un cambio de nombre registrado.
);
GO

-- @entidad Avatar | Imagen subida por el jugador como foto de perfil (CU-12 FA-01).
-- @fn Llave simple.
CREATE TABLE dbo.Avatar (
    id_avatar          INT IDENTITY(1,1) NOT NULL,  -- Identificador del avatar.
    id_usuario         INT            NOT NULL,  -- Cuenta que lo subió.
    ruta_imagen        NVARCHAR(260)  NOT NULL,  -- Ubicación del archivo en el almacenamiento del servidor.
    formato            VARCHAR(4)     NOT NULL,  -- `JPG` o `PNG` (CU-12 RN-05).
    tamano_bytes       INT            NOT NULL,  -- Tamaño del archivo; hasta dos megabytes.
    fecha_subida       DATETIME2(0)   NOT NULL DEFAULT (SYSUTCDATETIME()),  -- Momento de la subida.
    vigente            BIT            NOT NULL DEFAULT (1),  -- Si es el avatar que se muestra; el anterior pasa a falso (CU-12 RN-06).
    CONSTRAINT PK_Avatar PRIMARY KEY (id_avatar),
    CONSTRAINT FK_Avatar_Usuario FOREIGN KEY (id_usuario) REFERENCES dbo.Usuario (id_usuario),  -- 1:N | Un usuario sube muchos avatares; solo uno está vigente.
    CONSTRAINT CK_Avatar_formato CHECK (formato IN ('JPG','PNG')),
    CONSTRAINT CK_Avatar_tamano CHECK (tamano_bytes BETWEEN 1 AND 2097152)
);
GO
CREATE UNIQUE INDEX UX_Avatar_vigente ON dbo.Avatar (id_usuario) WHERE vigente = 1;  -- A lo sumo un avatar vigente por cuenta (CU-12 RN-06).
GO

-- @entidad EnlaceRed | Enlace a una red social que el jugador muestra en su perfil (CU-12).
-- @fn Llave sustituta; (id_usuario, `orden`) es llave candidata.
CREATE TABLE dbo.EnlaceRed (
    id_enlace          INT IDENTITY(1,1) NOT NULL,  -- Identificador del enlace.
    id_usuario         INT            NOT NULL,  -- Cuenta que lo publica.
    orden              TINYINT        NOT NULL,  -- Posición en el perfil, de 1 a 4.
    url                NVARCHAR(500)  NOT NULL,  -- Dirección web; no se admiten acortadores (CU-12 RN-04).
    CONSTRAINT PK_EnlaceRed PRIMARY KEY (id_enlace),
    CONSTRAINT UQ_EnlaceRed_orden UNIQUE (id_usuario, orden),  -- Junto con el CHECK del orden, limita a cuatro enlaces por cuenta (CU-12 RN-03).
    CONSTRAINT FK_EnlaceRed_Usuario FOREIGN KEY (id_usuario) REFERENCES dbo.Usuario (id_usuario),  -- 1:N | Un usuario publica hasta cuatro enlaces.
    CONSTRAINT CK_EnlaceRed_orden CHECK (orden BETWEEN 1 AND 4)
);
GO

-- @entidad UsuarioObjeto | Objetos cosméticos que posee cada cuenta; es la relación N:M entre Usuario y ObjetoCosmetico (relación Posee del diagrama).
-- @fn Llave compuesta; `fecha_obtencion` y `origen` dependen del par usuario-objeto completo. Es la relación Posee del diagrama.
CREATE TABLE dbo.UsuarioObjeto (
    id_usuario         INT            NOT NULL,  -- Cuenta que posee el objeto.
    id_objeto          INT            NOT NULL,  -- Objeto poseído.
    fecha_obtencion    DATETIME2(0)   NOT NULL DEFAULT (SYSUTCDATETIME()),  -- Momento en que se obtuvo.
    origen             VARCHAR(10)    NOT NULL,  -- `INICIAL`, `COMPRA`, `CAJA` o `NIVEL`.
    CONSTRAINT PK_UsuarioObjeto PRIMARY KEY (id_usuario, id_objeto),
    CONSTRAINT FK_UsuarioObjeto_Usuario FOREIGN KEY (id_usuario) REFERENCES dbo.Usuario (id_usuario),  -- 1:N | Un usuario posee muchos objetos.
    CONSTRAINT FK_UsuarioObjeto_ObjetoCosmetico FOREIGN KEY (id_objeto) REFERENCES dbo.ObjetoCosmetico (id_objeto),  -- 1:N | Un objeto lo poseen muchos usuarios.
    CONSTRAINT CK_UsuarioObjeto_origen CHECK (origen IN ('INICIAL','COMPRA','CAJA','NIVEL'))
);
GO

-- @entidad Equipamiento | Objeto que cada cuenta lleva equipado en cada ranura; siempre hay exactamente uno por ranura (CU-14 RN-01).
-- @fn [3FN] Llaves candidatas (id_usuario, id_ranura) e (id_usuario, id_objeto). La dependencia id_objeto -> id_ranura parte de algo que no es superllave, pero id_ranura es atributo primo: cumple 3FN y no FNBC. La llave foránea compuesta impide que ranura y objeto se contradigan.
CREATE TABLE dbo.Equipamiento (
    id_usuario         INT            NOT NULL,  -- Cuenta.
    id_ranura          TINYINT        NOT NULL,  -- Ranura; con la cuenta forma la llave, así que no puede haber dos objetos en la misma ranura.
    id_objeto          INT            NOT NULL,  -- Objeto equipado; debe ser de la ranura y debe poseerse.
    CONSTRAINT PK_Equipamiento PRIMARY KEY (id_usuario, id_ranura),
    CONSTRAINT UQ_Equipamiento_objeto UNIQUE (id_usuario, id_objeto),  -- Llave candidata: como el objeto determina su ranura, la cuenta y el objeto también identifican la fila.
    CONSTRAINT FK_Equipamiento_UsuarioObjeto FOREIGN KEY (id_usuario, id_objeto) REFERENCES dbo.UsuarioObjeto (id_usuario, id_objeto),  -- 1:0..1 | Solo se equipa lo que se posee (CU-14 RN-02); un objeto poseído está equipado a lo sumo en una ranura.
    CONSTRAINT FK_Equipamiento_ObjetoCosmetico FOREIGN KEY (id_objeto, id_ranura) REFERENCES dbo.ObjetoCosmetico (id_objeto, id_ranura),  -- 1:N | El objeto equipado pertenece a la ranura de la fila.
    CONSTRAINT FK_Equipamiento_Ranura FOREIGN KEY (id_ranura) REFERENCES dbo.Ranura (id_ranura)  -- 1:N | Cada usuario tiene una fila por ranura del catálogo.
);
GO

/*---------------------------------------------------------------------
  4. Partida
---------------------------------------------------------------------*/

-- @entidad Partida | Partida clasificatoria, privada o contra la IA. Se guarda completa porque de ella dependen el historial, la repetición, la reconexión y los reportes.
-- @fn Llave simple. Sin num_jugadores ni la duración del diagrama (dependencia transitiva y dato derivado). `tipo` es discriminador. Sin ganador: es la participación con resultado `GANADA`. `turno_actual` es redundancia controlada del estado vigente; mandan las *Jugada*.
CREATE TABLE dbo.Partida (
    id_partida           INT IDENTITY(1,1) NOT NULL,  -- Identificador de la partida.
    id_modo              TINYINT        NOT NULL,  -- Modo; de él salen tablero, plazas y muros, que no se repiten aquí.
    tipo                 VARCHAR(15)    NOT NULL,  -- `CLASIFICATORIA`, `PRIVADA` o `IA`. Discrimina qué atributos aplican.
    estado               VARCHAR(20)    NOT NULL DEFAULT ('EN_CURSO'),  -- `EN_CURSO`, `PENDIENTE_DE_CIERRE` o `FINALIZADA` (CU-25 RN-13).
    minutos_reloj        TINYINT        NULL,  -- 3, 5 o 10; nulo solo en partidas contra la IA sin reloj (CU-27 RN-06).
    fecha_inicio         DATETIME2(0)   NOT NULL DEFAULT (SYSUTCDATETIME()),  -- Inicio. La duración se calcula y no se guarda (CU-36 RN-02).
    fecha_fin            DATETIME2(0)   NULL,  -- Cierre de la partida.
    forma_termino        VARCHAR(15)    NULL,  -- `META`, `TIEMPO_AGOTADO`, `RENDICION`, `TABLAS` o `ABANDONO` (CU-25 RN-01).
    turno_actual         TINYINT        NOT NULL DEFAULT (1),  -- `orden_turno` del participante que tiene el turno. Redundancia controlada: se deduce de las *Jugada*, que mandan si discrepan.
    id_nivel_ia          TINYINT        NULL,  -- Nivel de la IA; solo en partidas `IA` (D-12).
    permite_deshacer     BIT            NULL,  -- Opción elegida al empezar; solo en partidas `IA`.
    permite_sugerencias  BIT            NULL,  -- Opción elegida al empezar; solo en partidas `IA`.
    deshacer_usados      TINYINT        NULL,  -- Veces que se usó deshacer; solo en partidas `IA`.
    sugerencias_usadas   TINYINT        NULL,  -- Sugerencias pedidas; solo en partidas `IA`.
    CONSTRAINT PK_Partida PRIMARY KEY (id_partida),
    CONSTRAINT FK_Partida_Modo FOREIGN KEY (id_modo) REFERENCES dbo.Modo (id_modo),  -- 1:N | Un modo se juega en muchas partidas; cada partida es de un modo.
    CONSTRAINT FK_Partida_NivelIA FOREIGN KEY (id_nivel_ia) REFERENCES dbo.NivelIA (id_nivel_ia),  -- 1:N | Un nivel de IA se enfrenta en muchas partidas; solo las de tipo IA lo tienen.
    CONSTRAINT CK_Partida_tipo CHECK (tipo IN ('CLASIFICATORIA','PRIVADA','IA')),
    CONSTRAINT CK_Partida_estado CHECK (estado IN ('EN_CURSO','PENDIENTE_DE_CIERRE','FINALIZADA')),
    CONSTRAINT CK_Partida_forma CHECK (forma_termino IN ('META','TIEMPO_AGOTADO','RENDICION','TABLAS','ABANDONO')),
    CONSTRAINT CK_Partida_reloj CHECK (minutos_reloj IN (3, 5, 10)),
    CONSTRAINT CK_Partida_ia CHECK (
        (tipo = 'IA' AND id_nivel_ia IS NOT NULL AND permite_deshacer IS NOT NULL AND permite_sugerencias IS NOT NULL
            AND deshacer_usados IS NOT NULL AND sugerencias_usadas IS NOT NULL)
        OR (tipo <> 'IA' AND id_nivel_ia IS NULL AND permite_deshacer IS NULL AND permite_sugerencias IS NULL
            AND deshacer_usados IS NULL AND sugerencias_usadas IS NULL AND minutos_reloj IS NOT NULL)),
    CONSTRAINT CK_Partida_cierre CHECK (
        (estado = 'EN_CURSO' AND fecha_fin IS NULL AND forma_termino IS NULL)
        OR (estado = 'PENDIENTE_DE_CIERRE' AND fecha_fin IS NULL AND forma_termino IS NOT NULL)
        OR (estado = 'FINALIZADA' AND fecha_fin IS NOT NULL AND forma_termino IS NOT NULL))
);
GO

-- @entidad Participacion | Participación de un jugador en una partida; es la relación N:M entre Usuario y Partida (relación Participa del diagrama). La IA no tiene participación (D-12).
-- @fn Llaves candidatas (id_partida, id_usuario) e (id_partida, orden_turno). `diferencia_elo` y `terminada` son calculadas: dependían de otras columnas de la fila. `casilla_actual`, `muros_restantes` y `reloj_restante` son redundancia controlada del estado vigente; mandan las *Jugada*.
CREATE TABLE dbo.Participacion (
    id_partida           INT            NOT NULL,  -- Partida.
    id_usuario           INT            NOT NULL,  -- Jugador.
    orden_turno          TINYINT        NOT NULL,  -- Orden en que juega, de 1 a 4.
    simbolo_peon         VARCHAR(10)    NOT NULL,  -- Símbolo y color que distinguen su peón (color_ficha en el diagrama).
    casilla_actual       VARCHAR(3)     NOT NULL,  -- Casilla que ocupa el peón, en notación de tablero. Redundancia controlada: es la de su última jugada.
    muros_restantes      TINYINT        NOT NULL,  -- Muros que le quedan; nace con los del modo o de la sala (CU-18). Redundancia controlada: los iniciales menos sus jugadas de tipo `MURO`.
    reloj_restante       INT            NULL,  -- Milisegundos que le quedan; nulo si la partida no tiene reloj. Redundancia controlada: el reloj inicial menos el tiempo consumido en sus jugadas, o cero para quien pierde por tiempo, porque la jugada que llegó tarde no se guarda (CU-20 FA-06).
    elo_inicial          SMALLINT       NULL,  -- Elo con el que entró; base del cálculo (CU-17 RN-04, CU-25 RN-04).
    elo_final            SMALLINT       NULL,  -- Elo resultante; solo en partidas clasificatorias.
    diferencia_elo       AS (elo_final - elo_inicial),  -- Cambio de elo que muestra el historial (CU-36 RN-03). Calculada y no almacenada: depende de otras dos columnas de la fila.
    resultado            VARCHAR(10)    NULL,  -- `GANADA`, `PERDIDA` o `TABLAS`; nulo mientras no termina.
    posicion             TINYINT        NULL,  -- Posición en el modo de cuatro jugadores, de 1 a 4 (CU-25 RN-02); nula en las de dos jugadores y contra la IA, donde el resultado ya la dice.
    forma_termino        VARCHAR(15)    NULL,  -- Forma en que salió antes que la partida, en cuatro jugadores: `META`, `RENDICION`, `ABANDONO` o `TIEMPO_AGOTADO`.
    conectado            BIT            NOT NULL DEFAULT (1),  -- Estado de conexión; se guarda para sobrevivir a un reinicio (CU-26).
    fecha_desconexion    DATETIME2(0)   NULL,  -- Inicio de la última desconexión, para el plazo de sesenta segundos (CU-24 RN-06); no se borra al reconectar, así que no sustituye a `conectado`.
    terminada            AS (CASE WHEN resultado IS NULL THEN CAST(0 AS BIT) ELSE CAST(1 AS BIT) END),  -- Si la participación está cerrada (D-11). Calculada: es exactamente que `resultado` no sea nulo.
    CONSTRAINT PK_Participacion PRIMARY KEY (id_partida, id_usuario),
    CONSTRAINT UQ_Participacion_turno UNIQUE (id_partida, orden_turno),  -- Dos jugadores no comparten turno en la misma partida.
    CONSTRAINT FK_Participacion_Partida FOREIGN KEY (id_partida) REFERENCES dbo.Partida (id_partida),  -- 1:N | Una partida tiene de 1 a 4 participaciones (1 contra la IA).
    CONSTRAINT FK_Participacion_Usuario FOREIGN KEY (id_usuario) REFERENCES dbo.Usuario (id_usuario),  -- 1:N | Un usuario participa en muchas partidas.
    CONSTRAINT CK_Participacion_resultado CHECK (resultado IN ('GANADA','PERDIDA','TABLAS')),
    CONSTRAINT CK_Participacion_forma CHECK (forma_termino IN ('META','TIEMPO_AGOTADO','RENDICION','ABANDONO')),
    CONSTRAINT CK_Participacion_rangos CHECK (orden_turno BETWEEN 1 AND 4 AND posicion BETWEEN 1 AND 4 AND muros_restantes <= 20),
    CONSTRAINT CK_Participacion_conexion CHECK (conectado = 1 OR fecha_desconexion IS NOT NULL)
);
GO
CREATE UNIQUE INDEX UX_Participacion_sin_terminar ON dbo.Participacion (id_usuario) WHERE resultado IS NULL;  -- Una sola participación sin terminar por jugador, incluidas las de la IA (D-11). Filtra por `resultado` porque un índice filtrado no admite columnas calculadas.
GO

-- @entidad ParticipacionObjeto | Aspecto con el que cada jugador entró a la partida, una fila por ranura; no cambia aunque el jugador equipe otra cosa (CU-14 RN-03, CU-37 RN-03).
-- @fn [3FN] Mismo caso que *Equipamiento*: id_objeto -> id_ranura con id_ranura dentro de la llave; cumple 3FN y no FNBC.
CREATE TABLE dbo.ParticipacionObjeto (
    id_partida           INT            NOT NULL,  -- Partida.
    id_usuario           INT            NOT NULL,  -- Jugador.
    id_ranura            TINYINT        NOT NULL,  -- Ranura.
    id_objeto            INT            NOT NULL,  -- Objeto que tenía equipado en esa ranura al empezar.
    CONSTRAINT PK_ParticipacionObjeto PRIMARY KEY (id_partida, id_usuario, id_ranura),
    CONSTRAINT UQ_ParticipacionObjeto_objeto UNIQUE (id_partida, id_usuario, id_objeto),  -- Llave candidata: como el objeto determina su ranura, también identifica la fila.
    CONSTRAINT FK_ParticipacionObjeto_Participacion FOREIGN KEY (id_partida, id_usuario) REFERENCES dbo.Participacion (id_partida, id_usuario),  -- 1:N | Una participación fija un objeto por cada ranura.
    CONSTRAINT FK_ParticipacionObjeto_ObjetoCosmetico FOREIGN KEY (id_objeto, id_ranura) REFERENCES dbo.ObjetoCosmetico (id_objeto, id_ranura)  -- 1:N | Un objeto aparece en muchas participaciones, siempre en su ranura.
);
GO

-- @entidad Jugada | Movimiento de peón o colocación de muro, en orden. El tablero se reconstruye sumando las jugadas; los muros no tienen tabla propia (CU-21).
-- @fn Llave compuesta; cada atributo describe la jugada entera. `tipo` discrimina qué casillas aplican.
CREATE TABLE dbo.Jugada (
    id_partida           INT            NOT NULL,  -- Partida.
    numero_jugada        SMALLINT       NOT NULL,  -- Número consecutivo dentro de la partida (CU-20 RN-06).
    id_usuario           INT            NULL,  -- Jugador que la hizo; nulo si la hizo la IA (CU-27 RN-03).
    tipo                 VARCHAR(10)    NOT NULL,  -- `MOVIMIENTO` o `MURO`. Discrimina qué casillas aplican.
    casilla_origen       VARCHAR(3)     NULL,  -- Casilla de salida del peón; solo en `MOVIMIENTO`.
    casilla_destino      VARCHAR(3)     NULL,  -- Casilla de llegada del peón; solo en `MOVIMIENTO`.
    surco                VARCHAR(3)     NULL,  -- Surco donde se colocó el muro; solo en `MURO`.
    orientacion          VARCHAR(10)    NULL,  -- `HORIZONTAL` o `VERTICAL`; solo en `MURO`.
    tiempo_consumido     INT            NOT NULL,  -- Milisegundos que tardó el jugador.
    fecha_jugada         DATETIME2(3)   NOT NULL DEFAULT (SYSUTCDATETIME()),  -- Momento en que se registró.
    deshecha             BIT            NOT NULL DEFAULT (0),  -- Marca de deshacer contra la IA; la jugada no se borra (CU-27 RN-05).
    CONSTRAINT PK_Jugada PRIMARY KEY (id_partida, numero_jugada),
    CONSTRAINT FK_Jugada_Partida FOREIGN KEY (id_partida) REFERENCES dbo.Partida (id_partida),  -- 1:N | Una partida tiene muchas jugadas.
    CONSTRAINT FK_Jugada_Participacion FOREIGN KEY (id_partida, id_usuario) REFERENCES dbo.Participacion (id_partida, id_usuario),  -- 1:N | Un participante hace muchas jugadas; las de la IA no tienen participante.
    CONSTRAINT CK_Jugada_tipo CHECK (
        (tipo = 'MOVIMIENTO' AND casilla_origen IS NOT NULL AND casilla_destino IS NOT NULL AND surco IS NULL AND orientacion IS NULL)
        OR (tipo = 'MURO' AND surco IS NOT NULL AND orientacion IN ('HORIZONTAL','VERTICAL') AND casilla_origen IS NULL AND casilla_destino IS NULL)),
    CONSTRAINT CK_Jugada_rangos CHECK (numero_jugada >= 1 AND tiempo_consumido >= 0)
);
GO

-- @entidad OfertaTablas | Oferta de tablas en una partida de dos jugadores (CU-22). Se guarda para la reconexión y como prueba de acoso.
-- @fn Llave simple.
CREATE TABLE dbo.OfertaTablas (
    id_oferta            INT IDENTITY(1,1) NOT NULL,  -- Identificador de la oferta.
    id_partida           INT            NOT NULL,  -- Partida.
    id_ofertante         INT            NOT NULL,  -- Participante que la ofrece.
    numero_jugada        SMALLINT       NOT NULL,  -- Jugada tras la que se ofreció; limita una oferta cada cinco jugadas (CU-22 RN-03).
    fecha_oferta         DATETIME2(0)   NOT NULL DEFAULT (SYSUTCDATETIME()),  -- Momento de la oferta.
    estado               VARCHAR(10)    NOT NULL DEFAULT ('PENDIENTE'),  -- `PENDIENTE`, `ACEPTADA`, `RECHAZADA` o `CADUCADA`.
    fecha_respuesta      DATETIME2(0)   NULL,  -- Momento en que se aceptó, rechazó o caducó.
    CONSTRAINT PK_OfertaTablas PRIMARY KEY (id_oferta),
    CONSTRAINT FK_OfertaTablas_Participacion FOREIGN KEY (id_partida, id_ofertante) REFERENCES dbo.Participacion (id_partida, id_usuario),  -- 1:N | Un participante hace muchas ofertas en su partida.
    CONSTRAINT CK_OfertaTablas_estado CHECK (estado IN ('PENDIENTE','ACEPTADA','RECHAZADA','CADUCADA')),
    CONSTRAINT CK_OfertaTablas_respuesta CHECK ((estado = 'PENDIENTE' AND fecha_respuesta IS NULL) OR (estado <> 'PENDIENTE' AND fecha_respuesta IS NOT NULL))
);
GO
CREATE UNIQUE INDEX UX_OfertaTablas_pendiente ON dbo.OfertaTablas (id_partida) WHERE estado = 'PENDIENTE';  -- A lo sumo una oferta pendiente por partida; la segunda es aceptación (CU-22 RN-04).
GO

-- @entidad EnlaceEspectador | Enlace compartido para ver una partida desde fuera del juego. Es lo único que se guarda de los espectadores (D-19).
-- @fn Llave simple; `token_hash` es llave candidata. Sin indicador de activo: el enlace vale mientras su *Partida* está `EN_CURSO` (CU-34 RN-06), y un indicador repetiría ese estado.
CREATE TABLE dbo.EnlaceEspectador (
    id_enlace            INT IDENTITY(1,1) NOT NULL,  -- Identificador del enlace.
    id_partida           INT            NOT NULL,  -- Partida que se comparte; el enlace deja de valer cuando termina.
    id_creador           INT            NOT NULL,  -- Participante que lo compartió.
    token_hash           VARBINARY(32)  NOT NULL,  -- Resumen del token del enlace.
    fecha_creacion       DATETIME2(0)   NOT NULL DEFAULT (SYSUTCDATETIME()),  -- Momento en que se compartió.
    CONSTRAINT PK_EnlaceEspectador PRIMARY KEY (id_enlace),
    CONSTRAINT UQ_EnlaceEspectador_token UNIQUE (token_hash),  -- El token identifica un solo enlace.
    CONSTRAINT FK_EnlaceEspectador_Participacion FOREIGN KEY (id_partida, id_creador) REFERENCES dbo.Participacion (id_partida, id_usuario)  -- 1:N | Un participante comparte uno o más enlaces de su partida.
);
GO

/*---------------------------------------------------------------------
  5. Emparejamiento, salas y chat
---------------------------------------------------------------------*/

-- @entidad ColaEmparejamiento | Jugadores que esperan partida clasificatoria. Se persiste para poder vaciarla y avisar si el servidor se reinicia (CU-17).
-- @fn La llave es la llave foránea: relación 1:0..1 con *Usuario*. Sin elo: el del modo se lee de *EstadisticaModo*, y mientras el jugador espera no puede cambiar, porque solo lo escribe el cierre de una partida (CU-25).
CREATE TABLE dbo.ColaEmparejamiento (
    id_usuario           INT            NOT NULL,  -- Jugador en espera; como llave, impide que esté dos veces en la cola.
    id_modo              TINYINT        NOT NULL,  -- Modo buscado.
    minutos_reloj        TINYINT        NOT NULL,  -- Reloj buscado: 3, 5 o 10.
    fecha_entrada        DATETIME2(0)   NOT NULL DEFAULT (SYSUTCDATETIME()),  -- Inicio de la espera; con ella se amplía la ventana de elo (CU-17 RN-03).
    CONSTRAINT PK_ColaEmparejamiento PRIMARY KEY (id_usuario),
    CONSTRAINT FK_ColaEmparejamiento_Usuario FOREIGN KEY (id_usuario) REFERENCES dbo.Usuario (id_usuario),  -- 1:0..1 | Un usuario ocupa a lo sumo un lugar en la cola.
    CONSTRAINT FK_ColaEmparejamiento_Modo FOREIGN KEY (id_modo) REFERENCES dbo.Modo (id_modo),  -- 1:N | En la cola de un modo esperan muchos jugadores.
    CONSTRAINT CK_ColaEmparejamiento_reloj CHECK (minutos_reloj IN (3, 5, 10))
);
GO
CREATE INDEX IX_ColaEmparejamiento_busqueda ON dbo.ColaEmparejamiento (id_modo, minutos_reloj, fecha_entrada);
GO

-- @entidad Sala | Sala privada con código, con los ajustes que elige el anfitrión (CU-18).
-- @fn Llave simple. `codigo` solo es único entre las salas no cerradas, así que no es llave candidata.
CREATE TABLE dbo.Sala (
    id_sala                 INT IDENTITY(1,1) NOT NULL,  -- Identificador de la sala.
    codigo                  CHAR(6)        NOT NULL,  -- Seis caracteres sin 0, O, 1 ni I; único entre las salas no cerradas (CU-18 RN-01).
    id_anfitrion            INT            NOT NULL,  -- Jugador que creó la sala.
    id_modo                 TINYINT        NOT NULL,  -- Modo, que fija el tablero y las plazas.
    muros_por_jugador       TINYINT        NOT NULL,  -- De 1 a 20, elegido por el anfitrión (CU-18 RN-04).
    minutos_reloj           TINYINT        NOT NULL,  -- 3, 5 o 10.
    permite_espectadores    BIT            NOT NULL DEFAULT (1),  -- Si la partida de la sala admite espectadores.
    estado                  VARCHAR(10)    NOT NULL DEFAULT ('ABIERTA'),  -- `ABIERTA`, `EN_PARTIDA` o `CERRADA`.
    id_partida              INT            NULL,  -- Partida que se inició desde la sala.
    fecha_creacion          DATETIME2(0)   NOT NULL DEFAULT (SYSUTCDATETIME()),  -- Creación de la sala.
    fecha_ultima_actividad  DATETIME2(0)   NOT NULL DEFAULT (SYSUTCDATETIME()),  -- Para cerrar la sala a los treinta minutos sin actividad (CU-18 RN-08).
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
CREATE UNIQUE INDEX UX_Sala_codigo ON dbo.Sala (codigo) WHERE estado <> 'CERRADA';  -- El código es único entre las salas no cerradas y puede reutilizarse después (CU-18 RN-01).
CREATE UNIQUE INDEX UX_Sala_partida ON dbo.Sala (id_partida) WHERE id_partida IS NOT NULL;  -- Una partida viene de una sola sala.
GO

-- @entidad SalaParticipante | Plaza que ocupa un jugador en una sala. Describe un estado presente y se borra al salir (CU-19).
-- @fn La llave es `id_usuario`: un jugador está en una sola sala a la vez (CU-18 RN-02). (id_sala, `plaza`) es llave candidata.
CREATE TABLE dbo.SalaParticipante (
    id_usuario           INT            NOT NULL,  -- Jugador; como llave, impide que esté en dos salas a la vez (CU-18 RN-02).
    id_sala              INT            NOT NULL,  -- Sala.
    plaza                TINYINT        NOT NULL,  -- Número de plaza, de 1 a 4.
    listo                BIT            NOT NULL DEFAULT (0),  -- Nadie está listo hasta declararlo (CU-19 RN-03).
    fecha_union          DATETIME2(0)   NOT NULL DEFAULT (SYSUTCDATETIME()),  -- Momento en que entró.
    CONSTRAINT PK_SalaParticipante PRIMARY KEY (id_usuario),
    CONSTRAINT UQ_SalaParticipante_plaza UNIQUE (id_sala, plaza),  -- Dos jugadores no ocupan la misma plaza (CU-19 RN-02).
    CONSTRAINT FK_SalaParticipante_Sala FOREIGN KEY (id_sala) REFERENCES dbo.Sala (id_sala),  -- 1:N | Una sala tiene de 1 a 4 miembros.
    CONSTRAINT FK_SalaParticipante_Usuario FOREIGN KEY (id_usuario) REFERENCES dbo.Usuario (id_usuario),  -- 1:0..1 | Un usuario ocupa a lo sumo una plaza.
    CONSTRAINT CK_SalaParticipante_plaza CHECK (plaza BETWEEN 1 AND 4)
);
GO

-- @entidad Invitacion | Invitación a jugar, que da acceso a una sala sin conocer su código (CU-32).
-- @fn Llave simple.
CREATE TABLE dbo.Invitacion (
    id_invitacion        INT IDENTITY(1,1) NOT NULL,  -- Identificador de la invitación.
    id_sala              INT            NOT NULL,  -- Sala a la que se invita.
    id_emisor            INT            NOT NULL,  -- Jugador que invita.
    id_destinatario      INT            NOT NULL,  -- Jugador invitado.
    fecha_invitacion     DATETIME2(0)   NOT NULL DEFAULT (SYSUTCDATETIME()),  -- Envío.
    fecha_expiracion     DATETIME2(0)   NOT NULL,  -- Sesenta segundos después del envío (CU-32 RN-04).
    estado               VARCHAR(10)    NOT NULL DEFAULT ('PENDIENTE'),  -- `PENDIENTE`, `ACEPTADA`, `RECHAZADA` o `EXPIRADA`.
    CONSTRAINT PK_Invitacion PRIMARY KEY (id_invitacion),
    CONSTRAINT FK_Invitacion_Sala FOREIGN KEY (id_sala) REFERENCES dbo.Sala (id_sala),  -- 1:N | Una sala recibe muchas invitaciones.
    CONSTRAINT FK_Invitacion_Emisor FOREIGN KEY (id_emisor) REFERENCES dbo.Usuario (id_usuario),  -- 1:N | Un usuario envía muchas invitaciones (rol emisor).
    CONSTRAINT FK_Invitacion_Destinatario FOREIGN KEY (id_destinatario) REFERENCES dbo.Usuario (id_usuario),  -- 1:N | Un usuario recibe muchas invitaciones (rol destinatario).
    CONSTRAINT CK_Invitacion_estado CHECK (estado IN ('PENDIENTE','ACEPTADA','RECHAZADA','EXPIRADA')),
    CONSTRAINT CK_Invitacion_distintos CHECK (id_emisor <> id_destinatario)
);
GO
CREATE UNIQUE INDEX UX_Invitacion_pendiente ON dbo.Invitacion (id_emisor, id_destinatario) WHERE estado = 'PENDIENTE';  -- Una sola invitación pendiente del mismo emisor al mismo destinatario (CU-32 RN-04).
GO

-- @entidad Mensaje | Mensaje de chat. Se guarda porque el reporte lo adjunta como prueba (CU-28, CU-42).
-- @fn Llave simple; `canal` discrimina si aplica partida o sala.
CREATE TABLE dbo.Mensaje (
    id_mensaje           BIGINT IDENTITY(1,1) NOT NULL,  -- Identificador del mensaje.
    id_autor             INT            NOT NULL,  -- Jugador que lo escribió.
    canal                VARCHAR(12)    NOT NULL,  -- `PARTIDA`, `ESPECTADORES`, `SALA`, `GLOBAL` o `AMIGOS`. Discrimina a qué pertenece el mensaje.
    id_partida           INT            NULL,  -- Partida; solo en los canales `PARTIDA` y `ESPECTADORES`.
    id_sala              INT            NULL,  -- Sala; solo en el canal `SALA`.
    texto                NVARCHAR(500)  NOT NULL,  -- Texto tal como se escribió, en Unicode y sin traducir (CU-28 RN-12).
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
  6. Clasificación y economía
---------------------------------------------------------------------*/

-- @entidad EstadisticaModo | Estadísticas y elo de cada cuenta en cada modo, solo de partidas clasificatorias (CU-25 RN-14); es la relación N:M entre Usuario y Modo (relación Tiene del diagrama, ahora por modo, D-04).
-- @fn Llave compuesta usuario-modo; cada contador depende de los dos. Sustituye a la entidad Estadísticas 1:1 del diagrama, que habría obligado a repetir los contadores de cada modo. Sin el derivado porcentaje_victorias. Los contadores son redundancia controlada.
CREATE TABLE dbo.EstadisticaModo (
    id_usuario           INT            NOT NULL,  -- Cuenta.
    id_modo              TINYINT        NOT NULL,  -- Modo.
    puntos_elo           SMALLINT       NOT NULL DEFAULT (1000),  -- Elo actual en el modo; lo escribe solo el CU-25.
    fecha_ultima_partida DATETIME2(0)   NULL,  -- Fin de la última partida clasificatoria del modo: cuándo se alcanzó el elo actual; desempata el ranking (CU-35 RN-06).
    elo_maximo           SMALLINT       NOT NULL DEFAULT (1000),  -- Elo más alto alcanzado.
    partidas_jugadas     INT            NOT NULL DEFAULT (0),  -- Partidas clasificatorias, incluidas las tablas, que no son victoria ni derrota (CU-25 FA-05).
    partidas_ganadas     INT            NOT NULL DEFAULT (0),  -- Victorias. El porcentaje se calcula y no se guarda (CU-15 RN-01).
    partidas_perdidas    INT            NOT NULL DEFAULT (0),  -- Derrotas, incluidas rendiciones y abandonos.
    racha_actual         SMALLINT       NOT NULL DEFAULT (0),  -- Victorias seguidas por llegada a meta (CU-25 RN-11).
    mejor_racha          SMALLINT       NOT NULL DEFAULT (0),  -- Racha más larga.
    tiempo_total_jugado  INT            NOT NULL DEFAULT (0),  -- Segundos jugados en partidas clasificatorias del modo.
    barreras_colocadas   INT            NOT NULL DEFAULT (0),  -- Muros colocados, contados desde *Jugada* al cerrar cada partida.
    abandonos            INT            NOT NULL DEFAULT (0),  -- Abandonos en partidas en línea, para la moderación (CU-24 RN-05).
    id_division          TINYINT        NULL,  -- División actual; nula hasta jugar cinco partidas en el modo (CU-25 RN-14).
    CONSTRAINT PK_EstadisticaModo PRIMARY KEY (id_usuario, id_modo),
    CONSTRAINT FK_EstadisticaModo_Usuario FOREIGN KEY (id_usuario) REFERENCES dbo.Usuario (id_usuario),  -- 1:N | Un usuario tiene una fila de estadísticas por cada modo.
    CONSTRAINT FK_EstadisticaModo_Modo FOREIGN KEY (id_modo) REFERENCES dbo.Modo (id_modo),  -- 1:N | Un modo tiene estadísticas de muchos usuarios.
    CONSTRAINT FK_EstadisticaModo_Division FOREIGN KEY (id_division) REFERENCES dbo.Division (id_division),  -- 1:N | En una división hay muchos jugadores de cada modo.
    CONSTRAINT CK_EstadisticaModo_contadores CHECK (partidas_ganadas + partidas_perdidas <= partidas_jugadas
        AND partidas_ganadas >= 0 AND partidas_perdidas >= 0 AND abandonos >= 0 AND tiempo_total_jugado >= 0
        AND barreras_colocadas >= 0 AND racha_actual >= 0 AND mejor_racha >= racha_actual AND elo_maximo >= puntos_elo)
);
GO
CREATE INDEX IX_EstadisticaModo_ranking ON dbo.EstadisticaModo (id_modo, puntos_elo DESC, fecha_ultima_partida) INCLUDE (partidas_jugadas, id_division);
GO

-- @entidad HistorialDivision | Cambio de división de una cuenta en un modo. No se deduce de una sola partida por las partidas de margen, así que se guarda (CU-15).
-- @fn Llave simple.
CREATE TABLE dbo.HistorialDivision (
    id_historial_division  INT IDENTITY(1,1) NOT NULL,  -- Identificador del cambio.
    id_usuario             INT            NOT NULL,  -- Cuenta.
    id_modo                TINYINT        NOT NULL,  -- Modo en que cambió de división.
    id_division_anterior   TINYINT        NULL,  -- División de la que sale; nula al obtener la primera.
    id_division_nueva      TINYINT        NOT NULL,  -- División a la que llega.
    fecha_cambio           DATETIME2(0)   NOT NULL DEFAULT (SYSUTCDATETIME()),  -- Momento del cambio; lo marca la gráfica de elo.
    CONSTRAINT PK_HistorialDivision PRIMARY KEY (id_historial_division),
    CONSTRAINT FK_HistorialDivision_EstadisticaModo FOREIGN KEY (id_usuario, id_modo) REFERENCES dbo.EstadisticaModo (id_usuario, id_modo),  -- 1:N | Las estadísticas de un modo acumulan muchos cambios de división.
    CONSTRAINT FK_HistorialDivision_Anterior FOREIGN KEY (id_division_anterior) REFERENCES dbo.Division (id_division),  -- 1:N | Una división es el origen de muchos cambios (rol anterior).
    CONSTRAINT FK_HistorialDivision_Nueva FOREIGN KEY (id_division_nueva) REFERENCES dbo.Division (id_division),  -- 1:N | Una división es el destino de muchos cambios (rol nueva).
    CONSTRAINT CK_HistorialDivision_cambio CHECK (id_division_anterior IS NULL OR id_division_anterior <> id_division_nueva)
);
GO

-- @entidad Caja | Caja comprada u obtenida al subir de nivel. Existe sin abrir entre la compra y la apertura (CU-39 RN-09).
-- @fn Llave simple.
CREATE TABLE dbo.Caja (
    id_caja              INT IDENTITY(1,1) NOT NULL,  -- Identificador de la caja.
    id_usuario           INT            NOT NULL,  -- Cuenta dueña de la caja.
    id_tipo_caja         TINYINT        NOT NULL,  -- Tipo, que fija el contenido posible.
    origen               VARCHAR(10)    NOT NULL,  -- `COMPRA` o `PARTIDA`.
    estado               VARCHAR(10)    NOT NULL DEFAULT ('SIN_ABRIR'),  -- `SIN_ABRIR`, `ABIERTA` o `CADUCADA`.
    fecha_obtencion      DATETIME2(0)   NOT NULL DEFAULT (SYSUTCDATETIME()),  -- Momento en que se obtuvo.
    fecha_apertura       DATETIME2(0)   NULL,  -- Momento en que se abrió.
    fecha_caducidad      DATETIME2(0)   NULL,  -- Solo en cajas ganadas jugando, a los catorce días; las compradas no caducan (CU-39 RN-06).
    CONSTRAINT PK_Caja PRIMARY KEY (id_caja),
    CONSTRAINT FK_Caja_Usuario FOREIGN KEY (id_usuario) REFERENCES dbo.Usuario (id_usuario),  -- 1:N | Un usuario tiene muchas cajas.
    CONSTRAINT FK_Caja_TipoCaja FOREIGN KEY (id_tipo_caja) REFERENCES dbo.TipoCaja (id_tipo_caja),  -- 1:N | Un tipo de caja se concreta en muchas cajas.
    CONSTRAINT CK_Caja_origen CHECK (origen IN ('COMPRA','PARTIDA')),
    CONSTRAINT CK_Caja_estado CHECK (estado IN ('SIN_ABRIR','ABIERTA','CADUCADA')),
    CONSTRAINT CK_Caja_caducidad CHECK (origen = 'PARTIDA' OR fecha_caducidad IS NULL),
    CONSTRAINT CK_Caja_apertura CHECK ((estado = 'ABIERTA' AND fecha_apertura IS NOT NULL) OR (estado <> 'ABIERTA' AND fecha_apertura IS NULL))
);
GO

-- @entidad CajaContenido | Los tres objetos que salieron al abrir una caja, registrados para poder comprobarlos después (CU-39 RN-07).
-- @fn Llave compuesta. `convertido` pasó a calculada porque dependía de `monedas_conversion`.
CREATE TABLE dbo.CajaContenido (
    id_caja              INT            NOT NULL,  -- Caja abierta.
    numero               TINYINT        NOT NULL,  -- Posición del objeto en la caja, de 1 a 3.
    id_objeto            INT            NOT NULL,  -- Objeto que salió.
    monedas_conversion   INT            NULL,  -- Monedas recibidas si el objeto estaba repetido y se convirtió (CU-39 RN-03).
    convertido           AS (CASE WHEN monedas_conversion IS NULL THEN CAST(0 AS BIT) ELSE CAST(1 AS BIT) END),  -- Si el objeto se convirtió en monedas. Calculada: es exactamente que `monedas_conversion` no sea nula.
    CONSTRAINT PK_CajaContenido PRIMARY KEY (id_caja, numero),
    CONSTRAINT FK_CajaContenido_Caja FOREIGN KEY (id_caja) REFERENCES dbo.Caja (id_caja),  -- 1:N | Una caja abierta tiene tres objetos.
    CONSTRAINT FK_CajaContenido_ObjetoCosmetico FOREIGN KEY (id_objeto) REFERENCES dbo.ObjetoCosmetico (id_objeto),  -- 1:N | Un objeto sale en muchas cajas.
    CONSTRAINT CK_CajaContenido_rangos CHECK (numero BETWEEN 1 AND 3 AND (monedas_conversion IS NULL OR monedas_conversion > 0))
);
GO

-- @entidad MovimientoMoneda | Entrada o salida de monedas. El saldo verdadero es su suma; nunca se modifica ni se elimina (CU-40 RN-01).
-- @fn Llave simple; `tipo` discrimina qué origen aplica.
CREATE TABLE dbo.MovimientoMoneda (
    id_movimiento        BIGINT IDENTITY(1,1) NOT NULL,  -- Identificador del movimiento.
    id_usuario           INT            NOT NULL,  -- Cuenta afectada.
    tipo                 VARCHAR(12)    NOT NULL,  -- `PARTIDA`, `NIVEL`, `COMPRA`, `COMPRA_CAJA`, `CONVERSION` o `DEVOLUCION`. Discrimina qué origen aplica.
    importe              INT            NOT NULL,  -- Monedas; negativo en las compras.
    fecha_movimiento     DATETIME2(0)   NOT NULL DEFAULT (SYSUTCDATETIME()),  -- Momento del movimiento.
    id_partida           INT            NULL,  -- Partida que lo originó, en `PARTIDA`.
    id_objeto            INT            NULL,  -- Objeto comprado o convertido, en `COMPRA` y `CONVERSION`.
    id_caja              INT            NULL,  -- Caja comprada o abierta, en `COMPRA_CAJA` y `CONVERSION`.
    CONSTRAINT PK_MovimientoMoneda PRIMARY KEY (id_movimiento),
    CONSTRAINT FK_MovimientoMoneda_Usuario FOREIGN KEY (id_usuario) REFERENCES dbo.Usuario (id_usuario),  -- 1:N | Un usuario acumula muchos movimientos.
    CONSTRAINT FK_MovimientoMoneda_Partida FOREIGN KEY (id_partida) REFERENCES dbo.Partida (id_partida),  -- 1:N | Una partida clasificatoria genera un movimiento por participante.
    CONSTRAINT FK_MovimientoMoneda_ObjetoCosmetico FOREIGN KEY (id_objeto) REFERENCES dbo.ObjetoCosmetico (id_objeto),  -- 1:N | Un objeto aparece en muchos movimientos de compra o conversión.
    CONSTRAINT FK_MovimientoMoneda_Caja FOREIGN KEY (id_caja) REFERENCES dbo.Caja (id_caja),  -- 1:N | Una caja genera su cobro y sus conversiones.
    CONSTRAINT CK_MovimientoMoneda_tipo CHECK (tipo IN ('PARTIDA','NIVEL','COMPRA','COMPRA_CAJA','CONVERSION','DEVOLUCION')),
    CONSTRAINT CK_MovimientoMoneda_importe CHECK (
        (tipo IN ('COMPRA','COMPRA_CAJA') AND importe < 0)
        OR (tipo IN ('PARTIDA','NIVEL','CONVERSION') AND importe > 0)
        OR (tipo = 'DEVOLUCION' AND importe <> 0)),
    CONSTRAINT CK_MovimientoMoneda_origen CHECK (
        (tipo = 'PARTIDA' AND id_partida IS NOT NULL)
        OR (tipo = 'COMPRA' AND id_objeto IS NOT NULL)
        OR (tipo = 'COMPRA_CAJA' AND id_caja IS NOT NULL)
        OR (tipo = 'CONVERSION' AND id_caja IS NOT NULL AND id_objeto IS NOT NULL)
        OR tipo IN ('NIVEL','DEVOLUCION'))
);
GO
CREATE INDEX IX_MovimientoMoneda_usuario ON dbo.MovimientoMoneda (id_usuario, fecha_movimiento) INCLUDE (importe);
GO

/*---------------------------------------------------------------------
  7. Relaciones entre jugadores y tutorial
---------------------------------------------------------------------*/

-- @entidad Amistad | Amistad recíproca entre dos cuentas, guardada una sola vez por par ordenado (CU-31 RN-03).
-- @fn Llave compuesta de par ordenado: el CHECK impide guardar la misma amistad en los dos sentidos.
CREATE TABLE dbo.Amistad (
    id_usuario_a         INT            NOT NULL,  -- El menor de los dos identificadores.
    id_usuario_b         INT            NOT NULL,  -- El mayor de los dos identificadores.
    fecha_amistad        DATETIME2(0)   NOT NULL DEFAULT (SYSUTCDATETIME()),  -- Momento en que se aceptó la solicitud.
    CONSTRAINT PK_Amistad PRIMARY KEY (id_usuario_a, id_usuario_b),
    CONSTRAINT FK_Amistad_UsuarioA FOREIGN KEY (id_usuario_a) REFERENCES dbo.Usuario (id_usuario),  -- 1:N | Un usuario es amigo de muchos (como el menor del par).
    CONSTRAINT FK_Amistad_UsuarioB FOREIGN KEY (id_usuario_b) REFERENCES dbo.Usuario (id_usuario),  -- 1:N | Un usuario es amigo de muchos (como el mayor del par).
    CONSTRAINT CK_Amistad_par_ordenado CHECK (id_usuario_a < id_usuario_b)
);
GO
CREATE INDEX IX_Amistad_b ON dbo.Amistad (id_usuario_b);
GO

-- @entidad Solicitud | Solicitud de amistad pendiente. Tiene dirección, a diferencia de la amistad, y se borra al responderse (CU-30, CU-31).
-- @fn Llave sustituta; (id_solicitante, id_destinatario) es llave candidata.
CREATE TABLE dbo.Solicitud (
    id_solicitud         INT IDENTITY(1,1) NOT NULL,  -- Identificador de la solicitud.
    id_solicitante       INT            NOT NULL,  -- Jugador que la envía.
    id_destinatario      INT            NOT NULL,  -- Jugador que la recibe.
    fecha_solicitud      DATETIME2(0)   NOT NULL DEFAULT (SYSUTCDATETIME()),  -- Envío; caduca a los treinta días (CU-31 RN-05).
    CONSTRAINT PK_Solicitud PRIMARY KEY (id_solicitud),
    CONSTRAINT UQ_Solicitud_par UNIQUE (id_solicitante, id_destinatario),  -- No hay dos solicitudes iguales entre el mismo par (CU-30 RN-03).
    CONSTRAINT FK_Solicitud_Solicitante FOREIGN KEY (id_solicitante) REFERENCES dbo.Usuario (id_usuario),  -- 1:N | Un usuario envía muchas solicitudes (rol solicitante).
    CONSTRAINT FK_Solicitud_Destinatario FOREIGN KEY (id_destinatario) REFERENCES dbo.Usuario (id_usuario),  -- 1:N | Un usuario recibe muchas solicitudes (rol destinatario).
    CONSTRAINT CK_Solicitud_distintos CHECK (id_solicitante <> id_destinatario)
);
GO

-- @entidad Silencio | Jugador silenciado por otro; solo lo consulta quien silenció (CU-33).
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

-- @entidad Bloqueo | Bloqueo entre dos jugadores; impide emparejar, invitar, buscar, solicitar y compartir sala (CU-33 RN-05).
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

-- @entidad ProgresoTutorial | Avance de cada cuenta en cada lección del tutorial; es la relación N:M entre Usuario y Leccion (CU-41).
-- @fn Llave compuesta usuario-lección. `completada` pasó a calculada porque dependía de `fecha_completada`.
CREATE TABLE dbo.ProgresoTutorial (
    id_usuario           INT            NOT NULL,  -- Cuenta.
    id_leccion           TINYINT        NOT NULL,  -- Lección.
    paso_actual          TINYINT        NOT NULL,  -- Último paso completado.
    fecha_actualizacion  DATETIME2(0)   NOT NULL DEFAULT (SYSUTCDATETIME()),  -- Último avance.
    fecha_completada     DATETIME2(0)   NULL,  -- Momento en que se terminó la lección.
    completada           AS (CASE WHEN fecha_completada IS NULL THEN CAST(0 AS BIT) ELSE CAST(1 AS BIT) END),  -- Si la lección está terminada. Calculada: es exactamente que `fecha_completada` no sea nula.
    CONSTRAINT PK_ProgresoTutorial PRIMARY KEY (id_usuario, id_leccion),
    CONSTRAINT FK_ProgresoTutorial_Usuario FOREIGN KEY (id_usuario) REFERENCES dbo.Usuario (id_usuario),  -- 1:N | Un usuario avanza en muchas lecciones.
    CONSTRAINT FK_ProgresoTutorial_Leccion FOREIGN KEY (id_leccion) REFERENCES dbo.Leccion (id_leccion),  -- 1:N | Una lección la cursan muchos usuarios.
    CONSTRAINT CK_ProgresoTutorial_paso CHECK (paso_actual >= 1)
);
GO

/*---------------------------------------------------------------------
  8. Moderación y bitácoras
  Nada de lo que produce la moderación se elimina.
---------------------------------------------------------------------*/

-- @entidad Reporte | Denuncia de un jugador contra otro. Las pruebas se adjuntan por referencia a la partida, no por copia (CU-42 RN-01).
-- @fn Llave simple. El motivo pasó a catálogo (*MotivoReporte*). La partida adjunta se valida con llaves foráneas compuestas hacia *Participacion* (CU-42 RN-09).
CREATE TABLE dbo.Reporte (
    id_reporte           INT IDENTITY(1,1) NOT NULL,  -- Identificador del reporte.
    id_denunciante       INT            NOT NULL,  -- Jugador que reporta (rol reportante del diagrama).
    id_reportado         INT            NOT NULL,  -- Jugador reportado.
    id_motivo            TINYINT        NOT NULL,  -- Motivo del catálogo.
    descripcion          NVARCHAR(500)  NULL,  -- Texto opcional del denunciante.
    id_partida           INT            NULL,  -- Partida de la que salen las pruebas, si se adjunta; la jugaron el denunciante y el reportado (CU-42 RN-09).
    fecha_reporte        DATETIME2(0)   NOT NULL DEFAULT (SYSUTCDATETIME()),  -- Envío.
    estado               VARCHAR(20)    NOT NULL DEFAULT ('PENDIENTE'),  -- `PENDIENTE`, `EN_REVISION`, `RESUELTO_SIN_SANCION` o `RESUELTO_CON_SANCION`.
    id_moderador         INT            NULL,  -- Moderador que lo tiene en revisión o lo resolvió.
    fecha_asignacion     DATETIME2(0)   NULL,  -- Momento en que se tomó; a los treinta minutos vuelve a la cola (CU-43 RN-03).
    nota_resolucion      NVARCHAR(1000) NULL,  -- Nota obligatoria al resolver (CU-43 RN-07).
    fecha_resolucion     DATETIME2(0)   NULL,  -- Momento de la resolución.
    CONSTRAINT PK_Reporte PRIMARY KEY (id_reporte),
    CONSTRAINT FK_Reporte_Denunciante FOREIGN KEY (id_denunciante) REFERENCES dbo.Usuario (id_usuario),  -- 1:N | Un usuario emite muchos reportes (relación Emite del diagrama).
    CONSTRAINT FK_Reporte_Reportado FOREIGN KEY (id_reportado) REFERENCES dbo.Usuario (id_usuario),  -- 1:N | Un usuario recibe muchos reportes (relación Señala del diagrama).
    CONSTRAINT FK_Reporte_MotivoReporte FOREIGN KEY (id_motivo) REFERENCES dbo.MotivoReporte (id_motivo),  -- 1:N | Un motivo clasifica muchos reportes.
    CONSTRAINT FK_Reporte_ParticipacionDenunciante FOREIGN KEY (id_partida, id_denunciante) REFERENCES dbo.Participacion (id_partida, id_usuario),  -- 1:N | La partida adjunta es una que jugó el denunciante (CU-42 RN-09; relación Sobre del diagrama).
    CONSTRAINT FK_Reporte_ParticipacionReportado FOREIGN KEY (id_partida, id_reportado) REFERENCES dbo.Participacion (id_partida, id_usuario),  -- 1:N | La partida adjunta es una que jugó el reportado (CU-42 RN-09).
    CONSTRAINT FK_Reporte_Moderador FOREIGN KEY (id_moderador) REFERENCES dbo.Usuario (id_usuario),  -- 1:N | Un moderador revisa muchos reportes.
    CONSTRAINT CK_Reporte_distintos CHECK (id_denunciante <> id_reportado),
    CONSTRAINT CK_Reporte_estado CHECK (
        (estado = 'PENDIENTE' AND id_moderador IS NULL AND fecha_asignacion IS NULL AND fecha_resolucion IS NULL)
        OR (estado = 'EN_REVISION' AND id_moderador IS NOT NULL AND fecha_asignacion IS NOT NULL AND fecha_resolucion IS NULL)
        OR (estado IN ('RESUELTO_SIN_SANCION','RESUELTO_CON_SANCION') AND id_moderador IS NOT NULL
            AND nota_resolucion IS NOT NULL AND fecha_resolucion IS NOT NULL))
);
GO
CREATE UNIQUE INDEX UX_Reporte_partida ON dbo.Reporte (id_denunciante, id_reportado, id_partida) WHERE id_partida IS NOT NULL;  -- No se reporta dos veces al mismo jugador por la misma partida (CU-42 RN-03).
CREATE INDEX IX_Reporte_cola ON dbo.Reporte (estado, fecha_reporte);
GO

-- @entidad Sancion | Sanción aplicada por un moderador, de ámbito de cuenta o de chat (D-05). Sustituye al Baneo del diagrama; al retirarse se desactiva, no se borra.
-- @fn Llave simple. `activa` pasó a calculada porque dependía de `fecha_retiro`. Sin num_reportes ni activo del Baneo del diagrama, que eran derivados. `tipo` es discriminador.
CREATE TABLE dbo.Sancion (
    id_sancion             INT IDENTITY(1,1) NOT NULL,  -- Identificador de la sanción.
    id_usuario             INT            NOT NULL,  -- Jugador sancionado.
    id_moderador           INT            NOT NULL,  -- Moderador que la aplicó; la conserva aunque se le retire el rol (CU-47 RN-03).
    id_reporte             INT            NULL,  -- Reporte que la originó, si lo hay.
    ambito                 VARCHAR(10)    NOT NULL,  -- `CUENTA` o `CHAT` (CU-44 RN-03).
    tipo                   VARCHAR(10)    NOT NULL,  -- `TEMPORAL` o `PERMANENTE`. Discrimina si aplica `fecha_fin`.
    motivo                 NVARCHAR(500)  NOT NULL,  -- Lo que comprobó el moderador (CU-44 RN-06).
    fecha_inicio           DATETIME2(0)   NOT NULL DEFAULT (SYSUTCDATETIME()),  -- Inicio de la sanción.
    fecha_fin              DATETIME2(0)   NULL,  -- Fin de una sanción temporal; nula si es permanente (CU-44 RN-04).
    fecha_retiro           DATETIME2(0)   NULL,  -- Retiro manual por apelación o por sustitución (CU-43 RN-06).
    id_sancion_sustituta   INT            NULL,  -- Sanción del mismo ámbito que la sustituyó (CU-44 RN-09).
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

-- @entidad Apelacion | Apelación de una sanción por parte del sancionado; hay a lo sumo una por sanción (CU-45 RN-01).
-- @fn Llave sustituta; `id_sancion` es llave candidata.
CREATE TABLE dbo.Apelacion (
    id_apelacion         INT IDENTITY(1,1) NOT NULL,  -- Identificador de la apelación.
    id_sancion           INT            NOT NULL,  -- Sanción apelada.
    texto                NVARCHAR(1000) NOT NULL,  -- Texto del sancionado; no se rechaza por lenguaje (CU-45 RN-04).
    marca_lenguaje       BIT            NOT NULL DEFAULT (0),  -- Si el filtro de palabras encontró un término, como aviso al moderador.
    fecha_apelacion      DATETIME2(0)   NOT NULL DEFAULT (SYSUTCDATETIME()),  -- Envío.
    estado               VARCHAR(12)    NOT NULL DEFAULT ('PENDIENTE'),  -- `PENDIENTE`, `EN_REVISION`, `ACEPTADA` o `RECHAZADA`.
    id_moderador         INT            NULL,  -- Moderador que la revisa; distinto del que aplicó la sanción (CU-45 RN-06).
    fecha_asignacion     DATETIME2(0)   NULL,  -- Momento en que se tomó; a los treinta minutos vuelve a la cola (CU-43 RN-03).
    nota_resolucion      NVARCHAR(1000) NULL,  -- Nota obligatoria al resolver.
    fecha_resolucion     DATETIME2(0)   NULL,  -- Momento de la resolución.
    CONSTRAINT PK_Apelacion PRIMARY KEY (id_apelacion),
    CONSTRAINT UQ_Apelacion_sancion UNIQUE (id_sancion),  -- Una sola apelación por sanción (CU-45 RN-01).
    CONSTRAINT FK_Apelacion_Sancion FOREIGN KEY (id_sancion) REFERENCES dbo.Sancion (id_sancion),  -- 1:0..1 | Una sanción tiene a lo sumo una apelación.
    CONSTRAINT FK_Apelacion_Moderador FOREIGN KEY (id_moderador) REFERENCES dbo.Usuario (id_usuario),  -- 1:N | Un moderador resuelve muchas apelaciones.
    CONSTRAINT CK_Apelacion_estado CHECK (
        (estado = 'PENDIENTE' AND id_moderador IS NULL AND fecha_asignacion IS NULL AND fecha_resolucion IS NULL)
        OR (estado = 'EN_REVISION' AND id_moderador IS NOT NULL AND fecha_asignacion IS NOT NULL AND fecha_resolucion IS NULL)
        OR (estado IN ('ACEPTADA','RECHAZADA') AND id_moderador IS NOT NULL AND nota_resolucion IS NOT NULL AND fecha_resolucion IS NOT NULL))
);
GO

-- @entidad BitacoraModeracion | Registro de cada acción de moderación y administración, incluida la consulta de las bitácoras (CU-48 RN-04). Solo admite inserción.
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

-- @entidad BitacoraAcceso | Registro de cada intento de acceso y de cada cambio de credenciales, exitoso o no. Nunca contiene contraseñas ni códigos (CU-48 RN-05).
-- @fn Llave simple; solo admite inserción.
CREATE TABLE dbo.BitacoraAcceso (
    id_bitacora             BIGINT IDENTITY(1,1) NOT NULL,  -- Identificador del registro.
    id_usuario              INT            NULL,  -- Cuenta, si se identificó; nula en intentos contra cuentas inexistentes.
    identificador_capturado NVARCHAR(254)  NULL,  -- Nickname o correo tecleado; único rastro de un intento contra una cuenta inexistente (CU-48 RN-06).
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
  9. Procedimientos para las eliminaciones físicas
  El usuario de conexión no tiene permiso DELETE. Las únicas filas que
  la aplicación borra (cola, plazas de sala, solicitudes, amistades,
  silencios, bloqueos y enlaces del perfil) se borran con estos
  procedimientos, que pertenecen a dbo igual que las tablas: por el
  encadenamiento de propiedad, SQL Server no comprueba el permiso
  DELETE de quien ejecuta, solo su permiso EXECUTE.
---------------------------------------------------------------------*/

-- CU-17 FA-03 y EX-04, CU-11: el jugador sale de la cola o es emparejado.
CREATE PROCEDURE dbo.usp_ColaEmparejamiento_Salir
    @id_usuario INT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM dbo.ColaEmparejamiento WHERE id_usuario = @id_usuario;
    SELECT @@ROWCOUNT AS filas_eliminadas;
END;
GO

-- CU-18 FA-05, CU-19: un miembro sale de la sala. Si sale el anfitrión, la sala se cierra (CU-18 RN-07).
CREATE PROCEDURE dbo.usp_SalaParticipante_Salir
    @id_sala    INT,
    @id_usuario INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRANSACTION;
        IF EXISTS (SELECT 1 FROM dbo.Sala WHERE id_sala = @id_sala AND id_anfitrion = @id_usuario AND estado <> 'CERRADA')
        BEGIN
            UPDATE dbo.Sala SET estado = 'CERRADA' WHERE id_sala = @id_sala;
            DELETE FROM dbo.SalaParticipante WHERE id_sala = @id_sala;
        END
        ELSE
        BEGIN
            DELETE FROM dbo.SalaParticipante WHERE id_sala = @id_sala AND id_usuario = @id_usuario;
            UPDATE dbo.Sala SET fecha_ultima_actividad = SYSUTCDATETIME() WHERE id_sala = @id_sala;
        END
    COMMIT TRANSACTION;
END;
GO

-- CU-18 FA-09, CU-25 FA-08: la sala se cierra por inactividad o al terminar su partida.
CREATE PROCEDURE dbo.usp_Sala_Cerrar
    @id_sala INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRANSACTION;
        UPDATE dbo.Sala SET estado = 'CERRADA' WHERE id_sala = @id_sala;
        DELETE FROM dbo.SalaParticipante WHERE id_sala = @id_sala;
    COMMIT TRANSACTION;
END;
GO

-- CU-31: la solicitud se elimina al aceptarla, rechazarla o cancelarla (CU-31 RN-06).
CREATE PROCEDURE dbo.usp_Solicitud_Eliminar
    @id_solicitud INT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM dbo.Solicitud WHERE id_solicitud = @id_solicitud;
    SELECT @@ROWCOUNT AS filas_eliminadas;
END;
GO

-- CU-49: eliminar a un amigo. Se busca por el par ordenado (CU-49 RN-02).
CREATE PROCEDURE dbo.usp_Amistad_Eliminar
    @id_usuario INT,
    @id_amigo   INT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM dbo.Amistad
    WHERE id_usuario_a = CASE WHEN @id_usuario < @id_amigo THEN @id_usuario ELSE @id_amigo END
      AND id_usuario_b = CASE WHEN @id_usuario < @id_amigo THEN @id_amigo ELSE @id_usuario END;
    SELECT @@ROWCOUNT AS filas_eliminadas;
END;
GO

-- CU-33 FA-07: dejar de silenciar.
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

-- CU-33 FA-07: desbloquear. No restaura la amistad eliminada (CU-33 RN-06).
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

-- CU-12 paso 13: el jugador quita un enlace de su perfil.
CREATE PROCEDURE dbo.usp_EnlaceRed_Eliminar
    @id_usuario INT,
    @id_enlace  INT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM dbo.EnlaceRed WHERE id_enlace = @id_enlace AND id_usuario = @id_usuario;
    SELECT @@ROWCOUNT AS filas_eliminadas;
END;
GO

-- CU-33 pasos 7 a 9: bloquear elimina la amistad, las solicitudes y las invitaciones pendientes del par,
-- y si comparten sala retira al bloqueado cuando el anfitrión es quien bloquea, o a quien bloquea en caso contrario.
CREATE PROCEDURE dbo.usp_Bloqueo_Aplicar
    @id_bloqueador INT,
    @id_bloqueado  INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @menor INT = CASE WHEN @id_bloqueador < @id_bloqueado THEN @id_bloqueador ELSE @id_bloqueado END;
    DECLARE @mayor INT = CASE WHEN @id_bloqueador < @id_bloqueado THEN @id_bloqueado ELSE @id_bloqueador END;
    DECLARE @id_sala INT, @id_anfitrion INT;

    BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM dbo.Bloqueo WHERE id_bloqueador = @id_bloqueador AND id_bloqueado = @id_bloqueado)
            INSERT INTO dbo.Bloqueo (id_bloqueador, id_bloqueado) VALUES (@id_bloqueador, @id_bloqueado);

        DELETE FROM dbo.Amistad WHERE id_usuario_a = @menor AND id_usuario_b = @mayor;

        DELETE FROM dbo.Solicitud
        WHERE (id_solicitante = @id_bloqueador AND id_destinatario = @id_bloqueado)
           OR (id_solicitante = @id_bloqueado AND id_destinatario = @id_bloqueador);

        UPDATE dbo.Invitacion SET estado = 'EXPIRADA'
        WHERE estado = 'PENDIENTE'
          AND ((id_emisor = @id_bloqueador AND id_destinatario = @id_bloqueado)
            OR (id_emisor = @id_bloqueado AND id_destinatario = @id_bloqueador));

        SELECT @id_sala = s.id_sala, @id_anfitrion = s.id_anfitrion
        FROM dbo.Sala AS s
        JOIN dbo.SalaParticipante AS a ON a.id_sala = s.id_sala AND a.id_usuario = @id_bloqueador
        JOIN dbo.SalaParticipante AS b ON b.id_sala = s.id_sala AND b.id_usuario = @id_bloqueado
        WHERE s.estado = 'ABIERTA';

        IF @id_sala IS NOT NULL
            DELETE FROM dbo.SalaParticipante
            WHERE id_sala = @id_sala
              AND id_usuario = CASE WHEN @id_anfitrion = @id_bloqueador THEN @id_bloqueado ELSE @id_bloqueador END;
    COMMIT TRANSACTION;
END;
GO

-- CU-11 pasos 13 a 18: baja definitiva de la cuenta, con la anonimización en la misma transacción
-- (D-07, D-17). La fila de Usuario se conserva porque otros registros dependen de ella.
-- El servidor comprueba antes la contraseña y que no haya partida en línea sin terminar (pasos 9 y 10).
CREATE PROCEDURE dbo.usp_Usuario_DarDeBaja
    @id_usuario INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @id_sala_propia INT;

    BEGIN TRANSACTION;
        -- Paso 13. El prefijo anonimo_ es un formato reservado que ningún jugador puede elegir,
        -- como el del invitado (CU-06 RN-02), así que los valores anónimos son únicos.
        UPDATE dbo.Usuario
        SET estado_cuenta    = 'ELIMINADA',
            fecha_baja       = SYSUTCDATETIME(),
            nickname         = CONCAT(N'anonimo_', id_usuario),
            correo           = CONCAT(N'anonimo_', id_usuario, N'@bastion.invalid'),
            contrasena_hash  = NULL,
            contrasena_sal   = NULL,
            fecha_nacimiento = NULL,
            codigo_amigo     = NULL
        WHERE id_usuario = @id_usuario
          AND tipo_cuenta = 'REGISTRADA'
          AND rol <> 'ADMINISTRADOR'
          AND estado_cuenta <> 'ELIMINADA';
        IF @@ROWCOUNT = 0
            THROW 50001, N'La cuenta no existe, ya fue dada de baja, es de invitado o es de administración (CU-11 RN-06, RN-07).', 1;

        -- Paso 14
        DELETE FROM dbo.EnlaceRed         WHERE id_usuario = @id_usuario;
        DELETE FROM dbo.HistorialNickname WHERE id_usuario = @id_usuario;
        DELETE FROM dbo.Amistad           WHERE id_usuario_a = @id_usuario OR id_usuario_b = @id_usuario;
        DELETE FROM dbo.Silencio          WHERE id_usuario = @id_usuario OR id_silenciado = @id_usuario;
        DELETE FROM dbo.Bloqueo           WHERE id_bloqueador = @id_usuario OR id_bloqueado = @id_usuario;
        UPDATE dbo.Avatar SET vigente = 0 WHERE id_usuario = @id_usuario AND vigente = 1;

        -- Paso 15. Si era anfitrión de una sala abierta, la sala se cierra (CU-18 RN-07).
        DELETE FROM dbo.ColaEmparejamiento WHERE id_usuario = @id_usuario;
        SELECT @id_sala_propia = id_sala FROM dbo.Sala WHERE id_anfitrion = @id_usuario AND estado = 'ABIERTA';
        IF @id_sala_propia IS NOT NULL
        BEGIN
            UPDATE dbo.Sala SET estado = 'CERRADA' WHERE id_sala = @id_sala_propia;
            DELETE FROM dbo.SalaParticipante WHERE id_sala = @id_sala_propia;
        END
        DELETE FROM dbo.SalaParticipante WHERE id_usuario = @id_usuario;

        -- Paso 16
        DELETE FROM dbo.Solicitud WHERE id_solicitante = @id_usuario OR id_destinatario = @id_usuario;
        UPDATE dbo.Invitacion SET estado = 'EXPIRADA'
        WHERE estado = 'PENDIENTE' AND (id_emisor = @id_usuario OR id_destinatario = @id_usuario);

        -- Paso 17
        UPDATE dbo.Reporte SET estado = 'PENDIENTE', id_moderador = NULL, fecha_asignacion = NULL
        WHERE estado = 'EN_REVISION' AND id_moderador = @id_usuario;

        -- Paso 18
        UPDATE dbo.Sesion SET fecha_fin = SYSUTCDATETIME(), motivo_cierre = 'BAJA_CUENTA'
        WHERE id_usuario = @id_usuario AND fecha_fin IS NULL;
    COMMIT TRANSACTION;
END;
GO

/*=====================================================================
  Bastion - Tablas de la fase posterior
  Motor: SQL Server 2019 o posterior (CON-04).

  NO forma parte de la entrega de las catorce semanas. Crea las tablas y
  las columnas que solo existen por los agregados del equipo: cosméticos
  y skins, tienda, cajas, monedas, niveles, divisiones, perfil, amigos,
  invitaciones, espectador, IA y tutorial (D-22). Los casos de uso que
  las escriben están marcados como fase posterior en la sección
  "Priorización de requisitos y casos de uso".

  Orden de ejecución, sobre una base que ya tiene el núcleo:
     1. crear_base_datos.sql
     2. crear_tablas.sql
     3. insertar_datos_prueba.sql
     4. fase_posterior/crear_tablas_fase_posterior.sql   <- este archivo
     5. fase_posterior/insertar_datos_prueba_fase_posterior.sql

  Contenido:
     1. Catálogos precargados de la fase posterior (D-09)
     2. Columnas y restricciones que se agregan al núcleo
     3. Perfil y personalización
     4. Aspecto en partida y espectador
     5. Invitaciones
     6. Clasificación y economía
     7. Relaciones entre jugadores y tutorial
     8. Procedimientos

  Las tablas conservan las convenciones de crear_tablas.sql, y sus
  comentarios se convierten en el documento con bd/generar_tablas.ps1
  (-Sql fase_posterior/crear_tablas_fase_posterior.sql).
=====================================================================*/

USE Bastion;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/*---------------------------------------------------------------------
  1. Catálogos precargados de la fase posterior (D-09)
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

/*---------------------------------------------------------------------
  2. Columnas y restricciones que se agregan al núcleo
  Van antes que las tablas nuevas porque algunas de ellas (HistorialDivision,
  ParticipacionObjeto) dependen de estas columnas o de sus llaves.
---------------------------------------------------------------------*/

-- Usuario: lo que usan el perfil, la economía, los amigos y el espectador.
ALTER TABLE dbo.Usuario ADD
    codigo_amigo                 CHAR(8)        NULL,  -- Código para encontrar al jugador sin su nickname (CU-30 RN-06).
    id_icono                     TINYINT        NOT NULL CONSTRAINT DF_Usuario_id_icono DEFAULT (1),  -- Icono predefinido, de 1 a 32 (CU-08 RN-03).
    permite_espectadores         BIT            NOT NULL CONSTRAINT DF_Usuario_permite_espectadores DEFAULT (1),  -- Si admite espectadores (CU-34 RN-02).
    nivel                        SMALLINT       NOT NULL CONSTRAINT DF_Usuario_nivel DEFAULT (1),  -- Nivel alcanzado.
    experiencia                  INT            NOT NULL CONSTRAINT DF_Usuario_experiencia DEFAULT (0),  -- Experiencia acumulada.
    saldo_monedas                INT            NOT NULL CONSTRAINT DF_Usuario_saldo_monedas DEFAULT (0),  -- Copia de la suma de MovimientoMoneda; redundancia controlada (CU-40 RN-02).
    cajas_sin_raro               TINYINT        NOT NULL CONSTRAINT DF_Usuario_cajas_sin_raro DEFAULT (0),  -- Cajas seguidas sin objeto raro (CU-39 RN-05).
    fecha_configuracion_inicial  DATETIME2(0)   NULL;  -- Marca de la configuración de primera vez (CU-08 RN-01).
GO
ALTER TABLE dbo.Usuario ADD
    CONSTRAINT CK_Usuario_rangos CHECK (id_icono BETWEEN 1 AND 32 AND nivel >= 1 AND experiencia >= 0
        AND saldo_monedas >= 0 AND cajas_sin_raro BETWEEN 0 AND 10);
CREATE UNIQUE INDEX UX_Usuario_codigo_amigo ON dbo.Usuario (codigo_amigo) WHERE codigo_amigo IS NOT NULL;  -- El código de amigo es único por cuenta (CU-30 RN-06).
GO

-- EstadisticaModo: lo que muestran el perfil y el ranking.
ALTER TABLE dbo.EstadisticaModo ADD
    elo_maximo           SMALLINT       NOT NULL CONSTRAINT DF_EstadisticaModo_elo_maximo DEFAULT (1000),  -- Elo más alto alcanzado.
    racha_actual         SMALLINT       NOT NULL CONSTRAINT DF_EstadisticaModo_racha_actual DEFAULT (0),  -- Victorias seguidas por llegada a meta (CU-25 RN-11).
    mejor_racha          SMALLINT       NOT NULL CONSTRAINT DF_EstadisticaModo_mejor_racha DEFAULT (0),  -- Racha más larga.
    tiempo_total_jugado  INT            NOT NULL CONSTRAINT DF_EstadisticaModo_tiempo DEFAULT (0),  -- Segundos jugados en partidas clasificatorias del modo.
    barreras_colocadas   INT            NOT NULL CONSTRAINT DF_EstadisticaModo_barreras DEFAULT (0),  -- Muros colocados, contados desde Jugada al cerrar cada partida.
    id_division          TINYINT        NULL;  -- División actual; nula hasta jugar cinco partidas en el modo (CU-25 RN-14).
GO
ALTER TABLE dbo.EstadisticaModo ADD
    CONSTRAINT FK_EstadisticaModo_Division FOREIGN KEY (id_division) REFERENCES dbo.Division (id_division),
    CONSTRAINT CK_EstadisticaModo_progresion CHECK (tiempo_total_jugado >= 0 AND barreras_colocadas >= 0
        AND racha_actual >= 0 AND mejor_racha >= racha_actual AND elo_maximo >= puntos_elo);
GO

-- Sala: si la partida de la sala admite espectadores.
ALTER TABLE dbo.Sala ADD
    permite_espectadores BIT NOT NULL CONSTRAINT DF_Sala_permite_espectadores DEFAULT (1);
GO

-- Partida: las partidas contra la IA (D-12). El reloj se vuelve opcional y el
-- tipo admite IA; hay que soltar antes las restricciones que leen esas columnas.
ALTER TABLE dbo.Partida DROP CONSTRAINT CK_Partida_tipo, CK_Partida_reloj;
ALTER TABLE dbo.Partida ALTER COLUMN minutos_reloj TINYINT NULL;
ALTER TABLE dbo.Partida ADD
    id_nivel_ia          TINYINT        NULL,  -- Nivel de la IA; solo en partidas IA (D-12).
    permite_deshacer     BIT            NULL,  -- Opción elegida al empezar; solo en partidas IA.
    permite_sugerencias  BIT            NULL,  -- Opción elegida al empezar; solo en partidas IA.
    deshacer_usados      TINYINT        NULL,  -- Veces que se usó deshacer; solo en partidas IA.
    sugerencias_usadas   TINYINT        NULL;  -- Sugerencias pedidas; solo en partidas IA.
GO
ALTER TABLE dbo.Partida ADD
    CONSTRAINT FK_Partida_NivelIA FOREIGN KEY (id_nivel_ia) REFERENCES dbo.NivelIA (id_nivel_ia),
    CONSTRAINT CK_Partida_tipo CHECK (tipo IN ('CLASIFICATORIA','PRIVADA','IA')),
    CONSTRAINT CK_Partida_reloj CHECK (minutos_reloj IN (3, 5, 10)),
    CONSTRAINT CK_Partida_ia CHECK (
        (tipo = 'IA' AND id_nivel_ia IS NOT NULL AND permite_deshacer IS NOT NULL AND permite_sugerencias IS NOT NULL
            AND deshacer_usados IS NOT NULL AND sugerencias_usadas IS NOT NULL)
        OR (tipo <> 'IA' AND id_nivel_ia IS NULL AND permite_deshacer IS NULL AND permite_sugerencias IS NULL
            AND deshacer_usados IS NULL AND sugerencias_usadas IS NULL AND minutos_reloj IS NOT NULL));
GO

-- Jugada: las de la IA no tienen jugador, y deshacer las marca en lugar de borrarlas
-- (CU-27 RN-03, RN-05). La llave foránea lee id_usuario, así que se suelta y se repone.
ALTER TABLE dbo.Jugada DROP CONSTRAINT FK_Jugada_Participacion;
ALTER TABLE dbo.Jugada ALTER COLUMN id_usuario INT NULL;
ALTER TABLE dbo.Jugada ADD
    deshecha BIT NOT NULL CONSTRAINT DF_Jugada_deshecha DEFAULT (0);  -- Marca de deshacer contra la IA.
GO
ALTER TABLE dbo.Jugada ADD
    CONSTRAINT FK_Jugada_Participacion FOREIGN KEY (id_partida, id_usuario) REFERENCES dbo.Participacion (id_partida, id_usuario);
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
  4. Aspecto en partida y espectador
---------------------------------------------------------------------*/

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
  5. Invitaciones
---------------------------------------------------------------------*/

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

/*---------------------------------------------------------------------
  6. Clasificación y economía
---------------------------------------------------------------------*/

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
  8. Procedimientos
  Borrados físicos de la fase posterior y versión completa del bloqueo.
---------------------------------------------------------------------*/

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

-- CU-33 pasos 7 a 9, versión completa: bloquear elimina además la amistad, las solicitudes y las
-- invitaciones pendientes del par. Las plazas de sala se llevan en memoria (D-24).
ALTER PROCEDURE dbo.usp_Bloqueo_Aplicar
    @id_bloqueador INT,
    @id_bloqueado  INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @menor INT = CASE WHEN @id_bloqueador < @id_bloqueado THEN @id_bloqueador ELSE @id_bloqueado END;
    DECLARE @mayor INT = CASE WHEN @id_bloqueador < @id_bloqueado THEN @id_bloqueado ELSE @id_bloqueador END;

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

        -- Paso 15. Si era anfitrión de una sala abierta, la sala se cierra (CU-18 RN-07). La cola y
        -- las plazas de sala las vacía el Servidor de partidas en memoria (D-24).
        UPDATE dbo.Sala SET estado = 'CERRADA' WHERE id_anfitrion = @id_usuario AND estado = 'ABIERTA';

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

/*=====================================================================
  Bastion - Inserción de datos de prueba (3 de 3)
  Motor: SQL Server 2019 o posterior (CON-04); probado en SQL Server 2025.

  Orden de ejecución:
     1. crear_base_datos.sql
     2. crear_tablas.sql
     3. insertar_datos_prueba.sql  <- este archivo

  Archivo generado por bd/generar_datos_prueba.py a partir del escenario de
  bd/datos_prueba/. No editar a mano: se edita el escenario y se vuelve a
  generar.

  Carga los catálogos precargados (D-09) y un escenario de prueba que ocupa
  las 47 tablas. Es una fotografía de la base el 2026-09-01 18:00:00 UTC.
  Lo que el modelo guarda como consecuencia de otras filas (elo,
  estadísticas, divisiones, saldo, estado del tablero) se calculó a partir
  de ellas, y las consultas del final lo comprueban.

  Se ejecuta con una cuenta de administración sobre las tablas recién
  creadas y vacías: fija los identificadores con IDENTITY_INSERT, que
  BastionServerConnection no puede usar. Todo va en una transacción: si
  una fila falla, no se carga ninguna.

  El archivo está en UTF-8: se ejecuta con sqlcmd -f 65001, o se abre en
  SQL Server Management Studio, que lo reconoce por su marca de orden de
  bytes. Los textos van como literales N'...', con sus eñes y acentos, y la
  comprobación 16 del final verifica que se guardaron sin pérdida (D-21).
=====================================================================*/

USE Bastion;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

BEGIN TRANSACTION;

/*---------------------------------------------------------------------
  Catálogos precargados (D-09)
---------------------------------------------------------------------*/

-- Cada catálogo guarda el código de cada fila; su nombre está en los diccionarios de recursos (D-21).
INSERT INTO dbo.Ranura (id_ranura, codigo) VALUES
    (1, N'PEON'),
    (2, N'MURO'),
    (3, N'TABLERO'),
    (4, N'TITULO'),
    (5, N'MARCO'),
    (6, N'EMOTES');

INSERT INTO dbo.ObjetoCosmetico (id_objeto, id_ranura, codigo, rareza, precio, nivel_requerido, a_la_venta, activo, es_inicial, es_predeterminado) VALUES
    (101, 1, N'PEON_CLASICO', N'COMUN', 0, 1, 0, 1, 1, 1),
    (102, 1, N'PEON_PIEDRA', N'COMUN', 0, 1, 0, 1, 1, 0),
    (103, 1, N'PEON_CRISTAL', N'RARO', 250, 3, 1, 1, 0, 0),
    (104, 1, N'PEON_DORADO', N'EPICO', 600, 8, 1, 1, 0, 0),
    (105, 1, N'PEON_DRAGON', N'LEGENDARIO', 0, 1, 0, 1, 0, 0),
    (106, 1, N'PEON_TEMPORADA_1', N'RARO', 0, 1, 0, 0, 0, 0),
    (201, 2, N'MURO_MADERA', N'COMUN', 0, 1, 0, 1, 1, 1),
    (202, 2, N'MURO_LADRILLO', N'COMUN', 150, 1, 1, 1, 0, 0),
    (203, 2, N'MURO_HIELO', N'RARO', 0, 1, 0, 1, 0, 0),
    (204, 2, N'MURO_RUNICO', N'EPICO', 500, 5, 1, 1, 0, 0),
    (301, 3, N'TABLERO_CLASICO', N'COMUN', 0, 1, 0, 1, 1, 1),
    (302, 3, N'TABLERO_MARMOL', N'RARO', 300, 4, 1, 1, 0, 0),
    (303, 3, N'TABLERO_NOCTURNO', N'EPICO', 0, 1, 0, 1, 0, 0),
    (401, 4, N'TITULO_NOVATO', N'COMUN', 0, 1, 0, 1, 1, 1),
    (402, 4, N'TITULO_CONSTRUCTOR', N'RARO', 0, 3, 0, 1, 0, 0),
    (403, 4, N'TITULO_ESTRATEGA', N'EPICO', 400, 6, 1, 1, 0, 0),
    (501, 5, N'MARCO_SENCILLO', N'COMUN', 0, 1, 0, 1, 1, 1),
    (502, 5, N'MARCO_PLATA', N'RARO', 200, 2, 1, 1, 0, 0),
    (503, 5, N'MARCO_FUEGO', N'LEGENDARIO', 0, 1, 0, 1, 0, 0),
    (601, 6, N'EMOTE_SALUDO', N'COMUN', 0, 1, 0, 1, 1, 1),
    (602, 6, N'EMOTE_PULGAR_ARRIBA', N'COMUN', 0, 1, 0, 1, 1, 0),
    (603, 6, N'EMOTE_RISA', N'RARO', 120, 1, 1, 1, 0, 0),
    (604, 6, N'EMOTE_APLAUSO', N'EPICO', 0, 1, 0, 1, 0, 0);

INSERT INTO dbo.Modo (id_modo, codigo, tamano_tablero, num_jugadores, muros_por_jugador, activo) VALUES
    (1, N'CLASICO', 9, 2, 10, 1),
    (2, N'CUATRO_JUGADORES', 9, 4, 5, 1),
    (3, N'RAPIDA', 7, 2, 6, 1);

INSERT INTO dbo.Division (id_division, codigo, elo_minimo, elo_descenso) VALUES
    (1, N'BRONCE', 0, 0),
    (2, N'PLATA', 1030, 1010),
    (3, N'ORO', 1150, 1130),
    (4, N'MURO_PIEDRA', 1300, 1280);

INSERT INTO dbo.NivelIA (id_nivel_ia, codigo, elo_aproximado) VALUES
    (1, N'APRENDIZ', 1000),
    (2, N'CONSTRUCTOR', 1500),
    (3, N'ARQUITECTO', 1900),
    (4, N'BASTION', 2300);

INSERT INTO dbo.Leccion (id_leccion, orden, codigo, num_pasos) VALUES
    (1, 1, N'TABLERO_Y_META', 3),
    (2, 2, N'MOVER_PEON', 4),
    (3, 3, N'SALTAR_RIVAL', 4),
    (4, 4, N'COLOCAR_MUROS', 5),
    (5, 5, N'MUROS_SIN_ENCIERRO', 4),
    (6, 6, N'RELOJ', 3),
    (7, 7, N'PARTIDA_CUATRO', 4);

INSERT INTO dbo.TipoCaja (id_tipo_caja, codigo, precio, activo) VALUES
    (1, N'CAJA_MADERA', 300, 1),
    (2, N'CAJA_HIERRO', 700, 1),
    (3, N'CAJA_TEMPORADA_1', 500, 0);

INSERT INTO dbo.TipoCajaObjeto (id_tipo_caja, id_objeto, probabilidad) VALUES
    (1, 202, 30),
    (1, 603, 30),
    (1, 502, 20),
    (1, 203, 12),
    (1, 303, 5),
    (1, 604, 3),
    (2, 103, 25),
    (2, 302, 25),
    (2, 203, 20),
    (2, 604, 15),
    (2, 105, 10),
    (2, 503, 5),
    (3, 106, 60),
    (3, 603, 40);

-- Un término sin idioma se filtra en todos (CU-28 RN-01).
SET IDENTITY_INSERT dbo.PalabraProhibida ON;
INSERT INTO dbo.PalabraProhibida (id_palabra, termino, idioma, ambito) VALUES
    (1, N'tonto', N'es-MX', N'AMBOS'),
    (2, N'idiota', N'es-MX', N'AMBOS'),
    (3, N'estúpido', N'es-MX', N'CHAT'),
    (4, N'admin', NULL, N'NICKNAME'),
    (5, N'moderador', N'es-MX', N'NICKNAME'),
    (6, N'moderator', N'en', N'NICKNAME'),
    (7, N'idiot', N'en', N'AMBOS'),
    (8, N'stupid', N'en', N'CHAT');
SET IDENTITY_INSERT dbo.PalabraProhibida OFF;

INSERT INTO dbo.MotivoReporte (id_motivo, codigo) VALUES
    (1, N'LENGUAJE_OFENSIVO'),
    (2, N'ACOSO'),
    (3, N'NOMBRE_INAPROPIADO'),
    (4, N'TRAMPAS'),
    (5, N'JUEGO_ANTIDEPORTIVO');

/*---------------------------------------------------------------------
  Cuenta y acceso
---------------------------------------------------------------------*/

-- Saldo y cajas sin objeto raro salen de los movimientos y cajas de más abajo.
SET IDENTITY_INSERT dbo.Usuario ON;
INSERT INTO dbo.Usuario (id_usuario, tipo_cuenta, estado_cuenta, rol, nickname, correo, contrasena_hash, contrasena_sal, fecha_nacimiento, idioma_preferido, codigo_amigo, id_icono, permite_espectadores, nivel, experiencia, saldo_monedas, cajas_sin_raro, intentos_fallidos, fecha_ultimo_intento_fallido, bloqueada_hasta, doble_factor_habilitado, fecha_registro, fecha_configuracion_inicial, fecha_ultimo_envio_verificacion, fecha_ultimo_envio_recuperacion, fecha_baja) VALUES
    (1, N'REGISTRADA', N'ACTIVA', N'ADMINISTRADOR', N'admin_bastion', N'admin@bastion.mx', HASHBYTES('SHA2_512', 'Admin#2026:admin_bastion'), HASHBYTES('SHA2_256', 'sal:admin_bastion'), '1990-05-12', N'es-MX', N'ADM7KQ2P', 1, 1, 1, 0, 0, 0, 3, '2026-09-01T09:02:10', '2026-09-01T09:07:10', 0, '2026-06-01T10:00:00', '2026-06-01T10:05:00', '2026-06-01T10:00:00', '2026-09-01T17:46:00', NULL),
    (2, N'REGISTRADA', N'ACTIVA', N'MODERADOR', N'ana_modera', N'ana.moderadora@correo.mx', HASHBYTES('SHA2_512', 'Ana#Modera26:ana_modera'), HASHBYTES('SHA2_256', 'sal:ana_modera'), '1995-02-20', N'es-MX', N'ANA4M9QX', 7, 1, 1, 150, 0, 0, 0, NULL, NULL, 0, '2026-06-02T09:00:00', '2026-06-02T09:04:00', '2026-06-02T09:00:00', NULL, NULL),
    (3, N'REGISTRADA', N'ACTIVA', N'JUGADOR', N'luis_quo', N'luis.quo@correo.mx', HASHBYTES('SHA2_512', 'Luis#Quo2026:luis_quo'), HASHBYTES('SHA2_256', 'sal:luis_quo'), '2008-03-15', N'es-MX', N'LQ8R2T6W', 12, 1, 4, 1650, 245, 0, 0, NULL, NULL, 0, '2026-06-10T16:00:00', '2026-06-10T16:06:00', '2026-09-01T17:20:00', NULL, NULL),
    (4, N'REGISTRADA', N'ACTIVA', N'JUGADOR', N'marta_muros', N'marta@correo.mx', HASHBYTES('SHA2_512', 'Marta#Muros9:marta_muros'), HASHBYTES('SHA2_256', 'sal:marta_muros'), '2009-07-01', N'es-MX', N'MM3P7Z4K', 5, 1, 3, 900, 310, 0, 0, NULL, NULL, 1, '2026-06-12T18:30:00', '2026-06-12T18:35:00', '2026-06-12T18:30:00', NULL, NULL),
    (5, N'REGISTRADA', N'ACTIVA', N'JUGADOR', N'pedro_peon', N'pedro@correo.mx', HASHBYTES('SHA2_512', 'Pedro#Peon13:pedro_peon'), HASHBYTES('SHA2_256', 'sal:pedro_peon'), '2012-11-30', N'es-MX', N'PP6N2C8V', 3, 0, 2, 420, 80, 0, 0, NULL, NULL, 0, '2026-06-15T12:00:00', '2026-06-15T12:10:00', '2026-06-15T12:00:00', NULL, NULL),
    (6, N'REGISTRADA', N'ACTIVA', N'JUGADOR', N'sofia_salto', N'sofia@correo.mx', HASHBYTES('SHA2_512', 'Sofia#Salto8:sofia_salto'), HASHBYTES('SHA2_256', 'sal:sofia_salto'), '2011-04-18', N'en', N'SS9H3J5D', 20, 1, 2, 380, 90, 0, 0, NULL, NULL, 0, '2026-06-18T20:00:00', '2026-06-18T20:03:00', '2026-06-18T20:00:00', '2026-08-20T10:55:00', NULL),
    (7, N'INVITADO', N'ACTIVA', N'JUGADOR', N'Invitado_4821', NULL, NULL, NULL, NULL, N'es-MX', NULL, 1, 1, 1, 60, 0, 0, 0, NULL, NULL, 0, '2026-08-30T16:00:00', NULL, NULL, NULL, NULL),
    (8, N'REGISTRADA', N'PENDIENTE', N'JUGADOR', N'nico_nuevo', N'nico@correo.mx', HASHBYTES('SHA2_512', 'Nico#Nuevo26:nico_nuevo'), HASHBYTES('SHA2_256', 'sal:nico_nuevo'), '2010-09-09', N'es-MX', N'NN5T8B2R', 1, 1, 1, 0, 0, 0, 0, NULL, NULL, 0, '2026-08-28T19:00:00', NULL, '2026-09-01T12:00:00', NULL, NULL),
    (9, N'REGISTRADA', N'SUSPENDIDA', N'JUGADOR', N'rayo_veloz', N'rayo@correo.mx', HASHBYTES('SHA2_512', 'Rayo#Veloz77:rayo_veloz'), HASHBYTES('SHA2_256', 'sal:rayo_veloz'), '2007-12-01', N'es-MX', N'RV2K9X4M', 9, 1, 1, 90, 25, 0, 0, NULL, NULL, 0, '2026-06-20T15:00:00', '2026-06-20T15:02:00', '2026-06-20T15:00:00', NULL, NULL),
    (10, N'REGISTRADA', N'ELIMINADA', N'JUGADOR', N'anonimo_10', N'anonimo_10', NULL, NULL, NULL, N'es-MX', NULL, 1, 1, 1, 200, 0, 0, 0, NULL, NULL, 0, '2026-06-22T11:00:00', '2026-06-22T11:05:00', '2026-06-22T11:00:00', NULL, '2026-08-02T13:00:00'),
    (11, N'REGISTRADA', N'BANEADA', N'JUGADOR', N'4dm1n_oficial', N'cuatro.admin@correo.mx', HASHBYTES('SHA2_512', 'Adm1n#Falso6:4dm1n_oficial'), HASHBYTES('SHA2_256', 'sal:4dm1n_oficial'), '2006-01-10', N'es-MX', N'FK4D9M2N', 2, 1, 1, 0, 0, 0, 0, NULL, NULL, 0, '2026-08-22T19:00:00', '2026-08-22T19:18:00', '2026-08-22T19:00:00', NULL, NULL);
SET IDENTITY_INSERT dbo.Usuario OFF;

SET IDENTITY_INSERT dbo.Sesion ON;
INSERT INTO dbo.Sesion (id_sesion, id_usuario, token_hash, fecha_inicio, fecha_expiracion, fecha_ultimo_uso, fecha_fin, motivo_cierre, direccion_ip, huella_dispositivo, nombre_dispositivo, version_cliente) VALUES
    (1, 1, HASHBYTES('SHA2_256', 'sesion:1'), '2026-08-31T08:00:00', '2026-09-01T08:00:00', '2026-08-31T11:58:00', '2026-08-31T12:00:00', N'CIERRE_VOLUNTARIO', N'189.203.14.20', N'hw-admin-01', N'Laptop de oficina', N'1.0.2'),
    (2, 2, HASHBYTES('SHA2_256', 'sesion:2'), '2026-09-01T17:00:00', '2026-09-02T17:00:00', '2026-09-01T17:59:00', NULL, NULL, N'201.141.22.7', N'hw-ana-01', N'PC de escritorio', N'1.0.2'),
    (3, 3, HASHBYTES('SHA2_256', 'sesion:3'), '2026-08-31T20:00:00', '2026-09-01T20:00:00', '2026-08-31T22:30:00', '2026-09-01T17:10:00', N'CIERRE_REMOTO', N'189.203.55.3', N'hw-luis-tab', N'Tableta', N'1.0.2'),
    (4, 3, HASHBYTES('SHA2_256', 'sesion:4'), '2026-09-01T17:05:00', '2026-09-02T17:05:00', '2026-09-01T17:59:00', NULL, NULL, N'189.203.55.9', N'hw-luis-pc', N'PC de escritorio', N'1.0.2'),
    (5, 4, HASHBYTES('SHA2_256', 'sesion:5'), '2026-08-01T19:00:00', '2026-08-02T19:00:00', '2026-08-01T20:29:00', '2026-08-01T20:30:00', N'CIERRE_VOLUNTARIO', N'187.190.3.41', N'hw-marta-01', N'Laptop', N'1.0.2'),
    (6, 4, HASHBYTES('SHA2_256', 'sesion:6'), '2026-09-01T17:54:00', '2026-09-02T17:54:00', '2026-09-01T17:59:00', NULL, NULL, N'187.190.3.41', N'hw-marta-01', N'Laptop', N'1.0.2'),
    (7, 5, HASHBYTES('SHA2_256', 'sesion:7'), '2026-09-01T17:45:00', '2026-09-02T17:45:00', '2026-09-01T17:59:00', NULL, NULL, N'201.141.80.12', N'hw-pedro-01', N'PC familiar', N'1.0.2'),
    (8, 6, HASHBYTES('SHA2_256', 'sesion:8'), '2026-08-19T18:00:00', '2026-08-20T18:00:00', '2026-08-19T21:00:00', '2026-08-20T11:05:00', N'CAMBIO_CREDENCIALES', N'187.190.66.5', N'hw-sofia-01', N'Celular', N'1.0.2'),
    (9, 6, HASHBYTES('SHA2_256', 'sesion:9'), '2026-09-01T17:25:00', '2026-09-02T17:25:00', '2026-09-01T17:59:00', NULL, NULL, N'187.190.66.5', N'hw-sofia-01', N'Celular', N'1.0.2'),
    (10, 9, HASHBYTES('SHA2_256', 'sesion:10'), '2026-08-26T17:00:00', '2026-08-27T17:00:00', '2026-08-26T19:00:00', '2026-08-27T10:00:00', N'SANCION', N'201.141.90.33', N'hw-rayo-01', N'Laptop', N'1.0.2'),
    (11, 10, HASHBYTES('SHA2_256', 'sesion:11'), '2026-08-02T12:30:00', '2026-08-03T12:30:00', '2026-08-02T12:59:00', '2026-08-02T13:00:00', N'BAJA_CUENTA', N'189.203.77.8', N'hw-diez-01', N'PC', N'1.0.2'),
    (12, 7, HASHBYTES('SHA2_256', 'sesion:12'), '2026-08-30T16:00:00', '2026-08-31T16:00:00', '2026-08-30T17:30:00', NULL, NULL, N'189.203.40.2', N'hw-invitado-4821', N'Celular', N'1.0.2'),
    (13, 7, HASHBYTES('SHA2_256', 'sesion:13'), '2026-09-01T17:48:00', '2026-09-02T17:48:00', '2026-09-01T17:59:00', NULL, NULL, N'189.203.40.2', N'hw-invitado-4821', N'Celular', N'1.0.2'),
    (14, 7, HASHBYTES('SHA2_256', 'sesion:14'), '2026-08-31T16:20:00', '2026-09-01T16:20:00', '2026-08-31T16:40:00', NULL, NULL, N'189.203.40.2', N'hw-invitado-4821', N'Celular', N'1.0.2'),
    (15, 11, HASHBYTES('SHA2_256', 'sesion:15'), '2026-08-22T19:15:00', '2026-08-23T19:15:00', '2026-08-22T21:00:00', '2026-08-23T10:00:00', N'SANCION', N'201.141.33.8', N'hw-once-01', N'PC', N'1.0.2');
SET IDENTITY_INSERT dbo.Sesion OFF;

SET IDENTITY_INSERT dbo.CodigoSegundoFactor ON;
INSERT INTO dbo.CodigoSegundoFactor (id_codigo, id_usuario, codigo_hash, canal, fecha_generacion, fecha_expiracion, intentos, estado) VALUES
    (1, 4, HASHBYTES('SHA2_256', 'codigo:1'), N'CORREO', '2026-08-01T19:05:00', '2026-08-01T19:10:00', 0, N'CONSUMIDO'),
    (2, 4, HASHBYTES('SHA2_256', 'codigo:2'), N'CORREO', '2026-08-15T20:00:00', '2026-08-15T20:05:00', 3, N'INVALIDADO'),
    (3, 4, HASHBYTES('SHA2_256', 'codigo:3'), N'CORREO', '2026-09-01T17:53:00', '2026-09-01T17:58:00', 0, N'CONSUMIDO'),
    (4, 4, HASHBYTES('SHA2_256', 'codigo:4'), N'CORREO', '2026-09-01T17:58:00', '2026-09-01T18:03:00', 0, N'PENDIENTE');
SET IDENTITY_INSERT dbo.CodigoSegundoFactor OFF;

SET IDENTITY_INSERT dbo.TokenVerificacionCorreo ON;
INSERT INTO dbo.TokenVerificacionCorreo (id_token, id_usuario, token_hash, proposito, correo_destino, fecha_generacion, fecha_expiracion, estado) VALUES
    (1, 1, HASHBYTES('SHA2_256', 'verificacion:1'), N'ALTA', NULL, '2026-06-01T10:00:00', '2026-06-02T10:00:00', N'USADO'),
    (2, 2, HASHBYTES('SHA2_256', 'verificacion:2'), N'ALTA', NULL, '2026-06-02T09:00:00', '2026-06-03T09:00:00', N'USADO'),
    (3, 3, HASHBYTES('SHA2_256', 'verificacion:3'), N'ALTA', NULL, '2026-06-10T16:00:00', '2026-06-11T16:00:00', N'USADO'),
    (4, 4, HASHBYTES('SHA2_256', 'verificacion:4'), N'ALTA', NULL, '2026-06-12T18:30:00', '2026-06-13T18:30:00', N'USADO'),
    (5, 5, HASHBYTES('SHA2_256', 'verificacion:5'), N'ALTA', NULL, '2026-06-15T12:00:00', '2026-06-16T12:00:00', N'USADO'),
    (6, 6, HASHBYTES('SHA2_256', 'verificacion:6'), N'ALTA', NULL, '2026-06-18T20:00:00', '2026-06-19T20:00:00', N'USADO'),
    (7, 9, HASHBYTES('SHA2_256', 'verificacion:7'), N'ALTA', NULL, '2026-06-20T15:00:00', '2026-06-21T15:00:00', N'USADO'),
    (8, 10, HASHBYTES('SHA2_256', 'verificacion:8'), N'ALTA', NULL, '2026-06-22T11:00:00', '2026-06-23T11:00:00', N'USADO'),
    (9, 8, HASHBYTES('SHA2_256', 'verificacion:9'), N'ALTA', NULL, '2026-08-28T19:00:00', '2026-08-29T19:00:00', N'INVALIDADO'),
    (10, 8, HASHBYTES('SHA2_256', 'verificacion:10'), N'ALTA', NULL, '2026-09-01T12:00:00', '2026-09-02T12:00:00', N'PENDIENTE'),
    (11, 3, HASHBYTES('SHA2_256', 'verificacion:11'), N'CAMBIO_CORREO', N'luis.quo.nuevo@correo.mx', '2026-09-01T17:20:00', '2026-09-02T17:20:00', N'PENDIENTE'),
    (12, 11, HASHBYTES('SHA2_256', 'verificacion:12'), N'ALTA', NULL, '2026-08-22T19:00:00', '2026-08-23T19:00:00', N'USADO');
SET IDENTITY_INSERT dbo.TokenVerificacionCorreo OFF;

SET IDENTITY_INSERT dbo.TokenRecuperacion ON;
INSERT INTO dbo.TokenRecuperacion (id_token, id_usuario, token_hash, fecha_generacion, fecha_expiracion, intentos, estado) VALUES
    (1, 6, HASHBYTES('SHA2_256', 'recuperacion:1'), '2026-08-20T10:55:00', '2026-08-20T11:25:00', 1, N'USADO'),
    (2, 1, HASHBYTES('SHA2_256', 'recuperacion:2'), '2026-09-01T17:40:00', '2026-09-01T18:10:00', 0, N'INVALIDADO'),
    (3, 1, HASHBYTES('SHA2_256', 'recuperacion:3'), '2026-09-01T17:46:00', '2026-09-01T18:16:00', 0, N'PENDIENTE');
SET IDENTITY_INSERT dbo.TokenRecuperacion OFF;

-- Cada cuenta aceptó el texto en su idioma preferido (CU-02 RN-12).
SET IDENTITY_INSERT dbo.AceptacionTerminos ON;
INSERT INTO dbo.AceptacionTerminos (id_aceptacion, id_usuario, version_terminos, idioma, fecha_aceptacion, direccion_ip) VALUES
    (1, 1, N'2026.1', N'es-MX', '2026-06-01T10:00:00', N'189.203.14.20'),
    (2, 2, N'2026.1', N'es-MX', '2026-06-02T09:00:00', N'201.141.22.7'),
    (3, 3, N'2026.1', N'es-MX', '2026-06-10T16:00:00', N'189.203.55.3'),
    (4, 3, N'2026.2', N'es-MX', '2026-08-01T10:00:00', N'189.203.55.9'),
    (5, 4, N'2026.1', N'es-MX', '2026-06-12T18:30:00', N'187.190.3.41'),
    (6, 5, N'2026.1', N'es-MX', '2026-06-15T12:00:00', N'201.141.80.12'),
    (7, 6, N'2026.1', N'en', '2026-06-18T20:00:00', N'187.190.66.5'),
    (8, 8, N'2026.2', N'es-MX', '2026-08-28T19:00:00', N'201.141.5.60'),
    (9, 9, N'2026.1', N'es-MX', '2026-06-20T15:00:00', N'201.141.90.33'),
    (10, 10, N'2026.1', N'es-MX', '2026-06-22T11:00:00', N'189.203.77.8'),
    (11, 11, N'2026.2', N'es-MX', '2026-08-22T19:00:00', N'201.141.33.8');
SET IDENTITY_INSERT dbo.AceptacionTerminos OFF;

/*---------------------------------------------------------------------
  Perfil y personalización
---------------------------------------------------------------------*/

INSERT INTO dbo.HistorialNickname (id_usuario, nickname_anterior, fecha_cambio) VALUES
    (6, N'sofi_123', '2026-07-02T19:00:00');

SET IDENTITY_INSERT dbo.Avatar ON;
INSERT INTO dbo.Avatar (id_avatar, id_usuario, ruta_imagen, formato, tamano_bytes, fecha_subida, vigente) VALUES
    (1, 4, N'/avatares/4/1.png', N'PNG', 480000, '2026-06-20T12:00:00', 0),
    (2, 4, N'/avatares/4/2.jpg', N'JPG', 350000, '2026-08-05T17:00:00', 1),
    (3, 10, N'/avatares/10/1.jpg', N'JPG', 200000, '2026-06-23T09:00:00', 0);
SET IDENTITY_INSERT dbo.Avatar OFF;

SET IDENTITY_INSERT dbo.EnlaceRed ON;
INSERT INTO dbo.EnlaceRed (id_enlace, id_usuario, orden, url) VALUES
    (1, 3, 1, N'https://www.youtube.com/@luisquo'),
    (2, 3, 2, N'https://www.twitch.tv/luisquo');
SET IDENTITY_INSERT dbo.EnlaceRed OFF;

-- Los iniciales de toda cuenta (CU-02 RN-08), las compras, las recompensas y lo que salió en cajas.
INSERT INTO dbo.UsuarioObjeto (id_usuario, id_objeto, fecha_obtencion, origen) VALUES
    (1, 101, '2026-06-01T10:00:00', N'INICIAL'),
    (1, 102, '2026-06-01T10:00:00', N'INICIAL'),
    (1, 201, '2026-06-01T10:00:00', N'INICIAL'),
    (1, 301, '2026-06-01T10:00:00', N'INICIAL'),
    (1, 401, '2026-06-01T10:00:00', N'INICIAL'),
    (1, 501, '2026-06-01T10:00:00', N'INICIAL'),
    (1, 601, '2026-06-01T10:00:00', N'INICIAL'),
    (1, 602, '2026-06-01T10:00:00', N'INICIAL'),
    (2, 101, '2026-06-02T09:00:00', N'INICIAL'),
    (2, 102, '2026-06-02T09:00:00', N'INICIAL'),
    (2, 201, '2026-06-02T09:00:00', N'INICIAL'),
    (2, 301, '2026-06-02T09:00:00', N'INICIAL'),
    (2, 401, '2026-06-02T09:00:00', N'INICIAL'),
    (2, 501, '2026-06-02T09:00:00', N'INICIAL'),
    (2, 601, '2026-06-02T09:00:00', N'INICIAL'),
    (2, 602, '2026-06-02T09:00:00', N'INICIAL'),
    (3, 101, '2026-06-10T16:00:00', N'INICIAL'),
    (3, 102, '2026-06-10T16:00:00', N'INICIAL'),
    (3, 103, '2026-07-27T18:00:00', N'COMPRA'),
    (3, 201, '2026-06-10T16:00:00', N'INICIAL'),
    (3, 202, '2026-08-27T12:01:00', N'CAJA'),
    (3, 203, '2026-08-27T12:01:00', N'CAJA'),
    (3, 301, '2026-06-10T16:00:00', N'INICIAL'),
    (3, 401, '2026-06-10T16:00:00', N'INICIAL'),
    (3, 402, '2026-07-20T19:10:00', N'NIVEL'),
    (3, 501, '2026-06-10T16:00:00', N'INICIAL'),
    (3, 601, '2026-06-10T16:00:00', N'INICIAL'),
    (3, 602, '2026-06-10T16:00:00', N'INICIAL'),
    (3, 603, '2026-07-21T18:00:00', N'COMPRA'),
    (4, 101, '2026-06-12T18:30:00', N'INICIAL'),
    (4, 102, '2026-06-12T18:30:00', N'INICIAL'),
    (4, 201, '2026-06-12T18:30:00', N'INICIAL'),
    (4, 202, '2026-08-16T19:00:00', N'COMPRA'),
    (4, 301, '2026-06-12T18:30:00', N'INICIAL'),
    (4, 401, '2026-06-12T18:30:00', N'INICIAL'),
    (4, 501, '2026-06-12T18:30:00', N'INICIAL'),
    (4, 601, '2026-06-12T18:30:00', N'INICIAL'),
    (4, 602, '2026-06-12T18:30:00', N'INICIAL'),
    (5, 101, '2026-06-15T12:00:00', N'INICIAL'),
    (5, 102, '2026-06-15T12:00:00', N'INICIAL'),
    (5, 201, '2026-06-15T12:00:00', N'INICIAL'),
    (5, 301, '2026-06-15T12:00:00', N'INICIAL'),
    (5, 401, '2026-06-15T12:00:00', N'INICIAL'),
    (5, 501, '2026-06-15T12:00:00', N'INICIAL'),
    (5, 601, '2026-06-15T12:00:00', N'INICIAL'),
    (5, 602, '2026-06-15T12:00:00', N'INICIAL'),
    (5, 603, '2026-08-21T17:00:00', N'COMPRA'),
    (6, 101, '2026-06-18T20:00:00', N'INICIAL'),
    (6, 102, '2026-06-18T20:00:00', N'INICIAL'),
    (6, 201, '2026-06-18T20:00:00', N'INICIAL'),
    (6, 301, '2026-06-18T20:00:00', N'INICIAL'),
    (6, 401, '2026-06-18T20:00:00', N'INICIAL'),
    (6, 501, '2026-06-18T20:00:00', N'INICIAL'),
    (6, 601, '2026-06-18T20:00:00', N'INICIAL'),
    (6, 602, '2026-06-18T20:00:00', N'INICIAL'),
    (7, 101, '2026-08-30T16:00:00', N'INICIAL'),
    (7, 102, '2026-08-30T16:00:00', N'INICIAL'),
    (7, 201, '2026-08-30T16:00:00', N'INICIAL'),
    (7, 301, '2026-08-30T16:00:00', N'INICIAL'),
    (7, 401, '2026-08-30T16:00:00', N'INICIAL'),
    (7, 501, '2026-08-30T16:00:00', N'INICIAL'),
    (7, 601, '2026-08-30T16:00:00', N'INICIAL'),
    (7, 602, '2026-08-30T16:00:00', N'INICIAL'),
    (8, 101, '2026-08-28T19:00:00', N'INICIAL'),
    (8, 102, '2026-08-28T19:00:00', N'INICIAL'),
    (8, 201, '2026-08-28T19:00:00', N'INICIAL'),
    (8, 301, '2026-08-28T19:00:00', N'INICIAL'),
    (8, 401, '2026-08-28T19:00:00', N'INICIAL'),
    (8, 501, '2026-08-28T19:00:00', N'INICIAL'),
    (8, 601, '2026-08-28T19:00:00', N'INICIAL'),
    (8, 602, '2026-08-28T19:00:00', N'INICIAL'),
    (9, 101, '2026-06-20T15:00:00', N'INICIAL'),
    (9, 102, '2026-06-20T15:00:00', N'INICIAL'),
    (9, 201, '2026-06-20T15:00:00', N'INICIAL'),
    (9, 301, '2026-06-20T15:00:00', N'INICIAL'),
    (9, 401, '2026-06-20T15:00:00', N'INICIAL'),
    (9, 501, '2026-06-20T15:00:00', N'INICIAL'),
    (9, 601, '2026-06-20T15:00:00', N'INICIAL'),
    (9, 602, '2026-06-20T15:00:00', N'INICIAL'),
    (10, 101, '2026-06-22T11:00:00', N'INICIAL'),
    (10, 102, '2026-06-22T11:00:00', N'INICIAL'),
    (10, 201, '2026-06-22T11:00:00', N'INICIAL'),
    (10, 301, '2026-06-22T11:00:00', N'INICIAL'),
    (10, 401, '2026-06-22T11:00:00', N'INICIAL'),
    (10, 501, '2026-06-22T11:00:00', N'INICIAL'),
    (10, 601, '2026-06-22T11:00:00', N'INICIAL'),
    (10, 602, '2026-06-22T11:00:00', N'INICIAL'),
    (11, 101, '2026-08-22T19:00:00', N'INICIAL'),
    (11, 102, '2026-08-22T19:00:00', N'INICIAL'),
    (11, 201, '2026-08-22T19:00:00', N'INICIAL'),
    (11, 301, '2026-08-22T19:00:00', N'INICIAL'),
    (11, 401, '2026-08-22T19:00:00', N'INICIAL'),
    (11, 501, '2026-08-22T19:00:00', N'INICIAL'),
    (11, 601, '2026-08-22T19:00:00', N'INICIAL'),
    (11, 602, '2026-08-22T19:00:00', N'INICIAL');

INSERT INTO dbo.Equipamiento (id_usuario, id_ranura, id_objeto) VALUES
    (1, 1, 101),
    (1, 2, 201),
    (1, 3, 301),
    (1, 4, 401),
    (1, 5, 501),
    (1, 6, 601),
    (2, 1, 101),
    (2, 2, 201),
    (2, 3, 301),
    (2, 4, 401),
    (2, 5, 501),
    (2, 6, 601),
    (3, 1, 103),
    (3, 2, 201),
    (3, 3, 301),
    (3, 4, 402),
    (3, 5, 501),
    (3, 6, 603),
    (4, 1, 101),
    (4, 2, 202),
    (4, 3, 301),
    (4, 4, 401),
    (4, 5, 501),
    (4, 6, 601),
    (5, 1, 101),
    (5, 2, 201),
    (5, 3, 301),
    (5, 4, 401),
    (5, 5, 501),
    (5, 6, 603),
    (6, 1, 101),
    (6, 2, 201),
    (6, 3, 301),
    (6, 4, 401),
    (6, 5, 501),
    (6, 6, 601),
    (7, 1, 101),
    (7, 2, 201),
    (7, 3, 301),
    (7, 4, 401),
    (7, 5, 501),
    (7, 6, 601),
    (8, 1, 101),
    (8, 2, 201),
    (8, 3, 301),
    (8, 4, 401),
    (8, 5, 501),
    (8, 6, 601),
    (9, 1, 101),
    (9, 2, 201),
    (9, 3, 301),
    (9, 4, 401),
    (9, 5, 501),
    (9, 6, 601),
    (10, 1, 101),
    (10, 2, 201),
    (10, 3, 301),
    (10, 4, 401),
    (10, 5, 501),
    (10, 6, 601),
    (11, 1, 101),
    (11, 2, 201),
    (11, 3, 301),
    (11, 4, 401),
    (11, 5, 501),
    (11, 6, 601);

/*---------------------------------------------------------------------
  Partida
---------------------------------------------------------------------*/

SET IDENTITY_INSERT dbo.Partida ON;
INSERT INTO dbo.Partida (id_partida, id_modo, tipo, estado, minutos_reloj, fecha_inicio, fecha_fin, forma_termino, turno_actual, id_nivel_ia, permite_deshacer, permite_sugerencias, deshacer_usados, sugerencias_usadas) VALUES
    (1, 1, N'CLASIFICATORIA', N'FINALIZADA', 5, '2026-07-05T17:00:00', '2026-07-05T17:01:42', N'META', 2, NULL, NULL, NULL, NULL, NULL),
    (2, 1, N'CLASIFICATORIA', N'FINALIZADA', 5, '2026-07-08T18:00:00', '2026-07-08T18:00:52', N'RENDICION', 1, NULL, NULL, NULL, NULL, NULL),
    (3, 1, N'CLASIFICATORIA', N'FINALIZADA', 5, '2026-07-12T16:30:00', '2026-07-12T16:31:54', N'META', 1, NULL, NULL, NULL, NULL, NULL),
    (4, 1, N'CLASIFICATORIA', N'FINALIZADA', 5, '2026-07-20T19:00:00', '2026-07-20T19:01:56', N'META', 1, NULL, NULL, NULL, NULL, NULL),
    (5, 1, N'CLASIFICATORIA', N'FINALIZADA', 5, '2026-07-26T17:30:00', '2026-07-26T17:31:40', N'META', 2, NULL, NULL, NULL, NULL, NULL),
    (6, 3, N'CLASIFICATORIA', N'FINALIZADA', 3, '2026-08-10T18:00:00', '2026-08-10T18:01:11', N'TABLAS', 1, NULL, NULL, NULL, NULL, NULL),
    (7, 2, N'CLASIFICATORIA', N'FINALIZADA', 10, '2026-08-15T19:00:00', '2026-08-15T19:01:30', N'ABANDONO', 2, NULL, NULL, NULL, NULL, NULL),
    (8, 1, N'IA', N'FINALIZADA', NULL, '2026-08-20T16:00:00', '2026-08-20T16:01:18', N'RENDICION', 2, 1, 1, 1, 1, 2),
    (9, 1, N'CLASIFICATORIA', N'FINALIZADA', 5, '2026-08-26T17:10:00', '2026-08-26T17:11:55', N'META', 2, NULL, NULL, NULL, NULL, NULL),
    (10, 3, N'PRIVADA', N'FINALIZADA', 10, '2026-08-31T16:30:00', '2026-08-31T16:31:05', N'META', 2, NULL, NULL, NULL, NULL, NULL),
    (11, 3, N'CLASIFICATORIA', N'FINALIZADA', 3, '2026-08-28T18:00:00', '2026-08-28T18:03:29', N'TIEMPO_AGOTADO', 2, NULL, NULL, NULL, NULL, NULL),
    (12, 1, N'CLASIFICATORIA', N'EN_CURSO', 5, '2026-09-01T17:30:00', NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL);
SET IDENTITY_INSERT dbo.Partida OFF;

INSERT INTO dbo.Participacion (id_partida, id_usuario, orden_turno, simbolo_peon, casilla_actual, muros_restantes, reloj_restante, elo_inicial, elo_final, resultado, posicion, forma_termino, conectado, fecha_desconexion) VALUES
    (1, 3, 1, N'AZUL', N'e9', 10, 249352, 1000, 1016, N'GANADA', NULL, NULL, 1, NULL),
    (1, 4, 2, N'ROJO', N'd7', 6, 248933, 1000, 984, N'PERDIDA', NULL, NULL, 1, NULL),
    (2, 4, 1, N'AZUL', N'f3', 10, 276855, 984, 969, N'PERDIDA', NULL, NULL, 1, NULL),
    (2, 3, 2, N'ROJO', N'e7', 9, 280098, 1016, 1031, N'GANADA', NULL, NULL, 1, NULL),
    (3, 3, 1, N'AZUL', N'f5', 7, 247688, 1031, 1012, N'PERDIDA', NULL, NULL, 1, NULL),
    (3, 4, 2, N'ROJO', N'e1', 10, 238336, 969, 988, N'GANADA', NULL, NULL, 1, NULL),
    (4, 4, 1, N'AZUL', N'c4', 7, 237856, 988, 973, N'PERDIDA', NULL, NULL, 1, NULL),
    (4, 3, 2, N'ROJO', N'e1', 10, 246504, 1012, 1027, N'GANADA', NULL, NULL, 1, NULL),
    (5, 3, 1, N'AZUL', N'e9', 10, 251954, 1027, 1041, N'GANADA', NULL, NULL, 1, NULL),
    (5, 4, 2, N'ROJO', N'e4', 9, 248532, 973, 959, N'PERDIDA', NULL, NULL, 1, NULL),
    (6, 5, 1, N'AZUL', N'd4', 5, 148800, 1000, 1000, N'TABLAS', NULL, NULL, 1, NULL),
    (6, 6, 2, N'ROJO', N'e5', 5, 153124, 1000, 1000, N'TABLAS', NULL, NULL, 1, NULL),
    (7, 3, 1, N'AZUL', N'e5', 5, 572532, 1000, 1024, N'GANADA', 1, NULL, 1, NULL),
    (7, 4, 2, N'ROJO', N'c5', 4, 580568, 1000, 1008, N'PERDIDA', 2, N'ABANDONO', 1, NULL),
    (7, 5, 3, N'VERDE', N'e8', 5, 596640, 1000, 976, N'PERDIDA', 4, N'ABANDONO', 1, NULL),
    (7, 6, 4, N'AMARILLO', N'g5', 5, 580685, 1000, 992, N'PERDIDA', 3, N'ABANDONO', 1, NULL),
    (8, 5, 1, N'AZUL', N'f4', 10, NULL, NULL, NULL, N'PERDIDA', NULL, NULL, 1, NULL),
    (9, 3, 1, N'AZUL', N'd9', 10, 234012, 1041, 1055, N'GANADA', NULL, NULL, 1, NULL),
    (9, 9, 2, N'ROJO', N'g6', 7, 251344, 1000, 986, N'PERDIDA', NULL, NULL, 1, NULL),
    (10, 6, 1, N'AZUL', N'd7', 8, 568176, NULL, NULL, N'GANADA', NULL, NULL, 1, NULL),
    (10, 7, 2, N'ROJO', N'c5', 6, 567480, NULL, NULL, N'PERDIDA', NULL, NULL, 1, NULL),
    (11, 4, 1, N'AZUL', N'e4', 6, 151220, 1000, 1016, N'GANADA', NULL, NULL, 1, NULL),
    (11, 5, 2, N'ROJO', N'd5', 5, 0, 1000, 984, N'PERDIDA', NULL, NULL, 1, NULL),
    (12, 3, 1, N'AZUL', N'e4', 10, 284985, 1055, NULL, NULL, NULL, NULL, 1, NULL),
    (12, 6, 2, N'ROJO', N'e7', 9, 279228, 1000, NULL, NULL, NULL, NULL, 1, '2026-09-01T17:38:00');

-- El aspecto que cada jugador tenía equipado al empezar (CU-14 RN-03).
INSERT INTO dbo.ParticipacionObjeto (id_partida, id_usuario, id_ranura, id_objeto) VALUES
    (1, 3, 1, 101),
    (1, 3, 2, 201),
    (1, 3, 3, 301),
    (1, 3, 4, 401),
    (1, 3, 5, 501),
    (1, 3, 6, 601),
    (1, 4, 1, 101),
    (1, 4, 2, 201),
    (1, 4, 3, 301),
    (1, 4, 4, 401),
    (1, 4, 5, 501),
    (1, 4, 6, 601),
    (2, 4, 1, 101),
    (2, 4, 2, 201),
    (2, 4, 3, 301),
    (2, 4, 4, 401),
    (2, 4, 5, 501),
    (2, 4, 6, 601),
    (2, 3, 1, 101),
    (2, 3, 2, 201),
    (2, 3, 3, 301),
    (2, 3, 4, 401),
    (2, 3, 5, 501),
    (2, 3, 6, 601),
    (3, 3, 1, 101),
    (3, 3, 2, 201),
    (3, 3, 3, 301),
    (3, 3, 4, 401),
    (3, 3, 5, 501),
    (3, 3, 6, 601),
    (3, 4, 1, 101),
    (3, 4, 2, 201),
    (3, 4, 3, 301),
    (3, 4, 4, 401),
    (3, 4, 5, 501),
    (3, 4, 6, 601),
    (4, 4, 1, 101),
    (4, 4, 2, 201),
    (4, 4, 3, 301),
    (4, 4, 4, 401),
    (4, 4, 5, 501),
    (4, 4, 6, 601),
    (4, 3, 1, 101),
    (4, 3, 2, 201),
    (4, 3, 3, 301),
    (4, 3, 4, 401),
    (4, 3, 5, 501),
    (4, 3, 6, 601),
    (5, 3, 1, 101),
    (5, 3, 2, 201),
    (5, 3, 3, 301),
    (5, 3, 4, 402),
    (5, 3, 5, 501),
    (5, 3, 6, 603),
    (5, 4, 1, 101),
    (5, 4, 2, 201),
    (5, 4, 3, 301),
    (5, 4, 4, 401),
    (5, 4, 5, 501),
    (5, 4, 6, 601),
    (6, 5, 1, 101),
    (6, 5, 2, 201),
    (6, 5, 3, 301),
    (6, 5, 4, 401),
    (6, 5, 5, 501),
    (6, 5, 6, 601),
    (6, 6, 1, 101),
    (6, 6, 2, 201),
    (6, 6, 3, 301),
    (6, 6, 4, 401),
    (6, 6, 5, 501),
    (6, 6, 6, 601),
    (7, 3, 1, 103),
    (7, 3, 2, 201),
    (7, 3, 3, 301),
    (7, 3, 4, 402),
    (7, 3, 5, 501),
    (7, 3, 6, 603),
    (7, 4, 1, 101),
    (7, 4, 2, 201),
    (7, 4, 3, 301),
    (7, 4, 4, 401),
    (7, 4, 5, 501),
    (7, 4, 6, 601),
    (7, 5, 1, 101),
    (7, 5, 2, 201),
    (7, 5, 3, 301),
    (7, 5, 4, 401),
    (7, 5, 5, 501),
    (7, 5, 6, 601),
    (7, 6, 1, 101),
    (7, 6, 2, 201),
    (7, 6, 3, 301),
    (7, 6, 4, 401),
    (7, 6, 5, 501),
    (7, 6, 6, 601),
    (8, 5, 1, 101),
    (8, 5, 2, 201),
    (8, 5, 3, 301),
    (8, 5, 4, 401),
    (8, 5, 5, 501),
    (8, 5, 6, 601),
    (9, 3, 1, 103),
    (9, 3, 2, 201),
    (9, 3, 3, 301),
    (9, 3, 4, 402),
    (9, 3, 5, 501),
    (9, 3, 6, 603),
    (9, 9, 1, 101),
    (9, 9, 2, 201),
    (9, 9, 3, 301),
    (9, 9, 4, 401),
    (9, 9, 5, 501),
    (9, 9, 6, 601),
    (10, 6, 1, 101),
    (10, 6, 2, 201),
    (10, 6, 3, 301),
    (10, 6, 4, 401),
    (10, 6, 5, 501),
    (10, 6, 6, 601),
    (10, 7, 1, 101),
    (10, 7, 2, 201),
    (10, 7, 3, 301),
    (10, 7, 4, 401),
    (10, 7, 5, 501),
    (10, 7, 6, 601),
    (11, 4, 1, 101),
    (11, 4, 2, 202),
    (11, 4, 3, 301),
    (11, 4, 4, 401),
    (11, 4, 5, 501),
    (11, 4, 6, 601),
    (11, 5, 1, 101),
    (11, 5, 2, 201),
    (11, 5, 3, 301),
    (11, 5, 4, 401),
    (11, 5, 5, 501),
    (11, 5, 6, 603),
    (12, 3, 1, 103),
    (12, 3, 2, 201),
    (12, 3, 3, 301),
    (12, 3, 4, 402),
    (12, 3, 5, 501),
    (12, 3, 6, 603),
    (12, 6, 1, 101),
    (12, 6, 2, 201),
    (12, 6, 3, 301),
    (12, 6, 4, 401),
    (12, 6, 5, 501),
    (12, 6, 6, 601);

INSERT INTO dbo.Jugada (id_partida, numero_jugada, id_usuario, tipo, casilla_origen, casilla_destino, surco, orientacion, tiempo_consumido, fecha_jugada, deshecha) VALUES
    (1, 1, 3, N'MOVIMIENTO', N'e1', N'e2', NULL, NULL, 7148, '2026-07-05T17:00:07.148', 0),
    (1, 2, 4, N'MURO', NULL, NULL, N'a7', N'HORIZONTAL', 6067, '2026-07-05T17:00:13.215', 0),
    (1, 3, 3, N'MOVIMIENTO', N'e2', N'e3', NULL, NULL, 4986, '2026-07-05T17:00:18.201', 0),
    (1, 4, 4, N'MOVIMIENTO', N'e9', N'd9', NULL, NULL, 3905, '2026-07-05T17:00:22.106', 0),
    (1, 5, 3, N'MOVIMIENTO', N'e3', N'e4', NULL, NULL, 2824, '2026-07-05T17:00:24.930', 0),
    (1, 6, 4, N'MURO', NULL, NULL, N'g7', N'HORIZONTAL', 10743, '2026-07-05T17:00:35.673', 0),
    (1, 7, 3, N'MOVIMIENTO', N'e4', N'e5', NULL, NULL, 9662, '2026-07-05T17:00:45.335', 0),
    (1, 8, 4, N'MOVIMIENTO', N'd9', N'd8', NULL, NULL, 8581, '2026-07-05T17:00:53.916', 0),
    (1, 9, 3, N'MOVIMIENTO', N'e5', N'e6', NULL, NULL, 7500, '2026-07-05T17:01:01.416', 0),
    (1, 10, 4, N'MURO', NULL, NULL, N'b3', N'VERTICAL', 6419, '2026-07-05T17:01:07.835', 0),
    (1, 11, 3, N'MOVIMIENTO', N'e6', N'e7', NULL, NULL, 5338, '2026-07-05T17:01:13.173', 0),
    (1, 12, 4, N'MOVIMIENTO', N'd8', N'd7', NULL, NULL, 4257, '2026-07-05T17:01:17.430', 0),
    (1, 13, 3, N'MOVIMIENTO', N'e7', N'e8', NULL, NULL, 3176, '2026-07-05T17:01:20.606', 0),
    (1, 14, 4, N'MURO', NULL, NULL, N'h2', N'HORIZONTAL', 11095, '2026-07-05T17:01:31.701', 0),
    (1, 15, 3, N'MOVIMIENTO', N'e8', N'e9', NULL, NULL, 10014, '2026-07-05T17:01:41.715', 0),
    (2, 1, 4, N'MOVIMIENTO', N'e1', N'e2', NULL, NULL, 3877, '2026-07-08T18:00:03.877', 0),
    (2, 2, 3, N'MOVIMIENTO', N'e9', N'e8', NULL, NULL, 2796, '2026-07-08T18:00:06.673', 0),
    (2, 3, 4, N'MOVIMIENTO', N'e2', N'e3', NULL, NULL, 10715, '2026-07-08T18:00:17.388', 0),
    (2, 4, 3, N'MURO', NULL, NULL, N'd3', N'HORIZONTAL', 9634, '2026-07-08T18:00:27.022', 0),
    (2, 5, 4, N'MOVIMIENTO', N'e3', N'f3', NULL, NULL, 8553, '2026-07-08T18:00:35.575', 0),
    (2, 6, 3, N'MOVIMIENTO', N'e8', N'e7', NULL, NULL, 7472, '2026-07-08T18:00:43.047', 0),
    (3, 1, 3, N'MOVIMIENTO', N'e1', N'f1', NULL, NULL, 9606, '2026-07-12T16:30:09.606', 0),
    (3, 2, 4, N'MOVIMIENTO', N'e9', N'e8', NULL, NULL, 8525, '2026-07-12T16:30:18.131', 0),
    (3, 3, 3, N'MOVIMIENTO', N'f1', N'f2', NULL, NULL, 7444, '2026-07-12T16:30:25.575', 0),
    (3, 4, 4, N'MOVIMIENTO', N'e8', N'e7', NULL, NULL, 6363, '2026-07-12T16:30:31.938', 0),
    (3, 5, 3, N'MURO', NULL, NULL, N'a5', N'HORIZONTAL', 5282, '2026-07-12T16:30:37.220', 0),
    (3, 6, 4, N'MOVIMIENTO', N'e7', N'e6', NULL, NULL, 4201, '2026-07-12T16:30:41.421', 0),
    (3, 7, 3, N'MOVIMIENTO', N'f2', N'f3', NULL, NULL, 3120, '2026-07-12T16:30:44.541', 0),
    (3, 8, 4, N'MOVIMIENTO', N'e6', N'e5', NULL, NULL, 11039, '2026-07-12T16:30:55.580', 0),
    (3, 9, 3, N'MURO', NULL, NULL, N'h6', N'VERTICAL', 9958, '2026-07-12T16:31:05.538', 0),
    (3, 10, 4, N'MOVIMIENTO', N'e5', N'e4', NULL, NULL, 8877, '2026-07-12T16:31:14.415', 0),
    (3, 11, 3, N'MOVIMIENTO', N'f3', N'f4', NULL, NULL, 7796, '2026-07-12T16:31:22.211', 0),
    (3, 12, 4, N'MOVIMIENTO', N'e4', N'e3', NULL, NULL, 6715, '2026-07-12T16:31:28.926', 0),
    (3, 13, 3, N'MURO', NULL, NULL, N'c7', N'HORIZONTAL', 5634, '2026-07-12T16:31:34.560', 0),
    (3, 14, 4, N'MOVIMIENTO', N'e3', N'e2', NULL, NULL, 4553, '2026-07-12T16:31:39.113', 0),
    (3, 15, 3, N'MOVIMIENTO', N'f4', N'f5', NULL, NULL, 3472, '2026-07-12T16:31:42.585', 0),
    (3, 16, 4, N'MOVIMIENTO', N'e2', N'e1', NULL, NULL, 11391, '2026-07-12T16:31:53.976', 0),
    (4, 1, 4, N'MOVIMIENTO', N'e1', N'd1', NULL, NULL, 6335, '2026-07-20T19:00:06.335', 0),
    (4, 2, 3, N'MOVIMIENTO', N'e9', N'e8', NULL, NULL, 5254, '2026-07-20T19:00:11.589', 0),
    (4, 3, 4, N'MOVIMIENTO', N'd1', N'd2', NULL, NULL, 4173, '2026-07-20T19:00:15.762', 0),
    (4, 4, 3, N'MOVIMIENTO', N'e8', N'e7', NULL, NULL, 3092, '2026-07-20T19:00:18.854', 0),
    (4, 5, 4, N'MURO', NULL, NULL, N'f5', N'VERTICAL', 11011, '2026-07-20T19:00:29.865', 0),
    (4, 6, 3, N'MOVIMIENTO', N'e7', N'e6', NULL, NULL, 9930, '2026-07-20T19:00:39.795', 0),
    (4, 7, 4, N'MOVIMIENTO', N'd2', N'd3', NULL, NULL, 8849, '2026-07-20T19:00:48.644', 0),
    (4, 8, 3, N'MOVIMIENTO', N'e6', N'e5', NULL, NULL, 7768, '2026-07-20T19:00:56.412', 0),
    (4, 9, 4, N'MURO', NULL, NULL, N'b6', N'HORIZONTAL', 6687, '2026-07-20T19:01:03.099', 0),
    (4, 10, 3, N'MOVIMIENTO', N'e5', N'e4', NULL, NULL, 5606, '2026-07-20T19:01:08.705', 0),
    (4, 11, 4, N'MOVIMIENTO', N'd3', N'c3', NULL, NULL, 4525, '2026-07-20T19:01:13.230', 0),
    (4, 12, 3, N'MOVIMIENTO', N'e4', N'e3', NULL, NULL, 3444, '2026-07-20T19:01:16.674', 0),
    (4, 13, 4, N'MOVIMIENTO', N'c3', N'c4', NULL, NULL, 11363, '2026-07-20T19:01:28.037', 0),
    (4, 14, 3, N'MOVIMIENTO', N'e3', N'e2', NULL, NULL, 10282, '2026-07-20T19:01:38.319', 0),
    (4, 15, 4, N'MURO', NULL, NULL, N'g2', N'HORIZONTAL', 9201, '2026-07-20T19:01:47.520', 0),
    (4, 16, 3, N'MOVIMIENTO', N'e2', N'e1', NULL, NULL, 8120, '2026-07-20T19:01:55.640', 0),
    (5, 1, 3, N'MOVIMIENTO', N'e1', N'e2', NULL, NULL, 3064, '2026-07-26T17:30:03.064', 0),
    (5, 2, 4, N'MOVIMIENTO', N'e9', N'e8', NULL, NULL, 10983, '2026-07-26T17:30:14.047', 0),
    (5, 3, 3, N'MOVIMIENTO', N'e2', N'e3', NULL, NULL, 9902, '2026-07-26T17:30:23.949', 0),
    (5, 4, 4, N'MOVIMIENTO', N'e8', N'e7', NULL, NULL, 8821, '2026-07-26T17:30:32.770', 0),
    (5, 5, 3, N'MOVIMIENTO', N'e3', N'e4', NULL, NULL, 7740, '2026-07-26T17:30:40.510', 0),
    (5, 6, 4, N'MOVIMIENTO', N'e7', N'e6', NULL, NULL, 6659, '2026-07-26T17:30:47.169', 0),
    (5, 7, 3, N'MOVIMIENTO', N'e4', N'e5', NULL, NULL, 5578, '2026-07-26T17:30:52.747', 0),
    (5, 8, 4, N'MURO', NULL, NULL, N'a2', N'VERTICAL', 4497, '2026-07-26T17:30:57.244', 0),
    (5, 9, 3, N'MOVIMIENTO', N'e5', N'e7', NULL, NULL, 3416, '2026-07-26T17:31:00.660', 0),
    (5, 10, 4, N'MOVIMIENTO', N'e6', N'e5', NULL, NULL, 11335, '2026-07-26T17:31:11.995', 0),
    (5, 11, 3, N'MOVIMIENTO', N'e7', N'e8', NULL, NULL, 10254, '2026-07-26T17:31:22.249', 0),
    (5, 12, 4, N'MOVIMIENTO', N'e5', N'e4', NULL, NULL, 9173, '2026-07-26T17:31:31.422', 0),
    (5, 13, 3, N'MOVIMIENTO', N'e8', N'e9', NULL, NULL, 8092, '2026-07-26T17:31:39.514', 0),
    (6, 1, 5, N'MOVIMIENTO', N'd1', N'd2', NULL, NULL, 8793, '2026-08-10T18:00:08.793', 0),
    (6, 2, 6, N'MOVIMIENTO', N'd7', N'd6', NULL, NULL, 7712, '2026-08-10T18:00:16.505', 0),
    (6, 3, 5, N'MURO', NULL, NULL, N'c5', N'HORIZONTAL', 6631, '2026-08-10T18:00:23.136', 0),
    (6, 4, 6, N'MOVIMIENTO', N'd6', N'e6', NULL, NULL, 5550, '2026-08-10T18:00:28.686', 0),
    (6, 5, 5, N'MOVIMIENTO', N'd2', N'd3', NULL, NULL, 4469, '2026-08-10T18:00:33.155', 0),
    (6, 6, 6, N'MURO', NULL, NULL, N'c2', N'HORIZONTAL', 3388, '2026-08-10T18:00:36.543', 0),
    (6, 7, 5, N'MOVIMIENTO', N'd3', N'd4', NULL, NULL, 11307, '2026-08-10T18:00:47.850', 0),
    (6, 8, 6, N'MOVIMIENTO', N'e6', N'e5', NULL, NULL, 10226, '2026-08-10T18:00:58.076', 0),
    (7, 1, 3, N'MOVIMIENTO', N'e1', N'e2', NULL, NULL, 5522, '2026-08-15T19:00:05.522', 0),
    (7, 2, 4, N'MOVIMIENTO', N'a5', N'b5', NULL, NULL, 4441, '2026-08-15T19:00:09.963', 0),
    (7, 3, 5, N'MOVIMIENTO', N'e9', N'e8', NULL, NULL, 3360, '2026-08-15T19:00:13.323', 0),
    (7, 4, 6, N'MOVIMIENTO', N'i5', N'h5', NULL, NULL, 11279, '2026-08-15T19:00:24.602', 0),
    (7, 5, 3, N'MOVIMIENTO', N'e2', N'e3', NULL, NULL, 10198, '2026-08-15T19:00:34.800', 0),
    (7, 6, 4, N'MURO', NULL, NULL, N'b6', N'HORIZONTAL', 9117, '2026-08-15T19:00:43.917', 0),
    (7, 7, 6, N'MOVIMIENTO', N'h5', N'g5', NULL, NULL, 8036, '2026-08-15T19:00:51.953', 0),
    (7, 8, 3, N'MOVIMIENTO', N'e3', N'e4', NULL, NULL, 6955, '2026-08-15T19:00:58.908', 0),
    (7, 9, 4, N'MOVIMIENTO', N'b5', N'c5', NULL, NULL, 5874, '2026-08-15T19:01:04.782', 0),
    (7, 10, 3, N'MOVIMIENTO', N'e4', N'e5', NULL, NULL, 4793, '2026-08-15T19:01:09.575', 0),
    (8, 1, 5, N'MOVIMIENTO', N'e1', N'e2', NULL, NULL, 11251, '2026-08-20T16:00:11.251', 0),
    (8, 2, NULL, N'MOVIMIENTO', N'e9', N'e8', NULL, NULL, 10170, '2026-08-20T16:00:21.421', 0),
    (8, 3, 5, N'MOVIMIENTO', N'e2', N'e3', NULL, NULL, 9089, '2026-08-20T16:00:30.510', 0),
    (8, 4, NULL, N'MURO', NULL, NULL, N'e4', N'HORIZONTAL', 8008, '2026-08-20T16:00:38.518', 0),
    (8, 5, 5, N'MOVIMIENTO', N'e3', N'd3', NULL, NULL, 6927, '2026-08-20T16:00:45.445', 1),
    (8, 6, NULL, N'MOVIMIENTO', N'e8', N'e7', NULL, NULL, 5846, '2026-08-20T16:00:51.291', 1),
    (8, 7, 5, N'MOVIMIENTO', N'e3', N'f3', NULL, NULL, 4765, '2026-08-20T16:00:56.056', 0),
    (8, 8, NULL, N'MOVIMIENTO', N'e8', N'e7', NULL, NULL, 3684, '2026-08-20T16:00:59.740', 0),
    (8, 9, 5, N'MOVIMIENTO', N'f3', N'f4', NULL, NULL, 2603, '2026-08-20T16:01:02.343', 0),
    (9, 1, 3, N'MOVIMIENTO', N'e1', N'e2', NULL, NULL, 7980, '2026-08-26T17:10:07.980', 0),
    (9, 2, 9, N'MOVIMIENTO', N'e9', N'f9', NULL, NULL, 6899, '2026-08-26T17:10:14.879', 0),
    (9, 3, 3, N'MOVIMIENTO', N'e2', N'e3', NULL, NULL, 5818, '2026-08-26T17:10:20.697', 0),
    (9, 4, 9, N'MURO', NULL, NULL, N'e5', N'HORIZONTAL', 4737, '2026-08-26T17:10:25.434', 0),
    (9, 5, 3, N'MOVIMIENTO', N'e3', N'e4', NULL, NULL, 3656, '2026-08-26T17:10:29.090', 0),
    (9, 6, 9, N'MOVIMIENTO', N'f9', N'f8', NULL, NULL, 2575, '2026-08-26T17:10:31.665', 0),
    (9, 7, 3, N'MOVIMIENTO', N'e4', N'e5', NULL, NULL, 10494, '2026-08-26T17:10:42.159', 0),
    (9, 8, 9, N'MURO', NULL, NULL, N'd6', N'VERTICAL', 9413, '2026-08-26T17:10:51.572', 0),
    (9, 9, 3, N'MOVIMIENTO', N'e5', N'd5', NULL, NULL, 8332, '2026-08-26T17:10:59.904', 0),
    (9, 10, 9, N'MOVIMIENTO', N'f8', N'f7', NULL, NULL, 7251, '2026-08-26T17:11:07.155', 0),
    (9, 11, 3, N'MOVIMIENTO', N'd5', N'd6', NULL, NULL, 6170, '2026-08-26T17:11:13.325', 0),
    (9, 12, 9, N'MOVIMIENTO', N'f7', N'f6', NULL, NULL, 5089, '2026-08-26T17:11:18.414', 0),
    (9, 13, 3, N'MOVIMIENTO', N'd6', N'd7', NULL, NULL, 4008, '2026-08-26T17:11:22.422', 0),
    (9, 14, 9, N'MURO', NULL, NULL, N'h3', N'HORIZONTAL', 2927, '2026-08-26T17:11:25.349', 0),
    (9, 15, 3, N'MOVIMIENTO', N'd7', N'd8', NULL, NULL, 10846, '2026-08-26T17:11:36.195', 0),
    (9, 16, 9, N'MOVIMIENTO', N'f6', N'g6', NULL, NULL, 9765, '2026-08-26T17:11:45.960', 0),
    (9, 17, 3, N'MOVIMIENTO', N'd8', N'd9', NULL, NULL, 8684, '2026-08-26T17:11:54.644', 0),
    (10, 1, 6, N'MOVIMIENTO', N'd1', N'd2', NULL, NULL, 4709, '2026-08-31T16:30:04.709', 0),
    (10, 2, 7, N'MOVIMIENTO', N'd7', N'c7', NULL, NULL, 3628, '2026-08-31T16:30:08.337', 0),
    (10, 3, 6, N'MOVIMIENTO', N'd2', N'd3', NULL, NULL, 2547, '2026-08-31T16:30:10.884', 0),
    (10, 4, 7, N'MURO', NULL, NULL, N'e3', N'VERTICAL', 10466, '2026-08-31T16:30:21.350', 0),
    (10, 5, 6, N'MOVIMIENTO', N'd3', N'd4', NULL, NULL, 9385, '2026-08-31T16:30:30.735', 0),
    (10, 6, 7, N'MOVIMIENTO', N'c7', N'c6', NULL, NULL, 8304, '2026-08-31T16:30:39.039', 0),
    (10, 7, 6, N'MOVIMIENTO', N'd4', N'd5', NULL, NULL, 7223, '2026-08-31T16:30:46.262', 0),
    (10, 8, 7, N'MOVIMIENTO', N'c6', N'c5', NULL, NULL, 6142, '2026-08-31T16:30:52.404', 0),
    (10, 9, 6, N'MOVIMIENTO', N'd5', N'd6', NULL, NULL, 5061, '2026-08-31T16:30:57.465', 0),
    (10, 10, 7, N'MURO', NULL, NULL, N'a1', N'HORIZONTAL', 3980, '2026-08-31T16:31:01.445', 0),
    (10, 11, 6, N'MOVIMIENTO', N'd6', N'd7', NULL, NULL, 2899, '2026-08-31T16:31:04.344', 0),
    (11, 1, 4, N'MOVIMIENTO', N'd1', N'd2', NULL, NULL, 10438, '2026-08-28T18:00:10.438', 0),
    (11, 2, 5, N'MOVIMIENTO', N'd7', N'd6', NULL, NULL, 9357, '2026-08-28T18:00:19.795', 0),
    (11, 3, 4, N'MOVIMIENTO', N'd2', N'd3', NULL, NULL, 8276, '2026-08-28T18:00:28.071', 0),
    (11, 4, 5, N'MURO', NULL, NULL, N'c3', N'HORIZONTAL', 7195, '2026-08-28T18:00:35.266', 0),
    (11, 5, 4, N'MOVIMIENTO', N'd3', N'e3', NULL, NULL, 6114, '2026-08-28T18:00:41.380', 0),
    (11, 6, 5, N'MOVIMIENTO', N'd6', N'd5', NULL, NULL, 5033, '2026-08-28T18:00:46.413', 0),
    (11, 7, 4, N'MOVIMIENTO', N'e3', N'e4', NULL, NULL, 3952, '2026-08-28T18:00:50.365', 0),
    (12, 1, 3, N'MOVIMIENTO', N'e1', N'e2', NULL, NULL, 7167, '2026-09-01T17:30:07.167', 0),
    (12, 2, 6, N'MOVIMIENTO', N'e9', N'e8', NULL, NULL, 6086, '2026-09-01T17:30:13.253', 0),
    (12, 3, 3, N'MOVIMIENTO', N'e2', N'e3', NULL, NULL, 5005, '2026-09-01T17:30:18.258', 0),
    (12, 4, 6, N'MURO', NULL, NULL, N'e4', N'HORIZONTAL', 3924, '2026-09-01T17:30:22.182', 0),
    (12, 5, 3, N'MOVIMIENTO', N'e3', N'e4', NULL, NULL, 2843, '2026-09-01T17:30:25.025', 0),
    (12, 6, 6, N'MOVIMIENTO', N'e8', N'e7', NULL, NULL, 10762, '2026-09-01T17:30:35.787', 0);

SET IDENTITY_INSERT dbo.OfertaTablas ON;
INSERT INTO dbo.OfertaTablas (id_oferta, id_partida, id_ofertante, numero_jugada, fecha_oferta, estado, fecha_respuesta) VALUES
    (1, 4, 3, 4, '2026-07-20T19:00:21', N'CADUCADA', '2026-07-20T19:00:30'),
    (2, 6, 6, 2, '2026-08-10T18:00:19', N'RECHAZADA', '2026-08-10T18:00:25'),
    (3, 6, 6, 8, '2026-08-10T18:01:01', N'ACEPTADA', '2026-08-10T18:01:11'),
    (4, 12, 6, 6, '2026-09-01T17:30:38', N'PENDIENTE', NULL);
SET IDENTITY_INSERT dbo.OfertaTablas OFF;

SET IDENTITY_INSERT dbo.EnlaceEspectador ON;
INSERT INTO dbo.EnlaceEspectador (id_enlace, id_partida, id_creador, token_hash, fecha_creacion) VALUES
    (1, 12, 3, HASHBYTES('SHA2_256', 'espectador:1'), '2026-09-01T17:40:00');
SET IDENTITY_INSERT dbo.EnlaceEspectador OFF;

/*---------------------------------------------------------------------
  Emparejamiento, salas y chat
---------------------------------------------------------------------*/

SET IDENTITY_INSERT dbo.Sala ON;
INSERT INTO dbo.Sala (id_sala, codigo, id_anfitrion, id_modo, muros_por_jugador, minutos_reloj, permite_espectadores, estado, id_partida, fecha_creacion, fecha_ultima_actividad) VALUES
    (1, N'K7MTQ3', 6, 3, 8, 10, 1, N'CERRADA', 10, '2026-08-31T16:20:00', '2026-08-31T16:31:05'),
    (2, N'QX7PRM', 5, 1, 10, 5, 1, N'ABIERTA', NULL, '2026-09-01T17:50:00', '2026-09-01T17:58:30');
SET IDENTITY_INSERT dbo.Sala OFF;

INSERT INTO dbo.SalaParticipante (id_usuario, id_sala, plaza, listo, fecha_union) VALUES
    (5, 2, 1, 1, '2026-09-01T17:50:00'),
    (7, 2, 2, 0, '2026-09-01T17:52:00');

SET IDENTITY_INSERT dbo.Invitacion ON;
INSERT INTO dbo.Invitacion (id_invitacion, id_sala, id_emisor, id_destinatario, fecha_invitacion, fecha_expiracion, estado) VALUES
    (1, 1, 6, 4, '2026-08-31T16:21:00', '2026-08-31T16:22:00', N'EXPIRADA'),
    (2, 1, 6, 4, '2026-08-31T16:23:00', '2026-08-31T16:24:00', N'RECHAZADA'),
    (4, 1, 6, 7, '2026-08-31T16:24:00', '2026-08-31T16:25:00', N'ACEPTADA'),
    (3, 2, 5, 2, '2026-09-01T17:59:40', '2026-09-01T18:00:40', N'PENDIENTE');
SET IDENTITY_INSERT dbo.Invitacion OFF;

SET IDENTITY_INSERT dbo.Mensaje ON;
INSERT INTO dbo.Mensaje (id_mensaje, id_autor, canal, id_partida, id_sala, texto, fecha_envio) VALUES
    (1, 9, N'GLOBAL', NULL, NULL, N'Nadie aquí sabe jugar', '2026-08-25T21:00:00'),
    (2, 9, N'PARTIDA', 9, NULL, N'Juegas horrible, mejor ni lo intentes', '2026-08-26T17:11:05'),
    (3, 3, N'PARTIDA', 9, NULL, N'Tranquilo, es solo un juego', '2026-08-26T17:11:20'),
    (4, 6, N'SALA', NULL, 1, N'Welcome! We can start whenever you want', '2026-08-31T16:25:00'),
    (5, 3, N'AMIGOS', NULL, NULL, N'¿Jugamos más tarde?', '2026-09-01T17:15:00'),
    (6, 6, N'PARTIDA', 12, NULL, N'¡Suerte!', '2026-09-01T17:30:05'),
    (7, 3, N'PARTIDA', 12, NULL, N'Igualmente, compañera 👍', '2026-09-01T17:30:12'),
    (8, 2, N'ESPECTADORES', 12, NULL, N'Buen muro de sofía', '2026-09-01T17:31:00'),
    (9, 5, N'SALA', NULL, 2, N'¿Listos?', '2026-09-01T17:53:00'),
    (10, 7, N'SALA', NULL, 2, N'Ya casi', '2026-09-01T17:53:30'),
    (11, 4, N'GLOBAL', NULL, NULL, N'¿Alguien para una rápida?', '2026-09-01T17:56:00');
SET IDENTITY_INSERT dbo.Mensaje OFF;

INSERT INTO dbo.ColaEmparejamiento (id_usuario, id_modo, minutos_reloj, fecha_entrada) VALUES
    (4, 3, 3, '2026-09-01T17:55:00');

/*---------------------------------------------------------------------
  Clasificación y economía
---------------------------------------------------------------------*/

-- Una fila por cuenta y modo activo (CU-02 RN-06); los contadores resumen sus partidas clasificatorias.
INSERT INTO dbo.EstadisticaModo (id_usuario, id_modo, puntos_elo, fecha_ultima_partida, elo_maximo, partidas_jugadas, partidas_ganadas, partidas_perdidas, racha_actual, mejor_racha, tiempo_total_jugado, barreras_colocadas, abandonos, id_division) VALUES
    (1, 1, 1000, NULL, 1000, 0, 0, 0, 0, 0, 0, 0, 0, NULL),
    (1, 2, 1000, NULL, 1000, 0, 0, 0, 0, 0, 0, 0, 0, NULL),
    (1, 3, 1000, NULL, 1000, 0, 0, 0, 0, 0, 0, 0, 0, NULL),
    (2, 1, 1000, NULL, 1000, 0, 0, 0, 0, 0, 0, 0, 0, NULL),
    (2, 2, 1000, NULL, 1000, 0, 0, 0, 0, 0, 0, 0, 0, NULL),
    (2, 3, 1000, NULL, 1000, 0, 0, 0, 0, 0, 0, 0, 0, NULL),
    (3, 1, 1055, '2026-08-26T17:11:55', 1055, 6, 5, 1, 3, 3, 599, 4, 0, 2),
    (3, 2, 1024, '2026-08-15T19:01:30', 1024, 1, 1, 0, 0, 0, 90, 0, 0, NULL),
    (3, 3, 1000, NULL, 1000, 0, 0, 0, 0, 0, 0, 0, 0, NULL),
    (4, 1, 959, '2026-07-26T17:31:40', 1000, 5, 1, 4, 0, 1, 484, 8, 0, 1),
    (4, 2, 1008, '2026-08-15T19:01:30', 1008, 1, 0, 1, 0, 0, 90, 1, 1, NULL),
    (4, 3, 1016, '2026-08-28T18:03:29', 1016, 1, 1, 0, 0, 0, 209, 0, 0, NULL),
    (5, 1, 1000, NULL, 1000, 0, 0, 0, 0, 0, 0, 0, 0, NULL),
    (5, 2, 976, '2026-08-15T19:01:30', 1000, 1, 0, 1, 0, 0, 90, 0, 1, NULL),
    (5, 3, 984, '2026-08-28T18:03:29', 1000, 2, 0, 1, 0, 0, 280, 2, 0, NULL),
    (6, 1, 1000, NULL, 1000, 0, 0, 0, 0, 0, 0, 0, 0, NULL),
    (6, 2, 992, '2026-08-15T19:01:30', 1000, 1, 0, 1, 0, 0, 90, 0, 1, NULL),
    (6, 3, 1000, '2026-08-10T18:01:11', 1000, 1, 0, 0, 0, 0, 71, 1, 0, NULL),
    (7, 1, 1000, NULL, 1000, 0, 0, 0, 0, 0, 0, 0, 0, NULL),
    (7, 2, 1000, NULL, 1000, 0, 0, 0, 0, 0, 0, 0, 0, NULL),
    (7, 3, 1000, NULL, 1000, 0, 0, 0, 0, 0, 0, 0, 0, NULL),
    (8, 1, 1000, NULL, 1000, 0, 0, 0, 0, 0, 0, 0, 0, NULL),
    (8, 2, 1000, NULL, 1000, 0, 0, 0, 0, 0, 0, 0, 0, NULL),
    (8, 3, 1000, NULL, 1000, 0, 0, 0, 0, 0, 0, 0, 0, NULL),
    (9, 1, 986, '2026-08-26T17:11:55', 1000, 1, 0, 1, 0, 0, 115, 3, 0, NULL),
    (9, 2, 1000, NULL, 1000, 0, 0, 0, 0, 0, 0, 0, 0, NULL),
    (9, 3, 1000, NULL, 1000, 0, 0, 0, 0, 0, 0, 0, 0, NULL),
    (10, 1, 1000, NULL, 1000, 0, 0, 0, 0, 0, 0, 0, 0, NULL),
    (10, 2, 1000, NULL, 1000, 0, 0, 0, 0, 0, 0, 0, 0, NULL),
    (10, 3, 1000, NULL, 1000, 0, 0, 0, 0, 0, 0, 0, 0, NULL),
    (11, 1, 1000, NULL, 1000, 0, 0, 0, 0, 0, 0, 0, 0, NULL),
    (11, 2, 1000, NULL, 1000, 0, 0, 0, 0, 0, 0, 0, 0, NULL),
    (11, 3, 1000, NULL, 1000, 0, 0, 0, 0, 0, 0, 0, 0, NULL);

SET IDENTITY_INSERT dbo.HistorialDivision ON;
INSERT INTO dbo.HistorialDivision (id_historial_division, id_usuario, id_modo, id_division_anterior, id_division_nueva, fecha_cambio) VALUES
    (1, 3, 1, NULL, 2, '2026-07-26T17:31:40'),
    (2, 4, 1, NULL, 1, '2026-07-26T17:31:40');
SET IDENTITY_INSERT dbo.HistorialDivision OFF;

SET IDENTITY_INSERT dbo.Caja ON;
INSERT INTO dbo.Caja (id_caja, id_usuario, id_tipo_caja, origen, estado, fecha_obtencion, fecha_apertura, fecha_caducidad) VALUES
    (1, 4, 1, N'PARTIDA', N'CADUCADA', '2026-07-26T17:40:00', NULL, '2026-08-09T17:40:00'),
    (2, 5, 1, N'PARTIDA', N'SIN_ABRIR', '2026-08-20T16:10:00', NULL, '2026-09-03T16:10:00'),
    (3, 3, 1, N'COMPRA', N'ABIERTA', '2026-08-27T12:00:00', '2026-08-27T12:01:00', NULL);
SET IDENTITY_INSERT dbo.Caja OFF;

INSERT INTO dbo.CajaContenido (id_caja, numero, id_objeto, monedas_conversion) VALUES
    (3, 1, 202, NULL),
    (3, 2, 603, 40),
    (3, 3, 203, NULL);

SET IDENTITY_INSERT dbo.MovimientoMoneda ON;
INSERT INTO dbo.MovimientoMoneda (id_movimiento, id_usuario, tipo, importe, fecha_movimiento, id_partida, id_objeto, id_caja) VALUES
    (1, 3, N'PARTIDA', 100, '2026-07-05T17:01:42', 1, NULL, NULL),
    (2, 4, N'PARTIDA', 25, '2026-07-05T17:01:42', 1, NULL, NULL),
    (3, 4, N'PARTIDA', 25, '2026-07-08T18:00:52', 2, NULL, NULL),
    (4, 3, N'PARTIDA', 100, '2026-07-08T18:00:52', 2, NULL, NULL),
    (5, 3, N'PARTIDA', 25, '2026-07-12T16:31:54', 3, NULL, NULL),
    (6, 4, N'PARTIDA', 100, '2026-07-12T16:31:54', 3, NULL, NULL),
    (7, 4, N'PARTIDA', 25, '2026-07-20T19:01:56', 4, NULL, NULL),
    (8, 3, N'PARTIDA', 100, '2026-07-20T19:01:56', 4, NULL, NULL),
    (9, 3, N'NIVEL', 100, '2026-07-20T19:10:00', NULL, NULL, NULL),
    (10, 3, N'COMPRA', -120, '2026-07-21T18:00:00', NULL, 603, NULL),
    (11, 3, N'PARTIDA', 100, '2026-07-26T17:31:40', 5, NULL, NULL),
    (12, 4, N'PARTIDA', 25, '2026-07-26T17:31:40', 5, NULL, NULL),
    (13, 3, N'COMPRA', -250, '2026-07-27T18:00:00', NULL, 103, NULL),
    (14, 5, N'PARTIDA', 50, '2026-08-10T18:01:11', 6, NULL, NULL),
    (15, 6, N'PARTIDA', 50, '2026-08-10T18:01:11', 6, NULL, NULL),
    (16, 3, N'PARTIDA', 150, '2026-08-15T19:01:30', 7, NULL, NULL),
    (17, 4, N'PARTIDA', 60, '2026-08-15T19:01:30', 7, NULL, NULL),
    (18, 5, N'PARTIDA', 25, '2026-08-15T19:01:30', 7, NULL, NULL),
    (19, 6, N'PARTIDA', 40, '2026-08-15T19:01:30', 7, NULL, NULL),
    (20, 4, N'NIVEL', 100, '2026-08-15T19:10:00', NULL, NULL, NULL),
    (21, 4, N'COMPRA', -150, '2026-08-16T19:00:00', NULL, 202, NULL),
    (22, 5, N'NIVEL', 100, '2026-08-20T16:10:00', NULL, NULL, NULL),
    (23, 5, N'COMPRA', -120, '2026-08-21T17:00:00', NULL, 603, NULL),
    (24, 3, N'PARTIDA', 100, '2026-08-26T17:11:55', 9, NULL, NULL),
    (25, 9, N'PARTIDA', 25, '2026-08-26T17:11:55', 9, NULL, NULL),
    (26, 3, N'NIVEL', 100, '2026-08-26T17:20:00', NULL, NULL, NULL),
    (27, 3, N'COMPRA_CAJA', -300, '2026-08-27T12:00:00', NULL, NULL, 3),
    (28, 3, N'CONVERSION', 40, '2026-08-27T12:01:00', NULL, 603, 3),
    (29, 4, N'PARTIDA', 100, '2026-08-28T18:03:29', 11, NULL, NULL),
    (30, 5, N'PARTIDA', 25, '2026-08-28T18:03:29', 11, NULL, NULL);
SET IDENTITY_INSERT dbo.MovimientoMoneda OFF;

/*---------------------------------------------------------------------
  Relaciones entre jugadores y tutorial
---------------------------------------------------------------------*/

INSERT INTO dbo.Amistad (id_usuario_a, id_usuario_b, fecha_amistad) VALUES
    (3, 4, '2026-06-20T18:00:00'),
    (3, 5, '2026-06-25T17:00:00'),
    (2, 5, '2026-07-01T12:00:00'),
    (4, 6, '2026-07-03T19:00:00');

SET IDENTITY_INSERT dbo.Solicitud ON;
INSERT INTO dbo.Solicitud (id_solicitud, id_solicitante, id_destinatario, fecha_solicitud) VALUES
    (1, 6, 5, '2026-08-29T20:00:00');
SET IDENTITY_INSERT dbo.Solicitud OFF;

INSERT INTO dbo.Silencio (id_usuario, id_silenciado, fecha_silencio) VALUES
    (4, 9, '2026-08-25T21:05:00');

INSERT INTO dbo.Bloqueo (id_bloqueador, id_bloqueado, fecha_bloqueo) VALUES
    (3, 9, '2026-08-26T17:25:00');

INSERT INTO dbo.ProgresoTutorial (id_usuario, id_leccion, paso_actual, fecha_actualizacion, fecha_completada) VALUES
    (5, 1, 3, '2026-06-15T12:20:00', '2026-06-15T12:20:00'),
    (5, 2, 4, '2026-06-15T12:35:00', '2026-06-15T12:35:00'),
    (5, 3, 2, '2026-06-16T18:00:00', NULL),
    (6, 1, 3, '2026-06-18T20:10:00', '2026-06-18T20:10:00'),
    (6, 2, 4, '2026-06-18T20:20:00', '2026-06-18T20:20:00'),
    (6, 3, 4, '2026-06-19T17:00:00', '2026-06-19T17:00:00'),
    (6, 4, 5, '2026-06-19T17:15:00', '2026-06-19T17:15:00'),
    (7, 1, 3, '2026-08-30T16:10:00', '2026-08-30T16:10:00');

/*---------------------------------------------------------------------
  Moderación y bitácoras
---------------------------------------------------------------------*/

SET IDENTITY_INSERT dbo.Reporte ON;
INSERT INTO dbo.Reporte (id_reporte, id_denunciante, id_reportado, id_motivo, descripcion, id_partida, fecha_reporte, estado, id_moderador, fecha_asignacion, nota_resolucion, fecha_resolucion) VALUES
    (1, 3, 9, 1, N'Me insultó en el chat de la partida.', 9, '2026-08-26T17:20:00', N'RESUELTO_CON_SANCION', 2, '2026-08-27T09:50:00', N'Insultos comprobados en el chat de la partida.', '2026-08-27T10:00:00'),
    (2, 4, 9, 2, N'Molesta a todos en el chat global.', NULL, '2026-08-25T21:06:00', N'PENDIENTE', NULL, NULL, NULL, NULL),
    (3, 6, 3, 5, N'Creo que esperó a que abandonáramos.', 7, '2026-08-15T19:30:00', N'EN_REVISION', 2, '2026-09-01T17:40:00', NULL, NULL),
    (4, 3, 11, 3, N'Su nickname imita al del administrador.', NULL, '2026-08-22T20:30:00', N'RESUELTO_CON_SANCION', 2, '2026-08-23T09:55:00', N'El nickname suplanta al equipo del juego.', '2026-08-23T10:00:00'),
    (5, 4, 3, 4, N'Me saltó y llegó a la meta muy rápido; creo que usa un programa.', 5, '2026-07-26T17:40:00', N'RESUELTO_SIN_SANCION', 2, '2026-07-27T09:00:00', N'La repetición muestra jugadas legales; el salto es válido (CU-20 RN-03).', '2026-07-27T09:20:00');
SET IDENTITY_INSERT dbo.Reporte OFF;

-- La sustituta se enlaza después con UPDATE, cuando ya existe (CU-44 RN-09).
SET IDENTITY_INSERT dbo.Sancion ON;
INSERT INTO dbo.Sancion (id_sancion, id_usuario, id_moderador, id_reporte, ambito, tipo, motivo, fecha_inicio, fecha_fin, fecha_retiro, id_sancion_sustituta) VALUES
    (1, 9, 2, 1, N'CUENTA', N'TEMPORAL', N'Insultos en el chat de una partida.', '2026-08-27T10:00:00', '2026-08-28T10:00:00', '2026-08-27T16:00:00', NULL),
    (2, 9, 2, 1, N'CUENTA', N'TEMPORAL', N'Insultos reiterados; se amplía la suspensión.', '2026-08-27T16:00:00', '2026-09-03T16:00:00', NULL, NULL),
    (3, 5, 2, NULL, N'CHAT', N'TEMPORAL', N'Mensajes repetidos para molestar.', '2026-07-10T12:00:00', '2026-07-11T12:00:00', NULL, NULL),
    (4, 6, 2, NULL, N'CHAT', N'PERMANENTE', N'Lenguaje ofensivo en el chat global.', '2026-08-05T18:00:00', NULL, '2026-08-06T12:00:00', NULL),
    (5, 11, 2, 4, N'CUENTA', N'PERMANENTE', N'Suplanta al equipo del juego con su nickname.', '2026-08-23T10:00:00', NULL, NULL, NULL);
SET IDENTITY_INSERT dbo.Sancion OFF;

SET IDENTITY_INSERT dbo.Apelacion ON;
INSERT INTO dbo.Apelacion (id_apelacion, id_sancion, texto, marca_lenguaje, fecha_apelacion, estado, id_moderador, fecha_asignacion, nota_resolucion, fecha_resolucion) VALUES
    (1, 4, N'Fue un malentendido con una palabra en inglés.', 0, '2026-08-05T20:00:00', N'ACEPTADA', 1, '2026-08-06T11:30:00', N'La palabra no era un insulto en su contexto.', '2026-08-06T12:00:00'),
    (2, 2, N'No fue para tanto, solo le dije que jugaba tonto.', 1, '2026-08-29T10:00:00', N'PENDIENTE', NULL, NULL, NULL, NULL),
    (3, 3, N'Solo repetí el mensaje porque nadie me contestaba.', 0, '2026-07-10T13:00:00', N'RECHAZADA', 1, '2026-07-10T15:00:00', N'Los mensajes repetidos para molestar constan en el chat.', '2026-07-10T15:10:00');
SET IDENTITY_INSERT dbo.Apelacion OFF;

SET IDENTITY_INSERT dbo.BitacoraModeracion ON;
INSERT INTO dbo.BitacoraModeracion (id_bitacora, id_moderador, accion, id_usuario_afectado, detalle, fecha_hora) VALUES
    (1, 1, N'ROL_OTORGADO', 2, N'Rol MODERADOR otorgado.', '2026-06-05T10:00:00'),
    (2, 2, N'SANCION_APLICADA', 5, N'Sanción 3: chat, temporal.', '2026-07-10T12:00:00'),
    (3, 1, N'APELACION_RESUELTA', 5, N'Apelación 3 rechazada; se mantiene la sanción 3.', '2026-07-10T15:10:00'),
    (4, 2, N'REPORTE_TOMADO', 3, N'Reporte 5.', '2026-07-27T09:00:00'),
    (5, 2, N'REPORTE_RESUELTO', 3, N'Reporte 5 resuelto sin sanción.', '2026-07-27T09:20:00'),
    (6, 2, N'SANCION_APLICADA', 6, N'Sanción 4: chat, permanente.', '2026-08-05T18:00:00'),
    (7, 1, N'APELACION_RESUELTA', 6, N'Apelación 1 aceptada; sanción 4 retirada.', '2026-08-06T12:00:00'),
    (8, 2, N'REPORTE_TOMADO', 11, N'Reporte 4.', '2026-08-23T09:55:00'),
    (9, 2, N'SANCION_APLICADA', 11, N'Sanción 5: cuenta, permanente.', '2026-08-23T10:00:00'),
    (10, 2, N'REPORTE_RESUELTO', 11, N'Reporte 4 resuelto con sanción.', '2026-08-23T10:00:00'),
    (11, 2, N'REPORTE_TOMADO', 9, N'Reporte 2.', '2026-08-26T10:00:00'),
    (12, 2, N'REPORTE_LIBERADO', 9, N'Reporte 2: vuelve a la cola a los treinta minutos (CU-43 RN-03).', '2026-08-26T10:30:00'),
    (13, 2, N'REPORTE_TOMADO', 9, N'Reporte 1.', '2026-08-27T09:50:00'),
    (14, 2, N'SANCION_APLICADA', 9, N'Sanción 1: cuenta, temporal.', '2026-08-27T10:00:00'),
    (15, 2, N'REPORTE_RESUELTO', 9, N'Reporte 1 resuelto con sanción.', '2026-08-27T10:00:00'),
    (16, 2, N'SANCION_APLICADA', 9, N'Sanción 2: sustituye a la 1.', '2026-08-27T16:00:00'),
    (17, 4, N'INTENTO_SIN_PERMISO', NULL, N'Intentó abrir la cola de reportes.', '2026-08-30T18:00:00'),
    (18, 1, N'CONSULTA_BITACORA', NULL, N'Bitácora de acceso, últimos siete días.', '2026-08-31T09:00:00'),
    (19, 2, N'REPORTE_TOMADO', 3, N'Reporte 3.', '2026-09-01T17:40:00');
SET IDENTITY_INSERT dbo.BitacoraModeracion OFF;

SET IDENTITY_INSERT dbo.BitacoraAcceso ON;
INSERT INTO dbo.BitacoraAcceso (id_bitacora, id_usuario, identificador_capturado, resultado, direccion_ip, fecha_hora) VALUES
    (1, 1, NULL, N'REGISTRO_EXITOSO', N'189.203.14.20', '2026-06-01T10:00:00'),
    (2, 1, NULL, N'CUENTA_VERIFICADA', N'189.203.14.20', '2026-06-01T10:10:00'),
    (3, 2, NULL, N'REGISTRO_EXITOSO', N'201.141.22.7', '2026-06-02T09:00:00'),
    (4, 2, NULL, N'CUENTA_VERIFICADA', N'201.141.22.7', '2026-06-02T09:10:00'),
    (5, 3, NULL, N'REGISTRO_EXITOSO', N'189.203.55.3', '2026-06-10T16:00:00'),
    (6, 3, NULL, N'CUENTA_VERIFICADA', N'189.203.55.3', '2026-06-10T16:10:00'),
    (7, 4, NULL, N'REGISTRO_EXITOSO', N'187.190.3.41', '2026-06-12T18:30:00'),
    (8, 4, NULL, N'CUENTA_VERIFICADA', N'187.190.3.41', '2026-06-12T18:40:00'),
    (9, 5, NULL, N'REGISTRO_EXITOSO', N'201.141.80.12', '2026-06-15T12:00:00'),
    (10, 5, NULL, N'CUENTA_VERIFICADA', N'201.141.80.12', '2026-06-15T12:10:00'),
    (11, 6, NULL, N'REGISTRO_EXITOSO', N'187.190.66.5', '2026-06-18T20:00:00'),
    (12, 6, NULL, N'CUENTA_VERIFICADA', N'187.190.66.5', '2026-06-18T20:10:00'),
    (13, 9, NULL, N'REGISTRO_EXITOSO', N'201.141.90.33', '2026-06-20T15:00:00'),
    (14, 9, NULL, N'CUENTA_VERIFICADA', N'201.141.90.33', '2026-06-20T15:10:00'),
    (15, 10, NULL, N'REGISTRO_EXITOSO', N'189.203.77.8', '2026-06-22T11:00:00'),
    (16, 10, NULL, N'CUENTA_VERIFICADA', N'189.203.77.8', '2026-06-22T11:10:00'),
    (17, 2, NULL, N'CAMBIO_CONTRASENA', N'201.141.22.7', '2026-07-15T12:00:00'),
    (18, 4, N'marta_muros', N'EXITO', N'187.190.3.41', '2026-08-01T19:00:00'),
    (19, 4, N'marta_muros', N'SEGUNDO_FACTOR_ACTIVADO', N'187.190.3.41', '2026-08-01T19:06:00'),
    (20, 4, NULL, N'CIERRE_VOLUNTARIO', N'187.190.3.41', '2026-08-01T20:30:00'),
    (21, 10, NULL, N'EXITO', N'189.203.77.8', '2026-08-02T12:30:00'),
    (22, 10, NULL, N'CUENTA_ELIMINADA', N'189.203.77.8', '2026-08-02T13:00:00'),
    (23, 4, N'marta_muros', N'SEGUNDO_FACTOR_FALLIDO', N'187.190.3.41', '2026-08-15T20:03:00'),
    (24, 6, N'sofia_salto', N'EXITO', N'187.190.66.5', '2026-08-19T18:00:00'),
    (25, 6, NULL, N'RECUPERACION_SOLICITADA', N'187.190.66.5', '2026-08-20T10:55:00'),
    (26, 6, NULL, N'RECUPERACION_EXITOSA', N'187.190.66.5', '2026-08-20T11:05:00'),
    (27, 11, NULL, N'REGISTRO_EXITOSO', N'201.141.33.8', '2026-08-22T19:00:00'),
    (28, 11, NULL, N'CUENTA_VERIFICADA', N'201.141.33.8', '2026-08-22T19:10:00'),
    (29, 11, N'4dm1n_oficial', N'EXITO', N'201.141.33.8', '2026-08-22T19:15:00'),
    (30, 11, N'4dm1n_oficial', N'CUENTA_SANCIONADA', N'201.141.33.8', '2026-08-24T18:00:00'),
    (31, 9, N'rayo_veloz', N'EXITO', N'201.141.90.33', '2026-08-26T17:00:00'),
    (32, 8, NULL, N'REGISTRO_EXITOSO', N'201.141.5.60', '2026-08-28T19:00:00'),
    (33, NULL, N'admin', N'REGISTRO_RECHAZADO', N'201.141.5.61', '2026-08-29T12:00:00'),
    (34, NULL, N'pepe@correo.mx', N'RECUPERACION_CORREO_INEXISTENTE', N'201.141.8.14', '2026-08-29T13:00:00'),
    (35, 7, NULL, N'ALTA_INVITADO', N'189.203.40.2', '2026-08-30T16:00:00'),
    (36, 9, N'rayo_veloz', N'CUENTA_SANCIONADA', N'201.141.90.33', '2026-08-30T19:00:00'),
    (37, 1, N'admin_bastion', N'EXITO', N'189.203.14.20', '2026-08-31T08:00:00'),
    (38, 1, NULL, N'CIERRE_VOLUNTARIO', N'189.203.14.20', '2026-08-31T12:00:00'),
    (39, 3, N'luis_quo', N'EXITO', N'189.203.55.3', '2026-08-31T20:00:00'),
    (40, 1, N'admin_bastion', N'CONTRASENA_INCORRECTA', N'189.203.14.20', '2026-09-01T09:00:00'),
    (41, 1, N'admin_bastion', N'CONTRASENA_INCORRECTA', N'189.203.14.20', '2026-09-01T09:01:00'),
    (42, 1, N'admin_bastion', N'CONTRASENA_INCORRECTA', N'189.203.14.20', '2026-09-01T09:02:10'),
    (43, 1, N'admin_bastion', N'BLOQUEO_VIGENTE', N'189.203.14.20', '2026-09-01T09:04:00'),
    (44, 8, N'nico_nuevo', N'CUENTA_PENDIENTE', N'201.141.5.60', '2026-09-01T11:55:00'),
    (45, 2, N'ana_modera', N'EXITO', N'201.141.22.7', '2026-09-01T17:00:00'),
    (46, NULL, N'luis_qou', N'USUARIO_INEXISTENTE', N'189.203.55.9', '2026-09-01T17:04:30'),
    (47, 3, N'luis_quo', N'EXITO', N'189.203.55.9', '2026-09-01T17:05:00'),
    (48, 3, NULL, N'CIERRE_REMOTO', N'189.203.55.9', '2026-09-01T17:10:00'),
    (49, 3, NULL, N'CAMBIO_CORREO_SOLICITADO', N'189.203.55.9', '2026-09-01T17:20:00'),
    (50, 6, N'sofia_salto', N'EXITO', N'187.190.66.5', '2026-09-01T17:25:00'),
    (51, 1, NULL, N'RECUPERACION_SOLICITADA', N'189.203.14.20', '2026-09-01T17:40:00'),
    (52, 5, N'pedro_peon', N'EXITO', N'201.141.80.12', '2026-09-01T17:45:00'),
    (53, 1, NULL, N'RECUPERACION_SOLICITADA', N'189.203.14.20', '2026-09-01T17:46:00'),
    (54, 4, N'marta_muros', N'EXITO', N'187.190.3.41', '2026-09-01T17:54:00');
SET IDENTITY_INSERT dbo.BitacoraAcceso OFF;

UPDATE dbo.Sancion SET id_sancion_sustituta = 2 WHERE id_sancion = 1;

COMMIT TRANSACTION;
GO

/*---------------------------------------------------------------------
  Comprobación: cada fila debe mostrar 0 incoherencias. Recalcula en la
  propia base las redundancias controladas y las reglas que los datos de
  prueba deben cumplir.
---------------------------------------------------------------------*/
SELECT comprobacion, incoherencias FROM (
    SELECT 1 AS n, N'Saldo igual a la suma de movimientos (CU-40 RN-02)' AS comprobacion, COUNT(*) AS incoherencias
    FROM dbo.Usuario AS u
    WHERE u.saldo_monedas <> ISNULL((SELECT SUM(m.importe) FROM dbo.MovimientoMoneda AS m WHERE m.id_usuario = u.id_usuario), 0)
    UNION ALL
    SELECT 2, N'Partidas, victorias y derrotas por modo', COUNT(*)
    FROM dbo.EstadisticaModo AS e
    CROSS APPLY (SELECT COUNT(*) AS jugadas,
                        SUM(CASE WHEN p.resultado = 'GANADA' THEN 1 ELSE 0 END) AS ganadas,
                        SUM(CASE WHEN p.resultado = 'PERDIDA' THEN 1 ELSE 0 END) AS perdidas
                 FROM dbo.Participacion AS p JOIN dbo.Partida AS pa ON pa.id_partida = p.id_partida
                 WHERE p.id_usuario = e.id_usuario AND pa.id_modo = e.id_modo
                   AND pa.tipo = 'CLASIFICATORIA' AND p.resultado IS NOT NULL) AS c
    WHERE e.partidas_jugadas <> c.jugadas OR e.partidas_ganadas <> ISNULL(c.ganadas, 0) OR e.partidas_perdidas <> ISNULL(c.perdidas, 0)
    UNION ALL
    SELECT 3, N'Elo vigente igual al último elo final', COUNT(*)
    FROM dbo.EstadisticaModo AS e
    WHERE e.puntos_elo <> ISNULL((SELECT TOP (1) p.elo_final FROM dbo.Participacion AS p
                                  JOIN dbo.Partida AS pa ON pa.id_partida = p.id_partida
                                  WHERE p.id_usuario = e.id_usuario AND pa.id_modo = e.id_modo AND p.elo_final IS NOT NULL
                                  ORDER BY pa.fecha_fin DESC), 1000)
    UNION ALL
    SELECT 4, N'Muros colocados en partidas clasificatorias', COUNT(*)
    FROM dbo.EstadisticaModo AS e
    WHERE e.barreras_colocadas <> (SELECT COUNT(*) FROM dbo.Jugada AS j JOIN dbo.Partida AS pa ON pa.id_partida = j.id_partida
                                   WHERE j.id_usuario = e.id_usuario AND pa.id_modo = e.id_modo AND pa.tipo = 'CLASIFICATORIA'
                                     AND pa.estado = 'FINALIZADA' AND j.tipo = 'MURO' AND j.deshecha = 0)
    UNION ALL
    SELECT 5, N'División solo a partir de cinco partidas (CU-25 RN-14)', COUNT(*)
    FROM dbo.EstadisticaModo AS e
    WHERE (e.id_division IS NULL AND e.partidas_jugadas >= 5) OR (e.id_division IS NOT NULL AND e.partidas_jugadas < 5)
    UNION ALL
    SELECT 6, N'Muros restantes: los iniciales menos los colocados', COUNT(*)
    FROM dbo.Participacion AS p
    JOIN dbo.Partida AS pa ON pa.id_partida = p.id_partida
    JOIN dbo.Modo AS mo ON mo.id_modo = pa.id_modo
    LEFT JOIN dbo.Sala AS s ON s.id_partida = pa.id_partida
    WHERE p.muros_restantes <> COALESCE(s.muros_por_jugador, mo.muros_por_jugador)
          - (SELECT COUNT(*) FROM dbo.Jugada AS j WHERE j.id_partida = p.id_partida AND j.id_usuario = p.id_usuario
             AND j.tipo = 'MURO' AND j.deshecha = 0)
    UNION ALL
    SELECT 7, N'Reloj restante: el inicial menos el consumido, o cero si se agotó', COUNT(*)
    FROM dbo.Participacion AS p JOIN dbo.Partida AS pa ON pa.id_partida = p.id_partida
    WHERE pa.minutos_reloj IS NOT NULL
      AND p.reloj_restante <> CASE WHEN pa.forma_termino = 'TIEMPO_AGOTADO' AND p.resultado = 'PERDIDA' THEN 0
          ELSE pa.minutos_reloj * 60000
          - ISNULL((SELECT SUM(j.tiempo_consumido) FROM dbo.Jugada AS j WHERE j.id_partida = p.id_partida AND j.id_usuario = p.id_usuario), 0) END
    UNION ALL
    SELECT 8, N'Casilla actual igual a la de la última jugada', COUNT(*)
    FROM dbo.Participacion AS p
    CROSS APPLY (SELECT TOP (1) j.casilla_destino FROM dbo.Jugada AS j
                 WHERE j.id_partida = p.id_partida AND j.id_usuario = p.id_usuario AND j.tipo = 'MOVIMIENTO' AND j.deshecha = 0
                 ORDER BY j.numero_jugada DESC) AS ultima
    WHERE p.casilla_actual <> ultima.casilla_destino
    UNION ALL
    SELECT 9, N'Un objeto equipado en cada ranura (CU-14 RN-01)', COUNT(*)
    FROM dbo.Usuario AS u
    WHERE (SELECT COUNT(*) FROM dbo.Equipamiento AS e WHERE e.id_usuario = u.id_usuario) <> (SELECT COUNT(*) FROM dbo.Ranura)
    UNION ALL
    SELECT 10, N'Aspecto fijado en cada ranura por participación', COUNT(*)
    FROM dbo.Participacion AS p
    WHERE (SELECT COUNT(*) FROM dbo.ParticipacionObjeto AS o WHERE o.id_partida = p.id_partida AND o.id_usuario = p.id_usuario)
          <> (SELECT COUNT(*) FROM dbo.Ranura)
    UNION ALL
    SELECT 11, N'Estadísticas de cada cuenta en cada modo activo (CU-02 RN-06)', COUNT(*)
    FROM dbo.Usuario AS u CROSS JOIN dbo.Modo AS m
    WHERE m.activo = 1 AND NOT EXISTS (SELECT 1 FROM dbo.EstadisticaModo AS e WHERE e.id_usuario = u.id_usuario AND e.id_modo = m.id_modo)
    UNION ALL
    SELECT 12, N'Objetos iniciales de cada cuenta (CU-02 RN-08)', COUNT(*)
    FROM dbo.Usuario AS u CROSS JOIN dbo.ObjetoCosmetico AS o
    WHERE o.es_inicial = 1 AND NOT EXISTS (SELECT 1 FROM dbo.UsuarioObjeto AS uo WHERE uo.id_usuario = u.id_usuario AND uo.id_objeto = o.id_objeto)
    UNION ALL
    SELECT 13, N'Un ganador en cada partida decidida entre jugadores', COUNT(*)
    FROM dbo.Partida AS pa
    WHERE pa.estado = 'FINALIZADA' AND pa.forma_termino <> 'TABLAS' AND pa.tipo <> 'IA'
      AND (SELECT COUNT(*) FROM dbo.Participacion AS p WHERE p.id_partida = pa.id_partida AND p.resultado = 'GANADA') <> 1
    UNION ALL
    SELECT 14, N'Probabilidades de cada tipo de caja que suman 100', COUNT(*)
    FROM (SELECT id_tipo_caja FROM dbo.TipoCajaObjeto GROUP BY id_tipo_caja HAVING SUM(probabilidad) <> 100) AS x
    UNION ALL
    SELECT 15, N'Tres objetos en cada caja abierta (CU-39 RN-07)', COUNT(*)
    FROM dbo.Caja AS c
    WHERE c.estado = 'ABIERTA' AND (SELECT COUNT(*) FROM dbo.CajaContenido AS x WHERE x.id_caja = c.id_caja) <> 3
    UNION ALL
    SELECT 16, N'Textos con ñ, acentos y emojis idénticos a los insertados (D-21)', COUNT(*)
    FROM (
          SELECT e.v FROM (VALUES
                  (N'est' + NCHAR(250) + N'pido')) AS e(v)
          WHERE NOT EXISTS (SELECT 1 FROM dbo.PalabraProhibida AS t WHERE t.termino = e.v COLLATE Latin1_General_100_BIN2)
          UNION ALL
          SELECT e.v FROM (VALUES
                  (N'Nadie aqu' + NCHAR(237) + N' sabe jugar'),
                  (NCHAR(191) + N'Jugamos m' + NCHAR(225) + N's tarde?'),
                  (NCHAR(161) + N'Suerte!'),
                  (N'Igualmente, compa' + NCHAR(241) + N'era ' + NCHAR(128077)),
                  (N'Buen muro de sof' + NCHAR(237) + N'a'),
                  (NCHAR(191) + N'Listos?'),
                  (NCHAR(191) + N'Alguien para una r' + NCHAR(225) + N'pida?')) AS e(v)
          WHERE NOT EXISTS (SELECT 1 FROM dbo.Mensaje AS t WHERE t.texto = e.v COLLATE Latin1_General_100_BIN2)
          UNION ALL
          SELECT e.v FROM (VALUES
                  (N'Me insult' + NCHAR(243) + N' en el chat de la partida.'),
                  (N'Creo que esper' + NCHAR(243) + N' a que abandon' + NCHAR(225) + N'ramos.'),
                  (N'Me salt' + NCHAR(243) + N' y lleg' + NCHAR(243) + N' a la meta muy r' + NCHAR(225) + N'pido; creo que usa un programa.')) AS e(v)
          WHERE NOT EXISTS (SELECT 1 FROM dbo.Reporte AS t WHERE t.descripcion = e.v COLLATE Latin1_General_100_BIN2)
          UNION ALL
          SELECT e.v FROM (VALUES
                  (N'La repetici' + NCHAR(243) + N'n muestra jugadas legales; el salto es v' + NCHAR(225) + N'lido (CU-20 RN-03).')) AS e(v)
          WHERE NOT EXISTS (SELECT 1 FROM dbo.Reporte AS t WHERE t.nota_resolucion = e.v COLLATE Latin1_General_100_BIN2)
          UNION ALL
          SELECT e.v FROM (VALUES
                  (N'Insultos reiterados; se ampl' + NCHAR(237) + N'a la suspensi' + NCHAR(243) + N'n.')) AS e(v)
          WHERE NOT EXISTS (SELECT 1 FROM dbo.Sancion AS t WHERE t.motivo = e.v COLLATE Latin1_General_100_BIN2)
          UNION ALL
          SELECT e.v FROM (VALUES
                  (N'Fue un malentendido con una palabra en ingl' + NCHAR(233) + N's.'),
                  (N'Solo repet' + NCHAR(237) + N' el mensaje porque nadie me contestaba.')) AS e(v)
          WHERE NOT EXISTS (SELECT 1 FROM dbo.Apelacion AS t WHERE t.texto = e.v COLLATE Latin1_General_100_BIN2)
          UNION ALL
          SELECT e.v FROM (VALUES
                  (N'Sanci' + NCHAR(243) + N'n 3: chat, temporal.'),
                  (N'Apelaci' + NCHAR(243) + N'n 3 rechazada; se mantiene la sanci' + NCHAR(243) + N'n 3.'),
                  (N'Reporte 5 resuelto sin sanci' + NCHAR(243) + N'n.'),
                  (N'Sanci' + NCHAR(243) + N'n 4: chat, permanente.'),
                  (N'Apelaci' + NCHAR(243) + N'n 1 aceptada; sanci' + NCHAR(243) + N'n 4 retirada.'),
                  (N'Sanci' + NCHAR(243) + N'n 5: cuenta, permanente.'),
                  (N'Reporte 4 resuelto con sanci' + NCHAR(243) + N'n.'),
                  (N'Sanci' + NCHAR(243) + N'n 1: cuenta, temporal.'),
                  (N'Reporte 1 resuelto con sanci' + NCHAR(243) + N'n.'),
                  (N'Sanci' + NCHAR(243) + N'n 2: sustituye a la 1.'),
                  (N'Intent' + NCHAR(243) + N' abrir la cola de reportes.'),
                  (N'Bit' + NCHAR(225) + N'cora de acceso, ' + NCHAR(250) + N'ltimos siete d' + NCHAR(237) + N'as.')) AS e(v)
          WHERE NOT EXISTS (SELECT 1 FROM dbo.BitacoraModeracion AS t WHERE t.detalle = e.v COLLATE Latin1_General_100_BIN2)
         ) AS distintos
) AS c
ORDER BY n;

-- Filas cargadas por tabla.
SELECT t.name AS tabla, SUM(p.rows) AS filas
FROM sys.tables AS t
JOIN sys.partitions AS p ON p.object_id = t.object_id AND p.index_id IN (0, 1)
GROUP BY t.name
ORDER BY t.name;
GO

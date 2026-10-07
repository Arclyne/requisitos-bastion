/*=====================================================================
  Bastion - Inserción de datos de prueba del núcleo (3 de 3)
  Motor: SQL Server 2019 o posterior (CON-04).

  Orden de ejecución:
     1. crear_base_datos.sql
     2. crear_tablas.sql
     3. insertar_datos_prueba.sql  <- este archivo

  Archivo generado por bd/generar_datos_prueba.py a partir del escenario de
  bd/datos_prueba/. No editar a mano: se edita el escenario y se vuelve a
  generar.

  Carga los catálogos del núcleo y la parte del escenario de prueba que
  cabe en las 19 tablas del núcleo. Es una fotografía de la base el 2026-09-01 18:00:00
  UTC. Lo que el escenario tiene de los agregados (objetos, monedas, cajas,
  divisiones, amigos, la partida contra la IA) se carga después con
  fase_posterior/insertar_datos_prueba_fase_posterior.sql (D-22).
  Lo que el modelo guarda como consecuencia de otras filas (elo,
  estadísticas, estado del tablero) se calculó a partir de ellas, y las
  consultas del final lo comprueban.

  Se ejecuta con una cuenta de administración sobre las tablas recién
  creadas y vacías: fija los identificadores con IDENTITY_INSERT, que
  BastionServerConnection no puede usar. Todo va en una transacción: si
  una fila falla, no se carga ninguna.

  El archivo está en UTF-8: se ejecuta con sqlcmd -f 65001, o se abre en
  SQL Server Management Studio, que lo reconoce por su marca de orden de
  bytes. Los textos van como literales N'...', con sus eñes y acentos, y la
  última comprobación verifica que se guardaron sin pérdida (D-21).
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

INSERT INTO dbo.Modo (id_modo, codigo, tamano_tablero, num_jugadores, muros_por_jugador, activo) VALUES
    (1, N'CLASICO', 9, 2, 10, 1),
    (2, N'CUATRO_JUGADORES', 9, 4, 5, 1),
    (3, N'RAPIDA', 7, 2, 6, 1);

-- Un término sin idioma se filtra en todos (CU-19 RN-01).
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

/*---------------------------------------------------------------------
  Cuenta y acceso
---------------------------------------------------------------------*/

-- Saldo y cajas sin objeto raro salen de los movimientos y cajas de más abajo. La última versión de los términos que aceptó cada cuenta (D-23).
SET IDENTITY_INSERT dbo.Usuario ON;
INSERT INTO dbo.Usuario (id_usuario, tipo_cuenta, estado_cuenta, rol, nickname, correo, contrasena_hash, contrasena_sal, fecha_nacimiento, idioma_preferido, intentos_fallidos, fecha_ultimo_intento_fallido, bloqueada_hasta, doble_factor_habilitado, fecha_registro, fecha_ultimo_envio_verificacion, fecha_ultimo_envio_recuperacion, fecha_baja, version_terminos, idioma_terminos, fecha_aceptacion_terminos) VALUES
    (1, N'REGISTRADA', N'ACTIVA', N'ADMINISTRADOR', N'admin_bastion', N'admin@bastion.mx', HASHBYTES('SHA2_512', 'Admin#2026:admin_bastion'), HASHBYTES('SHA2_256', 'sal:admin_bastion'), '1990-05-12', N'es-MX', 3, '2026-09-01T09:02:10', '2026-09-01T09:07:10', 0, '2026-06-01T10:00:00', '2026-06-01T10:00:00', '2026-09-01T17:46:00', NULL, N'2026.1', N'es-MX', '2026-06-01T10:00:00'),
    (2, N'REGISTRADA', N'ACTIVA', N'MODERADOR', N'ana_modera', N'ana.moderadora@correo.mx', HASHBYTES('SHA2_512', 'Ana#Modera26:ana_modera'), HASHBYTES('SHA2_256', 'sal:ana_modera'), '1995-02-20', N'es-MX', 0, NULL, NULL, 0, '2026-06-02T09:00:00', '2026-06-02T09:00:00', NULL, NULL, N'2026.1', N'es-MX', '2026-06-02T09:00:00'),
    (3, N'REGISTRADA', N'ACTIVA', N'JUGADOR', N'luis_quo', N'luis.quo@correo.mx', HASHBYTES('SHA2_512', 'Luis#Quo2026:luis_quo'), HASHBYTES('SHA2_256', 'sal:luis_quo'), '2008-03-15', N'es-MX', 0, NULL, NULL, 0, '2026-06-10T16:00:00', '2026-09-01T17:20:00', NULL, NULL, N'2026.2', N'es-MX', '2026-08-01T10:00:00'),
    (4, N'REGISTRADA', N'ACTIVA', N'JUGADOR', N'marta_muros', N'marta@correo.mx', HASHBYTES('SHA2_512', 'Marta#Muros9:marta_muros'), HASHBYTES('SHA2_256', 'sal:marta_muros'), '2009-07-01', N'es-MX', 0, NULL, NULL, 1, '2026-06-12T18:30:00', '2026-06-12T18:30:00', NULL, NULL, N'2026.1', N'es-MX', '2026-06-12T18:30:00'),
    (5, N'REGISTRADA', N'ACTIVA', N'JUGADOR', N'pedro_peon', N'pedro@correo.mx', HASHBYTES('SHA2_512', 'Pedro#Peon13:pedro_peon'), HASHBYTES('SHA2_256', 'sal:pedro_peon'), '2012-11-30', N'es-MX', 0, NULL, NULL, 0, '2026-06-15T12:00:00', '2026-06-15T12:00:00', NULL, NULL, N'2026.1', N'es-MX', '2026-06-15T12:00:00'),
    (6, N'REGISTRADA', N'ACTIVA', N'JUGADOR', N'sofia_salto', N'sofia@correo.mx', HASHBYTES('SHA2_512', 'Sofia#Salto8:sofia_salto'), HASHBYTES('SHA2_256', 'sal:sofia_salto'), '2011-04-18', N'en', 0, NULL, NULL, 0, '2026-06-18T20:00:00', '2026-06-18T20:00:00', '2026-08-20T10:55:00', NULL, N'2026.1', N'en', '2026-06-18T20:00:00'),
    (7, N'INVITADO', N'ACTIVA', N'JUGADOR', N'Invitado_4821', NULL, NULL, NULL, NULL, N'es-MX', 0, NULL, NULL, 0, '2026-08-30T16:00:00', NULL, NULL, NULL, NULL, NULL, NULL),
    (8, N'REGISTRADA', N'PENDIENTE', N'JUGADOR', N'nico_nuevo', N'nico@correo.mx', HASHBYTES('SHA2_512', 'Nico#Nuevo26:nico_nuevo'), HASHBYTES('SHA2_256', 'sal:nico_nuevo'), '2010-09-09', N'es-MX', 0, NULL, NULL, 0, '2026-08-28T19:00:00', '2026-09-01T12:00:00', NULL, NULL, N'2026.2', N'es-MX', '2026-08-28T19:00:00'),
    (9, N'REGISTRADA', N'SUSPENDIDA', N'JUGADOR', N'rayo_veloz', N'rayo@correo.mx', HASHBYTES('SHA2_512', 'Rayo#Veloz77:rayo_veloz'), HASHBYTES('SHA2_256', 'sal:rayo_veloz'), '2007-12-01', N'es-MX', 0, NULL, NULL, 0, '2026-06-20T15:00:00', '2026-06-20T15:00:00', NULL, NULL, N'2026.1', N'es-MX', '2026-06-20T15:00:00'),
    (10, N'REGISTRADA', N'ELIMINADA', N'JUGADOR', N'anonimo_10', N'anonimo_10', NULL, NULL, NULL, N'es-MX', 0, NULL, NULL, 0, '2026-06-22T11:00:00', '2026-06-22T11:00:00', NULL, '2026-08-02T13:00:00', N'2026.1', N'es-MX', '2026-06-22T11:00:00'),
    (11, N'REGISTRADA', N'BANEADA', N'JUGADOR', N'4dm1n_oficial', N'cuatro.admin@correo.mx', HASHBYTES('SHA2_512', 'Adm1n#Falso6:4dm1n_oficial'), HASHBYTES('SHA2_256', 'sal:4dm1n_oficial'), '2006-01-10', N'es-MX', 0, NULL, NULL, 0, '2026-08-22T19:00:00', '2026-08-22T19:00:00', NULL, NULL, N'2026.2', N'es-MX', '2026-08-22T19:00:00');
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

-- Los tokens de verificación y de recuperación y los códigos del segundo factor, en una sola tabla (D-23).
SET IDENTITY_INSERT dbo.CodigoVerificacion ON;
INSERT INTO dbo.CodigoVerificacion (id_codigo, id_usuario, proposito, codigo_hash, correo_destino, fecha_generacion, fecha_expiracion, intentos, estado) VALUES
    (1, 1, N'ALTA', HASHBYTES('SHA2_256', 'verificacion:1'), NULL, '2026-06-01T10:00:00', '2026-06-02T10:00:00', 0, N'USADO'),
    (2, 2, N'ALTA', HASHBYTES('SHA2_256', 'verificacion:2'), NULL, '2026-06-02T09:00:00', '2026-06-03T09:00:00', 0, N'USADO'),
    (3, 3, N'ALTA', HASHBYTES('SHA2_256', 'verificacion:3'), NULL, '2026-06-10T16:00:00', '2026-06-11T16:00:00', 0, N'USADO'),
    (4, 4, N'ALTA', HASHBYTES('SHA2_256', 'verificacion:4'), NULL, '2026-06-12T18:30:00', '2026-06-13T18:30:00', 0, N'USADO'),
    (5, 5, N'ALTA', HASHBYTES('SHA2_256', 'verificacion:5'), NULL, '2026-06-15T12:00:00', '2026-06-16T12:00:00', 0, N'USADO'),
    (6, 6, N'ALTA', HASHBYTES('SHA2_256', 'verificacion:6'), NULL, '2026-06-18T20:00:00', '2026-06-19T20:00:00', 0, N'USADO'),
    (7, 9, N'ALTA', HASHBYTES('SHA2_256', 'verificacion:7'), NULL, '2026-06-20T15:00:00', '2026-06-21T15:00:00', 0, N'USADO'),
    (8, 10, N'ALTA', HASHBYTES('SHA2_256', 'verificacion:8'), NULL, '2026-06-22T11:00:00', '2026-06-23T11:00:00', 0, N'USADO'),
    (9, 4, N'SEGUNDO_FACTOR', HASHBYTES('SHA2_256', 'codigo:1'), NULL, '2026-08-01T19:05:00', '2026-08-01T19:10:00', 0, N'USADO'),
    (10, 4, N'SEGUNDO_FACTOR', HASHBYTES('SHA2_256', 'codigo:2'), NULL, '2026-08-15T20:00:00', '2026-08-15T20:05:00', 3, N'INVALIDADO'),
    (11, 6, N'RECUPERACION', HASHBYTES('SHA2_256', 'recuperacion:1'), NULL, '2026-08-20T10:55:00', '2026-08-20T11:25:00', 1, N'USADO'),
    (12, 11, N'ALTA', HASHBYTES('SHA2_256', 'verificacion:12'), NULL, '2026-08-22T19:00:00', '2026-08-23T19:00:00', 0, N'USADO'),
    (13, 8, N'ALTA', HASHBYTES('SHA2_256', 'verificacion:9'), NULL, '2026-08-28T19:00:00', '2026-08-29T19:00:00', 0, N'INVALIDADO'),
    (14, 8, N'ALTA', HASHBYTES('SHA2_256', 'verificacion:10'), NULL, '2026-09-01T12:00:00', '2026-09-02T12:00:00', 0, N'PENDIENTE'),
    (15, 3, N'CAMBIO_CORREO', HASHBYTES('SHA2_256', 'verificacion:11'), N'luis.quo.nuevo@correo.mx', '2026-09-01T17:20:00', '2026-09-02T17:20:00', 0, N'PENDIENTE'),
    (16, 1, N'RECUPERACION', HASHBYTES('SHA2_256', 'recuperacion:2'), NULL, '2026-09-01T17:40:00', '2026-09-01T18:10:00', 0, N'INVALIDADO'),
    (17, 1, N'RECUPERACION', HASHBYTES('SHA2_256', 'recuperacion:3'), NULL, '2026-09-01T17:46:00', '2026-09-01T18:16:00', 0, N'PENDIENTE'),
    (18, 4, N'SEGUNDO_FACTOR', HASHBYTES('SHA2_256', 'codigo:3'), NULL, '2026-09-01T17:53:00', '2026-09-01T17:58:00', 0, N'USADO'),
    (19, 4, N'SEGUNDO_FACTOR', HASHBYTES('SHA2_256', 'codigo:4'), NULL, '2026-09-01T17:58:00', '2026-09-01T18:03:00', 0, N'PENDIENTE');
SET IDENTITY_INSERT dbo.CodigoVerificacion OFF;

/*---------------------------------------------------------------------
  Partida
---------------------------------------------------------------------*/

SET IDENTITY_INSERT dbo.Partida ON;
INSERT INTO dbo.Partida (id_partida, id_modo, tipo, estado, minutos_reloj, fecha_inicio, fecha_fin, forma_termino, turno_actual) VALUES
    (1, 1, N'CLASIFICATORIA', N'FINALIZADA', 5, '2026-07-05T17:00:00', '2026-07-05T17:01:42', N'META', 2),
    (2, 1, N'CLASIFICATORIA', N'FINALIZADA', 5, '2026-07-08T18:00:00', '2026-07-08T18:00:52', N'RENDICION', 1),
    (3, 1, N'CLASIFICATORIA', N'FINALIZADA', 5, '2026-07-12T16:30:00', '2026-07-12T16:31:54', N'META', 1),
    (4, 1, N'CLASIFICATORIA', N'FINALIZADA', 5, '2026-07-20T19:00:00', '2026-07-20T19:01:56', N'META', 1),
    (5, 1, N'CLASIFICATORIA', N'FINALIZADA', 5, '2026-07-26T17:30:00', '2026-07-26T17:31:40', N'META', 2),
    (6, 3, N'CLASIFICATORIA', N'FINALIZADA', 3, '2026-08-10T18:00:00', '2026-08-10T18:01:11', N'TABLAS', 1),
    (7, 2, N'CLASIFICATORIA', N'FINALIZADA', 10, '2026-08-15T19:00:00', '2026-08-15T19:01:30', N'ABANDONO', 2),
    (9, 1, N'CLASIFICATORIA', N'FINALIZADA', 5, '2026-08-26T17:10:00', '2026-08-26T17:11:55', N'META', 2),
    (10, 3, N'PRIVADA', N'FINALIZADA', 10, '2026-08-31T16:30:00', '2026-08-31T16:31:05', N'META', 2),
    (11, 3, N'CLASIFICATORIA', N'FINALIZADA', 3, '2026-08-28T18:00:00', '2026-08-28T18:03:29', N'TIEMPO_AGOTADO', 2),
    (12, 1, N'CLASIFICATORIA', N'EN_CURSO', 5, '2026-09-01T17:30:00', NULL, NULL, 1);
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
    (9, 3, 1, N'AZUL', N'd9', 10, 234012, 1041, 1055, N'GANADA', NULL, NULL, 1, NULL),
    (9, 9, 2, N'ROJO', N'g6', 7, 251344, 1000, 986, N'PERDIDA', NULL, NULL, 1, NULL),
    (10, 6, 1, N'AZUL', N'd7', 8, 568176, NULL, NULL, N'GANADA', NULL, NULL, 1, NULL),
    (10, 7, 2, N'ROJO', N'c5', 6, 567480, NULL, NULL, N'PERDIDA', NULL, NULL, 1, NULL),
    (11, 4, 1, N'AZUL', N'e4', 6, 151220, 1000, 1016, N'GANADA', NULL, NULL, 1, NULL),
    (11, 5, 2, N'ROJO', N'd5', 5, 0, 1000, 984, N'PERDIDA', NULL, NULL, 1, NULL),
    (12, 3, 1, N'AZUL', N'e4', 10, 284985, 1055, NULL, NULL, NULL, NULL, 1, NULL),
    (12, 6, 2, N'ROJO', N'e7', 9, 279228, 1000, NULL, NULL, NULL, NULL, 1, '2026-09-01T17:38:00');

INSERT INTO dbo.Jugada (id_partida, numero_jugada, id_usuario, tipo, casilla_origen, casilla_destino, surco, orientacion, tiempo_consumido, fecha_jugada) VALUES
    (1, 1, 3, N'MOVIMIENTO', N'e1', N'e2', NULL, NULL, 7148, '2026-07-05T17:00:07.148'),
    (1, 2, 4, N'MURO', NULL, NULL, N'a7', N'HORIZONTAL', 6067, '2026-07-05T17:00:13.215'),
    (1, 3, 3, N'MOVIMIENTO', N'e2', N'e3', NULL, NULL, 4986, '2026-07-05T17:00:18.201'),
    (1, 4, 4, N'MOVIMIENTO', N'e9', N'd9', NULL, NULL, 3905, '2026-07-05T17:00:22.106'),
    (1, 5, 3, N'MOVIMIENTO', N'e3', N'e4', NULL, NULL, 2824, '2026-07-05T17:00:24.930'),
    (1, 6, 4, N'MURO', NULL, NULL, N'g7', N'HORIZONTAL', 10743, '2026-07-05T17:00:35.673'),
    (1, 7, 3, N'MOVIMIENTO', N'e4', N'e5', NULL, NULL, 9662, '2026-07-05T17:00:45.335'),
    (1, 8, 4, N'MOVIMIENTO', N'd9', N'd8', NULL, NULL, 8581, '2026-07-05T17:00:53.916'),
    (1, 9, 3, N'MOVIMIENTO', N'e5', N'e6', NULL, NULL, 7500, '2026-07-05T17:01:01.416'),
    (1, 10, 4, N'MURO', NULL, NULL, N'b3', N'VERTICAL', 6419, '2026-07-05T17:01:07.835'),
    (1, 11, 3, N'MOVIMIENTO', N'e6', N'e7', NULL, NULL, 5338, '2026-07-05T17:01:13.173'),
    (1, 12, 4, N'MOVIMIENTO', N'd8', N'd7', NULL, NULL, 4257, '2026-07-05T17:01:17.430'),
    (1, 13, 3, N'MOVIMIENTO', N'e7', N'e8', NULL, NULL, 3176, '2026-07-05T17:01:20.606'),
    (1, 14, 4, N'MURO', NULL, NULL, N'h2', N'HORIZONTAL', 11095, '2026-07-05T17:01:31.701'),
    (1, 15, 3, N'MOVIMIENTO', N'e8', N'e9', NULL, NULL, 10014, '2026-07-05T17:01:41.715'),
    (2, 1, 4, N'MOVIMIENTO', N'e1', N'e2', NULL, NULL, 3877, '2026-07-08T18:00:03.877'),
    (2, 2, 3, N'MOVIMIENTO', N'e9', N'e8', NULL, NULL, 2796, '2026-07-08T18:00:06.673'),
    (2, 3, 4, N'MOVIMIENTO', N'e2', N'e3', NULL, NULL, 10715, '2026-07-08T18:00:17.388'),
    (2, 4, 3, N'MURO', NULL, NULL, N'd3', N'HORIZONTAL', 9634, '2026-07-08T18:00:27.022'),
    (2, 5, 4, N'MOVIMIENTO', N'e3', N'f3', NULL, NULL, 8553, '2026-07-08T18:00:35.575'),
    (2, 6, 3, N'MOVIMIENTO', N'e8', N'e7', NULL, NULL, 7472, '2026-07-08T18:00:43.047'),
    (3, 1, 3, N'MOVIMIENTO', N'e1', N'f1', NULL, NULL, 9606, '2026-07-12T16:30:09.606'),
    (3, 2, 4, N'MOVIMIENTO', N'e9', N'e8', NULL, NULL, 8525, '2026-07-12T16:30:18.131'),
    (3, 3, 3, N'MOVIMIENTO', N'f1', N'f2', NULL, NULL, 7444, '2026-07-12T16:30:25.575'),
    (3, 4, 4, N'MOVIMIENTO', N'e8', N'e7', NULL, NULL, 6363, '2026-07-12T16:30:31.938'),
    (3, 5, 3, N'MURO', NULL, NULL, N'a5', N'HORIZONTAL', 5282, '2026-07-12T16:30:37.220'),
    (3, 6, 4, N'MOVIMIENTO', N'e7', N'e6', NULL, NULL, 4201, '2026-07-12T16:30:41.421'),
    (3, 7, 3, N'MOVIMIENTO', N'f2', N'f3', NULL, NULL, 3120, '2026-07-12T16:30:44.541'),
    (3, 8, 4, N'MOVIMIENTO', N'e6', N'e5', NULL, NULL, 11039, '2026-07-12T16:30:55.580'),
    (3, 9, 3, N'MURO', NULL, NULL, N'h6', N'VERTICAL', 9958, '2026-07-12T16:31:05.538'),
    (3, 10, 4, N'MOVIMIENTO', N'e5', N'e4', NULL, NULL, 8877, '2026-07-12T16:31:14.415'),
    (3, 11, 3, N'MOVIMIENTO', N'f3', N'f4', NULL, NULL, 7796, '2026-07-12T16:31:22.211'),
    (3, 12, 4, N'MOVIMIENTO', N'e4', N'e3', NULL, NULL, 6715, '2026-07-12T16:31:28.926'),
    (3, 13, 3, N'MURO', NULL, NULL, N'c7', N'HORIZONTAL', 5634, '2026-07-12T16:31:34.560'),
    (3, 14, 4, N'MOVIMIENTO', N'e3', N'e2', NULL, NULL, 4553, '2026-07-12T16:31:39.113'),
    (3, 15, 3, N'MOVIMIENTO', N'f4', N'f5', NULL, NULL, 3472, '2026-07-12T16:31:42.585'),
    (3, 16, 4, N'MOVIMIENTO', N'e2', N'e1', NULL, NULL, 11391, '2026-07-12T16:31:53.976'),
    (4, 1, 4, N'MOVIMIENTO', N'e1', N'd1', NULL, NULL, 6335, '2026-07-20T19:00:06.335'),
    (4, 2, 3, N'MOVIMIENTO', N'e9', N'e8', NULL, NULL, 5254, '2026-07-20T19:00:11.589'),
    (4, 3, 4, N'MOVIMIENTO', N'd1', N'd2', NULL, NULL, 4173, '2026-07-20T19:00:15.762'),
    (4, 4, 3, N'MOVIMIENTO', N'e8', N'e7', NULL, NULL, 3092, '2026-07-20T19:00:18.854'),
    (4, 5, 4, N'MURO', NULL, NULL, N'f5', N'VERTICAL', 11011, '2026-07-20T19:00:29.865'),
    (4, 6, 3, N'MOVIMIENTO', N'e7', N'e6', NULL, NULL, 9930, '2026-07-20T19:00:39.795'),
    (4, 7, 4, N'MOVIMIENTO', N'd2', N'd3', NULL, NULL, 8849, '2026-07-20T19:00:48.644'),
    (4, 8, 3, N'MOVIMIENTO', N'e6', N'e5', NULL, NULL, 7768, '2026-07-20T19:00:56.412'),
    (4, 9, 4, N'MURO', NULL, NULL, N'b6', N'HORIZONTAL', 6687, '2026-07-20T19:01:03.099'),
    (4, 10, 3, N'MOVIMIENTO', N'e5', N'e4', NULL, NULL, 5606, '2026-07-20T19:01:08.705'),
    (4, 11, 4, N'MOVIMIENTO', N'd3', N'c3', NULL, NULL, 4525, '2026-07-20T19:01:13.230'),
    (4, 12, 3, N'MOVIMIENTO', N'e4', N'e3', NULL, NULL, 3444, '2026-07-20T19:01:16.674'),
    (4, 13, 4, N'MOVIMIENTO', N'c3', N'c4', NULL, NULL, 11363, '2026-07-20T19:01:28.037'),
    (4, 14, 3, N'MOVIMIENTO', N'e3', N'e2', NULL, NULL, 10282, '2026-07-20T19:01:38.319'),
    (4, 15, 4, N'MURO', NULL, NULL, N'g2', N'HORIZONTAL', 9201, '2026-07-20T19:01:47.520'),
    (4, 16, 3, N'MOVIMIENTO', N'e2', N'e1', NULL, NULL, 8120, '2026-07-20T19:01:55.640'),
    (5, 1, 3, N'MOVIMIENTO', N'e1', N'e2', NULL, NULL, 3064, '2026-07-26T17:30:03.064'),
    (5, 2, 4, N'MOVIMIENTO', N'e9', N'e8', NULL, NULL, 10983, '2026-07-26T17:30:14.047'),
    (5, 3, 3, N'MOVIMIENTO', N'e2', N'e3', NULL, NULL, 9902, '2026-07-26T17:30:23.949'),
    (5, 4, 4, N'MOVIMIENTO', N'e8', N'e7', NULL, NULL, 8821, '2026-07-26T17:30:32.770'),
    (5, 5, 3, N'MOVIMIENTO', N'e3', N'e4', NULL, NULL, 7740, '2026-07-26T17:30:40.510'),
    (5, 6, 4, N'MOVIMIENTO', N'e7', N'e6', NULL, NULL, 6659, '2026-07-26T17:30:47.169'),
    (5, 7, 3, N'MOVIMIENTO', N'e4', N'e5', NULL, NULL, 5578, '2026-07-26T17:30:52.747'),
    (5, 8, 4, N'MURO', NULL, NULL, N'a2', N'VERTICAL', 4497, '2026-07-26T17:30:57.244'),
    (5, 9, 3, N'MOVIMIENTO', N'e5', N'e7', NULL, NULL, 3416, '2026-07-26T17:31:00.660'),
    (5, 10, 4, N'MOVIMIENTO', N'e6', N'e5', NULL, NULL, 11335, '2026-07-26T17:31:11.995'),
    (5, 11, 3, N'MOVIMIENTO', N'e7', N'e8', NULL, NULL, 10254, '2026-07-26T17:31:22.249'),
    (5, 12, 4, N'MOVIMIENTO', N'e5', N'e4', NULL, NULL, 9173, '2026-07-26T17:31:31.422'),
    (5, 13, 3, N'MOVIMIENTO', N'e8', N'e9', NULL, NULL, 8092, '2026-07-26T17:31:39.514'),
    (6, 1, 5, N'MOVIMIENTO', N'd1', N'd2', NULL, NULL, 8793, '2026-08-10T18:00:08.793'),
    (6, 2, 6, N'MOVIMIENTO', N'd7', N'd6', NULL, NULL, 7712, '2026-08-10T18:00:16.505'),
    (6, 3, 5, N'MURO', NULL, NULL, N'c5', N'HORIZONTAL', 6631, '2026-08-10T18:00:23.136'),
    (6, 4, 6, N'MOVIMIENTO', N'd6', N'e6', NULL, NULL, 5550, '2026-08-10T18:00:28.686'),
    (6, 5, 5, N'MOVIMIENTO', N'd2', N'd3', NULL, NULL, 4469, '2026-08-10T18:00:33.155'),
    (6, 6, 6, N'MURO', NULL, NULL, N'c2', N'HORIZONTAL', 3388, '2026-08-10T18:00:36.543'),
    (6, 7, 5, N'MOVIMIENTO', N'd3', N'd4', NULL, NULL, 11307, '2026-08-10T18:00:47.850'),
    (6, 8, 6, N'MOVIMIENTO', N'e6', N'e5', NULL, NULL, 10226, '2026-08-10T18:00:58.076'),
    (7, 1, 3, N'MOVIMIENTO', N'e1', N'e2', NULL, NULL, 5522, '2026-08-15T19:00:05.522'),
    (7, 2, 4, N'MOVIMIENTO', N'a5', N'b5', NULL, NULL, 4441, '2026-08-15T19:00:09.963'),
    (7, 3, 5, N'MOVIMIENTO', N'e9', N'e8', NULL, NULL, 3360, '2026-08-15T19:00:13.323'),
    (7, 4, 6, N'MOVIMIENTO', N'i5', N'h5', NULL, NULL, 11279, '2026-08-15T19:00:24.602'),
    (7, 5, 3, N'MOVIMIENTO', N'e2', N'e3', NULL, NULL, 10198, '2026-08-15T19:00:34.800'),
    (7, 6, 4, N'MURO', NULL, NULL, N'b6', N'HORIZONTAL', 9117, '2026-08-15T19:00:43.917'),
    (7, 7, 6, N'MOVIMIENTO', N'h5', N'g5', NULL, NULL, 8036, '2026-08-15T19:00:51.953'),
    (7, 8, 3, N'MOVIMIENTO', N'e3', N'e4', NULL, NULL, 6955, '2026-08-15T19:00:58.908'),
    (7, 9, 4, N'MOVIMIENTO', N'b5', N'c5', NULL, NULL, 5874, '2026-08-15T19:01:04.782'),
    (7, 10, 3, N'MOVIMIENTO', N'e4', N'e5', NULL, NULL, 4793, '2026-08-15T19:01:09.575'),
    (9, 1, 3, N'MOVIMIENTO', N'e1', N'e2', NULL, NULL, 7980, '2026-08-26T17:10:07.980'),
    (9, 2, 9, N'MOVIMIENTO', N'e9', N'f9', NULL, NULL, 6899, '2026-08-26T17:10:14.879'),
    (9, 3, 3, N'MOVIMIENTO', N'e2', N'e3', NULL, NULL, 5818, '2026-08-26T17:10:20.697'),
    (9, 4, 9, N'MURO', NULL, NULL, N'e5', N'HORIZONTAL', 4737, '2026-08-26T17:10:25.434'),
    (9, 5, 3, N'MOVIMIENTO', N'e3', N'e4', NULL, NULL, 3656, '2026-08-26T17:10:29.090'),
    (9, 6, 9, N'MOVIMIENTO', N'f9', N'f8', NULL, NULL, 2575, '2026-08-26T17:10:31.665'),
    (9, 7, 3, N'MOVIMIENTO', N'e4', N'e5', NULL, NULL, 10494, '2026-08-26T17:10:42.159'),
    (9, 8, 9, N'MURO', NULL, NULL, N'd6', N'VERTICAL', 9413, '2026-08-26T17:10:51.572'),
    (9, 9, 3, N'MOVIMIENTO', N'e5', N'd5', NULL, NULL, 8332, '2026-08-26T17:10:59.904'),
    (9, 10, 9, N'MOVIMIENTO', N'f8', N'f7', NULL, NULL, 7251, '2026-08-26T17:11:07.155'),
    (9, 11, 3, N'MOVIMIENTO', N'd5', N'd6', NULL, NULL, 6170, '2026-08-26T17:11:13.325'),
    (9, 12, 9, N'MOVIMIENTO', N'f7', N'f6', NULL, NULL, 5089, '2026-08-26T17:11:18.414'),
    (9, 13, 3, N'MOVIMIENTO', N'd6', N'd7', NULL, NULL, 4008, '2026-08-26T17:11:22.422'),
    (9, 14, 9, N'MURO', NULL, NULL, N'h3', N'HORIZONTAL', 2927, '2026-08-26T17:11:25.349'),
    (9, 15, 3, N'MOVIMIENTO', N'd7', N'd8', NULL, NULL, 10846, '2026-08-26T17:11:36.195'),
    (9, 16, 9, N'MOVIMIENTO', N'f6', N'g6', NULL, NULL, 9765, '2026-08-26T17:11:45.960'),
    (9, 17, 3, N'MOVIMIENTO', N'd8', N'd9', NULL, NULL, 8684, '2026-08-26T17:11:54.644'),
    (10, 1, 6, N'MOVIMIENTO', N'd1', N'd2', NULL, NULL, 4709, '2026-08-31T16:30:04.709'),
    (10, 2, 7, N'MOVIMIENTO', N'd7', N'c7', NULL, NULL, 3628, '2026-08-31T16:30:08.337'),
    (10, 3, 6, N'MOVIMIENTO', N'd2', N'd3', NULL, NULL, 2547, '2026-08-31T16:30:10.884'),
    (10, 4, 7, N'MURO', NULL, NULL, N'e3', N'VERTICAL', 10466, '2026-08-31T16:30:21.350'),
    (10, 5, 6, N'MOVIMIENTO', N'd3', N'd4', NULL, NULL, 9385, '2026-08-31T16:30:30.735'),
    (10, 6, 7, N'MOVIMIENTO', N'c7', N'c6', NULL, NULL, 8304, '2026-08-31T16:30:39.039'),
    (10, 7, 6, N'MOVIMIENTO', N'd4', N'd5', NULL, NULL, 7223, '2026-08-31T16:30:46.262'),
    (10, 8, 7, N'MOVIMIENTO', N'c6', N'c5', NULL, NULL, 6142, '2026-08-31T16:30:52.404'),
    (10, 9, 6, N'MOVIMIENTO', N'd5', N'd6', NULL, NULL, 5061, '2026-08-31T16:30:57.465'),
    (10, 10, 7, N'MURO', NULL, NULL, N'a1', N'HORIZONTAL', 3980, '2026-08-31T16:31:01.445'),
    (10, 11, 6, N'MOVIMIENTO', N'd6', N'd7', NULL, NULL, 2899, '2026-08-31T16:31:04.344'),
    (11, 1, 4, N'MOVIMIENTO', N'd1', N'd2', NULL, NULL, 10438, '2026-08-28T18:00:10.438'),
    (11, 2, 5, N'MOVIMIENTO', N'd7', N'd6', NULL, NULL, 9357, '2026-08-28T18:00:19.795'),
    (11, 3, 4, N'MOVIMIENTO', N'd2', N'd3', NULL, NULL, 8276, '2026-08-28T18:00:28.071'),
    (11, 4, 5, N'MURO', NULL, NULL, N'c3', N'HORIZONTAL', 7195, '2026-08-28T18:00:35.266'),
    (11, 5, 4, N'MOVIMIENTO', N'd3', N'e3', NULL, NULL, 6114, '2026-08-28T18:00:41.380'),
    (11, 6, 5, N'MOVIMIENTO', N'd6', N'd5', NULL, NULL, 5033, '2026-08-28T18:00:46.413'),
    (11, 7, 4, N'MOVIMIENTO', N'e3', N'e4', NULL, NULL, 3952, '2026-08-28T18:00:50.365'),
    (12, 1, 3, N'MOVIMIENTO', N'e1', N'e2', NULL, NULL, 7167, '2026-09-01T17:30:07.167'),
    (12, 2, 6, N'MOVIMIENTO', N'e9', N'e8', NULL, NULL, 6086, '2026-09-01T17:30:13.253'),
    (12, 3, 3, N'MOVIMIENTO', N'e2', N'e3', NULL, NULL, 5005, '2026-09-01T17:30:18.258'),
    (12, 4, 6, N'MURO', NULL, NULL, N'e4', N'HORIZONTAL', 3924, '2026-09-01T17:30:22.182'),
    (12, 5, 3, N'MOVIMIENTO', N'e3', N'e4', NULL, NULL, 2843, '2026-09-01T17:30:25.025'),
    (12, 6, 6, N'MOVIMIENTO', N'e8', N'e7', NULL, NULL, 10762, '2026-09-01T17:30:35.787');

SET IDENTITY_INSERT dbo.OfertaTablas ON;
INSERT INTO dbo.OfertaTablas (id_oferta, id_partida, id_ofertante, numero_jugada, fecha_oferta, estado, fecha_respuesta) VALUES
    (1, 4, 3, 4, '2026-07-20T19:00:21', N'CADUCADA', '2026-07-20T19:00:30'),
    (2, 6, 6, 2, '2026-08-10T18:00:19', N'RECHAZADA', '2026-08-10T18:00:25'),
    (3, 6, 6, 8, '2026-08-10T18:01:01', N'ACEPTADA', '2026-08-10T18:01:11'),
    (4, 12, 6, 6, '2026-09-01T17:30:38', N'PENDIENTE', NULL);
SET IDENTITY_INSERT dbo.OfertaTablas OFF;

/*---------------------------------------------------------------------
  Salas y chat
---------------------------------------------------------------------*/

SET IDENTITY_INSERT dbo.Sala ON;
INSERT INTO dbo.Sala (id_sala, codigo, id_anfitrion, id_modo, muros_por_jugador, minutos_reloj, estado, id_partida, fecha_creacion, fecha_ultima_actividad) VALUES
    (1, N'K7MTQ3', 6, 3, 8, 10, N'CERRADA', 10, '2026-08-31T16:20:00', '2026-08-31T16:31:05'),
    (2, N'QX7PRM', 5, 1, 10, 5, N'ABIERTA', NULL, '2026-09-01T17:50:00', '2026-09-01T17:58:30');
SET IDENTITY_INSERT dbo.Sala OFF;

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

/*---------------------------------------------------------------------
  Clasificación
---------------------------------------------------------------------*/

-- Una fila por cuenta y modo activo (CU-02 RN-06); los contadores resumen sus partidas clasificatorias.
INSERT INTO dbo.EstadisticaModo (id_usuario, id_modo, puntos_elo, fecha_ultima_partida, partidas_jugadas, partidas_ganadas, partidas_perdidas, abandonos) VALUES
    (1, 1, 1000, NULL, 0, 0, 0, 0),
    (1, 2, 1000, NULL, 0, 0, 0, 0),
    (1, 3, 1000, NULL, 0, 0, 0, 0),
    (2, 1, 1000, NULL, 0, 0, 0, 0),
    (2, 2, 1000, NULL, 0, 0, 0, 0),
    (2, 3, 1000, NULL, 0, 0, 0, 0),
    (3, 1, 1055, '2026-08-26T17:11:55', 6, 5, 1, 0),
    (3, 2, 1024, '2026-08-15T19:01:30', 1, 1, 0, 0),
    (3, 3, 1000, NULL, 0, 0, 0, 0),
    (4, 1, 959, '2026-07-26T17:31:40', 5, 1, 4, 0),
    (4, 2, 1008, '2026-08-15T19:01:30', 1, 0, 1, 1),
    (4, 3, 1016, '2026-08-28T18:03:29', 1, 1, 0, 0),
    (5, 1, 1000, NULL, 0, 0, 0, 0),
    (5, 2, 976, '2026-08-15T19:01:30', 1, 0, 1, 1),
    (5, 3, 984, '2026-08-28T18:03:29', 2, 0, 1, 0),
    (6, 1, 1000, NULL, 0, 0, 0, 0),
    (6, 2, 992, '2026-08-15T19:01:30', 1, 0, 1, 1),
    (6, 3, 1000, '2026-08-10T18:01:11', 1, 0, 0, 0),
    (7, 1, 1000, NULL, 0, 0, 0, 0),
    (7, 2, 1000, NULL, 0, 0, 0, 0),
    (7, 3, 1000, NULL, 0, 0, 0, 0),
    (8, 1, 1000, NULL, 0, 0, 0, 0),
    (8, 2, 1000, NULL, 0, 0, 0, 0),
    (8, 3, 1000, NULL, 0, 0, 0, 0),
    (9, 1, 986, '2026-08-26T17:11:55', 1, 0, 1, 0),
    (9, 2, 1000, NULL, 0, 0, 0, 0),
    (9, 3, 1000, NULL, 0, 0, 0, 0),
    (10, 1, 1000, NULL, 0, 0, 0, 0),
    (10, 2, 1000, NULL, 0, 0, 0, 0),
    (10, 3, 1000, NULL, 0, 0, 0, 0),
    (11, 1, 1000, NULL, 0, 0, 0, 0),
    (11, 2, 1000, NULL, 0, 0, 0, 0),
    (11, 3, 1000, NULL, 0, 0, 0, 0);

/*---------------------------------------------------------------------
  Relaciones entre jugadores
---------------------------------------------------------------------*/

INSERT INTO dbo.Silencio (id_usuario, id_silenciado, fecha_silencio) VALUES
    (4, 9, '2026-08-25T21:05:00');

INSERT INTO dbo.Bloqueo (id_bloqueador, id_bloqueado, fecha_bloqueo) VALUES
    (3, 9, '2026-08-26T17:25:00');

/*---------------------------------------------------------------------
  Moderación y bitácoras
---------------------------------------------------------------------*/

SET IDENTITY_INSERT dbo.Reporte ON;
INSERT INTO dbo.Reporte (id_reporte, id_denunciante, id_reportado, motivo, descripcion, id_partida, fecha_reporte, estado, id_moderador, fecha_asignacion, nota_resolucion, fecha_resolucion) VALUES
    (1, 3, 9, N'LENGUAJE_OFENSIVO', N'Me insultó en el chat de la partida.', 9, '2026-08-26T17:20:00', N'RESUELTO_CON_SANCION', 2, '2026-08-27T09:50:00', N'Insultos comprobados en el chat de la partida.', '2026-08-27T10:00:00'),
    (2, 4, 9, N'ACOSO', N'Molesta a todos en el chat global.', NULL, '2026-08-25T21:06:00', N'PENDIENTE', NULL, NULL, NULL, NULL),
    (3, 6, 3, N'JUEGO_ANTIDEPORTIVO', N'Creo que esperó a que abandonáramos.', 7, '2026-08-15T19:30:00', N'EN_REVISION', 2, '2026-09-01T17:40:00', NULL, NULL),
    (4, 3, 11, N'NOMBRE_INAPROPIADO', N'Su nickname imita al del administrador.', NULL, '2026-08-22T20:30:00', N'RESUELTO_CON_SANCION', 2, '2026-08-23T09:55:00', N'El nickname suplanta al equipo del juego.', '2026-08-23T10:00:00'),
    (5, 4, 3, N'TRAMPAS', N'Me saltó y llegó a la meta muy rápido; creo que usa un programa.', 5, '2026-07-26T17:40:00', N'RESUELTO_SIN_SANCION', 2, '2026-07-27T09:00:00', N'La repetición muestra jugadas legales; el salto es válido (CU-12 RN-03).', '2026-07-27T09:20:00');
SET IDENTITY_INSERT dbo.Reporte OFF;

-- La sustituta se enlaza después con UPDATE, cuando ya existe (DES-18 RN-09).
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
    (12, 2, N'REPORTE_LIBERADO', 9, N'Reporte 2: vuelve a la cola a los treinta minutos (DES-17 RN-03).', '2026-08-26T10:30:00'),
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
    SELECT 1 AS n, N'Partidas, victorias y derrotas por modo' AS comprobacion, COUNT(*) AS incoherencias
    FROM dbo.EstadisticaModo AS e
    CROSS APPLY (SELECT COUNT(*) AS jugadas,
                        SUM(CASE WHEN p.resultado = 'GANADA' THEN 1 ELSE 0 END) AS ganadas,
                        SUM(CASE WHEN p.resultado = 'PERDIDA' THEN 1 ELSE 0 END) AS perdidas
                 FROM dbo.Participacion AS p JOIN dbo.Partida AS pa ON pa.id_partida = p.id_partida
                 WHERE p.id_usuario = e.id_usuario AND pa.id_modo = e.id_modo
                   AND pa.tipo = 'CLASIFICATORIA' AND p.resultado IS NOT NULL) AS c
    WHERE e.partidas_jugadas <> c.jugadas OR e.partidas_ganadas <> ISNULL(c.ganadas, 0) OR e.partidas_perdidas <> ISNULL(c.perdidas, 0)
    UNION ALL
    SELECT 2, N'Elo vigente igual al último elo final', COUNT(*)
    FROM dbo.EstadisticaModo AS e
    WHERE e.puntos_elo <> ISNULL((SELECT TOP (1) p.elo_final FROM dbo.Participacion AS p
                                  JOIN dbo.Partida AS pa ON pa.id_partida = p.id_partida
                                  WHERE p.id_usuario = e.id_usuario AND pa.id_modo = e.id_modo AND p.elo_final IS NOT NULL
                                  ORDER BY pa.fecha_fin DESC), 1000)
    UNION ALL
    SELECT 3, N'Muros restantes: los iniciales menos los colocados', COUNT(*)
    FROM dbo.Participacion AS p
    JOIN dbo.Partida AS pa ON pa.id_partida = p.id_partida
    JOIN dbo.Modo AS mo ON mo.id_modo = pa.id_modo
    LEFT JOIN dbo.Sala AS s ON s.id_partida = pa.id_partida
    WHERE p.muros_restantes <> COALESCE(s.muros_por_jugador, mo.muros_por_jugador)
          - (SELECT COUNT(*) FROM dbo.Jugada AS j WHERE j.id_partida = p.id_partida AND j.id_usuario = p.id_usuario
             AND j.tipo = 'MURO')
    UNION ALL
    SELECT 4, N'Reloj restante: el inicial menos el consumido, o cero si se agotó', COUNT(*)
    FROM dbo.Participacion AS p JOIN dbo.Partida AS pa ON pa.id_partida = p.id_partida
    WHERE p.reloj_restante <> CASE WHEN pa.forma_termino = 'TIEMPO_AGOTADO' AND p.resultado = 'PERDIDA' THEN 0
          ELSE pa.minutos_reloj * 60000
          - ISNULL((SELECT SUM(j.tiempo_consumido) FROM dbo.Jugada AS j WHERE j.id_partida = p.id_partida AND j.id_usuario = p.id_usuario), 0) END
    UNION ALL
    SELECT 5, N'Casilla actual igual a la de la última jugada', COUNT(*)
    FROM dbo.Participacion AS p
    CROSS APPLY (SELECT TOP (1) j.casilla_destino FROM dbo.Jugada AS j
                 WHERE j.id_partida = p.id_partida AND j.id_usuario = p.id_usuario AND j.tipo = 'MOVIMIENTO'
                 ORDER BY j.numero_jugada DESC) AS ultima
    WHERE p.casilla_actual <> ultima.casilla_destino
    UNION ALL
    SELECT 6, N'Estadísticas de cada cuenta en cada modo activo (CU-02 RN-06)', COUNT(*)
    FROM dbo.Usuario AS u CROSS JOIN dbo.Modo AS m
    WHERE m.activo = 1 AND NOT EXISTS (SELECT 1 FROM dbo.EstadisticaModo AS e WHERE e.id_usuario = u.id_usuario AND e.id_modo = m.id_modo)
    UNION ALL
    SELECT 7, N'Un ganador en cada partida decidida', COUNT(*)
    FROM dbo.Partida AS pa
    WHERE pa.estado = 'FINALIZADA' AND pa.forma_termino <> 'TABLAS'
      AND (SELECT COUNT(*) FROM dbo.Participacion AS p WHERE p.id_partida = pa.id_partida AND p.resultado = 'GANADA') <> 1
    UNION ALL
    SELECT 8, N'Dos o cuatro participantes por partida, según su modo', COUNT(*)
    FROM dbo.Partida AS pa JOIN dbo.Modo AS mo ON mo.id_modo = pa.id_modo
    WHERE (SELECT COUNT(*) FROM dbo.Participacion AS p WHERE p.id_partida = pa.id_partida) <> mo.num_jugadores
    UNION ALL
    SELECT 9, N'Segundo factor activado con un código emitido (CU-05)', COUNT(*)
    FROM dbo.Usuario AS u
    WHERE u.doble_factor_habilitado = 1
      AND NOT EXISTS (SELECT 1 FROM dbo.CodigoVerificacion AS c WHERE c.id_usuario = u.id_usuario AND c.proposito = 'SEGUNDO_FACTOR')
    UNION ALL
    SELECT 10, N'Textos con ñ, acentos y emojis idénticos a los insertados (D-21)', COUNT(*)
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
                  (N'La repetici' + NCHAR(243) + N'n muestra jugadas legales; el salto es v' + NCHAR(225) + N'lido (CU-12 RN-03).')) AS e(v)
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

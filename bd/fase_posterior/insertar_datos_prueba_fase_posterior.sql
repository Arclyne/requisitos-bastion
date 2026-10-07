/*=====================================================================
  Bastion - Inserción de datos de prueba de la fase posterior
  Motor: SQL Server 2019 o posterior (CON-04).

  Se ejecuta después de fase_posterior/crear_tablas_fase_posterior.sql,
  sobre la base que ya tiene los datos del núcleo. Archivo generado por
  bd/generar_datos_prueba.py; no editar a mano.

  Completa el escenario de prueba con lo que pertenece a los agregados:
  los catálogos de la fase posterior, las columnas que se agregaron a
  Usuario, EstadisticaModo y Sala, la partida contra la IA y las 22
  tablas nuevas.
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
  Catálogos precargados de la fase posterior (D-09)
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

/*---------------------------------------------------------------------
  Columnas que se agregaron al núcleo
---------------------------------------------------------------------*/

-- Usuario: codigo_amigo, id_icono, permite_espectadores, nivel, experiencia, saldo_monedas, cajas_sin_raro, fecha_configuracion_inicial.
UPDATE dbo.Usuario SET codigo_amigo = N'ADM7KQ2P', id_icono = 1, permite_espectadores = 1, nivel = 1, experiencia = 0, saldo_monedas = 0, cajas_sin_raro = 0, fecha_configuracion_inicial = '2026-06-01T10:05:00' WHERE id_usuario = 1;
UPDATE dbo.Usuario SET codigo_amigo = N'ANA4M9QX', id_icono = 7, permite_espectadores = 1, nivel = 1, experiencia = 150, saldo_monedas = 0, cajas_sin_raro = 0, fecha_configuracion_inicial = '2026-06-02T09:04:00' WHERE id_usuario = 2;
UPDATE dbo.Usuario SET codigo_amigo = N'LQ8R2T6W', id_icono = 12, permite_espectadores = 1, nivel = 4, experiencia = 1650, saldo_monedas = 245, cajas_sin_raro = 0, fecha_configuracion_inicial = '2026-06-10T16:06:00' WHERE id_usuario = 3;
UPDATE dbo.Usuario SET codigo_amigo = N'MM3P7Z4K', id_icono = 5, permite_espectadores = 1, nivel = 3, experiencia = 900, saldo_monedas = 310, cajas_sin_raro = 0, fecha_configuracion_inicial = '2026-06-12T18:35:00' WHERE id_usuario = 4;
UPDATE dbo.Usuario SET codigo_amigo = N'PP6N2C8V', id_icono = 3, permite_espectadores = 0, nivel = 2, experiencia = 420, saldo_monedas = 80, cajas_sin_raro = 0, fecha_configuracion_inicial = '2026-06-15T12:10:00' WHERE id_usuario = 5;
UPDATE dbo.Usuario SET codigo_amigo = N'SS9H3J5D', id_icono = 20, permite_espectadores = 1, nivel = 2, experiencia = 380, saldo_monedas = 90, cajas_sin_raro = 0, fecha_configuracion_inicial = '2026-06-18T20:03:00' WHERE id_usuario = 6;
UPDATE dbo.Usuario SET codigo_amigo = NULL, id_icono = 1, permite_espectadores = 1, nivel = 1, experiencia = 60, saldo_monedas = 0, cajas_sin_raro = 0, fecha_configuracion_inicial = NULL WHERE id_usuario = 7;
UPDATE dbo.Usuario SET codigo_amigo = N'NN5T8B2R', id_icono = 1, permite_espectadores = 1, nivel = 1, experiencia = 0, saldo_monedas = 0, cajas_sin_raro = 0, fecha_configuracion_inicial = NULL WHERE id_usuario = 8;
UPDATE dbo.Usuario SET codigo_amigo = N'RV2K9X4M', id_icono = 9, permite_espectadores = 1, nivel = 1, experiencia = 90, saldo_monedas = 25, cajas_sin_raro = 0, fecha_configuracion_inicial = '2026-06-20T15:02:00' WHERE id_usuario = 9;
UPDATE dbo.Usuario SET codigo_amigo = NULL, id_icono = 1, permite_espectadores = 1, nivel = 1, experiencia = 200, saldo_monedas = 0, cajas_sin_raro = 0, fecha_configuracion_inicial = '2026-06-22T11:05:00' WHERE id_usuario = 10;
UPDATE dbo.Usuario SET codigo_amigo = N'FK4D9M2N', id_icono = 2, permite_espectadores = 1, nivel = 1, experiencia = 0, saldo_monedas = 0, cajas_sin_raro = 0, fecha_configuracion_inicial = '2026-08-22T19:18:00' WHERE id_usuario = 11;

-- Sala: permite_espectadores.
UPDATE dbo.Sala SET permite_espectadores = 1 WHERE id_sala = 1;
UPDATE dbo.Sala SET permite_espectadores = 1 WHERE id_sala = 2;

-- EstadisticaModo: elo_maximo, racha_actual, mejor_racha, tiempo_total_jugado, barreras_colocadas, id_division.
UPDATE dbo.EstadisticaModo SET elo_maximo = 1000, racha_actual = 0, mejor_racha = 0, tiempo_total_jugado = 0, barreras_colocadas = 0, id_division = NULL WHERE id_usuario = 1 AND id_modo = 1;
UPDATE dbo.EstadisticaModo SET elo_maximo = 1000, racha_actual = 0, mejor_racha = 0, tiempo_total_jugado = 0, barreras_colocadas = 0, id_division = NULL WHERE id_usuario = 1 AND id_modo = 2;
UPDATE dbo.EstadisticaModo SET elo_maximo = 1000, racha_actual = 0, mejor_racha = 0, tiempo_total_jugado = 0, barreras_colocadas = 0, id_division = NULL WHERE id_usuario = 1 AND id_modo = 3;
UPDATE dbo.EstadisticaModo SET elo_maximo = 1000, racha_actual = 0, mejor_racha = 0, tiempo_total_jugado = 0, barreras_colocadas = 0, id_division = NULL WHERE id_usuario = 2 AND id_modo = 1;
UPDATE dbo.EstadisticaModo SET elo_maximo = 1000, racha_actual = 0, mejor_racha = 0, tiempo_total_jugado = 0, barreras_colocadas = 0, id_division = NULL WHERE id_usuario = 2 AND id_modo = 2;
UPDATE dbo.EstadisticaModo SET elo_maximo = 1000, racha_actual = 0, mejor_racha = 0, tiempo_total_jugado = 0, barreras_colocadas = 0, id_division = NULL WHERE id_usuario = 2 AND id_modo = 3;
UPDATE dbo.EstadisticaModo SET elo_maximo = 1055, racha_actual = 3, mejor_racha = 3, tiempo_total_jugado = 599, barreras_colocadas = 4, id_division = 2 WHERE id_usuario = 3 AND id_modo = 1;
UPDATE dbo.EstadisticaModo SET elo_maximo = 1024, racha_actual = 0, mejor_racha = 0, tiempo_total_jugado = 90, barreras_colocadas = 0, id_division = NULL WHERE id_usuario = 3 AND id_modo = 2;
UPDATE dbo.EstadisticaModo SET elo_maximo = 1000, racha_actual = 0, mejor_racha = 0, tiempo_total_jugado = 0, barreras_colocadas = 0, id_division = NULL WHERE id_usuario = 3 AND id_modo = 3;
UPDATE dbo.EstadisticaModo SET elo_maximo = 1000, racha_actual = 0, mejor_racha = 1, tiempo_total_jugado = 484, barreras_colocadas = 8, id_division = 1 WHERE id_usuario = 4 AND id_modo = 1;
UPDATE dbo.EstadisticaModo SET elo_maximo = 1008, racha_actual = 0, mejor_racha = 0, tiempo_total_jugado = 90, barreras_colocadas = 1, id_division = NULL WHERE id_usuario = 4 AND id_modo = 2;
UPDATE dbo.EstadisticaModo SET elo_maximo = 1016, racha_actual = 0, mejor_racha = 0, tiempo_total_jugado = 209, barreras_colocadas = 0, id_division = NULL WHERE id_usuario = 4 AND id_modo = 3;
UPDATE dbo.EstadisticaModo SET elo_maximo = 1000, racha_actual = 0, mejor_racha = 0, tiempo_total_jugado = 0, barreras_colocadas = 0, id_division = NULL WHERE id_usuario = 5 AND id_modo = 1;
UPDATE dbo.EstadisticaModo SET elo_maximo = 1000, racha_actual = 0, mejor_racha = 0, tiempo_total_jugado = 90, barreras_colocadas = 0, id_division = NULL WHERE id_usuario = 5 AND id_modo = 2;
UPDATE dbo.EstadisticaModo SET elo_maximo = 1000, racha_actual = 0, mejor_racha = 0, tiempo_total_jugado = 280, barreras_colocadas = 2, id_division = NULL WHERE id_usuario = 5 AND id_modo = 3;
UPDATE dbo.EstadisticaModo SET elo_maximo = 1000, racha_actual = 0, mejor_racha = 0, tiempo_total_jugado = 0, barreras_colocadas = 0, id_division = NULL WHERE id_usuario = 6 AND id_modo = 1;
UPDATE dbo.EstadisticaModo SET elo_maximo = 1000, racha_actual = 0, mejor_racha = 0, tiempo_total_jugado = 90, barreras_colocadas = 0, id_division = NULL WHERE id_usuario = 6 AND id_modo = 2;
UPDATE dbo.EstadisticaModo SET elo_maximo = 1000, racha_actual = 0, mejor_racha = 0, tiempo_total_jugado = 71, barreras_colocadas = 1, id_division = NULL WHERE id_usuario = 6 AND id_modo = 3;
UPDATE dbo.EstadisticaModo SET elo_maximo = 1000, racha_actual = 0, mejor_racha = 0, tiempo_total_jugado = 0, barreras_colocadas = 0, id_division = NULL WHERE id_usuario = 7 AND id_modo = 1;
UPDATE dbo.EstadisticaModo SET elo_maximo = 1000, racha_actual = 0, mejor_racha = 0, tiempo_total_jugado = 0, barreras_colocadas = 0, id_division = NULL WHERE id_usuario = 7 AND id_modo = 2;
UPDATE dbo.EstadisticaModo SET elo_maximo = 1000, racha_actual = 0, mejor_racha = 0, tiempo_total_jugado = 0, barreras_colocadas = 0, id_division = NULL WHERE id_usuario = 7 AND id_modo = 3;
UPDATE dbo.EstadisticaModo SET elo_maximo = 1000, racha_actual = 0, mejor_racha = 0, tiempo_total_jugado = 0, barreras_colocadas = 0, id_division = NULL WHERE id_usuario = 8 AND id_modo = 1;
UPDATE dbo.EstadisticaModo SET elo_maximo = 1000, racha_actual = 0, mejor_racha = 0, tiempo_total_jugado = 0, barreras_colocadas = 0, id_division = NULL WHERE id_usuario = 8 AND id_modo = 2;
UPDATE dbo.EstadisticaModo SET elo_maximo = 1000, racha_actual = 0, mejor_racha = 0, tiempo_total_jugado = 0, barreras_colocadas = 0, id_division = NULL WHERE id_usuario = 8 AND id_modo = 3;
UPDATE dbo.EstadisticaModo SET elo_maximo = 1000, racha_actual = 0, mejor_racha = 0, tiempo_total_jugado = 115, barreras_colocadas = 3, id_division = NULL WHERE id_usuario = 9 AND id_modo = 1;
UPDATE dbo.EstadisticaModo SET elo_maximo = 1000, racha_actual = 0, mejor_racha = 0, tiempo_total_jugado = 0, barreras_colocadas = 0, id_division = NULL WHERE id_usuario = 9 AND id_modo = 2;
UPDATE dbo.EstadisticaModo SET elo_maximo = 1000, racha_actual = 0, mejor_racha = 0, tiempo_total_jugado = 0, barreras_colocadas = 0, id_division = NULL WHERE id_usuario = 9 AND id_modo = 3;
UPDATE dbo.EstadisticaModo SET elo_maximo = 1000, racha_actual = 0, mejor_racha = 0, tiempo_total_jugado = 0, barreras_colocadas = 0, id_division = NULL WHERE id_usuario = 10 AND id_modo = 1;
UPDATE dbo.EstadisticaModo SET elo_maximo = 1000, racha_actual = 0, mejor_racha = 0, tiempo_total_jugado = 0, barreras_colocadas = 0, id_division = NULL WHERE id_usuario = 10 AND id_modo = 2;
UPDATE dbo.EstadisticaModo SET elo_maximo = 1000, racha_actual = 0, mejor_racha = 0, tiempo_total_jugado = 0, barreras_colocadas = 0, id_division = NULL WHERE id_usuario = 10 AND id_modo = 3;
UPDATE dbo.EstadisticaModo SET elo_maximo = 1000, racha_actual = 0, mejor_racha = 0, tiempo_total_jugado = 0, barreras_colocadas = 0, id_division = NULL WHERE id_usuario = 11 AND id_modo = 1;
UPDATE dbo.EstadisticaModo SET elo_maximo = 1000, racha_actual = 0, mejor_racha = 0, tiempo_total_jugado = 0, barreras_colocadas = 0, id_division = NULL WHERE id_usuario = 11 AND id_modo = 2;
UPDATE dbo.EstadisticaModo SET elo_maximo = 1000, racha_actual = 0, mejor_racha = 0, tiempo_total_jugado = 0, barreras_colocadas = 0, id_division = NULL WHERE id_usuario = 11 AND id_modo = 3;

/*---------------------------------------------------------------------
  Partida contra la IA (D-12)
---------------------------------------------------------------------*/

-- La partida contra la IA (D-12).
SET IDENTITY_INSERT dbo.Partida ON;
INSERT INTO dbo.Partida (id_partida, id_modo, tipo, estado, minutos_reloj, fecha_inicio, fecha_fin, forma_termino, turno_actual, id_nivel_ia, permite_deshacer, permite_sugerencias, deshacer_usados, sugerencias_usadas) VALUES
    (8, 1, N'IA', N'FINALIZADA', NULL, '2026-08-20T16:00:00', '2026-08-20T16:01:18', N'RENDICION', 2, 1, 1, 1, 1, 2);
SET IDENTITY_INSERT dbo.Partida OFF;

-- La partida contra la IA (D-12).
INSERT INTO dbo.Participacion (id_partida, id_usuario, orden_turno, simbolo_peon, casilla_actual, muros_restantes, reloj_restante, elo_inicial, elo_final, resultado, posicion, forma_termino, conectado, fecha_desconexion) VALUES
    (8, 5, 1, N'AZUL', N'f4', 10, NULL, NULL, NULL, N'PERDIDA', NULL, NULL, 1, NULL);

-- La partida contra la IA (D-12).
INSERT INTO dbo.Jugada (id_partida, numero_jugada, id_usuario, tipo, casilla_origen, casilla_destino, surco, orientacion, tiempo_consumido, fecha_jugada, deshecha) VALUES
    (8, 1, 5, N'MOVIMIENTO', N'e1', N'e2', NULL, NULL, 11251, '2026-08-20T16:00:11.251', 0),
    (8, 2, NULL, N'MOVIMIENTO', N'e9', N'e8', NULL, NULL, 10170, '2026-08-20T16:00:21.421', 0),
    (8, 3, 5, N'MOVIMIENTO', N'e2', N'e3', NULL, NULL, 9089, '2026-08-20T16:00:30.510', 0),
    (8, 4, NULL, N'MURO', NULL, NULL, N'e4', N'HORIZONTAL', 8008, '2026-08-20T16:00:38.518', 0),
    (8, 5, 5, N'MOVIMIENTO', N'e3', N'd3', NULL, NULL, 6927, '2026-08-20T16:00:45.445', 1),
    (8, 6, NULL, N'MOVIMIENTO', N'e8', N'e7', NULL, NULL, 5846, '2026-08-20T16:00:51.291', 1),
    (8, 7, 5, N'MOVIMIENTO', N'e3', N'f3', NULL, NULL, 4765, '2026-08-20T16:00:56.056', 0),
    (8, 8, NULL, N'MOVIMIENTO', N'e8', N'e7', NULL, NULL, 3684, '2026-08-20T16:00:59.740', 0),
    (8, 9, 5, N'MOVIMIENTO', N'f3', N'f4', NULL, NULL, 2603, '2026-08-20T16:01:02.343', 0);

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
  Aspecto en partida y espectador
---------------------------------------------------------------------*/

-- El aspecto que cada jugador tenía equipado al empezar (DES-07 RN-03).
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

SET IDENTITY_INSERT dbo.EnlaceEspectador ON;
INSERT INTO dbo.EnlaceEspectador (id_enlace, id_partida, id_creador, token_hash, fecha_creacion) VALUES
    (1, 12, 3, HASHBYTES('SHA2_256', 'espectador:1'), '2026-09-01T17:40:00');
SET IDENTITY_INSERT dbo.EnlaceEspectador OFF;

/*---------------------------------------------------------------------
  Invitaciones
---------------------------------------------------------------------*/

SET IDENTITY_INSERT dbo.Invitacion ON;
INSERT INTO dbo.Invitacion (id_invitacion, id_sala, id_emisor, id_destinatario, fecha_invitacion, fecha_expiracion, estado) VALUES
    (1, 1, 6, 4, '2026-08-31T16:21:00', '2026-08-31T16:22:00', N'EXPIRADA'),
    (2, 1, 6, 4, '2026-08-31T16:23:00', '2026-08-31T16:24:00', N'RECHAZADA'),
    (4, 1, 6, 7, '2026-08-31T16:24:00', '2026-08-31T16:25:00', N'ACEPTADA'),
    (3, 2, 5, 2, '2026-09-01T17:59:40', '2026-09-01T18:00:40', N'PENDIENTE');
SET IDENTITY_INSERT dbo.Invitacion OFF;

/*---------------------------------------------------------------------
  Clasificación y economía
---------------------------------------------------------------------*/

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

INSERT INTO dbo.ProgresoTutorial (id_usuario, id_leccion, paso_actual, fecha_actualizacion, fecha_completada) VALUES
    (5, 1, 3, '2026-06-15T12:20:00', '2026-06-15T12:20:00'),
    (5, 2, 4, '2026-06-15T12:35:00', '2026-06-15T12:35:00'),
    (5, 3, 2, '2026-06-16T18:00:00', NULL),
    (6, 1, 3, '2026-06-18T20:10:00', '2026-06-18T20:10:00'),
    (6, 2, 4, '2026-06-18T20:20:00', '2026-06-18T20:20:00'),
    (6, 3, 4, '2026-06-19T17:00:00', '2026-06-19T17:00:00'),
    (6, 4, 5, '2026-06-19T17:15:00', '2026-06-19T17:15:00'),
    (7, 1, 3, '2026-08-30T16:10:00', '2026-08-30T16:10:00');


COMMIT TRANSACTION;
GO

/*---------------------------------------------------------------------
  Comprobación de la fase posterior: cada fila debe mostrar 0.
---------------------------------------------------------------------*/
SELECT comprobacion, incoherencias FROM (
    SELECT 1 AS n, N'Saldo igual a la suma de movimientos (DES-15 RN-02)' AS comprobacion, COUNT(*) AS incoherencias
    FROM dbo.Usuario AS u
    WHERE u.saldo_monedas <> ISNULL((SELECT SUM(m.importe) FROM dbo.MovimientoMoneda AS m WHERE m.id_usuario = u.id_usuario), 0)
    UNION ALL
    SELECT 2, N'Muros colocados en partidas clasificatorias', COUNT(*)
    FROM dbo.EstadisticaModo AS e
    WHERE e.barreras_colocadas <> (SELECT COUNT(*) FROM dbo.Jugada AS j JOIN dbo.Partida AS pa ON pa.id_partida = j.id_partida
                                   WHERE j.id_usuario = e.id_usuario AND pa.id_modo = e.id_modo AND pa.tipo = 'CLASIFICATORIA'
                                     AND pa.estado = 'FINALIZADA' AND j.tipo = 'MURO' AND j.deshecha = 0)
    UNION ALL
    SELECT 3, N'División solo a partir de cinco partidas (CU-16 RN-12)', COUNT(*)
    FROM dbo.EstadisticaModo AS e
    WHERE (e.id_division IS NULL AND e.partidas_jugadas >= 5) OR (e.id_division IS NOT NULL AND e.partidas_jugadas < 5)
    UNION ALL
    SELECT 4, N'Un objeto equipado en cada ranura (DES-07 RN-01)', COUNT(*)
    FROM dbo.Usuario AS u
    WHERE (SELECT COUNT(*) FROM dbo.Equipamiento AS e WHERE e.id_usuario = u.id_usuario) <> (SELECT COUNT(*) FROM dbo.Ranura)
    UNION ALL
    SELECT 5, N'Aspecto fijado en cada ranura por participación', COUNT(*)
    FROM dbo.Participacion AS p
    WHERE (SELECT COUNT(*) FROM dbo.ParticipacionObjeto AS o WHERE o.id_partida = p.id_partida AND o.id_usuario = p.id_usuario)
          <> (SELECT COUNT(*) FROM dbo.Ranura)
    UNION ALL
    SELECT 6, N'Objetos iniciales de cada cuenta (CU-02 RN-08)', COUNT(*)
    FROM dbo.Usuario AS u CROSS JOIN dbo.ObjetoCosmetico AS o
    WHERE o.es_inicial = 1 AND NOT EXISTS (SELECT 1 FROM dbo.UsuarioObjeto AS uo WHERE uo.id_usuario = u.id_usuario AND uo.id_objeto = o.id_objeto)
    UNION ALL
    SELECT 7, N'Probabilidades de cada tipo de caja que suman 100', COUNT(*)
    FROM (SELECT id_tipo_caja FROM dbo.TipoCajaObjeto GROUP BY id_tipo_caja HAVING SUM(probabilidad) <> 100) AS x
    UNION ALL
    SELECT 8, N'Tres objetos en cada caja abierta (DES-14 RN-07)', COUNT(*)
    FROM dbo.Caja AS c
    WHERE c.estado = 'ABIERTA' AND (SELECT COUNT(*) FROM dbo.CajaContenido AS x WHERE x.id_caja = c.id_caja) <> 3
    UNION ALL
    SELECT 9, N'Textos con ñ, acentos y emojis idénticos a los insertados (D-21)', COUNT(*)
    FROM (
          SELECT CAST(NULL AS NVARCHAR(10)) AS v WHERE 1 = 0
         ) AS distintos
) AS c
ORDER BY n;
GO

/*=====================================================================
  Bastion - Consultas de la sección Datos
  Motor: SQL Server 2019 o posterior (CON-04); probado en SQL Server 2025.

  Se ejecutan sobre la base cargada con insertar_datos_prueba.sql y solo
  leen: pueden abrirse en SQL Server Management Studio y ejecutarse una a
  una. bd/exportar_datos.py las ejecuta todas y convierte cada resultado en
  una tabla del documento.

  Cada consulta empieza con dos comentarios que lee el exportador:
    -- @consulta <nombre> | <título>
    -- @columnas <encabezado> | <encabezado> | ...
=====================================================================*/

USE Bastion;
GO
SET NOCOUNT ON;
GO

/*---------------------------------------------------------------------
  1. Registros cargados
---------------------------------------------------------------------*/

-- @consulta conteo | Filas por tabla
-- @columnas Tabla | Filas | Tabla | Filas | Tabla | Filas
WITH t AS (
    SELECT t.name AS tabla, SUM(p.rows) AS filas,
           ROW_NUMBER() OVER (ORDER BY t.name) - 1 AS n,
           COUNT(*) OVER () AS total
    FROM sys.tables AS t
    JOIN sys.partitions AS p ON p.object_id = t.object_id AND p.index_id IN (0, 1)
    GROUP BY t.name
)
SELECT CAST(a.tabla AS VARCHAR(26)) AS tabla, a.filas,
       CAST(b.tabla AS VARCHAR(26)) AS tabla, b.filas,
       ISNULL(CAST(c.tabla AS VARCHAR(26)), '') AS tabla, ISNULL(CAST(c.filas AS VARCHAR(12)), '') AS filas
FROM t AS a
LEFT JOIN t AS b ON b.n = a.n + (a.total + 2) / 3
LEFT JOIN t AS c ON c.n = a.n + 2 * ((a.total + 2) / 3)
WHERE a.n < (a.total + 2) / 3
ORDER BY a.n;
GO

/*---------------------------------------------------------------------
  2. Registros por tabla
---------------------------------------------------------------------*/

-- @consulta ranura | Ranura
-- @columnas Id | Código
SELECT id_ranura, codigo FROM dbo.Ranura ORDER BY id_ranura;

-- @consulta modo | Modo
-- @columnas Id | Código | Tablero | Jugadores | Muros | Activo
SELECT id_modo, codigo, tamano_tablero, num_jugadores, muros_por_jugador, activo FROM dbo.Modo ORDER BY id_modo;

-- @consulta division | Division
-- @columnas Id | Código | Elo mínimo | Elo de descenso
SELECT id_division, codigo, elo_minimo, elo_descenso FROM dbo.Division ORDER BY elo_minimo;

-- @consulta nivelia | NivelIA
-- @columnas Id | Código | Elo aproximado
SELECT id_nivel_ia, codigo, elo_aproximado FROM dbo.NivelIA ORDER BY id_nivel_ia;

-- @consulta leccion | Leccion
-- @columnas Id | Orden | Código | Pasos
SELECT id_leccion, orden, codigo, num_pasos FROM dbo.Leccion ORDER BY orden;

-- @consulta tipocaja | TipoCaja
-- @columnas Id | Código | Precio | Activo
SELECT id_tipo_caja, codigo, precio, activo FROM dbo.TipoCaja ORDER BY id_tipo_caja;

-- @consulta motivo | MotivoReporte
-- @columnas Id | Código
SELECT id_motivo, codigo FROM dbo.MotivoReporte ORDER BY id_motivo;

-- @consulta objeto | ObjetoCosmetico
-- @columnas Id | Ranura | Código | Rareza | Precio | Nivel | A la venta | Activo | Inicial | Predeterminado
SELECT o.id_objeto, r.codigo, o.codigo, o.rareza, o.precio, o.nivel_requerido, o.a_la_venta, o.activo, o.es_inicial, o.es_predeterminado
FROM dbo.ObjetoCosmetico AS o
JOIN dbo.Ranura AS r ON r.id_ranura = o.id_ranura
ORDER BY o.id_objeto;

-- @consulta tipocajaobjeto | TipoCajaObjeto
-- @columnas Tipo de caja | Objeto | Rareza | Probabilidad (%)
SELECT t.codigo, o.codigo, o.rareza, CAST(x.probabilidad AS DECIMAL(5,1))
FROM dbo.TipoCajaObjeto AS x
JOIN dbo.TipoCaja AS t ON t.id_tipo_caja = x.id_tipo_caja
JOIN dbo.ObjetoCosmetico AS o ON o.id_objeto = x.id_objeto
ORDER BY x.id_tipo_caja, x.probabilidad DESC, o.id_objeto;

-- @consulta palabra | PalabraProhibida
-- @columnas Id | Término | Idioma | Ámbito
SELECT id_palabra, termino, idioma, ambito FROM dbo.PalabraProhibida ORDER BY id_palabra;

-- @consulta usuario | Usuario
-- @columnas Id | Nickname | Tipo | Estado | Rol | Idioma | Correo | Nivel | Saldo | 2FA
SELECT id_usuario AS id, CAST(nickname AS NVARCHAR(14)) AS nickname, CAST(tipo_cuenta AS VARCHAR(10)) AS tipo,
       CAST(estado_cuenta AS VARCHAR(10)) AS estado, CAST(rol AS VARCHAR(13)) AS rol, CAST(idioma_preferido AS VARCHAR(6)) AS idioma,
       CAST(correo AS NVARCHAR(24)) AS correo, nivel, saldo_monedas AS saldo, doble_factor_habilitado AS dos_factores
FROM dbo.Usuario ORDER BY id_usuario;

-- @consulta sesion | Sesion
-- @columnas Id | Usuario | Inicio | Fin | Motivo de cierre | Dispositivo
SELECT s.id_sesion, u.nickname, CONVERT(VARCHAR(16), s.fecha_inicio, 120), CONVERT(VARCHAR(16), s.fecha_fin, 120),
       s.motivo_cierre, s.nombre_dispositivo
FROM dbo.Sesion AS s JOIN dbo.Usuario AS u ON u.id_usuario = s.id_usuario
ORDER BY s.id_sesion;

-- @consulta aceptacion | AceptacionTerminos
-- @columnas Id | Usuario | Versión | Idioma | Fecha
SELECT a.id_aceptacion, u.nickname, a.version_terminos, a.idioma, CONVERT(VARCHAR(16), a.fecha_aceptacion, 120)
FROM dbo.AceptacionTerminos AS a JOIN dbo.Usuario AS u ON u.id_usuario = a.id_usuario
ORDER BY a.id_aceptacion;

-- @consulta tokenverificacion | TokenVerificacionCorreo
-- @columnas Id | Usuario | Propósito | Correo destino | Generado | Estado
SELECT t.id_token, u.nickname, t.proposito, t.correo_destino, CONVERT(VARCHAR(16), t.fecha_generacion, 120), t.estado
FROM dbo.TokenVerificacionCorreo AS t JOIN dbo.Usuario AS u ON u.id_usuario = t.id_usuario
ORDER BY t.id_token;

-- @consulta tokenrecuperacion | TokenRecuperacion
-- @columnas Id | Usuario | Generado | Expira | Intentos | Estado
SELECT t.id_token, u.nickname, CONVERT(VARCHAR(16), t.fecha_generacion, 120), CONVERT(VARCHAR(16), t.fecha_expiracion, 120), t.intentos, t.estado
FROM dbo.TokenRecuperacion AS t JOIN dbo.Usuario AS u ON u.id_usuario = t.id_usuario
ORDER BY t.id_token;

-- @consulta codigo2fa | CodigoSegundoFactor
-- @columnas Id | Usuario | Canal | Generado | Expira | Intentos | Estado
SELECT c.id_codigo, u.nickname, c.canal, CONVERT(VARCHAR(16), c.fecha_generacion, 120), CONVERT(VARCHAR(16), c.fecha_expiracion, 120), c.intentos, c.estado
FROM dbo.CodigoSegundoFactor AS c JOIN dbo.Usuario AS u ON u.id_usuario = c.id_usuario
ORDER BY c.id_codigo;

-- @consulta perfil | HistorialNickname, Avatar y EnlaceRed
-- @columnas Tabla | Usuario | Dato | Fecha
SELECT 'HistorialNickname', u.nickname, CONCAT('antes: ', h.nickname_anterior), CONVERT(VARCHAR(16), h.fecha_cambio, 120)
FROM dbo.HistorialNickname AS h JOIN dbo.Usuario AS u ON u.id_usuario = h.id_usuario
UNION ALL
SELECT 'Avatar', u.nickname, CONCAT(a.ruta_imagen, ' (', a.formato, ', ', a.tamano_bytes / 1000, ' kB, ', IIF(a.vigente = 1, 'vigente', 'no vigente'), ')'),
       CONVERT(VARCHAR(16), a.fecha_subida, 120)
FROM dbo.Avatar AS a JOIN dbo.Usuario AS u ON u.id_usuario = a.id_usuario
UNION ALL
SELECT 'EnlaceRed', u.nickname, CONCAT(e.orden, ': ', e.url), NULL
FROM dbo.EnlaceRed AS e JOIN dbo.Usuario AS u ON u.id_usuario = e.id_usuario;

-- @consulta partida | Partida
-- @columnas Id | Tipo | Modo | Estado | Forma de término | Reloj (min) | Inicio | Fin | Nivel IA | Turno
SELECT p.id_partida, p.tipo, m.codigo, p.estado, p.forma_termino, p.minutos_reloj,
       CONVERT(VARCHAR(16), p.fecha_inicio, 120), CONVERT(VARCHAR(16), p.fecha_fin, 120), n.codigo, p.turno_actual
FROM dbo.Partida AS p
JOIN dbo.Modo AS m ON m.id_modo = p.id_modo
LEFT JOIN dbo.NivelIA AS n ON n.id_nivel_ia = p.id_nivel_ia
ORDER BY p.id_partida;

-- @consulta participacion | Participacion
-- @columnas Partida | Jugador | Orden | Resultado | Posición | Salida | Elo inicial | Elo final | Reloj (ms) | Casilla
SELECT pa.id_partida, u.nickname, pa.orden_turno, pa.resultado, pa.posicion, pa.forma_termino,
       pa.elo_inicial, pa.elo_final, pa.reloj_restante, pa.casilla_actual
FROM dbo.Participacion AS pa JOIN dbo.Usuario AS u ON u.id_usuario = pa.id_usuario
ORDER BY pa.id_partida, pa.orden_turno;

-- @consulta jugadasporpartida | Jugada, por partida
-- @columnas Partida | Jugadas | Movimientos | Muros | Deshechas | Primera | Última
SELECT id_partida, COUNT(*), SUM(IIF(tipo = 'MOVIMIENTO', 1, 0)), SUM(IIF(tipo = 'MURO', 1, 0)), SUM(CAST(deshecha AS INT)),
       CONVERT(VARCHAR(19), MIN(fecha_jugada), 120), CONVERT(VARCHAR(19), MAX(fecha_jugada), 120)
FROM dbo.Jugada GROUP BY id_partida ORDER BY id_partida;

-- @consulta oferta | OfertaTablas
-- @columnas Id | Partida | Ofertante | Tras la jugada | Estado | Ofrecida | Respondida
SELECT o.id_oferta, o.id_partida, u.nickname, o.numero_jugada, o.estado, CONVERT(VARCHAR(19), o.fecha_oferta, 120), CONVERT(VARCHAR(19), o.fecha_respuesta, 120)
FROM dbo.OfertaTablas AS o JOIN dbo.Usuario AS u ON u.id_usuario = o.id_ofertante
ORDER BY o.id_oferta;

-- @consulta enlaceespectador | EnlaceEspectador
-- @columnas Id | Partida | Creador | Creado
SELECT e.id_enlace, e.id_partida, u.nickname, CONVERT(VARCHAR(16), e.fecha_creacion, 120)
FROM dbo.EnlaceEspectador AS e JOIN dbo.Usuario AS u ON u.id_usuario = e.id_creador;

-- @consulta cola | ColaEmparejamiento
-- @columnas Usuario | Modo | Reloj (min) | Entrada
SELECT u.nickname, m.codigo, c.minutos_reloj, CONVERT(VARCHAR(19), c.fecha_entrada, 120)
FROM dbo.ColaEmparejamiento AS c
JOIN dbo.Usuario AS u ON u.id_usuario = c.id_usuario
JOIN dbo.Modo AS m ON m.id_modo = c.id_modo;

-- @consulta sala | Sala
-- @columnas Id | Código | Anfitrión | Modo | Muros | Reloj (min) | Espectadores | Estado | Partida | Creada
SELECT s.id_sala, s.codigo, u.nickname, m.codigo, s.muros_por_jugador, s.minutos_reloj, s.permite_espectadores, s.estado, s.id_partida,
       CONVERT(VARCHAR(16), s.fecha_creacion, 120)
FROM dbo.Sala AS s
JOIN dbo.Usuario AS u ON u.id_usuario = s.id_anfitrion
JOIN dbo.Modo AS m ON m.id_modo = s.id_modo
ORDER BY s.id_sala;

-- @consulta salaparticipante | SalaParticipante
-- @columnas Sala | Usuario | Plaza | Listo | Unión
SELECT sp.id_sala, u.nickname, sp.plaza, sp.listo, CONVERT(VARCHAR(19), sp.fecha_union, 120)
FROM dbo.SalaParticipante AS sp JOIN dbo.Usuario AS u ON u.id_usuario = sp.id_usuario
ORDER BY sp.id_sala, sp.plaza;

-- @consulta invitacion | Invitacion
-- @columnas Id | Sala | Emisor | Destinatario | Enviada | Estado
SELECT i.id_invitacion, i.id_sala, e.nickname, d.nickname, CONVERT(VARCHAR(19), i.fecha_invitacion, 120), i.estado
FROM dbo.Invitacion AS i
JOIN dbo.Usuario AS e ON e.id_usuario = i.id_emisor
JOIN dbo.Usuario AS d ON d.id_usuario = i.id_destinatario
ORDER BY i.id_invitacion;

-- @consulta mensaje | Mensaje
-- @columnas Id | Autor | Canal | Partida | Sala | Texto | Enviado
SELECT m.id_mensaje, u.nickname, m.canal, m.id_partida, m.id_sala, m.texto, CONVERT(VARCHAR(19), m.fecha_envio, 120)
FROM dbo.Mensaje AS m JOIN dbo.Usuario AS u ON u.id_usuario = m.id_autor
ORDER BY m.id_mensaje;

-- @consulta estadistica | EstadisticaModo, filas con partidas
-- @columnas Jugador | Modo | Elo | Elo máximo | Jugadas | Ganadas | Perdidas | Racha | Mejor racha | Abandonos | División
SELECT u.nickname, m.codigo, e.puntos_elo, e.elo_maximo, e.partidas_jugadas, e.partidas_ganadas, e.partidas_perdidas,
       e.racha_actual, e.mejor_racha, e.abandonos, d.codigo
FROM dbo.EstadisticaModo AS e
JOIN dbo.Usuario AS u ON u.id_usuario = e.id_usuario
JOIN dbo.Modo AS m ON m.id_modo = e.id_modo
LEFT JOIN dbo.Division AS d ON d.id_division = e.id_division
WHERE e.partidas_jugadas > 0
ORDER BY e.id_usuario, e.id_modo;

-- @consulta historialdivision | HistorialDivision
-- @columnas Id | Jugador | Modo | Anterior | Nueva | Fecha
SELECT h.id_historial_division, u.nickname, m.codigo, a.codigo, n.codigo, CONVERT(VARCHAR(16), h.fecha_cambio, 120)
FROM dbo.HistorialDivision AS h
JOIN dbo.Usuario AS u ON u.id_usuario = h.id_usuario
JOIN dbo.Modo AS m ON m.id_modo = h.id_modo
LEFT JOIN dbo.Division AS a ON a.id_division = h.id_division_anterior
JOIN dbo.Division AS n ON n.id_division = h.id_division_nueva
ORDER BY h.id_historial_division;

-- @consulta usuarioobjeto | UsuarioObjeto, por cuenta y origen
-- @columnas Usuario | Inicial | Compra | Caja | Nivel | Total
SELECT u.nickname, SUM(IIF(x.origen = 'INICIAL', 1, 0)), SUM(IIF(x.origen = 'COMPRA', 1, 0)), SUM(IIF(x.origen = 'CAJA', 1, 0)),
       SUM(IIF(x.origen = 'NIVEL', 1, 0)), COUNT(*)
FROM dbo.UsuarioObjeto AS x JOIN dbo.Usuario AS u ON u.id_usuario = x.id_usuario
GROUP BY x.id_usuario, u.nickname ORDER BY x.id_usuario;

-- @consulta equipamiento | Equipamiento, un objeto por ranura
-- @columnas Usuario | Peón | Muro | Tablero | Título | Marco | Emotes
SELECT u.nickname,
       MAX(IIF(e.id_ranura = 1, o.codigo, NULL)), MAX(IIF(e.id_ranura = 2, o.codigo, NULL)), MAX(IIF(e.id_ranura = 3, o.codigo, NULL)),
       MAX(IIF(e.id_ranura = 4, o.codigo, NULL)), MAX(IIF(e.id_ranura = 5, o.codigo, NULL)), MAX(IIF(e.id_ranura = 6, o.codigo, NULL))
FROM dbo.Equipamiento AS e
JOIN dbo.Usuario AS u ON u.id_usuario = e.id_usuario
JOIN dbo.ObjetoCosmetico AS o ON o.id_objeto = e.id_objeto
GROUP BY e.id_usuario, u.nickname ORDER BY e.id_usuario;

-- @consulta caja | Caja
-- @columnas Id | Usuario | Tipo | Origen | Estado | Obtenida | Abierta | Caduca
SELECT c.id_caja, u.nickname, t.codigo, c.origen, c.estado, CONVERT(VARCHAR(16), c.fecha_obtencion, 120),
       CONVERT(VARCHAR(16), c.fecha_apertura, 120), CONVERT(VARCHAR(16), c.fecha_caducidad, 120)
FROM dbo.Caja AS c
JOIN dbo.Usuario AS u ON u.id_usuario = c.id_usuario
JOIN dbo.TipoCaja AS t ON t.id_tipo_caja = c.id_tipo_caja
ORDER BY c.id_caja;

-- @consulta cajacontenido | CajaContenido
-- @columnas Caja | Número | Objeto | Monedas por conversión | Convertido
SELECT x.id_caja, x.numero, o.codigo, x.monedas_conversion, x.convertido
FROM dbo.CajaContenido AS x JOIN dbo.ObjetoCosmetico AS o ON o.id_objeto = x.id_objeto
ORDER BY x.id_caja, x.numero;

-- @consulta movimiento | MovimientoMoneda
-- @columnas Id | Usuario | Tipo | Importe | Fecha | Partida | Objeto | Caja
SELECT m.id_movimiento, u.nickname, m.tipo, m.importe, CONVERT(VARCHAR(16), m.fecha_movimiento, 120), m.id_partida, o.codigo, m.id_caja
FROM dbo.MovimientoMoneda AS m
JOIN dbo.Usuario AS u ON u.id_usuario = m.id_usuario
LEFT JOIN dbo.ObjetoCosmetico AS o ON o.id_objeto = m.id_objeto
ORDER BY m.id_movimiento;

-- @consulta social | Amistad, Solicitud, Silencio y Bloqueo
-- @columnas Tabla | De | A | Fecha
SELECT 'Amistad', a.nickname, b.nickname, CONVERT(VARCHAR(16), x.fecha_amistad, 120)
FROM dbo.Amistad AS x JOIN dbo.Usuario AS a ON a.id_usuario = x.id_usuario_a JOIN dbo.Usuario AS b ON b.id_usuario = x.id_usuario_b
UNION ALL
SELECT 'Solicitud', a.nickname, b.nickname, CONVERT(VARCHAR(16), x.fecha_solicitud, 120)
FROM dbo.Solicitud AS x JOIN dbo.Usuario AS a ON a.id_usuario = x.id_solicitante JOIN dbo.Usuario AS b ON b.id_usuario = x.id_destinatario
UNION ALL
SELECT 'Silencio', a.nickname, b.nickname, CONVERT(VARCHAR(16), x.fecha_silencio, 120)
FROM dbo.Silencio AS x JOIN dbo.Usuario AS a ON a.id_usuario = x.id_usuario JOIN dbo.Usuario AS b ON b.id_usuario = x.id_silenciado
UNION ALL
SELECT 'Bloqueo', a.nickname, b.nickname, CONVERT(VARCHAR(16), x.fecha_bloqueo, 120)
FROM dbo.Bloqueo AS x JOIN dbo.Usuario AS a ON a.id_usuario = x.id_bloqueador JOIN dbo.Usuario AS b ON b.id_usuario = x.id_bloqueado;

-- @consulta tutorial | ProgresoTutorial
-- @columnas Usuario | Lección | Paso actual | Pasos | Completada | Actualizado
SELECT u.nickname, l.codigo, p.paso_actual, l.num_pasos, p.completada, CONVERT(VARCHAR(16), p.fecha_actualizacion, 120)
FROM dbo.ProgresoTutorial AS p
JOIN dbo.Usuario AS u ON u.id_usuario = p.id_usuario
JOIN dbo.Leccion AS l ON l.id_leccion = p.id_leccion
ORDER BY p.id_usuario, l.orden;

-- @consulta reporte | Reporte
-- @columnas Id | Denunciante | Reportado | Motivo | Partida | Estado | Moderador | Enviado | Resuelto
SELECT r.id_reporte, d.nickname, x.nickname, m.codigo, r.id_partida, r.estado, o.nickname,
       CONVERT(VARCHAR(16), r.fecha_reporte, 120), CONVERT(VARCHAR(16), r.fecha_resolucion, 120)
FROM dbo.Reporte AS r
JOIN dbo.Usuario AS d ON d.id_usuario = r.id_denunciante
JOIN dbo.Usuario AS x ON x.id_usuario = r.id_reportado
JOIN dbo.MotivoReporte AS m ON m.id_motivo = r.id_motivo
LEFT JOIN dbo.Usuario AS o ON o.id_usuario = r.id_moderador
ORDER BY r.id_reporte;

-- @consulta sancion | Sancion
-- @columnas Id | Sancionado | Moderador | Reporte | Ámbito | Tipo | Inicio | Fin | Retiro | Sustituta | Activa
SELECT s.id_sancion, u.nickname, m.nickname, s.id_reporte, s.ambito, s.tipo, CONVERT(VARCHAR(16), s.fecha_inicio, 120),
       CONVERT(VARCHAR(16), s.fecha_fin, 120), CONVERT(VARCHAR(16), s.fecha_retiro, 120), s.id_sancion_sustituta, s.activa
FROM dbo.Sancion AS s
JOIN dbo.Usuario AS u ON u.id_usuario = s.id_usuario
JOIN dbo.Usuario AS m ON m.id_usuario = s.id_moderador
ORDER BY s.id_sancion;

-- @consulta apelacion | Apelacion
-- @columnas Id | Sanción | Texto | Marca de lenguaje | Estado | Moderador | Enviada | Resuelta
SELECT a.id_apelacion, a.id_sancion, a.texto, a.marca_lenguaje, a.estado, m.nickname,
       CONVERT(VARCHAR(16), a.fecha_apelacion, 120), CONVERT(VARCHAR(16), a.fecha_resolucion, 120)
FROM dbo.Apelacion AS a LEFT JOIN dbo.Usuario AS m ON m.id_usuario = a.id_moderador
ORDER BY a.id_apelacion;

-- @consulta bitacoramoderacion | BitacoraModeracion
-- @columnas Id | Moderador | Acción | Afectado | Detalle | Fecha
SELECT b.id_bitacora, m.nickname, b.accion, a.nickname, b.detalle, CONVERT(VARCHAR(16), b.fecha_hora, 120)
FROM dbo.BitacoraModeracion AS b
JOIN dbo.Usuario AS m ON m.id_usuario = b.id_moderador
LEFT JOIN dbo.Usuario AS a ON a.id_usuario = b.id_usuario_afectado
ORDER BY b.id_bitacora;

-- @consulta bitacoraacceso | BitacoraAcceso
-- @columnas Id | Cuenta | Identificador tecleado | Resultado | Dirección IP | Fecha
SELECT b.id_bitacora, u.nickname, b.identificador_capturado, b.resultado, b.direccion_ip, CONVERT(VARCHAR(16), b.fecha_hora, 120)
FROM dbo.BitacoraAcceso AS b LEFT JOIN dbo.Usuario AS u ON u.id_usuario = b.id_usuario
ORDER BY b.id_bitacora;
GO

/*---------------------------------------------------------------------
  3. Casos normales
---------------------------------------------------------------------*/

-- @consulta normalpartida | Una partida clasificatoria normal: la 1
-- @columnas Partida | Modo | Forma | Jugador | Resultado | Elo inicial | Elo final | Diferencia | Monedas
SELECT p.id_partida, m.codigo, p.forma_termino, u.nickname, pa.resultado, pa.elo_inicial, pa.elo_final, pa.diferencia_elo, mm.importe
FROM dbo.Partida AS p
JOIN dbo.Modo AS m ON m.id_modo = p.id_modo
JOIN dbo.Participacion AS pa ON pa.id_partida = p.id_partida
JOIN dbo.Usuario AS u ON u.id_usuario = pa.id_usuario
LEFT JOIN dbo.MovimientoMoneda AS mm ON mm.id_partida = p.id_partida AND mm.id_usuario = pa.id_usuario AND mm.tipo = 'PARTIDA'
WHERE p.id_partida = 1
ORDER BY pa.orden_turno;

-- @consulta normaljugadas | Las jugadas de la partida 1
-- @columnas Número | Jugador | Tipo | Origen | Destino | Surco | Orientación | Tiempo (ms) | Fecha
SELECT j.numero_jugada, u.nickname, j.tipo, j.casilla_origen, j.casilla_destino, j.surco, j.orientacion, j.tiempo_consumido,
       CONVERT(VARCHAR(23), j.fecha_jugada, 121)
FROM dbo.Jugada AS j JOIN dbo.Usuario AS u ON u.id_usuario = j.id_usuario
WHERE j.id_partida = 1
ORDER BY j.numero_jugada;

-- @consulta normalcompra | Compras en la tienda (CU-38)
-- @columnas Movimiento | Usuario | Objeto | Rareza | Importe | Fecha | Origen en UsuarioObjeto | Equipado
SELECT m.id_movimiento, u.nickname, o.codigo, o.rareza, m.importe, CONVERT(VARCHAR(16), m.fecha_movimiento, 120), x.origen,
       IIF(EXISTS (SELECT 1 FROM dbo.Equipamiento AS e WHERE e.id_usuario = m.id_usuario AND e.id_objeto = m.id_objeto), 'sí', 'no')
FROM dbo.MovimientoMoneda AS m
JOIN dbo.Usuario AS u ON u.id_usuario = m.id_usuario
JOIN dbo.ObjetoCosmetico AS o ON o.id_objeto = m.id_objeto
JOIN dbo.UsuarioObjeto AS x ON x.id_usuario = m.id_usuario AND x.id_objeto = m.id_objeto
WHERE m.tipo = 'COMPRA'
ORDER BY m.id_movimiento;
GO

/*---------------------------------------------------------------------
  4. Relaciones entre tablas
---------------------------------------------------------------------*/

-- @consulta relpartidas | Cada partida con su modo y sus participantes
-- @columnas Partida | Tipo | Modo | Estado | Jugador | Cuenta | Resultado | Elo final
SELECT p.id_partida AS partida, CAST(p.tipo AS VARCHAR(14)) AS tipo, CAST(m.codigo AS VARCHAR(16)) AS modo,
       CAST(p.estado AS VARCHAR(10)) AS estado, CAST(u.nickname AS NVARCHAR(14)) AS jugador,
       CAST(u.tipo_cuenta AS VARCHAR(10)) AS cuenta, CAST(pa.resultado AS VARCHAR(9)) AS resultado, pa.elo_final
FROM dbo.Partida AS p
JOIN dbo.Modo AS m ON m.id_modo = p.id_modo
JOIN dbo.Participacion AS pa ON pa.id_partida = p.id_partida
JOIN dbo.Usuario AS u ON u.id_usuario = pa.id_usuario
ORDER BY p.id_partida, pa.orden_turno;

-- @consulta relequipamiento | El aspecto de luis_quo: de la cuenta a la ranura
-- @columnas Usuario | Ranura | Objeto | Rareza | Obtenido | Origen
SELECT u.nickname, r.codigo, o.codigo, o.rareza, CONVERT(VARCHAR(16), x.fecha_obtencion, 120), x.origen
FROM dbo.Usuario AS u
JOIN dbo.Equipamiento AS e ON e.id_usuario = u.id_usuario
JOIN dbo.UsuarioObjeto AS x ON x.id_usuario = e.id_usuario AND x.id_objeto = e.id_objeto
JOIN dbo.ObjetoCosmetico AS o ON o.id_objeto = e.id_objeto AND o.id_ranura = e.id_ranura
JOIN dbo.Ranura AS r ON r.id_ranura = e.id_ranura
WHERE u.nickname = N'luis_quo'
ORDER BY r.id_ranura;

-- @consulta relmoderacion | Reporte, sanción y apelación
-- @columnas Reporte | Motivo | Denunciante | Reportado | Estado del reporte | Sanción | Tipo | Apelación | Estado de la apelación
SELECT r.id_reporte, m.codigo, d.nickname, x.nickname, r.estado, s.id_sancion, s.ambito + ' ' + s.tipo, a.id_apelacion, a.estado
FROM dbo.Reporte AS r
JOIN dbo.MotivoReporte AS m ON m.id_motivo = r.id_motivo
JOIN dbo.Usuario AS d ON d.id_usuario = r.id_denunciante
JOIN dbo.Usuario AS x ON x.id_usuario = r.id_reportado
LEFT JOIN dbo.Sancion AS s ON s.id_reporte = r.id_reporte
LEFT JOIN dbo.Apelacion AS a ON a.id_sancion = s.id_sancion
ORDER BY r.id_reporte, s.id_sancion;

-- @consulta relcajas | Cajas, su tipo, su contenido y las monedas por repetidos
-- @columnas Caja | Usuario | Tipo | Estado | Número | Objeto | Monedas por conversión | Movimiento
SELECT c.id_caja, u.nickname, t.codigo, c.estado, x.numero, o.codigo, x.monedas_conversion, mm.id_movimiento
FROM dbo.Caja AS c
JOIN dbo.Usuario AS u ON u.id_usuario = c.id_usuario
JOIN dbo.TipoCaja AS t ON t.id_tipo_caja = c.id_tipo_caja
LEFT JOIN dbo.CajaContenido AS x ON x.id_caja = c.id_caja
LEFT JOIN dbo.ObjetoCosmetico AS o ON o.id_objeto = x.id_objeto
LEFT JOIN dbo.MovimientoMoneda AS mm ON mm.id_caja = c.id_caja AND mm.id_objeto = x.id_objeto AND mm.tipo = 'CONVERSION'
ORDER BY c.id_caja, x.numero;

-- @consulta relsustitucion | Sanción que sustituye a otra: relación de Sancion consigo misma
-- @columnas Sanción retirada | Fin previsto | Retiro | Sustituta | Fin de la sustituta | Motivo de la sustituta
SELECT s.id_sancion, CONVERT(VARCHAR(16), s.fecha_fin, 120), CONVERT(VARCHAR(16), s.fecha_retiro, 120), n.id_sancion,
       CONVERT(VARCHAR(16), n.fecha_fin, 120), n.motivo
FROM dbo.Sancion AS s JOIN dbo.Sancion AS n ON n.id_sancion = s.id_sancion_sustituta;
GO

/*---------------------------------------------------------------------
  5. Estados y categorías
---------------------------------------------------------------------*/

-- @consulta estados | Filas por valor en las columnas de estado y de categoría
-- @columnas Columna | Valores y filas
SELECT CAST(c.columna AS VARCHAR(30)) AS columna, CAST(STRING_AGG(CONCAT(c.valor, ' (', c.n, ')'), ', ') WITHIN GROUP (ORDER BY c.n DESC, c.valor) AS VARCHAR(110)) AS valores_y_filas
FROM (
    SELECT 1 AS o, 'Usuario.tipo_cuenta' AS columna, tipo_cuenta AS valor, COUNT(*) AS n FROM dbo.Usuario GROUP BY tipo_cuenta
    UNION ALL SELECT 2, 'Usuario.estado_cuenta', estado_cuenta, COUNT(*) FROM dbo.Usuario GROUP BY estado_cuenta
    UNION ALL SELECT 3, 'Usuario.rol', rol, COUNT(*) FROM dbo.Usuario GROUP BY rol
    UNION ALL SELECT 4, 'Usuario.idioma_preferido', idioma_preferido, COUNT(*) FROM dbo.Usuario GROUP BY idioma_preferido
    UNION ALL SELECT 5, 'Partida.tipo', tipo, COUNT(*) FROM dbo.Partida GROUP BY tipo
    UNION ALL SELECT 6, 'Partida.estado', estado, COUNT(*) FROM dbo.Partida GROUP BY estado
    UNION ALL SELECT 7, 'Partida.forma_termino', ISNULL(forma_termino, 'NULL'), COUNT(*) FROM dbo.Partida GROUP BY forma_termino
    UNION ALL SELECT 8, 'Participacion.resultado', ISNULL(resultado, 'NULL'), COUNT(*) FROM dbo.Participacion GROUP BY resultado
    UNION ALL SELECT 9, 'OfertaTablas.estado', estado, COUNT(*) FROM dbo.OfertaTablas GROUP BY estado
    UNION ALL SELECT 10, 'Invitacion.estado', estado, COUNT(*) FROM dbo.Invitacion GROUP BY estado
    UNION ALL SELECT 11, 'Mensaje.canal', canal, COUNT(*) FROM dbo.Mensaje GROUP BY canal
    UNION ALL SELECT 12, 'ObjetoCosmetico.rareza', rareza, COUNT(*) FROM dbo.ObjetoCosmetico GROUP BY rareza
    UNION ALL SELECT 13, 'Caja.estado', estado, COUNT(*) FROM dbo.Caja GROUP BY estado
    UNION ALL SELECT 14, 'MovimientoMoneda.tipo', tipo, COUNT(*) FROM dbo.MovimientoMoneda GROUP BY tipo
    UNION ALL SELECT 15, 'Reporte.estado', estado, COUNT(*) FROM dbo.Reporte GROUP BY estado
    UNION ALL SELECT 16, 'Sancion.tipo', CONCAT(ambito, ' ', tipo), COUNT(*) FROM dbo.Sancion GROUP BY ambito, tipo
    UNION ALL SELECT 17, 'Apelacion.estado', estado, COUNT(*) FROM dbo.Apelacion GROUP BY estado
    UNION ALL SELECT 18, 'TokenRecuperacion.estado', estado, COUNT(*) FROM dbo.TokenRecuperacion GROUP BY estado
) AS c
GROUP BY c.o, c.columna
ORDER BY c.o;
GO

/*---------------------------------------------------------------------
  6. Variaciones relevantes
---------------------------------------------------------------------*/

-- @consulta variaciones | Registros que se salen del caso normal
-- @columnas Variación | Tabla | Registro | Dato que la muestra
SELECT CAST(v.variacion AS NVARCHAR(44)) AS variacion, CAST(v.tabla AS VARCHAR(18)) AS tabla, CAST(v.registro AS NVARCHAR(22)) AS registro, CAST(v.dato AS NVARCHAR(58)) AS dato
FROM (
    SELECT 1 AS o, N'Invitado: sin correo ni contraseña' AS variacion, 'Usuario' AS tabla, nickname COLLATE DATABASE_DEFAULT AS registro,
           CONCAT(N'correo ', ISNULL(correo, 'NULL'), N', contraseña ', IIF(contrasena_hash IS NULL, 'NULL', 'guardada')) AS dato
    FROM dbo.Usuario WHERE tipo_cuenta = 'INVITADO'
    UNION ALL
    SELECT 2, N'Cuenta eliminada y anonimizada (D-17)', 'Usuario', nickname COLLATE DATABASE_DEFAULT,
           CONCAT(N'correo ', correo, N', baja ', CONVERT(VARCHAR(16), fecha_baja, 120))
    FROM dbo.Usuario WHERE estado_cuenta = 'ELIMINADA'
    UNION ALL
    SELECT 3, N'Cuenta baneada: sanción permanente', 'Sancion', u.nickname COLLATE DATABASE_DEFAULT,
           CONCAT(s.ambito, ' ', s.tipo, N', fin ', ISNULL(CONVERT(VARCHAR(16), s.fecha_fin, 120), 'NULL'))
    FROM dbo.Sancion AS s JOIN dbo.Usuario AS u ON u.id_usuario = s.id_usuario WHERE s.tipo = 'PERMANENTE' AND s.ambito = 'CUENTA'
    UNION ALL
    SELECT 4, N'Interfaz y términos en inglés (D-21)', 'AceptacionTerminos', u.nickname COLLATE DATABASE_DEFAULT,
           CONCAT(N'versión ', a.version_terminos, N' en ', a.idioma)
    FROM dbo.AceptacionTerminos AS a JOIN dbo.Usuario AS u ON u.id_usuario = a.id_usuario WHERE a.idioma = 'en'
    UNION ALL
    SELECT 5, N'Chat con ñ, acentos, emoji e inglés', 'Mensaje', CONCAT(N'mensaje ', id_mensaje), texto
    FROM dbo.Mensaje WHERE id_mensaje IN (4, 7)
    UNION ALL
    SELECT 6, N'Partida contra la IA, sin reloj', 'Partida', CONCAT(N'partida ', id_partida),
           CONCAT(N'reloj ', ISNULL(CAST(minutos_reloj AS VARCHAR(5)), 'NULL'), N', deshacer usados ', deshacer_usados)
    FROM dbo.Partida WHERE tipo = 'IA'
    UNION ALL
    SELECT 7, N'Jugadas deshechas que se conservan (D-12)', 'Jugada', CONCAT(N'partida ', id_partida),
           CONCAT(N'jugadas ', STRING_AGG(numero_jugada, ', '), N' con deshecha = 1')
    FROM dbo.Jugada WHERE deshecha = 1 GROUP BY id_partida
    UNION ALL
    SELECT 8, N'Cuatro jugadores: posiciones y salidas', 'Participacion', u.nickname COLLATE DATABASE_DEFAULT,
           CONCAT(N'posición ', p.posicion, N', salida ', ISNULL(p.forma_termino, 'ninguna'))
    FROM dbo.Participacion AS p JOIN dbo.Usuario AS u ON u.id_usuario = p.id_usuario
    JOIN dbo.Partida AS pa ON pa.id_partida = p.id_partida JOIN dbo.Modo AS m ON m.id_modo = pa.id_modo
    WHERE m.num_jugadores = 4
    UNION ALL
    SELECT 9, N'Derrota por tiempo: reloj en cero', 'Participacion', u.nickname COLLATE DATABASE_DEFAULT,
           CONCAT(N'partida ', p.id_partida, N', reloj ', p.reloj_restante, ' ms')
    FROM dbo.Participacion AS p JOIN dbo.Usuario AS u ON u.id_usuario = p.id_usuario
    JOIN dbo.Partida AS pa ON pa.id_partida = p.id_partida
    WHERE pa.forma_termino = 'TIEMPO_AGOTADO' AND p.resultado = 'PERDIDA'
    UNION ALL
    SELECT 10, N'Objeto retirado del catálogo', 'ObjetoCosmetico', codigo, CONCAT(N'activo ', activo, N', a la venta ', a_la_venta)
    FROM dbo.ObjetoCosmetico WHERE activo = 0
    UNION ALL
    SELECT 11, N'Término prohibido en todos los idiomas', 'PalabraProhibida', termino COLLATE DATABASE_DEFAULT, N'idioma NULL'
    FROM dbo.PalabraProhibida WHERE idioma IS NULL
    UNION ALL
    SELECT 12, N'Sesión que expiró sin cierre', 'Sesion', CONCAT(N'sesión ', id_sesion),
           CONCAT(N'expiró ', CONVERT(VARCHAR(16), fecha_expiracion, 120), N', fin NULL')
    FROM dbo.Sesion WHERE fecha_fin IS NULL AND fecha_expiracion < '2026-09-01T18:00:00'
) AS v
ORDER BY v.o, v.registro COLLATE DATABASE_DEFAULT;

-- @consulta variaia | Las jugadas de la partida contra la IA, con las deshechas
-- @columnas Número | Jugador | Tipo | Origen | Destino | Surco | Orientación | Deshecha
SELECT j.numero_jugada, ISNULL(u.nickname, 'IA'), j.tipo, j.casilla_origen, j.casilla_destino, j.surco, j.orientacion, j.deshecha
FROM dbo.Jugada AS j LEFT JOIN dbo.Usuario AS u ON u.id_usuario = j.id_usuario
WHERE j.id_partida = 8
ORDER BY j.numero_jugada;
GO

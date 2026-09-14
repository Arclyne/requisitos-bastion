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

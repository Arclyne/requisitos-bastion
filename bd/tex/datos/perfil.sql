SELECT 'HistorialNickname', u.nickname, CONCAT('antes: ', h.nickname_anterior), CONVERT(VARCHAR(16), h.fecha_cambio, 120)
FROM dbo.HistorialNickname AS h JOIN dbo.Usuario AS u ON u.id_usuario = h.id_usuario
UNION ALL
SELECT 'Avatar', u.nickname, CONCAT(a.ruta_imagen, ' (', a.formato, ', ', a.tamano_bytes / 1000, ' kB, ', IIF(a.vigente = 1, 'vigente', 'no vigente'), ')'),
       CONVERT(VARCHAR(16), a.fecha_subida, 120)
FROM dbo.Avatar AS a JOIN dbo.Usuario AS u ON u.id_usuario = a.id_usuario
UNION ALL
SELECT 'EnlaceRed', u.nickname, CONCAT(e.orden, ': ', e.url), NULL
FROM dbo.EnlaceRed AS e JOIN dbo.Usuario AS u ON u.id_usuario = e.id_usuario;

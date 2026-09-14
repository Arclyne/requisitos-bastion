SELECT a.id_aceptacion, u.nickname, a.version_terminos, a.idioma, CONVERT(VARCHAR(16), a.fecha_aceptacion, 120)
FROM dbo.AceptacionTerminos AS a JOIN dbo.Usuario AS u ON u.id_usuario = a.id_usuario
ORDER BY a.id_aceptacion;

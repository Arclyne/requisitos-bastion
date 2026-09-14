SELECT s.id_sancion, u.nickname, m.nickname, s.id_reporte, s.ambito, s.tipo, CONVERT(VARCHAR(16), s.fecha_inicio, 120),
       CONVERT(VARCHAR(16), s.fecha_fin, 120), CONVERT(VARCHAR(16), s.fecha_retiro, 120), s.id_sancion_sustituta, s.activa
FROM dbo.Sancion AS s
JOIN dbo.Usuario AS u ON u.id_usuario = s.id_usuario
JOIN dbo.Usuario AS m ON m.id_usuario = s.id_moderador
ORDER BY s.id_sancion;

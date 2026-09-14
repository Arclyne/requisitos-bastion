SELECT b.id_bitacora, m.nickname, b.accion, a.nickname, b.detalle, CONVERT(VARCHAR(16), b.fecha_hora, 120)
FROM dbo.BitacoraModeracion AS b
JOIN dbo.Usuario AS m ON m.id_usuario = b.id_moderador
LEFT JOIN dbo.Usuario AS a ON a.id_usuario = b.id_usuario_afectado
ORDER BY b.id_bitacora;

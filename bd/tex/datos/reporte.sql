SELECT r.id_reporte, d.nickname, x.nickname, m.codigo, r.id_partida, r.estado, o.nickname,
       CONVERT(VARCHAR(16), r.fecha_reporte, 120), CONVERT(VARCHAR(16), r.fecha_resolucion, 120)
FROM dbo.Reporte AS r
JOIN dbo.Usuario AS d ON d.id_usuario = r.id_denunciante
JOIN dbo.Usuario AS x ON x.id_usuario = r.id_reportado
JOIN dbo.MotivoReporte AS m ON m.id_motivo = r.id_motivo
LEFT JOIN dbo.Usuario AS o ON o.id_usuario = r.id_moderador
ORDER BY r.id_reporte;

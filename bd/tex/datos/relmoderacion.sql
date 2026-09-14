SELECT r.id_reporte, m.codigo, d.nickname, x.nickname, r.estado,
       CAST(s.id_sancion AS VARCHAR(5)) + ': ' + s.ambito + ' ' + s.tipo, CAST(a.id_apelacion AS VARCHAR(5)) + ': ' + a.estado
FROM dbo.Reporte AS r
JOIN dbo.MotivoReporte AS m ON m.id_motivo = r.id_motivo
JOIN dbo.Usuario AS d ON d.id_usuario = r.id_denunciante
JOIN dbo.Usuario AS x ON x.id_usuario = r.id_reportado
LEFT JOIN dbo.Sancion AS s ON s.id_reporte = r.id_reporte
LEFT JOIN dbo.Apelacion AS a ON a.id_sancion = s.id_sancion
ORDER BY r.id_reporte, s.id_sancion;

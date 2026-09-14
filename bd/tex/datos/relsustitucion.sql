SELECT s.id_sancion, CONVERT(VARCHAR(16), s.fecha_fin, 120), CONVERT(VARCHAR(16), s.fecha_retiro, 120), n.id_sancion,
       CONVERT(VARCHAR(16), n.fecha_fin, 120), n.motivo
FROM dbo.Sancion AS s JOIN dbo.Sancion AS n ON n.id_sancion = s.id_sancion_sustituta;

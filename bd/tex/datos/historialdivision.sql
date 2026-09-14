SELECT h.id_historial_division, u.nickname, m.codigo, a.codigo, n.codigo, CONVERT(VARCHAR(16), h.fecha_cambio, 120)
FROM dbo.HistorialDivision AS h
JOIN dbo.Usuario AS u ON u.id_usuario = h.id_usuario
JOIN dbo.Modo AS m ON m.id_modo = h.id_modo
LEFT JOIN dbo.Division AS a ON a.id_division = h.id_division_anterior
JOIN dbo.Division AS n ON n.id_division = h.id_division_nueva
ORDER BY h.id_historial_division;

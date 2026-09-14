SELECT p.id_partida, p.tipo, m.codigo, p.estado, p.forma_termino, p.minutos_reloj,
       CONVERT(VARCHAR(16), p.fecha_inicio, 120), CONVERT(VARCHAR(16), p.fecha_fin, 120), n.codigo, p.turno_actual
FROM dbo.Partida AS p
JOIN dbo.Modo AS m ON m.id_modo = p.id_modo
LEFT JOIN dbo.NivelIA AS n ON n.id_nivel_ia = p.id_nivel_ia
ORDER BY p.id_partida;

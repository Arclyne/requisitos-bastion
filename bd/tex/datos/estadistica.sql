SELECT u.nickname, m.codigo, e.puntos_elo, e.elo_maximo, e.partidas_jugadas, e.partidas_ganadas, e.partidas_perdidas,
       e.racha_actual, e.mejor_racha, e.abandonos, d.codigo
FROM dbo.EstadisticaModo AS e
JOIN dbo.Usuario AS u ON u.id_usuario = e.id_usuario
JOIN dbo.Modo AS m ON m.id_modo = e.id_modo
LEFT JOIN dbo.Division AS d ON d.id_division = e.id_division
WHERE e.partidas_jugadas > 0
ORDER BY e.id_usuario, e.id_modo;

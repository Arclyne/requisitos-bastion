SELECT p.id_partida, m.codigo, p.forma_termino, u.nickname, pa.resultado, pa.elo_inicial, pa.elo_final, pa.diferencia_elo, mm.importe
FROM dbo.Partida AS p
JOIN dbo.Modo AS m ON m.id_modo = p.id_modo
JOIN dbo.Participacion AS pa ON pa.id_partida = p.id_partida
JOIN dbo.Usuario AS u ON u.id_usuario = pa.id_usuario
LEFT JOIN dbo.MovimientoMoneda AS mm ON mm.id_partida = p.id_partida AND mm.id_usuario = pa.id_usuario AND mm.tipo = 'PARTIDA'
WHERE p.id_partida = 1
ORDER BY pa.orden_turno;

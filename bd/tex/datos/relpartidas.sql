SELECT p.id_partida AS partida, CAST(p.tipo AS VARCHAR(14)) AS tipo, CAST(m.codigo AS VARCHAR(16)) AS modo,
       CAST(p.estado AS VARCHAR(10)) AS estado, CAST(u.nickname AS NVARCHAR(14)) AS jugador,
       CAST(u.tipo_cuenta AS VARCHAR(10)) AS cuenta, CAST(pa.resultado AS VARCHAR(9)) AS resultado, pa.elo_final
FROM dbo.Partida AS p
JOIN dbo.Modo AS m ON m.id_modo = p.id_modo
JOIN dbo.Participacion AS pa ON pa.id_partida = p.id_partida
JOIN dbo.Usuario AS u ON u.id_usuario = pa.id_usuario
ORDER BY p.id_partida, pa.orden_turno;

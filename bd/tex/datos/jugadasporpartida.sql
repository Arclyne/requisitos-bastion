SELECT id_partida, COUNT(*), SUM(IIF(tipo = 'MOVIMIENTO', 1, 0)), SUM(IIF(tipo = 'MURO', 1, 0)), SUM(CAST(deshecha AS INT)),
       CONVERT(VARCHAR(19), MIN(fecha_jugada), 120), CONVERT(VARCHAR(19), MAX(fecha_jugada), 120)
FROM dbo.Jugada GROUP BY id_partida ORDER BY id_partida;

SELECT j.numero_jugada, ISNULL(u.nickname, 'IA'), j.tipo, j.casilla_origen, j.casilla_destino, j.surco, j.orientacion, j.deshecha
FROM dbo.Jugada AS j LEFT JOIN dbo.Usuario AS u ON u.id_usuario = j.id_usuario
WHERE j.id_partida = 8
ORDER BY j.numero_jugada;

SELECT j.numero_jugada, u.nickname, j.tipo, j.casilla_origen, j.casilla_destino, j.surco, j.orientacion, j.tiempo_consumido,
       CONVERT(VARCHAR(23), j.fecha_jugada, 121)
FROM dbo.Jugada AS j JOIN dbo.Usuario AS u ON u.id_usuario = j.id_usuario
WHERE j.id_partida = 1
ORDER BY j.numero_jugada;

SELECT m.id_mensaje, u.nickname, m.canal, m.id_partida, m.id_sala, m.texto, CONVERT(VARCHAR(19), m.fecha_envio, 120)
FROM dbo.Mensaje AS m JOIN dbo.Usuario AS u ON u.id_usuario = m.id_autor
ORDER BY m.id_mensaje;

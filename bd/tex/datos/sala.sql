SELECT s.id_sala, s.codigo, u.nickname, m.codigo, s.muros_por_jugador, s.minutos_reloj, s.permite_espectadores, s.estado, s.id_partida,
       CONVERT(VARCHAR(16), s.fecha_creacion, 120)
FROM dbo.Sala AS s
JOIN dbo.Usuario AS u ON u.id_usuario = s.id_anfitrion
JOIN dbo.Modo AS m ON m.id_modo = s.id_modo
ORDER BY s.id_sala;

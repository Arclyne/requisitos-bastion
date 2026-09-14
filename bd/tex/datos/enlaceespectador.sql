SELECT e.id_enlace, e.id_partida, u.nickname, CONVERT(VARCHAR(16), e.fecha_creacion, 120)
FROM dbo.EnlaceEspectador AS e JOIN dbo.Usuario AS u ON u.id_usuario = e.id_creador;

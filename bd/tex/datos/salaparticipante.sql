SELECT sp.id_sala, u.nickname, sp.plaza, sp.listo, CONVERT(VARCHAR(19), sp.fecha_union, 120)
FROM dbo.SalaParticipante AS sp JOIN dbo.Usuario AS u ON u.id_usuario = sp.id_usuario
ORDER BY sp.id_sala, sp.plaza;

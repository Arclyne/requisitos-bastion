SELECT i.id_invitacion, i.id_sala, e.nickname, d.nickname, CONVERT(VARCHAR(19), i.fecha_invitacion, 120), i.estado
FROM dbo.Invitacion AS i
JOIN dbo.Usuario AS e ON e.id_usuario = i.id_emisor
JOIN dbo.Usuario AS d ON d.id_usuario = i.id_destinatario
ORDER BY i.id_invitacion;

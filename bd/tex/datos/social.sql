SELECT 'Amistad', a.nickname, b.nickname, CONVERT(VARCHAR(16), x.fecha_amistad, 120)
FROM dbo.Amistad AS x JOIN dbo.Usuario AS a ON a.id_usuario = x.id_usuario_a JOIN dbo.Usuario AS b ON b.id_usuario = x.id_usuario_b
UNION ALL
SELECT 'Solicitud', a.nickname, b.nickname, CONVERT(VARCHAR(16), x.fecha_solicitud, 120)
FROM dbo.Solicitud AS x JOIN dbo.Usuario AS a ON a.id_usuario = x.id_solicitante JOIN dbo.Usuario AS b ON b.id_usuario = x.id_destinatario
UNION ALL
SELECT 'Silencio', a.nickname, b.nickname, CONVERT(VARCHAR(16), x.fecha_silencio, 120)
FROM dbo.Silencio AS x JOIN dbo.Usuario AS a ON a.id_usuario = x.id_usuario JOIN dbo.Usuario AS b ON b.id_usuario = x.id_silenciado
UNION ALL
SELECT 'Bloqueo', a.nickname, b.nickname, CONVERT(VARCHAR(16), x.fecha_bloqueo, 120)
FROM dbo.Bloqueo AS x JOIN dbo.Usuario AS a ON a.id_usuario = x.id_bloqueador JOIN dbo.Usuario AS b ON b.id_usuario = x.id_bloqueado;

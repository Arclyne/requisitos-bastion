SELECT t.id_token, u.nickname, t.proposito, t.correo_destino, CONVERT(VARCHAR(16), t.fecha_generacion, 120), t.estado
FROM dbo.TokenVerificacionCorreo AS t JOIN dbo.Usuario AS u ON u.id_usuario = t.id_usuario
ORDER BY t.id_token;

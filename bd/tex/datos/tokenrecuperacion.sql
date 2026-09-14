SELECT t.id_token, u.nickname, CONVERT(VARCHAR(16), t.fecha_generacion, 120), CONVERT(VARCHAR(16), t.fecha_expiracion, 120), t.intentos, t.estado
FROM dbo.TokenRecuperacion AS t JOIN dbo.Usuario AS u ON u.id_usuario = t.id_usuario
ORDER BY t.id_token;

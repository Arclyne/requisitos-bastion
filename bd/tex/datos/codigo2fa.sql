SELECT c.id_codigo, u.nickname, c.canal, CONVERT(VARCHAR(16), c.fecha_generacion, 120), CONVERT(VARCHAR(16), c.fecha_expiracion, 120), c.intentos, c.estado
FROM dbo.CodigoSegundoFactor AS c JOIN dbo.Usuario AS u ON u.id_usuario = c.id_usuario
ORDER BY c.id_codigo;

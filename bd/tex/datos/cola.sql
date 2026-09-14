SELECT u.nickname, m.codigo, c.minutos_reloj, CONVERT(VARCHAR(19), c.fecha_entrada, 120)
FROM dbo.ColaEmparejamiento AS c
JOIN dbo.Usuario AS u ON u.id_usuario = c.id_usuario
JOIN dbo.Modo AS m ON m.id_modo = c.id_modo;

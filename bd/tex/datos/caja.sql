SELECT c.id_caja, u.nickname, t.codigo, c.origen, c.estado, CONVERT(VARCHAR(16), c.fecha_obtencion, 120),
       CONVERT(VARCHAR(16), c.fecha_apertura, 120), CONVERT(VARCHAR(16), c.fecha_caducidad, 120)
FROM dbo.Caja AS c
JOIN dbo.Usuario AS u ON u.id_usuario = c.id_usuario
JOIN dbo.TipoCaja AS t ON t.id_tipo_caja = c.id_tipo_caja
ORDER BY c.id_caja;

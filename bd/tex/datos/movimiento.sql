SELECT m.id_movimiento, u.nickname, m.tipo, m.importe, CONVERT(VARCHAR(16), m.fecha_movimiento, 120), m.id_partida, o.codigo, m.id_caja
FROM dbo.MovimientoMoneda AS m
JOIN dbo.Usuario AS u ON u.id_usuario = m.id_usuario
LEFT JOIN dbo.ObjetoCosmetico AS o ON o.id_objeto = m.id_objeto
ORDER BY m.id_movimiento;

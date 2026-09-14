SELECT m.id_movimiento, u.nickname, o.codigo, o.rareza, m.importe, CONVERT(VARCHAR(16), m.fecha_movimiento, 120), x.origen,
       IIF(EXISTS (SELECT 1 FROM dbo.Equipamiento AS e WHERE e.id_usuario = m.id_usuario AND e.id_objeto = m.id_objeto), 'sí', 'no')
FROM dbo.MovimientoMoneda AS m
JOIN dbo.Usuario AS u ON u.id_usuario = m.id_usuario
JOIN dbo.ObjetoCosmetico AS o ON o.id_objeto = m.id_objeto
JOIN dbo.UsuarioObjeto AS x ON x.id_usuario = m.id_usuario AND x.id_objeto = m.id_objeto
WHERE m.tipo = 'COMPRA'
ORDER BY m.id_movimiento;

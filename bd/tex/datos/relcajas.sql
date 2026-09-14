SELECT c.id_caja, u.nickname, t.codigo, c.estado, x.numero, o.codigo, x.monedas_conversion, mm.id_movimiento
FROM dbo.Caja AS c
JOIN dbo.Usuario AS u ON u.id_usuario = c.id_usuario
JOIN dbo.TipoCaja AS t ON t.id_tipo_caja = c.id_tipo_caja
LEFT JOIN dbo.CajaContenido AS x ON x.id_caja = c.id_caja
LEFT JOIN dbo.ObjetoCosmetico AS o ON o.id_objeto = x.id_objeto
LEFT JOIN dbo.MovimientoMoneda AS mm ON mm.id_caja = c.id_caja AND mm.id_objeto = x.id_objeto AND mm.tipo = 'CONVERSION'
ORDER BY c.id_caja, x.numero;

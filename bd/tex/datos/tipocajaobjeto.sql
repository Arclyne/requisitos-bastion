SELECT t.codigo, o.codigo, o.rareza, CAST(x.probabilidad AS DECIMAL(5,1))
FROM dbo.TipoCajaObjeto AS x
JOIN dbo.TipoCaja AS t ON t.id_tipo_caja = x.id_tipo_caja
JOIN dbo.ObjetoCosmetico AS o ON o.id_objeto = x.id_objeto
ORDER BY x.id_tipo_caja, x.probabilidad DESC, o.id_objeto;

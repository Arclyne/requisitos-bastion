SELECT x.id_caja, x.numero, o.codigo, x.monedas_conversion, x.convertido
FROM dbo.CajaContenido AS x JOIN dbo.ObjetoCosmetico AS o ON o.id_objeto = x.id_objeto
ORDER BY x.id_caja, x.numero;

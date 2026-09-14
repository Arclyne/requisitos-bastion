SELECT o.id_objeto, r.codigo, o.codigo, o.rareza, o.precio, o.nivel_requerido, o.a_la_venta, o.activo, o.es_inicial, o.es_predeterminado
FROM dbo.ObjetoCosmetico AS o
JOIN dbo.Ranura AS r ON r.id_ranura = o.id_ranura
ORDER BY o.id_objeto;

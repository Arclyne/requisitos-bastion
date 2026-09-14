SELECT u.nickname,
       MAX(IIF(e.id_ranura = 1, o.codigo, NULL)), MAX(IIF(e.id_ranura = 2, o.codigo, NULL)), MAX(IIF(e.id_ranura = 3, o.codigo, NULL)),
       MAX(IIF(e.id_ranura = 4, o.codigo, NULL)), MAX(IIF(e.id_ranura = 5, o.codigo, NULL)), MAX(IIF(e.id_ranura = 6, o.codigo, NULL))
FROM dbo.Equipamiento AS e
JOIN dbo.Usuario AS u ON u.id_usuario = e.id_usuario
JOIN dbo.ObjetoCosmetico AS o ON o.id_objeto = e.id_objeto
GROUP BY e.id_usuario, u.nickname ORDER BY e.id_usuario;

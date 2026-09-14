SELECT u.nickname, r.codigo, o.codigo, o.rareza, CONVERT(VARCHAR(16), x.fecha_obtencion, 120), x.origen
FROM dbo.Usuario AS u
JOIN dbo.Equipamiento AS e ON e.id_usuario = u.id_usuario
JOIN dbo.UsuarioObjeto AS x ON x.id_usuario = e.id_usuario AND x.id_objeto = e.id_objeto
JOIN dbo.ObjetoCosmetico AS o ON o.id_objeto = e.id_objeto AND o.id_ranura = e.id_ranura
JOIN dbo.Ranura AS r ON r.id_ranura = e.id_ranura
WHERE u.nickname = N'luis_quo'
ORDER BY r.id_ranura;

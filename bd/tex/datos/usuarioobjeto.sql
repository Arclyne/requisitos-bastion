SELECT u.nickname, SUM(IIF(x.origen = 'INICIAL', 1, 0)), SUM(IIF(x.origen = 'COMPRA', 1, 0)), SUM(IIF(x.origen = 'CAJA', 1, 0)),
       SUM(IIF(x.origen = 'NIVEL', 1, 0)), COUNT(*)
FROM dbo.UsuarioObjeto AS x JOIN dbo.Usuario AS u ON u.id_usuario = x.id_usuario
GROUP BY x.id_usuario, u.nickname ORDER BY x.id_usuario;

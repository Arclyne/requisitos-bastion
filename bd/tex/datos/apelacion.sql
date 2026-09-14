SELECT a.id_apelacion, a.id_sancion, a.texto, a.marca_lenguaje, a.estado, m.nickname,
       CONVERT(VARCHAR(16), a.fecha_apelacion, 120), CONVERT(VARCHAR(16), a.fecha_resolucion, 120)
FROM dbo.Apelacion AS a LEFT JOIN dbo.Usuario AS m ON m.id_usuario = a.id_moderador
ORDER BY a.id_apelacion;

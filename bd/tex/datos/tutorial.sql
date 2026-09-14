SELECT u.nickname, l.codigo, p.paso_actual, l.num_pasos, p.completada, CONVERT(VARCHAR(16), p.fecha_actualizacion, 120)
FROM dbo.ProgresoTutorial AS p
JOIN dbo.Usuario AS u ON u.id_usuario = p.id_usuario
JOIN dbo.Leccion AS l ON l.id_leccion = p.id_leccion
ORDER BY p.id_usuario, l.orden;

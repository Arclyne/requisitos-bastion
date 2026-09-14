SELECT s.id_sesion, u.nickname, CONVERT(VARCHAR(16), s.fecha_inicio, 120), CONVERT(VARCHAR(16), s.fecha_fin, 120),
       s.motivo_cierre, s.nombre_dispositivo
FROM dbo.Sesion AS s JOIN dbo.Usuario AS u ON u.id_usuario = s.id_usuario
ORDER BY s.id_sesion;

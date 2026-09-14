SELECT b.id_bitacora, u.nickname, b.identificador_capturado, b.resultado, b.direccion_ip, CONVERT(VARCHAR(16), b.fecha_hora, 120)
FROM dbo.BitacoraAcceso AS b LEFT JOIN dbo.Usuario AS u ON u.id_usuario = b.id_usuario
ORDER BY b.id_bitacora;

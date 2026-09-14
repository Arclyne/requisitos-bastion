SELECT o.id_oferta, o.id_partida, u.nickname, o.numero_jugada, o.estado, CONVERT(VARCHAR(19), o.fecha_oferta, 120), CONVERT(VARCHAR(19), o.fecha_respuesta, 120)
FROM dbo.OfertaTablas AS o JOIN dbo.Usuario AS u ON u.id_usuario = o.id_ofertante
ORDER BY o.id_oferta;

SELECT CAST(c.columna AS VARCHAR(30)) AS columna, CAST(STRING_AGG(CONCAT(c.valor, ' (', c.n, ')'), ', ') WITHIN GROUP (ORDER BY c.n DESC, c.valor) AS VARCHAR(110)) AS valores_y_filas
FROM (
    SELECT 1 AS o, 'Usuario.tipo_cuenta' AS columna, tipo_cuenta AS valor, COUNT(*) AS n FROM dbo.Usuario GROUP BY tipo_cuenta
    UNION ALL SELECT 2, 'Usuario.estado_cuenta', estado_cuenta, COUNT(*) FROM dbo.Usuario GROUP BY estado_cuenta
    UNION ALL SELECT 3, 'Usuario.rol', rol, COUNT(*) FROM dbo.Usuario GROUP BY rol
    UNION ALL SELECT 4, 'Usuario.idioma_preferido', idioma_preferido, COUNT(*) FROM dbo.Usuario GROUP BY idioma_preferido
    UNION ALL SELECT 5, 'Partida.tipo', tipo, COUNT(*) FROM dbo.Partida GROUP BY tipo
    UNION ALL SELECT 6, 'Partida.estado', estado, COUNT(*) FROM dbo.Partida GROUP BY estado
    UNION ALL SELECT 7, 'Partida.forma_termino', ISNULL(forma_termino, 'NULL'), COUNT(*) FROM dbo.Partida GROUP BY forma_termino
    UNION ALL SELECT 8, 'Participacion.resultado', ISNULL(resultado, 'NULL'), COUNT(*) FROM dbo.Participacion GROUP BY resultado
    UNION ALL SELECT 9, 'OfertaTablas.estado', estado, COUNT(*) FROM dbo.OfertaTablas GROUP BY estado
    UNION ALL SELECT 10, 'Invitacion.estado', estado, COUNT(*) FROM dbo.Invitacion GROUP BY estado
    UNION ALL SELECT 11, 'Mensaje.canal', canal, COUNT(*) FROM dbo.Mensaje GROUP BY canal
    UNION ALL SELECT 12, 'ObjetoCosmetico.rareza', rareza, COUNT(*) FROM dbo.ObjetoCosmetico GROUP BY rareza
    UNION ALL SELECT 13, 'Caja.estado', estado, COUNT(*) FROM dbo.Caja GROUP BY estado
    UNION ALL SELECT 14, 'MovimientoMoneda.tipo', tipo, COUNT(*) FROM dbo.MovimientoMoneda GROUP BY tipo
    UNION ALL SELECT 15, 'Reporte.estado', estado, COUNT(*) FROM dbo.Reporte GROUP BY estado
    UNION ALL SELECT 16, 'Sancion.tipo', CONCAT(ambito, ' ', tipo), COUNT(*) FROM dbo.Sancion GROUP BY ambito, tipo
    UNION ALL SELECT 17, 'Apelacion.estado', estado, COUNT(*) FROM dbo.Apelacion GROUP BY estado
    UNION ALL SELECT 18, 'TokenRecuperacion.estado', estado, COUNT(*) FROM dbo.TokenRecuperacion GROUP BY estado
) AS c
GROUP BY c.o, c.columna
ORDER BY c.o;

SELECT pa.id_partida, u.nickname, pa.orden_turno, pa.resultado, pa.posicion, pa.forma_termino,
       pa.elo_inicial, pa.elo_final, pa.reloj_restante, pa.casilla_actual
FROM dbo.Participacion AS pa JOIN dbo.Usuario AS u ON u.id_usuario = pa.id_usuario
ORDER BY pa.id_partida, pa.orden_turno;

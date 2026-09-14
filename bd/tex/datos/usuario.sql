SELECT id_usuario AS id, CAST(nickname AS NVARCHAR(14)) AS nickname, CAST(tipo_cuenta AS VARCHAR(10)) AS tipo,
       CAST(estado_cuenta AS VARCHAR(10)) AS estado, CAST(rol AS VARCHAR(13)) AS rol, CAST(idioma_preferido AS VARCHAR(6)) AS idioma,
       CAST(correo AS NVARCHAR(24)) AS correo, nivel, saldo_monedas AS saldo, doble_factor_habilitado AS dos_factores
FROM dbo.Usuario ORDER BY id_usuario;

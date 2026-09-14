/*=====================================================================
  Bastion - Pruebas de rechazo
  Motor: SQL Server 2019 o posterior (CON-04); probado en SQL Server 2025.

  Intenta, sobre la base cargada con insertar_datos_prueba.sql, operaciones
  que el documento prohíbe, y anota qué error devuelve SQL Server y qué
  restricción lo provoca. Cada intento va en su propia transacción, que se
  revierte siempre: el script no cambia ningún dato.

  Se ejecuta con una cuenta de administración, que puede actuar como
  BastionServerConnection con EXECUTE AS para la última prueba.
=====================================================================*/

USE Bastion;
GO
SET NOCOUNT ON;
SET XACT_ABORT OFF;

DECLARE @pruebas TABLE (
    n          INT            NOT NULL PRIMARY KEY,
    prueba     NVARCHAR(60)   NOT NULL,
    regla      NVARCHAR(24)   NOT NULL,
    sentencia  NVARCHAR(MAX)  NOT NULL
);
INSERT INTO @pruebas VALUES
    (1,  N'Estado de cuenta fuera del dominio',          N'CRUD, dominios',
         N'UPDATE dbo.Usuario SET estado_cuenta = ''BLOQUEADA'' WHERE id_usuario = 3;'),
    (2,  N'Nickname igual salvo mayúsculas y acentos',   N'CU-02 RN-01',
         N'INSERT INTO dbo.Usuario (tipo_cuenta, estado_cuenta, rol, nickname) VALUES (''INVITADO'', ''ACTIVA'', ''JUGADOR'', N''LUIS_QUÓ'');'),
    (3,  N'Idioma no admitido',                          N'CU-12 FA-07, D-21',
         N'UPDATE dbo.Usuario SET idioma_preferido = ''fr'' WHERE id_usuario = 3;'),
    (4,  N'Saldo de monedas negativo',                   N'CU-40 RN-02',
         N'UPDATE dbo.Usuario SET saldo_monedas = -50 WHERE id_usuario = 3;'),
    (5,  N'Amistad con una cuenta que no existe',        N'Llave foránea',
         N'INSERT INTO dbo.Amistad (id_usuario_a, id_usuario_b) VALUES (3, 99);'),
    (6,  N'Equipar un objeto que no se posee',           N'CU-14 RN-02',
         N'UPDATE dbo.Equipamiento SET id_objeto = 105 WHERE id_usuario = 5 AND id_ranura = 1;'),
    (7,  N'Equipar un objeto en otra ranura',            N'D-03, CU-14 RN-01',
         N'UPDATE dbo.Equipamiento SET id_objeto = 202 WHERE id_usuario = 3 AND id_ranura = 1;'),
    (8,  N'Segunda partida sin terminar',                N'D-11',
         N'INSERT INTO dbo.Participacion (id_partida, id_usuario, orden_turno, simbolo_peon, casilla_actual, muros_restantes) VALUES (6, 3, 3, ''VERDE'', ''d4'', 6);'),
    (9,  N'Segundo código de recuperación vigente',      N'CU-03 RN-05',
         N'INSERT INTO dbo.TokenRecuperacion (id_usuario, token_hash, fecha_expiracion, estado) VALUES (1, HASHBYTES(''SHA2_256'', ''otro''), ''2026-09-01T18:20:00'', ''PENDIENTE'');'),
    (10, N'Reportarse a sí mismo',                       N'CU-42 FA-06',
         N'INSERT INTO dbo.Reporte (id_denunciante, id_reportado, id_motivo, estado) VALUES (3, 3, 1, ''PENDIENTE'');'),
    (11, N'Sanción temporal sin fecha de fin',           N'CU-44 RN-04',
         N'INSERT INTO dbo.Sancion (id_usuario, id_moderador, ambito, tipo, motivo) VALUES (9, 2, ''CHAT'', ''TEMPORAL'', N''Prueba'');'),
    (12, N'Compra que no dice qué objeto',               N'CU-38 RN-08',
         N'INSERT INTO dbo.MovimientoMoneda (id_usuario, tipo, importe) VALUES (3, ''COMPRA'', -100);'),
    (13, N'Borrar con el usuario de conexión',           N'Permisos de conexión',
         N'EXECUTE AS LOGIN = ''BastionServerConnection''; DELETE FROM dbo.Silencio;');

DECLARE @resultados TABLE (n INT, error INT, mensaje NVARCHAR(4000));
DECLARE @n INT = 1, @sentencia NVARCHAR(MAX);
WHILE @n <= (SELECT MAX(n) FROM @pruebas)
BEGIN
    SELECT @sentencia = sentencia FROM @pruebas WHERE n = @n;
    BEGIN TRY
        BEGIN TRANSACTION;
        EXEC sys.sp_executesql @sentencia;
        ROLLBACK TRANSACTION;
        INSERT INTO @resultados VALUES (@n, 0, N'Aceptada: la base no la impidió.');
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        INSERT INTO @resultados VALUES (@n, ERROR_NUMBER(), ERROR_MESSAGE());
    END CATCH;
    SET @n += 1;
END;

-- El nombre de la restricción está entre las primeras comillas dobles del
-- mensaje (547), entre el primer par de comillas simples (2627) o entre el
-- segundo (2601).
SELECT CAST(p.n AS VARCHAR(2)) AS n,
       CAST(p.prueba AS NVARCHAR(44)) AS prueba,
       CAST(p.regla AS NVARCHAR(20)) AS regla,
       r.error,
       CAST(CASE
           WHEN r.error = 547 THEN SUBSTRING(r.mensaje, a.d1 + 1, CHARINDEX('"', r.mensaje, a.d1 + 1) - a.d1 - 1)
           WHEN r.error = 2627 THEN SUBSTRING(r.mensaje, a.s1 + 1, b.s2 - a.s1 - 1)
           WHEN r.error = 2601 THEN SUBSTRING(r.mensaje, c.s3 + 1, CHARINDEX('''', r.mensaje, c.s3 + 1) - c.s3 - 1)
           WHEN r.error = 229 THEN N'permiso DELETE denegado'
           ELSE r.mensaje END AS NVARCHAR(40)) AS rechazada_por
FROM @pruebas AS p
JOIN @resultados AS r ON r.n = p.n
CROSS APPLY (SELECT CHARINDEX('"', r.mensaje) AS d1, CHARINDEX('''', r.mensaje) AS s1) AS a
CROSS APPLY (SELECT CHARINDEX('''', r.mensaje, a.s1 + 1) AS s2) AS b
CROSS APPLY (SELECT CHARINDEX('''', r.mensaje, b.s2 + 1) AS s3) AS c
ORDER BY p.n;
GO

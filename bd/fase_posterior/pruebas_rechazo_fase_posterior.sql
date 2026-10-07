/*=====================================================================
  Bastion - Pruebas de rechazo de la fase posterior
  Motor: SQL Server 2019 o posterior (CON-04).

  Intenta, sobre la base cargada con los dos scripts de datos, el del núcleo y
  fase_posterior/insertar_datos_prueba_fase_posterior.sql, operaciones
  que el documento prohíbe, y anota qué error devuelve SQL Server y qué
  restricción lo provoca. Cada intento va en su propia transacción, que se
  revierte siempre: el script no cambia ningún dato.

  Se ejecuta con una cuenta de administración. Estas cinco pruebas estaban en pruebas_rechazo.sql antes de separar el
  núcleo de la fase posterior (D-22).
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
    (1,  N'Saldo de monedas negativo',                   N'CU-40 RN-02',
         N'UPDATE dbo.Usuario SET saldo_monedas = -50 WHERE id_usuario = 3;'),
    (2,  N'Amistad con una cuenta que no existe',        N'Llave foránea',
         N'INSERT INTO dbo.Amistad (id_usuario_a, id_usuario_b) VALUES (3, 99);'),
    (3,  N'Equipar un objeto que no se posee',           N'CU-14 RN-02',
         N'UPDATE dbo.Equipamiento SET id_objeto = 105 WHERE id_usuario = 5 AND id_ranura = 1;'),
    (4,  N'Equipar un objeto en otra ranura',            N'D-03, CU-14 RN-01',
         N'UPDATE dbo.Equipamiento SET id_objeto = 202 WHERE id_usuario = 3 AND id_ranura = 1;'),
    (5,  N'Compra que no dice qué objeto',               N'CU-38 RN-08',
         N'INSERT INTO dbo.MovimientoMoneda (id_usuario, tipo, importe) VALUES (3, ''COMPRA'', -100);');

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

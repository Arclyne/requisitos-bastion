/*=====================================================================
  Bastion - Creación de la base de datos (1 de 3)
  Motor: SQL Server 2019 o posterior (CON-04); probado en SQL Server 2025.

  Orden de ejecución:
     1. crear_base_datos.sql      <- este archivo
     2. crear_tablas.sql
     3. insertar_datos_prueba.sql

  Se ejecuta con una cuenta que pueda crear bases de datos e inicios de
  sesión (sysadmin), no con BastionServerConnection. Si la base Bastion
  ya existe, la elimina y la crea vacía: es un script de instalación,
  no de actualización.
=====================================================================*/

/*---------------------------------------------------------------------
  1. Base de datos
  Codificación UTF-8 (D-21). La intercalación Modern_Spanish_100_CI_AS_
  SC_UTF8 es española, no distingue mayúsculas y sí acentos, y fija la
  codificación del texto:
    - UTF8: las columnas VARCHAR y los literales sin prefijo N guardan
      texto en UTF-8, así que admiten la ñ, los acentos y cualquier
      carácter Unicode, no solo los de la página de códigos 1252. Las
      NVARCHAR guardan UTF-16 con cualquier intercalación.
    - SC: los caracteres suplementarios, como los emojis, cuentan como
      un carácter en LEN, SUBSTRING y los límites de longitud.
  Las columnas que deben compararse también sin acentos, como nickname,
  declaran su propia intercalación, también _SC_UTF8.
---------------------------------------------------------------------*/

USE master;
GO
IF DB_ID(N'Bastion') IS NOT NULL
BEGIN
    ALTER DATABASE Bastion SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE Bastion;
END
GO
CREATE DATABASE Bastion COLLATE Modern_Spanish_100_CI_AS_SC_UTF8;
GO

/*---------------------------------------------------------------------
  2. Usuario de conexión del servidor
  El Servidor de partidas se conecta con este usuario. Solo puede leer,
  insertar, modificar y ejecutar procedimientos en toda la base:
  no puede borrar filas, crear ni alterar objetos, ni conceder permisos.
---------------------------------------------------------------------*/

USE master;
GO
IF SUSER_ID(N'BastionServerConnection') IS NULL
    CREATE LOGIN BastionServerConnection
        WITH PASSWORD = N'B4sT10nCONnecti0n',
             DEFAULT_DATABASE = Bastion,
             CHECK_POLICY = ON,
             CHECK_EXPIRATION = OFF;
GO

USE Bastion;
GO
IF USER_ID(N'BastionServerConnection') IS NULL
    CREATE USER BastionServerConnection FOR LOGIN BastionServerConnection WITH DEFAULT_SCHEMA = dbo;
GO

-- Permisos a nivel de base de datos: alcanzan a todas las tablas, vistas y
-- procedimientos, presentes y futuros, de todos los esquemas.
GRANT SELECT, INSERT, UPDATE, EXECUTE ON DATABASE::Bastion TO BastionServerConnection;
GO

-- Comprobación: debe listar CONNECT (implícito al crear el usuario),
-- SELECT, INSERT, UPDATE y EXECUTE, todos con alcance DATABASE y estado GRANT.
SELECT pr.name            AS usuario,
       pe.permission_name AS permiso,
       pe.state_desc      AS estado,
       pe.class_desc      AS alcance
FROM sys.database_permissions AS pe
JOIN sys.database_principals  AS pr ON pr.principal_id = pe.grantee_principal_id
WHERE pr.name = N'BastionServerConnection'
ORDER BY pe.permission_name;
GO

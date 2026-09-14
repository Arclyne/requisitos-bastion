WITH t AS (
    SELECT t.name AS tabla, SUM(p.rows) AS filas,
           ROW_NUMBER() OVER (ORDER BY t.name) - 1 AS n,
           COUNT(*) OVER () AS total
    FROM sys.tables AS t
    JOIN sys.partitions AS p ON p.object_id = t.object_id AND p.index_id IN (0, 1)
    GROUP BY t.name
)
SELECT CAST(a.tabla AS VARCHAR(26)) AS tabla, a.filas,
       CAST(b.tabla AS VARCHAR(26)) AS tabla, b.filas,
       ISNULL(CAST(c.tabla AS VARCHAR(26)), '') AS tabla, ISNULL(CAST(c.filas AS VARCHAR(12)), '') AS filas
FROM t AS a
LEFT JOIN t AS b ON b.n = a.n + (a.total + 2) / 3
LEFT JOIN t AS c ON c.n = a.n + 2 * ((a.total + 2) / 3)
WHERE a.n < (a.total + 2) / 3
ORDER BY a.n;

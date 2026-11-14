/* CITYBIKE — Read-only physical SQL Server schema metadata export.
   Run in SSMS with the CityBikeDW database selected.
   Results-to-file will capture metadata from the actual current database.
   Does not modify any tables, run ETL or assume any benchmark counts.
*/
USE CityBikeDW;
SET NOCOUNT ON;
SELECT
    s.name AS schema_name,
    t.name AS table_name,
    c.column_id AS ordinal_position,
    c.name AS column_name,
    typ.name AS data_type,
    CASE WHEN typ.name IN ('varchar','nvarchar','char','nchar','binary','varbinary')
         THEN CASE WHEN c.max_length = -1 THEN 'MAX'
                   WHEN typ.name IN ('nvarchar','nchar') THEN CONVERT(varchar(20),c.max_length/2)
                   ELSE CONVERT(varchar(20),c.max_length) END
         WHEN typ.name IN ('decimal','numeric') THEN CONCAT(c.precision,',',c.scale)
         ELSE NULL END AS type_length_precision,
    c.is_nullable,
    c.is_identity,
    COALESCE(i.is_primary_key,0) AS is_primary_key,
    dc.definition AS default_expression
FROM sys.schemas s
JOIN sys.tables t ON t.schema_id = s.schema_id
JOIN sys.columns c ON c.object_id = t.object_id
JOIN sys.types typ ON typ.user_type_id = c.user_type_id
LEFT JOIN sys.default_constraints dc ON dc.parent_object_id=c.object_id AND dc.parent_column_id=c.column_id
OUTER APPLY (
    SELECT MAX(CASE WHEN idx.is_primary_key=1 THEN 1 ELSE 0 END) AS is_primary_key
    FROM sys.index_columns ic
    JOIN sys.indexes idx ON idx.object_id=ic.object_id AND idx.index_id=ic.index_id
    WHERE ic.object_id=c.object_id AND ic.column_id=c.column_id
) i
WHERE s.name IN ('stg','dw','etl')
ORDER BY s.name,t.name,c.column_id;

SELECT fk.name AS constraint_name,
       OBJECT_SCHEMA_NAME(fk.parent_object_id) AS parent_schema,
       OBJECT_NAME(fk.parent_object_id) AS parent_table,
       pc.name AS parent_column,
       OBJECT_SCHEMA_NAME(fk.referenced_object_id) AS referenced_schema,
       OBJECT_NAME(fk.referenced_object_id) AS referenced_table,
       rc.name AS referenced_column,
       fk.is_disabled,
       fk.is_not_trusted
FROM sys.foreign_keys fk
JOIN sys.foreign_key_columns fkc ON fkc.constraint_object_id=fk.object_id
JOIN sys.columns pc ON pc.object_id=fkc.parent_object_id AND pc.column_id=fkc.parent_column_id
JOIN sys.columns rc ON rc.object_id=fkc.referenced_object_id AND rc.column_id=fkc.referenced_column_id
WHERE OBJECT_SCHEMA_NAME(fk.parent_object_id) IN ('stg','dw','etl')
ORDER BY parent_schema,parent_table,fk.name,fkc.constraint_column_id;

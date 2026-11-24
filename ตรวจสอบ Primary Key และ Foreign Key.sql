USE HR_Payroll_DB
GO

SELECT
    TABLE_NAME,
    COLUMN_NAME,
    CONSTRAINT_NAME
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE OBJECTPROPERTY(
    OBJECT_ID(CONSTRAINT_NAME),
    'IsPrimaryKey'
) = 1
ORDER BY TABLE_NAME

SELECT
    fk.name AS ForeignKeyName,
    tp.name AS TableName,
    cp.name AS ColumnName,
    tr.name AS ReferenceTable,
    cr.name AS ReferenceColumn
FROM sys.foreign_keys fk
INNER JOIN sys.foreign_key_columns fkc
    ON fk.object_id = fkc.constraint_object_id
INNER JOIN sys.tables tp
    ON fkc.parent_object_id = tp.object_id
INNER JOIN sys.columns cp
    ON fkc.parent_object_id = cp.object_id
    AND fkc.parent_column_id = cp.column_id
INNER JOIN sys.tables tr
    ON fkc.referenced_object_id = tr.object_id
INNER JOIN sys.columns cr
    ON fkc.referenced_object_id = cr.object_id
    AND fkc.referenced_column_id = cr.column_id
ORDER BY tp.name

SELECT
    TABLE_NAME,
    CONSTRAINT_NAME,
    CONSTRAINT_TYPE
FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
ORDER BY TABLE_NAME

EXEC sp_helpconstraint 'Employees'
GO

EXEC sp_helpconstraint 'PayrollDetails'
GO

EXEC sp_helpconstraint 'LeaveRequests'
GO

EXEC sp_helpconstraint 'OTRequests'
GO
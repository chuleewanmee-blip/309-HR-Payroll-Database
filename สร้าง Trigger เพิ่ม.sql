USE HR_Payroll_DB
GO

-- Stored Procedures
SELECT 
    name AS ObjectName,
    create_date,
    modify_date
FROM sys.objects
WHERE type = 'P'
ORDER BY name
GO

-- Triggers
SELECT 
    name AS TriggerName,
    create_date,
    modify_date
FROM sys.triggers
WHERE parent_class = 1
ORDER BY name
GO

-- Functions
SELECT 
    name AS FunctionName,
    create_date,
    modify_date
FROM sys.objects
WHERE type IN ('FN', 'IF', 'TF')
ORDER BY name
GO

-- Views
SELECT 
    name AS ViewName,
    create_date,
    modify_date
FROM sys.views
ORDER BY name
GO

USE HR_Payroll_DB
GO

CREATE TRIGGER trg_CheckSalaryBeforeInsert
ON Employees
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON

    IF EXISTS (
        SELECT 1
        FROM inserted
        WHERE Salary < 0
    )
    BEGIN
        RAISERROR ('เงินเดือนต้องไม่ติดลบ', 16, 1)
        ROLLBACK TRANSACTION
        RETURN
    END
END
GO

USE HR_Payroll_DB
GO

SELECT 
    COLUMN_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Employees'
ORDER BY ORDINAL_POSITION
GO

USE HR_Payroll_DB
GO

CREATE TRIGGER trg_PreventEmployeeDelete
ON Employees
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON

    RAISERROR ('ไม่อนุญาตให้ลบข้อมูลพนักงาน', 16, 1)
    ROLLBACK TRANSACTION
END
GO


USE HR_Payroll_DB
GO

SELECT 
    name AS TriggerName,
    create_date,
    modify_date
FROM sys.triggers
WHERE parent_class = 1
ORDER BY name
GO

USE HR_Payroll_DB
GO

SELECT 
    name AS TriggerName,
    create_date,
    modify_date
FROM sys.triggers
WHERE parent_class = 1
ORDER BY name
GO
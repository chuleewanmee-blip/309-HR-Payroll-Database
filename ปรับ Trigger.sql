CREATE OR ALTER TRIGGER trg_PreventEmployeeDelete
ON Employees
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- ตรวจสอบประวัติเงินเดือน
    IF EXISTS (
        SELECT 1
        FROM deleted d
        INNER JOIN Payroll p
            ON d.EmployeeID = p.EmployeeID
    )
    BEGIN
        THROW 50001,
        N'ไม่สามารถลบพนักงานที่มีประวัติเงินเดือนได้',
        1;
    END;

    -- หากไม่มีประวัติเงินเดือนจึงอนุญาตให้ลบ
    DELETE e
    FROM Employee e
    INNER JOIN deleted d
        ON e.EmployeesID = d.EmployeesID;
END;
GO

EXEC sp_helptext 'trg_PreventEmployeeDelete';

USE HR_Payroll_DB
GO

SELECT
    name AS TriggerName,
    OBJECT_NAME(parent_id) AS TableName,
    create_date,
    modify_date,
    is_disabled
FROM sys.triggers
WHERE parent_class = 1
ORDER BY name
GO